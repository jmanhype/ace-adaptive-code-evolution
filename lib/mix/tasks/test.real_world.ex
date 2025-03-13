defmodule Mix.Tasks.Test.RealWorld do
  @moduledoc """
  Runs ACE real-world testing.
  
  ## Usage
  
  ```
  mix test.real_world
  ```
  """
  use Mix.Task
  
  @shortdoc "Runs ACE against real-world codebases"
  def run(_) do
    # Run standalone version of real-world tests
    IO.puts("ACE Real-World Codebase Testing")
    IO.puts("===============================")
    
    # Load the test corpus from the JSON configuration file
    codebases_config = 
      case File.read("test/real_world/codebases.json") do
        {:ok, json} -> 
          Jason.decode!(json)
        
        {:error, _} ->
          IO.puts("⚠️  codebases.json not found. Using default test corpus.")
          %{
            "codebases" => [
              %{
                "name" => "phoenix",
                "repo" => "https://github.com/phoenixframework/phoenix.git",
                "description" => "Elixir web framework",
                "language" => "elixir",
                "size" => "medium",
                "branch" => "main",
                "focus_areas" => ["performance", "maintainability"]
              }
            ]
          }
      end
    
    # Import the test modules
    Code.require_file("test/real_world/codebase_runner.exs")
    Code.require_file("test/real_world/result_analyzer.exs")
    
    # Create test run directory for results
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601() |> String.replace(":", "-")
    results_dir = "test/real_world/results/#{timestamp}"
    File.mkdir_p!(results_dir)
    
    # Create a symbolic link to latest results
    latest_dir = "test/real_world/results/latest"
    File.rm_rf(latest_dir)
    File.mkdir_p!(latest_dir)
    
    # Write test run info
    test_run_info = %{
      timestamp: timestamp,
      version: Mix.Project.config()[:version],
      elixir_version: System.version(),
      otp_version: :erlang.system_info(:otp_release) |> List.to_string(),
      codebases: codebases_config["codebases"] |> Enum.map(&(&1["name"]))
    }
    
    File.write!(Path.join(results_dir, "test_run_info.json"), Jason.encode!(test_run_info, pretty: true))
    File.write!(Path.join(latest_dir, "test_run_info.json"), Jason.encode!(test_run_info, pretty: true))
    
    # Run tests on each codebase
    results = %{}
    
    IO.puts("\nRunning tests on #{length(codebases_config["codebases"])} codebases...\n")
    
    codebases_config["codebases"]
    |> Enum.with_index(1)
    |> Enum.each(fn {codebase, index} ->
      IO.puts("#{index}/#{length(codebases_config["codebases"])} Testing #{codebase["name"]} (#{codebase["language"]})...")
      
      # Check if this run should be skipped
      updated_results = if Map.get(codebase, "skip", false) do
        IO.puts("  ⚠️  Skipping as configured in codebases.json")
        Map.put(results, codebase["name"], %{skipped: true})
      else
        # Run tests on this codebase
        # Using Code.eval_string to avoid compile-time dependency on possibly undefined module
        codebase_results = codebase  # Default value if nothing works
        
        try do
          # Dynamic code to check module existence and call function
          {result, _} = Code.eval_string("""
          if Code.ensure_loaded?(Ace.RealWorld.CodebaseRunner) and
             function_exported?(Ace.RealWorld.CodebaseRunner, :run, 1) do
            Ace.RealWorld.CodebaseRunner.run(codebase)
          else
            codebase_runner_path = Path.join(["#{__DIR__}", "..", "..", "ace", "real_world", "codebase_runner.ex"])
            if File.exists?(codebase_runner_path) do
              {module_code, _} = Code.eval_file(codebase_runner_path)
              if function_exported?(Ace.RealWorld.CodebaseRunner, :run, 1) do
                Ace.RealWorld.CodebaseRunner.run(codebase)
              else
                %{error: "CodebaseRunner.run/1 function not available"}
              end
            else
              %{error: "CodebaseRunner module not available"}
            end
          end
          """, [codebase: codebase])
          
          result
        rescue
          e -> 
            IO.puts("Error running codebase tests: #{Exception.message(e)}")
            %{error: "Error running codebase tests: #{Exception.message(e)}"}
        end
        
        # Save results
        codebase_dir = Path.join(results_dir, codebase["name"])
        latest_codebase_dir = Path.join(latest_dir, codebase["name"])
        File.mkdir_p!(codebase_dir)
        File.mkdir_p!(latest_codebase_dir)
        
        # Write results to JSON files
        File.write!(Path.join(codebase_dir, "results.json"), Jason.encode!(codebase_results, pretty: true))
        File.write!(Path.join(latest_codebase_dir, "results.json"), Jason.encode!(codebase_results, pretty: true))
        
        # Add to results map
        Map.put(results, codebase["name"], codebase_results)
      end
      
      # Return updated results
      _ = updated_results
      
      if !Map.get(codebase, "skip", false) do
        IO.puts("  ✅ Completed testing of #{codebase["name"]}")
      end
    end)
    
    # Analyze results
    IO.puts("\nAnalyzing results...")
    
    # Using dynamic eval to avoid compile-time dependency on possibly undefined module
    analysis = %{} # Default value
    
    try do
      # Dynamic code to check module existence and call function
      {result, _} = Code.eval_string("""
      if Code.ensure_loaded?(Ace.RealWorld.ResultAnalyzer) and
         function_exported?(Ace.RealWorld.ResultAnalyzer, :analyze_results, 1) do
        Ace.RealWorld.ResultAnalyzer.analyze_results(results_dir)
      else
        analyzer_path = Path.join(["#{__DIR__}", "..", "..", "ace", "real_world", "result_analyzer.ex"])
        if File.exists?(analyzer_path) do
          {module_code, _} = Code.eval_file(analyzer_path)
          if function_exported?(Ace.RealWorld.ResultAnalyzer, :analyze_results, 1) do
            Ace.RealWorld.ResultAnalyzer.analyze_results(results_dir)
          else
            %{error: "ResultAnalyzer.analyze_results/1 function not available"}
          end
        else
          %{error: "ResultAnalyzer module not available"}
        end
      end
      """, [results_dir: results_dir])
      
      result
    rescue
      e -> 
        IO.puts("Error analyzing results: #{Exception.message(e)}")
        %{error: "Error analyzing results: #{Exception.message(e)}"}
    end
    
    # Save analysis
    File.write!(Path.join(results_dir, "analysis.json"), Jason.encode!(analysis, pretty: true))
    File.write!(Path.join(latest_dir, "analysis.json"), Jason.encode!(analysis, pretty: true))
    
    # Print summary using dynamic evaluation to avoid compile-time dependency
    try do
      # The following string avoids direct reference to potentially undefined modules
      {_, _} = Code.eval_string("""
      if Code.ensure_loaded?(Ace.RealWorld.ResultAnalyzer) and
         function_exported?(Ace.RealWorld.ResultAnalyzer, :print_summary, 1) do
        Ace.RealWorld.ResultAnalyzer.print_summary(analysis)
      else
        IO.puts("Analysis complete. See results in: \#{results_dir}")
      end
      """, [analysis: analysis, results_dir: results_dir])
    rescue
      _ -> IO.puts("Analysis complete. See results in: #{results_dir}")
    end
    
    IO.puts("\n🎉 Real-world testing complete! Results saved to: #{results_dir}")
  end
end