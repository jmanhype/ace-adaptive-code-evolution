defmodule Ace.RealWorld.Benchmark do
  @moduledoc """
  Benchmarks for ACE on real-world codebases.
  """
  
  @doc """
  Runs performance benchmarks across all codebases.
  
  ## Parameters
  
  - `results_dir` - Directory containing test results
  
  ## Returns
  
  Map with benchmark results
  """
  def run_benchmarks(results_dir) do
    # Load analysis results
    analysis = Ace.RealWorld.ResultAnalyzer.analyze_results(results_dir)
    
    # Run each benchmark
    benchmarks = %{
      scaling: benchmark_scaling(analysis),
      memory_usage: benchmark_memory_usage(analysis),
      language_performance: benchmark_language_performance(analysis)
    }
    
    # Save benchmark results
    File.write!(
      Path.join(results_dir, "benchmarks.json"),
      Jason.encode!(benchmarks, pretty: true)
    )
    
    # Save to latest results
    File.write!(
      Path.join([results_dir, "..", "latest", "benchmarks.json"]),
      Jason.encode!(benchmarks, pretty: true)
    )
    
    # Return benchmark results
    benchmarks
  end
  
  @doc """
  Plots benchmark results.
  
  ## Parameters
  
  - `results_dir` - Directory containing test results
  - `output_dir` - Directory to save plots (defaults to results_dir)
  """
  def plot_benchmarks(results_dir, output_dir \\ nil) do
    output_dir = output_dir || results_dir
    
    # Ensure output directory exists
    File.mkdir_p!(output_dir)
    
    # Load benchmarks
    benchmarks = 
      Path.join(results_dir, "benchmarks.json")
      |> File.read!()
      |> Jason.decode!()
    
    # Generate gnuplot scripts for each benchmark
    plot_scaling(benchmarks["scaling"], output_dir)
    plot_memory_usage(benchmarks["memory_usage"], output_dir)
    plot_language_performance(benchmarks["language_performance"], output_dir)
    
    :ok
  end
  
  #
  # Private benchmark functions
  #
  
  # Benchmark how ACE scales with codebase size
  defp benchmark_scaling(analysis) do
    # Extract codebase sizes and timing information
    data = 
      Enum.map(analysis.codebases, fn {name, results} ->
        # Get line count
        line_count = get_in(results, ["stats", "line_count", "total"]) || 0
        
        # Get timing info
        analysis_time = get_in(results, ["metrics", "file_analysis", "elapsed_ms"]) || 0
        relationship_time = get_in(results, ["metrics", "relationship_detection", "elapsed_ms"]) || 0
        cross_file_time = get_in(results, ["metrics", "cross_file_analysis", "elapsed_ms"]) || 0
        
        # Calculate total time
        total_time = analysis_time + relationship_time + cross_file_time
        
        # Return data point
        %{
          codebase: name,
          line_count: line_count,
          analysis_time_ms: analysis_time,
          relationship_time_ms: relationship_time,
          cross_file_time_ms: cross_file_time,
          total_time_ms: total_time
        }
      end)
      |> Enum.filter(fn point -> point.line_count > 0 end)
      |> Enum.sort_by(fn point -> point.line_count end)
    
    # Fit scaling models
    models = %{
      linear: fit_linear_model(data, :line_count, :total_time_ms),
      power: fit_power_model(data, :line_count, :total_time_ms)
    }
    
    # Return benchmark data and models
    %{
      data: data,
      models: models
    }
  end
  
  # Benchmark memory usage patterns
  defp benchmark_memory_usage(analysis) do
    # Extract codebase sizes and memory information
    data = 
      Enum.map(analysis.codebases, fn {name, results} ->
        # Get line count
        line_count = get_in(results, ["stats", "line_count", "total"]) || 0
        
        # Get memory info
        analysis_memory = get_in(results, ["metrics", "file_analysis", "memory_delta_bytes"]) || 0
        relationship_memory = get_in(results, ["metrics", "relationship_detection", "memory_delta_bytes"]) || 0
        cross_file_memory = get_in(results, ["metrics", "cross_file_analysis", "memory_delta_bytes"]) || 0
        
        # Calculate total memory
        total_memory = analysis_memory + relationship_memory + cross_file_memory
        
        # Calculate memory per LOC
        memory_per_loc = if line_count > 0, do: total_memory / line_count, else: 0
        
        # Return data point
        %{
          codebase: name,
          line_count: line_count,
          analysis_memory_bytes: analysis_memory,
          relationship_memory_bytes: relationship_memory,
          cross_file_memory_bytes: cross_file_memory,
          total_memory_bytes: total_memory,
          bytes_per_loc: memory_per_loc
        }
      end)
      |> Enum.filter(fn point -> point.line_count > 0 end)
      |> Enum.sort_by(fn point -> point.line_count end)
    
    # Fit memory usage models
    models = %{
      linear: fit_linear_model(data, :line_count, :total_memory_bytes)
    }
    
    # Return benchmark data and models
    %{
      data: data,
      models: models
    }
  end
  
  # Benchmark performance by language
  defp benchmark_language_performance(analysis) do
    # Group by language
    by_language = 
      Enum.reduce(analysis.codebases, %{}, fn {name, results}, acc ->
        language = get_in(results, ["codebase", "language"])
        
        if language do
          language_data = %{
            codebase: name,
            line_count: get_in(results, ["stats", "line_count", "total"]) || 0,
            analysis_time_ms: get_in(results, ["metrics", "file_analysis", "elapsed_ms"]) || 0,
            relationship_time_ms: get_in(results, ["metrics", "relationship_detection", "elapsed_ms"]) || 0,
            cross_file_time_ms: get_in(results, ["metrics", "cross_file_analysis", "elapsed_ms"]) || 0
          }
          
          Map.update(
            acc, 
            language, 
            [language_data], 
            &[language_data | &1]
          )
        else
          acc
        end
      end)
    
    # Calculate average metrics by language
    language_averages = 
      Enum.map(by_language, fn {language, data_points} ->
        # Filter out data points with no line count
        valid_points = Enum.filter(data_points, fn p -> p.line_count > 0 end)
        
        if Enum.empty?(valid_points) do
          nil
        else
          # Calculate averages
          avg_analysis_time = average_of(valid_points, :analysis_time_ms)
          avg_relationship_time = average_of(valid_points, :relationship_time_ms)
          avg_cross_file_time = average_of(valid_points, :cross_file_time_ms)
          avg_line_count = average_of(valid_points, :line_count)
          
          # Calculate time per LOC
          time_per_1k_loc = 
            if avg_line_count > 0 do
              (avg_analysis_time + avg_relationship_time + avg_cross_file_time) / (avg_line_count / 1000)
            else
              0
            end
          
          %{
            language: language,
            codebase_count: length(valid_points),
            avg_line_count: avg_line_count,
            avg_analysis_time_ms: avg_analysis_time,
            avg_relationship_time_ms: avg_relationship_time,
            avg_cross_file_time_ms: avg_cross_file_time,
            time_per_1k_loc: time_per_1k_loc
          }
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.sort_by(fn avg -> avg.time_per_1k_loc end)
    
    # Return benchmark data
    %{
      by_language: by_language,
      language_averages: language_averages
    }
  end
  
  #
  # Private plotting functions
  #
  
  # Plot scaling benchmark results
  defp plot_scaling(scaling, output_dir) do
    data_file = Path.join(output_dir, "scaling_data.txt")
    script_file = Path.join(output_dir, "plot_scaling.gnuplot")
    output_file = Path.join(output_dir, "scaling_plot.png")
    
    # Write data file
    data_content = 
      scaling["data"]
      |> Enum.map(fn point ->
        "#{point["codebase"]} #{point["line_count"]} #{point["total_time_ms"]}"
      end)
      |> Enum.join("\n")
    
    File.write!(data_file, data_content)
    
    # Write gnuplot script
    script_content = """
    set terminal pngcairo enhanced font "Arial,12" size 800,600
    set output "#{output_file}"
    set title "ACE Performance Scaling"
    set xlabel "Lines of Code"
    set ylabel "Total Analysis Time (ms)"
    set grid
    set key left top
    
    # Plot data points
    plot "#{data_file}" using 2:3 with points pt 7 ps 1.5 title "Codebases"
    """
    
    File.write!(script_file, script_content)
    
    # Execute gnuplot (optional - depends on system)
    # System.cmd("gnuplot", [script_file])
  end
  
  # Plot memory usage benchmark results
  defp plot_memory_usage(memory_usage, output_dir) do
    data_file = Path.join(output_dir, "memory_data.txt")
    script_file = Path.join(output_dir, "plot_memory.gnuplot")
    output_file = Path.join(output_dir, "memory_plot.png")
    
    # Write data file
    data_content = 
      memory_usage["data"]
      |> Enum.map(fn point ->
        "#{point["codebase"]} #{point["line_count"]} #{point["total_memory_bytes"] / 1024}"
      end)
      |> Enum.join("\n")
    
    File.write!(data_file, data_content)
    
    # Write gnuplot script
    script_content = """
    set terminal pngcairo enhanced font "Arial,12" size 800,600
    set output "#{output_file}"
    set title "ACE Memory Usage"
    set xlabel "Lines of Code"
    set ylabel "Memory Usage (KB)"
    set grid
    set key left top
    
    # Plot data points
    plot "#{data_file}" using 2:3 with points pt 7 ps 1.5 title "Memory Usage"
    """
    
    File.write!(script_file, script_content)
    
    # Execute gnuplot (optional - depends on system)
    # System.cmd("gnuplot", [script_file])
  end
  
  # Plot language performance benchmark results
  defp plot_language_performance(language_performance, output_dir) do
    data_file = Path.join(output_dir, "language_data.txt")
    script_file = Path.join(output_dir, "plot_language.gnuplot")
    output_file = Path.join(output_dir, "language_plot.png")
    
    # Write data file
    data_content = 
      language_performance["language_averages"]
      |> Enum.map(fn avg ->
        "#{avg["language"]} #{avg["time_per_1k_loc"]}"
      end)
      |> Enum.join("\n")
    
    File.write!(data_file, data_content)
    
    # Write gnuplot script
    script_content = """
    set terminal pngcairo enhanced font "Arial,12" size 800,600
    set output "#{output_file}"
    set title "ACE Performance by Language"
    set xlabel "Language"
    set ylabel "Time per 1K LOC (ms)"
    set grid
    set key left top
    set style data histograms
    set style fill solid border -1
    
    # Plot data as histogram
    plot "#{data_file}" using 2:xtic(1) title ""
    """
    
    File.write!(script_file, script_content)
    
    # Execute gnuplot (optional - depends on system)
    # System.cmd("gnuplot", [script_file])
  end
  
  #
  # Private helper functions
  #
  
  # Calculate average of values for a specific key
  defp average_of(items, key) when is_list(items) and is_atom(key) do
    values = Enum.map(items, fn item -> Map.get(item, key, 0) end)
    if Enum.empty?(values), do: 0, else: Enum.sum(values) / length(values)
  end
  
  # Fit linear model (y = a*x + b)
  defp fit_linear_model(data, x_key, y_key) do
    # Extract x and y values
    points = Enum.map(data, fn point -> {Map.get(point, x_key, 0), Map.get(point, y_key, 0)} end)
    
    if Enum.empty?(points) do
      %{a: 0, b: 0, r_squared: 0}
    else
      # Calculate means
      n = length(points)
      sum_x = Enum.sum(Enum.map(points, fn {x, _} -> x end))
      sum_y = Enum.sum(Enum.map(points, fn {_, y} -> y end))
      mean_x = sum_x / n
      mean_y = sum_y / n
      
      # Calculate coefficients
      sum_xy = Enum.sum(Enum.map(points, fn {x, y} -> x * y end))
      sum_x_squared = Enum.sum(Enum.map(points, fn {x, _} -> x * x end))
      
      # Calculate slope (a) and intercept (b)
      a = (n * sum_xy - sum_x * sum_y) / (n * sum_x_squared - sum_x * sum_x)
      b = mean_y - a * mean_x
      
      # Calculate R-squared
      y_pred = Enum.map(points, fn {x, _} -> a * x + b end)
      ss_res = Enum.zip(points, y_pred)
              |> Enum.map(fn {{_, y_actual}, y_predicted} -> (y_actual - y_predicted) * (y_actual - y_predicted) end)
              |> Enum.sum()
      ss_tot = Enum.map(points, fn {_, y} -> (y - mean_y) * (y - mean_y) end)
              |> Enum.sum()
      
      r_squared = if ss_tot == 0, do: 0, else: 1 - ss_res / ss_tot
      
      %{a: a, b: b, r_squared: r_squared}
    end
  end
  
  # Fit power model (y = a*x^b)
  defp fit_power_model(data, x_key, y_key) do
    # Extract x and y values, filtering out non-positive values
    points = 
      Enum.map(data, fn point -> {Map.get(point, x_key, 0), Map.get(point, y_key, 0)} end)
      |> Enum.filter(fn {x, y} -> x > 0 && y > 0 end)
    
    if Enum.empty?(points) do
      %{a: 0, b: 0, r_squared: 0}
    else
      # Convert to log space for linear regression
      log_points = Enum.map(points, fn {x, y} -> {Math.log(x), Math.log(y)} end)
      
      # Fit linear model in log space
      linear_model = fit_linear_model(
        Enum.map(log_points, fn {log_x, log_y} -> %{x: log_x, y: log_y} end),
        :x,
        :y
      )
      
      # Convert back to power model
      a = Math.exp(linear_model.b)
      b = linear_model.a
      
      # Return power model parameters
      %{a: a, b: b, r_squared: linear_model.r_squared}
    end
  rescue
    # Handle errors (like Math not being defined)
    _ -> %{a: 0, b: 0, r_squared: 0}
  end
end

# Define Math module if not available
unless Code.ensure_loaded?(Math) do
  defmodule Math do
    @moduledoc false
    
    def log(x) when x > 0, do: :math.log(x)
    def exp(x), do: :math.exp(x)
  end
end