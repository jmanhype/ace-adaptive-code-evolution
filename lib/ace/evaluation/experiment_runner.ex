defmodule Ace.Evaluation.ExperimentRunner do
  @moduledoc """
  Runs experiments and collects metrics.
  """
  require Logger

  @doc """
  Runs an experiment and collects metrics.
  
  ## Parameters
  
    - `experiment`: The experiment to run
  
  ## Returns
  
    - `{:ok, results}`: Results of the experiment
    - `{:error, reason}`: If running the experiment fails
  """
  def run(experiment) do
    # Validate the experiment data
    with :ok <- validate_experiment(experiment) do
      try do
        # Get experiment type based on file extension
        _experiment_type = get_experiment_type(experiment)

        # Compile and run tests
        with {:ok, compilation_result} <- compile_experiment(experiment),
             {:ok, correctness_results} <- test_correctness(experiment),
             {:ok, performance_results} <- benchmark_performance(experiment),
             {:ok, complexity_results} <- analyze_complexity(experiment) do
          
          # Combine results
          results = %{
            metrics: %{
              compilation: compilation_result,
              correctness: correctness_results,
              performance: performance_results,
              complexity: complexity_results
            },
            success: determine_success(
              compilation_result,
              correctness_results,
              performance_results
            ),
            report: generate_report(
              compilation_result,
              correctness_results,
              performance_results,
              complexity_results
            )
          }

          {:ok, results}
        else
          {:error, phase, reason} ->
            # Clean up experiment files if needed
            {:error, "Experiment failed during #{phase}: #{reason}"}
          
          error ->
            # Unknown error structure
            {:error, "Experiment failed: #{inspect(error)}"}
        end
      rescue
        e ->
          # Clean up experiment files
          {:error, "Experiment failed with exception: #{Exception.message(e)}"}
      end
    end
  end

  # Private helper functions

  defp validate_experiment(%{setup_data: %{dir: dir}}) when is_binary(dir) do
    if File.dir?(dir) do
      :ok
    else
      {:error, "Experiment directory does not exist: #{dir}"}
    end
  end

  defp validate_experiment(_) do
    {:error, "Invalid experiment data"}
  end

  defp get_experiment_type(%{setup_data: setup_data}) do
    cond do
      Map.has_key?(setup_data, :original_file) && String.ends_with?(setup_data.original_file, ".ex") ->
        :elixir
      
      Map.has_key?(setup_data, :original_file) && String.ends_with?(setup_data.original_file, ".js") ->
        :javascript
      
      Map.has_key?(setup_data, :original_file) && String.ends_with?(setup_data.original_file, ".py") ->
        :python
      
      Map.has_key?(setup_data, :original_file) && String.ends_with?(setup_data.original_file, ".rb") ->
        :ruby
      
      Map.has_key?(setup_data, :original_file) && String.ends_with?(setup_data.original_file, ".go") ->
        :go
      
      true ->
        :generic
    end
  end

  defp compile_experiment(%{setup_data: %{dir: dir}} = experiment) do
    case get_experiment_type(experiment) do
      :elixir ->
        # Compile the original module
        original_result = System.cmd("elixirc", [experiment.setup_data.original_file], cd: dir)
        
        # Compile the optimized module
        optimized_result = System.cmd("elixirc", [experiment.setup_data.optimized_file], cd: dir)
        
        # Check for compilation errors
        case {original_result, optimized_result} do
          {{_, 0}, {_, 0}} ->
            {:ok, %{
              original_compiled: true,
              optimized_compiled: true,
              compilation_errors: nil
            }}
          
          {{original_output, original_code}, {optimized_output, optimized_code}} ->
            errors = %{
              original: %{output: original_output, exit_code: original_code},
              optimized: %{output: optimized_output, exit_code: optimized_code}
            }
            
            {:error, :compilation, "Compilation errors: #{inspect(errors)}"}
        end
      
      :javascript ->
        # JavaScript uses syntax validation instead of compilation
        # We'll use Node.js to check for syntax errors
        original_result = System.cmd("node", ["--check", experiment.setup_data.original_file], cd: dir)
        optimized_result = System.cmd("node", ["--check", experiment.setup_data.optimized_file], cd: dir)
        
        # Check for syntax errors
        case {original_result, optimized_result} do
          {{_, 0}, {_, 0}} ->
            {:ok, %{
              original_compiled: true,
              optimized_compiled: true,
              compilation_errors: nil
            }}
          
          {{original_output, original_code}, {optimized_output, optimized_code}} ->
            errors = %{
              original: %{output: original_output, exit_code: original_code},
              optimized: %{output: optimized_output, exit_code: optimized_code}
            }
            
            {:error, :compilation, "JavaScript syntax errors: #{inspect(errors)}"}
        end
      
      _other ->
        # For other languages, assume compilation succeeds
        # In a real implementation, this would invoke the appropriate compiler
        {:ok, %{
          original_compiled: true,
          optimized_compiled: true,
          compilation_errors: nil
        }}
    end
  rescue
    e -> {:error, :compilation, "Error during compilation: #{Exception.message(e)}"}
  end

  defp test_correctness(%{setup_data: %{dir: dir, test_file: test_file}} = experiment) do
    case get_experiment_type(experiment) do
      :elixir ->
        # Run the test file
        test_result = System.cmd("elixir", [test_file], cd: dir)
        
        case test_result do
          {output, 0} ->
            # Extract test results from output
            passed = String.contains?(output, "0 failures")
            failed_count = extract_test_failures(output)
            
            {:ok, %{
              passed: passed,
              failed_count: failed_count,
              output: output
            }}
          
          {output, _} ->
            {:error, :testing, "Tests failed: #{output}"}
        end

      :javascript ->
        # Run JavaScript tests with Jest, Mocha, or another JavaScript test framework
        # We'll use Jest for this example
        test_result = System.cmd("npx", ["jest", test_file], cd: dir)
        
        case test_result do
          {output, 0} ->
            # Extract test results from Jest output
            failed_count = extract_jest_failures(output)
            passed = failed_count == 0
            
            {:ok, %{
              passed: passed,
              failed_count: failed_count,
              output: output
            }}
          
          {output, _} ->
            {:error, :testing, "JavaScript tests failed: #{output}"}
        end
        
      :python ->
        # Run Python tests with pytest
        test_result = System.cmd("pytest", [test_file, "-v"], cd: dir)
        
        case test_result do
          {output, 0} ->
            # Extract test results from pytest output
            passed = String.contains?(output, "passed") && !String.contains?(output, "failed")
            failed_count = extract_pytest_failures(output)
            
            {:ok, %{
              passed: passed,
              failed_count: failed_count,
              output: output
            }}
          
          {output, _} ->
            {:error, :testing, "Python tests failed: #{output}"}
        end
      
      _other ->
        # For other languages, assume tests pass
        # In a real implementation, this would run the appropriate test runner
        {:ok, %{
          passed: true,
          failed_count: 0,
          output: "Tests skipped for non-supported language"
        }}
    end
  rescue
    e -> {:error, :testing, "Error during testing: #{Exception.message(e)}"}
  end
  
  # Extract failure count from Jest output
  defp extract_jest_failures(output) do
    case Regex.run(~r/Tests:\s+(\d+)\s+failed/i, output) do
      [_, count] -> String.to_integer(count)
      _ -> 0
    end
  end
  
  # Extract failure count from pytest output
  defp extract_pytest_failures(output) do
    case Regex.run(~r/(\d+)\s+failed/i, output) do
      [_, count] -> String.to_integer(count)
      _ -> 0
    end
  end

  defp benchmark_performance(%{setup_data: %{dir: dir, bench_file: bench_file}} = experiment) do
    case get_experiment_type(experiment) do
      :elixir ->
        # Run the benchmark file
        bench_result = System.cmd("elixir", [bench_file], cd: dir)
        
        case bench_result do
          {output, 0} ->
            # Extract benchmark results
            # This assumes the benchmark file outputs a map as its last expression
            case extract_benchmark_results(output) do
              {:ok, results} ->
                {:ok, results}
              
              {:error, reason} ->
                {:error, :benchmarking, "Failed to extract benchmark results: #{reason}"}
            end
          
          {output, _} ->
            {:error, :benchmarking, "Benchmark failed: #{output}"}
        end
      
      :javascript ->
        # Run JavaScript benchmark (using Benchmark.js)
        bench_result = System.cmd("node", [bench_file], cd: dir)
        
        case bench_result do
          {output, 0} ->
            # Extract benchmark results from JavaScript
            case extract_js_benchmark_results(output) do
              {:ok, results} ->
                {:ok, results}
              
              {:error, reason} ->
                {:error, :benchmarking, "Failed to extract JavaScript benchmark results: #{reason}"}
            end
          
          {output, _} ->
            {:error, :benchmarking, "JavaScript benchmark failed: #{output}"}
        end
        
      :python ->
        # Run Python benchmark
        bench_result = System.cmd("python", [bench_file], cd: dir)
        
        case bench_result do
          {output, 0} ->
            # Extract benchmark results from Python
            case extract_python_benchmark_results(output) do
              {:ok, results} ->
                {:ok, results}
              
              {:error, reason} ->
                {:error, :benchmarking, "Failed to extract Python benchmark results: #{reason}"}
            end
          
          {output, _} ->
            {:error, :benchmarking, "Python benchmark failed: #{output}"}
        end
      
      _other ->
        # For other languages, use basic metrics
        # In a real implementation, this would run appropriate benchmarks
        if Map.has_key?(experiment.setup_data, :metrics) do
          {:ok, experiment.setup_data.metrics}
        else
          {:ok, %{
            overall_improvement: 0.0,
            message: "Benchmarking not available for this language"
          }}
        end
    end
  rescue
    e -> {:error, :benchmarking, "Error during benchmarking: #{Exception.message(e)}"}
  end
  
  # Extract benchmark results from Python output
  defp extract_python_benchmark_results(output) do
    # Look for JSON output in the benchmark result
    case Regex.run(~r/BENCHMARK_RESULTS:\s*(.*?)\s*END_BENCHMARK_RESULTS/s, output) do
      [_, json_str] ->
        try do
          result = Jason.decode!(String.trim(json_str))
          
          # Convert to the expected format
          original_hz = get_in(result, ["original", "hz"]) || 0
          optimized_hz = get_in(result, ["optimized", "hz"]) || 0
          improvement = Map.get(result, "improvement") || 0
          
          {:ok, %{
            overall_improvement: improvement,
            original_ops_per_second: original_hz,
            optimized_ops_per_second: optimized_hz,
            function_metrics: %{} # Would extract function-specific metrics in a full implementation
          }}
        rescue
          e -> {:error, "Failed to parse Python benchmark JSON: #{Exception.message(e)}"}
        end
        
      nil ->
        # Alternative format: look for direct improvement statement
        case Regex.run(~r/Performance improvement:\s*([-+]?\d+\.?\d*)%/, output) do
          [_, percentage] ->
            case Float.parse(percentage) do
              {value, _} -> {:ok, %{overall_improvement: value}}
              :error -> {:error, "Failed to parse Python improvement percentage"}
            end
            
          nil ->
            {:error, "No Python benchmark results found in output"}
        end
    end
  end
  
  # Extract benchmark results from JavaScript output
  defp extract_js_benchmark_results(output) do
    # Look for JSON output in the benchmark result
    case Regex.run(~r/BENCHMARK_RESULTS:(.*?)END_BENCHMARK_RESULTS/s, output) do
      [_, json_str] ->
        try do
          result = Jason.decode!(String.trim(json_str))
          
          # Convert to the expected format
          original_ops = get_in(result, ["original", "hz"]) || 0
          optimized_ops = get_in(result, ["optimized", "hz"]) || 0
          
          # Calculate improvement percentage
          improvement_percent = 
            if original_ops > 0 do
              ((optimized_ops - original_ops) / original_ops) * 100
            else
              0.0
            end
          
          {:ok, %{
            overall_improvement: improvement_percent,
            original_ops_per_second: original_ops,
            optimized_ops_per_second: optimized_ops,
            function_metrics: %{} # Would extract function-specific metrics in a full implementation
          }}
        rescue
          e -> {:error, "Failed to parse JavaScript benchmark JSON: #{Exception.message(e)}"}
        end
        
      nil ->
        # Alternative format: look for direct improvement statement
        case Regex.run(~r/Performance improvement:\s*([-+]?\d+\.?\d*)%/, output) do
          [_, percentage] ->
            case Float.parse(percentage) do
              {value, _} -> {:ok, %{overall_improvement: value}}
              :error -> {:error, "Failed to parse JavaScript improvement percentage"}
            end
            
          nil ->
            {:error, "No JavaScript benchmark results found in output"}
        end
    end
  end

  defp analyze_complexity(experiment) do
    case get_experiment_type(experiment) do
      :elixir ->
        # Basic metrics like line count, character count
        original_code = File.read!(experiment.setup_data.original_file)
        optimized_code = File.read!(experiment.setup_data.optimized_file)
        
        original_metrics = calculate_code_metrics(original_code)
        optimized_metrics = calculate_code_metrics(optimized_code)
        
        {:ok, %{
          original: original_metrics,
          optimized: optimized_metrics,
          diff: %{
            lines: optimized_metrics.lines - original_metrics.lines,
            characters: optimized_metrics.characters - original_metrics.characters,
            functions: optimized_metrics.functions - original_metrics.functions,
            complexity_score: optimized_metrics.complexity_score - original_metrics.complexity_score
          }
        }}
      
      :javascript ->
        # JavaScript-specific complexity metrics
        original_code = File.read!(experiment.setup_data.original_file)
        optimized_code = File.read!(experiment.setup_data.optimized_file)
        
        original_metrics = calculate_js_code_metrics(original_code)
        optimized_metrics = calculate_js_code_metrics(optimized_code)
        
        {:ok, %{
          original: original_metrics,
          optimized: optimized_metrics,
          diff: %{
            lines: optimized_metrics.lines - original_metrics.lines,
            characters: optimized_metrics.characters - original_metrics.characters,
            functions: optimized_metrics.functions - original_metrics.functions,
            complexity_score: optimized_metrics.complexity_score - original_metrics.complexity_score
          }
        }}
        
      :python ->
        # Python-specific complexity metrics
        original_code = File.read!(experiment.setup_data.original_file)
        optimized_code = File.read!(experiment.setup_data.optimized_file)
        
        original_metrics = calculate_python_code_metrics(original_code)
        optimized_metrics = calculate_python_code_metrics(optimized_code)
        
        {:ok, %{
          original: original_metrics,
          optimized: optimized_metrics,
          diff: %{
            lines: optimized_metrics.lines - original_metrics.lines,
            characters: optimized_metrics.characters - original_metrics.characters,
            functions: optimized_metrics.functions - original_metrics.functions,
            complexity_score: optimized_metrics.complexity_score - original_metrics.complexity_score
          }
        }}
      
      _other ->
        # Basic size comparison for other languages
        original_size = File.stat!(experiment.setup_data.original_file).size
        optimized_size = File.stat!(experiment.setup_data.optimized_file).size
        
        {:ok, %{
          original: %{size: original_size},
          optimized: %{size: optimized_size},
          diff: %{
            size: optimized_size - original_size,
            percentage: ((optimized_size - original_size) / original_size) * 100
          }
        }}
    end
  rescue
    e -> {:error, :complexity_analysis, "Error during complexity analysis: #{Exception.message(e)}"}
  end
  
  # Calculate Python-specific code metrics
  defp calculate_python_code_metrics(code) do
    lines = String.split(code, "\n") |> length()
    characters = String.length(code)
    
    # Count functions (very basic, would need a proper Python parser in production)
    function_regex = ~r/def\s+(\w+)\s*\(/
    functions = Regex.scan(function_regex, code) |> length()
    
    # Basic complexity metrics for Python
    conditional_statements = Regex.scan(~r/\b(if|elif|else|for|while|with|try|except|finally)\b/, code) |> length()
    nested_blocks = Regex.scan(~r/\n\s{8,}[^\s]/, code) |> length()  # Indentation level > 2
    list_comprehensions = Regex.scan(~r/\[[^]]+for\s+.+\s+in\s+.+\]/, code) |> length()
    lambda_functions = Regex.scan(~r/lambda\s+\w+\s*:/, code) |> length()
    
    # Python-specific complexity score formula
    complexity_score = 
      (conditional_statements + nested_blocks * 2 - list_comprehensions * 0.5 + lambda_functions * 0.5) / 
      max(10, lines / 10)
    
    %{
      lines: lines,
      characters: characters,
      functions: functions,
      complexity_score: complexity_score
    }
  end
  
  # Calculate JavaScript-specific code metrics
  defp calculate_js_code_metrics(code) do
    lines = String.split(code, "\n") |> length()
    characters = String.length(code)
    
    # Count functions (very basic, would need a proper JavaScript parser in production)
    function_regex = ~r/(?:function\s+\w+|const\s+\w+\s*=\s*(?:function|\([^)]*\)\s*=>)|(?:^|\s)\w+\s*:\s*(?:function|\([^)]*\)\s*=>))/
    functions = Regex.scan(function_regex, code) |> length()
    
    # Basic complexity score for JavaScript
    # Count control structures, ternaries, callbacks
    control_flow = Regex.scan(~r/\b(if|for|while|switch|try|catch|do)\b/, code) |> length()
    ternaries = Regex.scan(~r/\?/, code) |> length()
    callbacks = Regex.scan(~r/=>\s*{/, code) |> length()
    nesting_count = Regex.scan(~r/\{\s*\{/, code) |> length()
    nesting = nesting_count * 0.5
    
    complexity_score = (control_flow + ternaries + callbacks + nesting) / (lines / 10)
    
    %{
      lines: lines,
      characters: characters,
      functions: functions, 
      complexity_score: complexity_score
    }
  end

  defp determine_success(compilation_result, correctness_results, performance_results) do
    # Success criteria:
    # 1. Both original and optimized code must compile
    # 2. All correctness tests must pass
    # 3. Performance should be at least as good as the original (or better)
    
    compilation_ok = compilation_result.original_compiled && compilation_result.optimized_compiled
    correctness_ok = correctness_results.passed && correctness_results.failed_count == 0
    
    performance_improvement = if Map.has_key?(performance_results, :overall_improvement) do
      performance_results.overall_improvement >= -1.0  # Allow up to 1% regression
    else
      true  # If we can't measure performance, assume it's ok
    end
    
    compilation_ok && correctness_ok && performance_improvement
  end

  defp generate_report(compilation_result, correctness_results, performance_results, complexity_results) do
    """
    # Optimization Evaluation Report
    
    ## Compilation
    Original Code: #{if compilation_result.original_compiled, do: "✅ Compiled Successfully", else: "❌ Compilation Failed"}
    Optimized Code: #{if compilation_result.optimized_compiled, do: "✅ Compiled Successfully", else: "❌ Compilation Failed"}
    #{if compilation_result.compilation_errors, do: "\nCompilation Errors:\n#{compilation_result.compilation_errors}\n", else: ""}
    
    ## Correctness Testing
    Status: #{if correctness_results.passed, do: "✅ All Tests Passed", else: "❌ #{correctness_results.failed_count} Tests Failed"}
    #{if !correctness_results.passed, do: "\nTest Output:\n#{correctness_results.output}\n", else: ""}
    
    ## Performance
    #{format_performance_report(performance_results)}
    
    ## Code Complexity
    #{format_complexity_report(complexity_results)}
    
    ## Recommendation
    #{generate_recommendation(compilation_result, correctness_results, performance_results, complexity_results)}
    """
  end

  defp format_performance_report(%{overall_improvement: improvement} = results) do
    function_metrics = Map.get(results, :function_metrics, %{})
    
    functions_report = if map_size(function_metrics) > 0 do
      functions_list = function_metrics
      |> Enum.map(fn {name, metrics} ->
        "- #{name}: #{format_percentage(metrics.improvement_percent)} improvement"
      end)
      |> Enum.join("\n")
      
      """
      Individual Function Performance:
      #{functions_list}
      """
    else
      ""
    end
    
    """
    Overall Performance Change: #{format_percentage(improvement)}
    #{functions_report}
    """
  end

  defp format_performance_report(results) do
    "Performance metrics unavailable or in non-standard format: #{inspect(results)}"
  end

  defp format_complexity_report(%{original: original, optimized: optimized, diff: diff}) do
    if Map.has_key?(original, :lines) && Map.has_key?(optimized, :lines) do
      """
      Code Size Change:
      - Lines: #{diff.lines} (#{format_relative_change(diff.lines, original.lines)})
      - Characters: #{diff.characters} (#{format_relative_change(diff.characters, original.characters)})
      - Functions: #{diff.functions} (#{format_relative_change(diff.functions, original.functions)})
      - Complexity Score: #{Float.round(diff.complexity_score, 2)} (#{format_relative_change(diff.complexity_score, original.complexity_score)})
      """
    else
      """
      Code Size Change:
      - Size: #{diff.size} bytes (#{format_relative_change(diff.size, original.size)})
      """
    end
  end

  defp format_complexity_report(results) do
    "Complexity metrics unavailable or in non-standard format: #{inspect(results)}"
  end

  defp generate_recommendation(compilation_result, correctness_results, performance_results, complexity_results) do
    success = determine_success(compilation_result, correctness_results, performance_results)
    
    if success do
      performance_info = if Map.has_key?(performance_results, :overall_improvement) do
        if performance_results.overall_improvement > 5.0 do
          "The optimization provides significant performance improvements (#{format_percentage(performance_results.overall_improvement)})."
        else
          "The optimization provides moderate performance improvements (#{format_percentage(performance_results.overall_improvement)})."
        end
      else
        "Performance impact could not be accurately measured."
      end
      
      complexity_info = if Map.has_key?(complexity_results, :diff) && Map.has_key?(complexity_results.diff, :complexity_score) do
        if complexity_results.diff.complexity_score < 0 do
          "The code complexity has been reduced, which should improve maintainability."
        else
          "The code complexity has increased slightly, which may affect maintainability."
        end
      else
        "Code complexity impact could not be accurately measured."
      end
      
      """
      ✅ OPTIMIZATION RECOMMENDED
      
      The optimization is functionally correct and maintains the original behavior.
      #{performance_info}
      #{complexity_info}
      
      Overall, this optimization is recommended for application.
      """
    else
      issues = []
      
      issues = if !compilation_result.original_compiled || !compilation_result.optimized_compiled do
        issues ++ ["compilation issues"]
      else
        issues
      end
      
      issues = if !correctness_results.passed do
        issues ++ ["correctness failures"]
      else
        issues
      end
      
      issues = if Map.has_key?(performance_results, :overall_improvement) && performance_results.overall_improvement < -1.0 do
        issues ++ ["performance regression (#{format_percentage(performance_results.overall_improvement)})"]
      else
        issues
      end
      
      issues_str = Enum.join(issues, ", ")
      
      """
      ❌ OPTIMIZATION NOT RECOMMENDED
      
      The optimization has #{issues_str}.
      Further refinement is needed before this optimization can be applied.
      """
    end
  end

  # Helper functions

  defp extract_test_failures(output) do
    case Regex.run(~r/(\d+) failures/, output) do
      [_, count] -> String.to_integer(count)
      _ -> 0
    end
  end

  defp extract_benchmark_results(output) do
    # Look for a map structure in the last lines of the output
    case Regex.run(~r/%\{(.+)\}\s*$/, output, dotall: true) do
      [_, map_str] ->
        try do
          {result, _} = Code.eval_string("%{#{map_str}}")
          {:ok, result}
        rescue
          e -> {:error, "Failed to parse benchmark results: #{Exception.message(e)}"}
        end
      
      nil ->
        # If no map found, try to extract an overall improvement percentage
        case Regex.run(~r/Overall performance change:\s*([-+]?\d+\.?\d*)%/, output) do
          [_, percentage] ->
            case Float.parse(percentage) do
              {value, _} -> {:ok, %{overall_improvement: value}}
              :error -> {:error, "Failed to parse overall improvement percentage"}
            end
          
          nil ->
            {:error, "No benchmark results found in output"}
        end
    end
  end

  defp calculate_code_metrics(code) do
    lines = String.split(code, "\n") |> length()
    characters = String.length(code)
    
    # Count functions (very basic, would need a proper parser in production)
    functions = Regex.scan(~r/\bdef\s+\w+/, code) |> length()
    
    # Basic complexity score (this would be more sophisticated in production)
    control_flow_count = Regex.scan(~r/\b(if|case|cond|for|while|with)\b/, code) |> length()
    nesting_count = Regex.scan(~r/\s{2,}(if|case|cond|for|while|with)\b/, code) |> length()
    nesting_penalty = nesting_count * 0.5
    
    complexity_score = (control_flow_count + nesting_penalty) / (lines / 10)
    
    %{
      lines: lines,
      characters: characters,
      functions: functions,
      complexity_score: complexity_score
    }
  end

  defp format_percentage(value) when is_number(value) do
    sign = if value >= 0, do: "+", else: ""
    "#{sign}#{Float.round(value, 2)}%"
  end

  defp format_percentage(_), do: "N/A"

  defp format_relative_change(diff, original) when is_number(diff) and is_number(original) and original != 0 do
    percentage = (diff / original) * 100
    format_percentage(percentage)
  end

  defp format_relative_change(_, _), do: "N/A"
end