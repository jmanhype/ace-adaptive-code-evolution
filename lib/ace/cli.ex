defmodule Ace.CLI do
  @moduledoc """
  Command Line Interface for ACE.

  This module provides a command-line interface for interacting with
  the Adaptive Code Evolution system.
  """
  
  @doc """
  Entry point for the command-line application.
  """
  def main(args) do
    {opts, cmd, _} = OptionParser.parse(args,
      strict: [
        api_key: :string,
        format: :string,
        output: :string,
        focus_areas: :string,
        severity_threshold: :string,
        strategy: :string,
        auto_apply: :boolean,
        cross_file: :boolean
      ],
      aliases: [
        k: :api_key,
        f: :format,
        o: :output,
        s: :strategy,
        a: :auto_apply,
        c: :cross_file
      ]
    )
  
    case cmd do
      ["analyze" | files] -> handle_analyze(files, opts)
      ["analyze-cross-file" | files] -> handle_analyze_cross_file(files, opts)
      ["optimize" | ids] -> handle_optimize(ids, opts)
      ["evaluate" | ids] -> handle_evaluate(ids, opts)
      ["apply" | ids] -> handle_apply(ids, opts)
      ["run" | files] -> handle_run(files, opts)
      ["init"] -> handle_init(opts)
      ["version"] -> show_version()
      ["help"] -> show_help()
      _ -> show_help()
    end
  end
  
  # Command handlers
  
  defp handle_analyze(files, opts) do
    format = opts[:format] || "text"
    output_path = opts[:output]
    focus_areas = parse_focus_areas(opts[:focus_areas])
    severity_threshold = opts[:severity_threshold] || "medium"
    
    # Check if cross-file analysis is requested
    if opts[:cross_file] && length(files) > 1 do
      handle_analyze_cross_file(files, opts)
    else
      # Regular single-file analysis
      results = Enum.map(files, fn file_path ->
        IO.puts("Analyzing #{file_path}...")
        
        with {:ok, content} <- File.read(file_path),
             language = detect_language(file_path),
             {:ok, analysis} <- Ace.analyze_code(content, language, [
               focus_areas: focus_areas,
               severity_threshold: severity_threshold,
               skip_db: true,      # Skip database interactions for CLI usage
               file_path: file_path  # Pass the file path for better context
             ]) do
          {file_path, {:ok, analysis}}
        else
          {:error, reason} -> {file_path, {:error, reason}}
        end
      end)
    
      formatted_output = case format do
        "json" -> format_results_json(results)
        "text" -> format_analysis_text(results)
        _ -> format_analysis_text(results)
      end
      
      if output_path do
        File.write!(output_path, formatted_output)
        IO.puts("Results written to #{output_path}")
      else
        IO.puts(formatted_output)
      end
    end
  end
  
  defp handle_analyze_cross_file(files, opts) do
    if length(files) < 2 do
      IO.puts("Error: analyze-cross-file requires at least two files to analyze")
      System.halt(1)
    end
    
    format = opts[:format] || "text"
    output_path = opts[:output]
    focus_areas = parse_focus_areas(opts[:focus_areas])
    severity_threshold = opts[:severity_threshold] || "medium"
    
    # Create a project with a unique name
    _project_name = "cli-project-#{:os.system_time(:millisecond)}"
    _project_id = "prj-#{:rand.uniform(999999)}"
    
    IO.puts("Analyzing cross-file relationships in #{length(files)} files...")
    
    # Prepare file contents for analysis
    file_contexts = 
      Enum.map(files, fn file_path ->
        case File.read(file_path) do
          {:ok, content} ->
            language = detect_language(file_path)
            %{
              file_path: file_path,
              file_name: Path.basename(file_path),
              language: language,
              content: content
            }
          {:error, reason} ->
            IO.puts("Error reading #{file_path}: #{reason}")
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
    
    if Enum.empty?(file_contexts) do
      IO.puts("Error: No valid files to analyze")
      System.halt(1)
    end
    
    # Get primary language for analysis
    languages = Enum.map(file_contexts, & &1.language) |> Enum.frequencies()
    primary_language = 
      Enum.max_by(languages, fn {_lang, count} -> count end, fn -> {"unknown", 0} end)
      |> elem(0)
    
    # Perform cross-file analysis
    case Ace.Infrastructure.AI.Orchestrator.analyze_cross_file(
      file_contexts,
      primary_language,
      [
        focus_areas: focus_areas,
        severity_threshold: severity_threshold
      ]
    ) do
      {:ok, opportunities} ->
        # Format the results
        result = %{
          files: file_contexts,
          opportunities: opportunities,
          primary_language: primary_language
        }
        
        formatted_output = case format do
          "json" -> Jason.encode!(result, pretty: true)
          _ -> format_cross_file_analysis_text(result)
        end
        
        if output_path do
          File.write!(output_path, formatted_output)
          IO.puts("Results written to #{output_path}")
        else
          IO.puts(formatted_output)
        end
        
      {:error, reason} ->
        IO.puts("Error performing cross-file analysis: #{inspect(reason)}")
        System.halt(1)
    end
  end
  
  defp handle_optimize(ids, opts) do
    strategy = opts[:strategy] || "auto"
    format = opts[:format] || "text"
    output_path = opts[:output]
    
    results = Enum.map(ids, fn id ->
      IO.puts("Optimizing opportunity #{id}...")
      
      case Ace.optimize(id, strategy, [skip_db: true]) do
        {:ok, optimization} -> {id, {:ok, optimization}}
        {:error, reason} -> {id, {:error, reason}}
      end
    end)
    
    formatted_output = case format do
      "json" -> format_results_json(results)
      "text" -> format_optimization_text(results)
      _ -> format_optimization_text(results)
    end
    
    if output_path do
      File.write!(output_path, formatted_output)
      IO.puts("Results written to #{output_path}")
    else
      IO.puts(formatted_output)
    end
  end
  
  defp handle_evaluate(ids, opts) do
    format = opts[:format] || "text"
    output_path = opts[:output]
    
    results = Enum.map(ids, fn id ->
      IO.puts("Evaluating optimization #{id}...")
      
      case Ace.evaluate_optimization(id) do
        {:ok, evaluation} -> {id, {:ok, evaluation}}
        {:error, reason} -> {id, {:error, reason}}
      end
    end)
    
    formatted_output = case format do
      "json" -> format_results_json(results)
      "text" -> format_evaluation_text(results)
      _ -> format_evaluation_text(results)
    end
    
    if output_path do
      File.write!(output_path, formatted_output)
      IO.puts("Results written to #{output_path}")
    else
      IO.puts(formatted_output)
    end
  end
  
  defp handle_apply(ids, opts) do
    format = opts[:format] || "text"
    output_path = opts[:output]
    
    results = Enum.map(ids, fn id ->
      IO.puts("Applying optimization #{id}...")
      
      case Ace.apply_optimization(id) do
        {:ok, applied} -> {id, {:ok, applied}}
        {:error, reason} -> {id, {:error, reason}}
      end
    end)
    
    formatted_output = case format do
      "json" -> format_results_json(results)
      "text" -> format_apply_text(results)
      _ -> format_apply_text(results)
    end
    
    if output_path do
      File.write!(output_path, formatted_output)
      IO.puts("Results written to #{output_path}")
    else
      IO.puts(formatted_output)
    end
  end
  
  defp handle_run(files, opts) do
    format = opts[:format] || "text"
    output_path = opts[:output]
    focus_areas = parse_focus_areas(opts[:focus_areas])
    severity_threshold = opts[:severity_threshold] || "medium"
    strategy = opts[:strategy] || "auto"
    auto_apply = opts[:auto_apply] || false
    
    results = Enum.map(files, fn file_path ->
      IO.puts("Running ACE pipeline on #{file_path}...")
      
      case Ace.run_pipeline(file_path, [
        focus_areas: focus_areas,
        severity_threshold: severity_threshold,
        strategy: strategy,
        auto_apply: auto_apply
      ]) do
        {:ok, pipeline_results} -> {file_path, {:ok, pipeline_results}}
        {:error, reason} -> {file_path, {:error, reason}}
      end
    end)
    
    formatted_output = case format do
      "json" -> format_results_json(results)
      "text" -> format_pipeline_text(results)
      _ -> format_pipeline_text(results)
    end
    
    if output_path do
      File.write!(output_path, formatted_output)
      IO.puts("Results written to #{output_path}")
    else
      IO.puts(formatted_output)
    end
  end
  
  defp handle_init(opts) do
    IO.puts("Initializing ACE configuration...")
    # Create basic configuration file
    config = """
    # ACE Configuration
    
    # AI provider configuration
    ai_provider: "#{opts[:ai_provider] || "groq"}"
    ai_model: "#{opts[:ai_model] || "llama3-70b-8192"}"
    
    # Default analysis settings
    default_focus_areas: ["performance", "maintainability"]
    default_severity_threshold: "medium"
    
    # Default optimization settings
    default_strategy: "auto"
    
    # Output settings
    default_format: "text"
    """
    
    File.write!(".ace.yaml", config)
    IO.puts("Configuration created at .ace.yaml")
  end
  
  defp show_version do
    version = Application.spec(:ace, :vsn) || "development"
    io_message = """
    ACE - Adaptive Code Evolution v#{version}
    
    For real AI-powered code analysis, set one of these environment variables:
      GROQ_API_KEY - For Groq LLM API (recommended)
      OPENAI_API_KEY - For OpenAI API
      ANTHROPIC_API_KEY - For Anthropic Claude API
    
    Without API keys, ACE will use mock responses for testing.
    """
    IO.puts(io_message)
  end
  
  defp show_help do
    IO.puts("""
    ACE - Adaptive Code Evolution
    
    Usage: ace COMMAND [OPTIONS] [ARGS]
    
    Commands:
      analyze [files]              Analyze code for optimization opportunities
      optimize [opportunity_ids]   Generate optimized implementations
      evaluate [optimization_ids]  Evaluate optimization effectiveness
      apply [optimization_ids]     Apply optimizations to codebase
      run [files]                  Run the complete pipeline
      init                         Create a configuration file
      version                      Show version
      help                         Show this help
    
    Options:
      -f, --format FORMAT          Output format (text, json)
      -o, --output FILE            Output file path
      --focus-areas AREAS          Comma-separated areas to focus on
      --severity-threshold LEVEL   Minimum severity threshold
      -s, --strategy STRATEGY      Optimization strategy
      -a, --auto-apply             Automatically apply successful optimizations
      -k, --api-key KEY            API key for AI provider
    
    Examples:
      ace analyze lib/my_module.ex
      ace optimize 123e4567-e89b-12d3-a456-426614174000
      ace run lib/my_module.ex --strategy performance --focus-areas performance
    """)
  end
  
  # Utility functions
  
  defp parse_focus_areas(nil), do: ["performance", "maintainability"]
  defp parse_focus_areas(focus_areas), do: String.split(focus_areas, ",")
  
  defp detect_language(file_path) do
    case Path.extname(file_path) do
      ".ex" -> "elixir"
      ".exs" -> "elixir"
      ".js" -> "javascript"
      ".ts" -> "javascript"
      ".py" -> "python"
      ".rb" -> "ruby"
      ".go" -> "go"
      _ext -> "unknown"
    end
  end
  
  # Output formatting functions
  
  defp format_results_json(results) do
    results_map = Map.new(results, fn {id, result} ->
      case result do
        {:ok, data} -> {id, data}
        {:error, reason} -> {id, %{error: reason}}
      end
    end)
    
    Jason.encode!(results_map, pretty: true)
  end
  
  defp format_analysis_text(results) do
    Enum.map(results, fn {file_path, result} ->
      case result do
        {:ok, analysis} ->
          opportunities = if Enum.empty?(analysis.opportunities) do
            "  No optimization opportunities found."
          else
            Enum.map(analysis.opportunities, fn opp ->
              # Generate a mock ID if none is present (for CLI without DB)
              opp_id = Map.get(opp, :id, "opp-#{:crypto.strong_rand_bytes(3) |> Base.encode16(case: :lower)}")
              
              """
                [#{opp_id}] #{Map.get(opp, :type, "unknown")} (#{Map.get(opp, :severity, "medium")})
                  Location: #{Map.get(opp, :location, "unknown")}
                  Description: #{Map.get(opp, :description, "No description")}
              """
            end)
            |> Enum.join("\n")
          end
          
          """
          Analysis of #{file_path}:
          #{opportunities}
          """
          
        {:error, reason} ->
          "Error analyzing #{file_path}: #{reason}"
      end
    end)
    |> Enum.join("\n\n")
  end
  
  defp format_optimization_text(results) do
    Enum.map(results, fn {id, result} ->
      case result do
        {:ok, optimization} ->
          """
          Optimization #{optimization.id}:
            Strategy: #{optimization.strategy}
            Status: #{optimization.status}
            Explanation: #{optimization.explanation}
            
          Original code:
          ```
          #{optimization.original_code}
          ```
          
          Optimized code:
          ```
          #{optimization.optimized_code}
          ```
          """
          
        {:error, reason} ->
          "Error optimizing opportunity #{id}: #{reason}"
      end
    end)
    |> Enum.join("\n\n")
  end
  
  defp format_evaluation_text(results) do
    Enum.map(results, fn {id, result} ->
      case result do
        {:ok, evaluation} ->
          metrics = if is_map(evaluation.metrics) do
            Enum.map(evaluation.metrics, fn {key, value} ->
              "  #{key}: #{format_metric_value(value)}"
            end)
            |> Enum.join("\n")
          else
            "  No metrics available"
          end
          
          """
          Evaluation of optimization #{id}:
            Success: #{evaluation.success}
            
          Metrics:
          #{metrics}
          
          Report:
          #{evaluation.report}
          """
          
        {:error, reason} ->
          "Error evaluating optimization #{id}: #{reason}"
      end
    end)
    |> Enum.join("\n\n")
  end
  
  defp format_apply_text(results) do
    Enum.map(results, fn {id, result} ->
      case result do
        {:ok, applied} ->
          "Successfully applied optimization #{id} to #{applied.file_path}"
        {:error, reason} ->
          "Error applying optimization #{id}: #{reason}"
      end
    end)
    |> Enum.join("\n")
  end
  
  defp format_pipeline_text(results) do
    Enum.map(results, fn {file_path, result} ->
      case result do
        {:ok, pipeline_results} ->
          opportunity_count = length(pipeline_results.opportunities)
          optimization_count = length(pipeline_results.optimizations)
          evaluation_count = length(pipeline_results.evaluations)
          applied_count = length(pipeline_results.applied)
          
          success_count = Enum.count(pipeline_results.evaluations, & &1.success)
          
          """
          Pipeline results for #{file_path}:
            Identified #{opportunity_count} optimization opportunities
            Generated #{optimization_count} optimized implementations
            Successfully evaluated #{success_count}/#{evaluation_count} optimizations
            Applied #{applied_count} optimizations
          """
          
        {:error, reason} ->
          "Error running pipeline on #{file_path}: #{reason}"
      end
    end)
    |> Enum.join("\n\n")
  end
  
  defp format_metric_value(value) when is_float(value), do: Float.round(value, 4)
  defp format_metric_value(value), do: inspect(value)
  
  defp format_cross_file_analysis_text(result) do
    # Format the cross-file analysis result as text
    file_list = Enum.map_join(result.files, "\n  ", & &1.file_path)
    
    opportunities = 
      if Enum.empty?(result.opportunities) do
        "  No cross-file optimization opportunities found."
      else
        Enum.map(result.opportunities, fn opp ->
          """
            #{opp.type} (#{opp.severity}):
              Description: #{opp.description}
              Files: #{format_affected_files(opp)}
              Rationale: #{opp.rationale}
              Suggested change: #{opp.suggested_change}
          """
        end)
        |> Enum.join("\n")
      end
    
    """
    Cross-file Analysis Results:
    
    Primary language: #{result.primary_language}
    
    Files analyzed:
      #{file_list}
    
    Opportunities:
    #{opportunities}
    """
  end
  
  defp format_affected_files(opp) do
    case Map.get(opp, :affected_files) do
      files when is_list(files) -> Enum.join(files, ", ")
      _ -> "multiple files"
    end
  end
end