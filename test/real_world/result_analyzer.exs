defmodule Ace.RealWorld.ResultAnalyzer do
  @moduledoc """
  Analyzes results from real-world codebase tests.
  """
  
  @doc """
  Analyzes results from a test run.
  
  ## Parameters
  
  - `results_dir` - Directory containing test results
  
  ## Returns
  
  Map with analysis results
  """
  def analyze_results(results_dir) do
    # Load test run info
    test_run_info = 
      Path.join(results_dir, "test_run_info.json")
      |> File.read!()
      |> Jason.decode!()
    
    # Get all codebase directories
    codebase_dirs = 
      results_dir
      |> File.ls!()
      |> Enum.filter(&File.dir?(Path.join(results_dir, &1)))
      |> Enum.reject(&(&1 == "latest"))
    
    # Load results for each codebase
    codebase_results = 
      Enum.reduce(codebase_dirs, %{}, fn dir, acc ->
        result_path = Path.join([results_dir, dir, "results.json"])
        
        if File.exists?(result_path) do
          results = File.read!(result_path) |> Jason.decode!()
          Map.put(acc, dir, results)
        else
          acc
        end
      end)
    
    # Generate comparative metrics
    comparative_metrics = generate_comparative_metrics(codebase_results)
    
    # Generate language-specific metrics
    language_metrics = generate_language_metrics(codebase_results)
    
    # Generate size-based metrics
    size_metrics = generate_size_metrics(codebase_results)
    
    # Return complete analysis
    %{
      test_run: test_run_info,
      codebases: codebase_results,
      comparative_metrics: comparative_metrics,
      language_metrics: language_metrics,
      size_metrics: size_metrics
    }
  end
  
  @doc """
  Prints a summary of the analysis results.
  
  ## Parameters
  
  - `analysis` - Analysis results from analyze_results/1
  """
  def print_summary(analysis) do
    IO.puts("\n=== ACE Real-World Testing Summary ===")
    IO.puts("Test run: #{analysis.test_run["timestamp"]}")
    IO.puts("Codebases tested: #{length(Map.keys(analysis.codebases))}")
    
    # Print codebase summaries
    IO.puts("\nCodebase Results:")
    Enum.each(analysis.codebases, fn {name, results} ->
      metrics = get_in(results, ["metrics", "summary"])
      
      if metrics do
        IO.puts("  #{name}:")
        IO.puts("    Files analyzed: #{metrics["file_count"]}")
        IO.puts("    Relationships detected: #{metrics["relationship_count"]}")
        IO.puts("    Cross-file opportunities: #{metrics["opportunity_count"]}")
        IO.puts("    Total analysis time: #{format_time(metrics["total_elapsed_ms"])}")
      else
        IO.puts("  #{name}: No metrics available")
      end
    end)
    
    # Print language summaries
    IO.puts("\nLanguage Results:")
    Enum.each(analysis.language_metrics, fn {language, metrics} ->
      IO.puts("  #{language}:")
      IO.puts("    Codebases: #{metrics.codebase_count}")
      IO.puts("    Avg. relationships per file: #{Float.round(metrics.avg_relationships_per_file, 2)}")
      IO.puts("    Avg. opportunities per file: #{Float.round(metrics.avg_opportunities_per_file, 2)}")
    end)
    
    # Print size-based metrics
    IO.puts("\nScaling Results:")
    IO.puts("  Analysis time per 1K lines of code:")
    Enum.each(analysis.size_metrics.time_per_1k_loc, fn {size, time} ->
      IO.puts("    #{size}: #{format_time(time)}")
    end)
  end
  
  #
  # Private helper functions
  #
  
  # Generate metrics comparing different codebases
  defp generate_comparative_metrics(codebase_results) do
    # Extract summary metrics for each codebase
    summaries = 
      Enum.reduce(codebase_results, %{}, fn {name, results}, acc ->
        summary = get_in(results, ["metrics", "summary"])
        if summary, do: Map.put(acc, name, summary), else: acc
      end)
    
    # Calculate averages, mins, maxes
    if Enum.empty?(summaries) do
      %{
        avg_analysis_time_ms: 0,
        avg_relationships_per_file: 0,
        avg_opportunities_per_file: 0
      }
    else
      metrics = %{
        avg_analysis_time_ms: average_of(summaries, "total_elapsed_ms"),
        avg_relationships_per_file: average_of(summaries, fn s -> 
          file_count = s["file_count"]
          relationship_count = s["relationship_count"]
          if file_count > 0, do: relationship_count / file_count, else: 0
        end),
        avg_opportunities_per_file: average_of(summaries, fn s -> 
          file_count = s["file_count"]
          opportunity_count = s["opportunity_count"]
          if file_count > 0, do: opportunity_count / file_count, else: 0
        end)
      }
      
      # Add min/max metrics
      metrics
      |> Map.put(:fastest_codebase, min_by(summaries, "total_elapsed_ms"))
      |> Map.put(:slowest_codebase, max_by(summaries, "total_elapsed_ms"))
      |> Map.put(:most_relationships, max_by(summaries, "relationship_count"))
      |> Map.put(:most_opportunities, max_by(summaries, "opportunity_count"))
    end
  end
  
  # Generate metrics grouped by language
  defp generate_language_metrics(codebase_results) do
    # Group codebases by language
    by_language = 
      Enum.reduce(codebase_results, %{}, fn {_name, results}, acc ->
        language = get_in(results, ["codebase", "language"])
        
        if language do
          Map.update(
            acc, 
            language, 
            [results], 
            &[results | &1]
          )
        else
          acc
        end
      end)
    
    # Calculate metrics for each language
    Enum.reduce(by_language, %{}, fn {language, results_list}, acc ->
      # Calculate language-specific metrics
      metrics = %{
        codebase_count: length(results_list),
        avg_relationships_per_file: average_language_metric(results_list, fn r ->
          file_count = get_in(r, ["metrics", "summary", "file_count"]) || 0
          relationship_count = get_in(r, ["metrics", "summary", "relationship_count"]) || 0
          if file_count > 0, do: relationship_count / file_count, else: 0
        end),
        avg_opportunities_per_file: average_language_metric(results_list, fn r ->
          file_count = get_in(r, ["metrics", "summary", "file_count"]) || 0
          opportunity_count = get_in(r, ["metrics", "summary", "opportunity_count"]) || 0
          if file_count > 0, do: opportunity_count / file_count, else: 0
        end)
      }
      
      Map.put(acc, language, metrics)
    end)
  end
  
  # Generate metrics based on codebase size
  defp generate_size_metrics(codebase_results) do
    # Group codebases by size
    by_size = 
      Enum.reduce(codebase_results, %{}, fn {_name, results}, acc ->
        size = get_in(results, ["codebase", "size"])
        
        if size do
          Map.update(
            acc, 
            size, 
            [results], 
            &[results | &1]
          )
        else
          acc
        end
      end)
    
    # Calculate metrics by size
    time_per_1k_loc = 
      Enum.reduce(by_size, %{}, fn {size, results_list}, acc ->
        # Calculate average analysis time per 1K LOC
        avg_time = average_size_metric(results_list, fn r ->
          time_ms = get_in(r, ["metrics", "summary", "total_elapsed_ms"]) || 0
          loc = get_in(r, ["stats", "line_count", "total"]) || 0
          
          if loc > 0, do: time_ms / (loc / 1000), else: 0
        end)
        
        Map.put(acc, size, avg_time)
      end)
    
    # Return size metrics
    %{
      time_per_1k_loc: time_per_1k_loc
    }
  end
  
  # Utility: Average of values extracted by key or function
  defp average_of(map, key_or_func) when is_map(map) do
    values = 
      Enum.map(map, fn {_, value} ->
        cond do
          is_function(key_or_func) -> key_or_func.(value)
          is_binary(key_or_func) -> value[key_or_func] || 0
          true -> 0
        end
      end)
    
    if Enum.empty?(values), do: 0, else: Enum.sum(values) / length(values)
  end
  
  # Utility: Min value by key
  defp min_by(map, key) when is_map(map) do
    Enum.min_by(map, fn {_, v} -> v[key] || 0 end, fn -> nil end)
  end
  
  # Utility: Max value by key
  defp max_by(map, key) when is_map(map) do
    Enum.max_by(map, fn {_, v} -> v[key] || 0 end, fn -> nil end)
  end
  
  # Utility: Average of language metrics
  defp average_language_metric(results_list, func) do
    values = Enum.map(results_list, func)
    if Enum.empty?(values), do: 0, else: Enum.sum(values) / length(values)
  end
  
  # Utility: Average of size metrics
  defp average_size_metric(results_list, func) do
    values = Enum.map(results_list, func)
    if Enum.empty?(values), do: 0, else: Enum.sum(values) / length(values)
  end
  
  # Format time in milliseconds to a readable string
  defp format_time(nil), do: "N/A"
  defp format_time(ms) when is_number(ms) do
    cond do
      ms < 1000 -> "#{Float.round(ms, 1)}ms"
      ms < 60000 -> "#{Float.round(ms / 1000, 1)}s"
      true -> "#{Float.round(ms / 60000, 1)}m"
    end
  end
end