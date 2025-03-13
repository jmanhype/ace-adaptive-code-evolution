# Run real-world codebase tests
# Mix task: mix test.real_world

# Ensure ACE application is started
Application.ensure_all_started(:ace)

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
          },
          %{
            "name" => "ecto",
            "repo" => "https://github.com/elixir-ecto/ecto.git",
            "description" => "Elixir database library",
            "language" => "elixir",
            "size" => "medium",
            "branch" => "master",
            "focus_areas" => ["performance", "maintainability"]
          }
        ]
      }
  end

# Import the test modules
Code.require_file("test/real_world/codebase_runner.exs")
Code.require_file("test/real_world/result_analyzer.exs")
Code.require_file("test/real_world/benchmark.exs")

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
    codebase_results = Ace.RealWorld.CodebaseRunner.run(codebase)
    
    # Save results
    codebase_dir = Path.join(results_dir, codebase["name"])
    latest_codebase_dir = Path.join(latest_dir, codebase["name"])
    File.mkdir_p!(codebase_dir)
    File.mkdir_p!(latest_codebase_dir)
    
    # Write results to JSON files
    File.write!(Path.join(codebase_dir, "results.json"), Jason.encode!(codebase_results, pretty: true))
    File.write!(Path.join(latest_codebase_dir, "results.json"), Jason.encode!(codebase_results, pretty: true))
    
    # Add to results map
    results_with_codebase = Map.put(results, codebase["name"], codebase_results)
    
    IO.puts("  ✅ Completed testing of #{codebase["name"]}")
    results_with_codebase
  end
  
  # Update results for next iteration
  _results = updated_results
end)

# Analyze results
IO.puts("\nAnalyzing results...")
analysis = Ace.RealWorld.ResultAnalyzer.analyze_results(results_dir)

# Save analysis
File.write!(Path.join(results_dir, "analysis.json"), Jason.encode!(analysis, pretty: true))
File.write!(Path.join(latest_dir, "analysis.json"), Jason.encode!(analysis, pretty: true))

# Print summary
Ace.RealWorld.ResultAnalyzer.print_summary(analysis)

IO.puts("\n🎉 Real-world testing complete! Results saved to: #{results_dir}")
IO.puts("   Run `mix ace.dashboard` to view the results in the web dashboard")