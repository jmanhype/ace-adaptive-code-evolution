defmodule Ace.RealWorld.CodebaseRunner do
  @moduledoc """
  Runs ACE on real-world codebases and collects metrics.
  """
  
  # Cache directory for cloned repositories
  @cache_dir "test/real_world/cache"
  
  @doc """
  Runs ACE on a real-world codebase and collects metrics.
  
  ## Parameters
  
  - `codebase` - Map containing codebase information from codebases.json
  - `options` - Additional options for the run
  
  ## Returns
  
  Map with test results and metrics
  """
  def run(codebase, _options \\ []) do
    IO.puts("  • Setting up test for #{codebase["name"]}...")
    
    # Ensure cache directory exists
    File.mkdir_p!(@cache_dir)
    
    # Prepare repository
    repo_dir = prepare_repository(codebase)
    
    # Gather codebase statistics
    IO.puts("  • Gathering codebase statistics...")
    stats = gather_codebase_stats(repo_dir, codebase["language"])
    
    # Initialize results map
    results = %{
      codebase: codebase,
      stats: stats,
      timestamps: %{
        started_at: DateTime.utc_now() |> DateTime.to_iso8601()
      },
      metrics: %{
        file_analysis: %{},
        relationship_detection: %{},
        cross_file_analysis: %{}
      },
      analysis_results: %{
        files: [],
        relationships: [],
        opportunities: []
      }
    }
    
    # Run file analysis
    IO.puts("  • Running file analysis...")
    {results, file_analyses} = with_timing(results, :file_analysis, fn ->
      analyze_files(repo_dir, codebase)
    end)
    
    # Store file analysis results
    results = put_in(results, [:analysis_results, :files], file_analyses)
    
    # Run relationship detection
    if length(file_analyses) > 0 do
      IO.puts("  • Detecting file relationships...")
      {results, relationships} = with_timing(results, :relationship_detection, fn ->
        detect_relationships(file_analyses, codebase)
      end)
      
      # Store relationship results
      results = put_in(results, [:analysis_results, :relationships], relationships)
      
      # Run cross-file analysis
      if length(relationships) > 0 do
        IO.puts("  • Performing cross-file analysis...")
        {results, opportunities} = with_timing(results, :cross_file_analysis, fn ->
          analyze_cross_file(file_analyses, relationships, codebase)
        end)
        
        # Store opportunity results
        results = put_in(results, [:analysis_results, :opportunities], opportunities)
      else
        IO.puts("  • Skipping cross-file analysis (no relationships detected)")
      end
    else
      IO.puts("  • Skipping relationship detection (no files analyzed)")
    end
    
    # Record completion timestamp
    results = put_in(results, [:timestamps, :completed_at], DateTime.utc_now() |> DateTime.to_iso8601())
    
    # Calculate summary metrics
    results = calculate_summary_metrics(results)
    
    # Return results
    results
  end
  
  #
  # Private helper functions
  #
  
  # Prepare the repository (clone if needed)
  defp prepare_repository(codebase) do
    repo_name = codebase["name"]
    repo_url = codebase["repo"]
    branch = codebase["branch"] || "main"
    
    # Create cache directory for this repo
    repo_dir = Path.join(@cache_dir, repo_name)
    
    # Clone or update repository
    if File.dir?(repo_dir) do
      IO.puts("  • Updating existing repository at #{repo_dir}...")
      
      # Update existing repository
      {output, status} = System.cmd("git", ["fetch", "origin"], cd: repo_dir)
      if status != 0, do: IO.puts("    ⚠️  Warning: git fetch failed: #{output}")
      
      {output, status} = System.cmd("git", ["checkout", branch], cd: repo_dir)
      if status != 0, do: IO.puts("    ⚠️  Warning: git checkout failed: #{output}")
      
      {output, status} = System.cmd("git", ["pull", "origin", branch], cd: repo_dir)
      if status != 0, do: IO.puts("    ⚠️  Warning: git pull failed: #{output}")
    else
      IO.puts("  • Cloning repository #{repo_url} to #{repo_dir}...")
      
      # Clone new repository
      {output, status} = System.cmd("git", ["clone", "--branch", branch, repo_url, repo_dir])
      if status != 0, do: raise("Failed to clone repository: #{output}")
    end
    
    # Return path to repository
    repo_dir
  end
  
  # Gather statistics about the codebase
  defp gather_codebase_stats(repo_dir, language) do
    # Get file count by extension
    files_by_extension = count_files_by_extension(repo_dir)
    
    # Get line count for the primary language
    line_count = count_lines_by_language(repo_dir, language)
    
    # Get git statistics
    git_stats = get_git_stats(repo_dir)
    
    # Combine statistics
    %{
      repo_size_bytes: get_directory_size(repo_dir),
      files_total: Enum.sum(Map.values(files_by_extension)),
      files_by_extension: files_by_extension,
      line_count: line_count,
      git_stats: git_stats
    }
  end
  
  # Count files by extension in the repository
  defp count_files_by_extension(repo_dir) do
    {output, 0} = System.cmd("find", [repo_dir, "-type", "f", "-not", "-path", "*/\\.*"], stderr_to_stdout: true)
    
    output
    |> String.split("\n", trim: true)
    |> Enum.map(&Path.extname/1)
    |> Enum.frequencies()
  end
  
  # Count lines of code by language
  defp count_lines_by_language(repo_dir, language) do
    extensions = language_extensions(language)
    
    if Enum.empty?(extensions) do
      %{total: 0, code: 0, comments: 0, blanks: 0}
    else
      extension_pattern = Enum.map_join(extensions, "|", &"\\#{&1}$")
      
      {output, _} = System.cmd("find", [
        repo_dir, 
        "-type", "f", 
        "-not", "-path", "*/\\.*", 
        "-regextype", "posix-extended",
        "-regex", ".*\\.(#{extension_pattern})"
      ], stderr_to_stdout: true)
      
      files = String.split(output, "\n", trim: true)
      
      # Count lines in each file
      Enum.reduce(files, %{total: 0, code: 0, comments: 0, blanks: 0}, fn file, acc ->
        case File.read(file) do
          {:ok, content} ->
            lines = String.split(content, "\n")
            code_lines = count_code_lines(lines, language)
            blank_lines = Enum.count(lines, &(String.trim(&1) == ""))
            comment_lines = length(lines) - code_lines - blank_lines
            
            %{
              total: acc.total + length(lines),
              code: acc.code + code_lines,
              comments: acc.comments + comment_lines,
              blanks: acc.blanks + blank_lines
            }
            
          {:error, _} ->
            acc
        end
      end)
    end
  end
  
  # Count code lines (non-blank, non-comment)
  defp count_code_lines(lines, language) do
    # This is a simplified implementation - a real one would need to handle
    # language-specific comment syntax, multi-line comments, etc.
    comment_patterns = language_comment_patterns(language)
    
    Enum.count(lines, fn line ->
      trimmed = String.trim(line)
      trimmed != "" && !Enum.any?(comment_patterns, &String.starts_with?(trimmed, &1))
    end)
  end
  
  # Get Git statistics for the repository
  defp get_git_stats(repo_dir) do
    # Get commit count
    {commit_count, 0} = System.cmd("git", ["rev-list", "--count", "HEAD"], cd: repo_dir)
    
    # Get contributor count
    {contributors, 0} = System.cmd("git", ["shortlog", "-s", "-n", "HEAD"], cd: repo_dir)
    contributor_count = contributors |> String.split("\n", trim: true) |> length()
    
    # Get latest commit date
    {latest_commit_date, 0} = System.cmd(
      "git", ["log", "-1", "--format=%cd", "--date=iso"], 
      cd: repo_dir
    )
    
    %{
      commit_count: String.trim(commit_count) |> String.to_integer(),
      contributor_count: contributor_count,
      latest_commit_date: String.trim(latest_commit_date)
    }
  end
  
  # Get total size of a directory in bytes
  defp get_directory_size(dir) do
    case :os.type() do
      {:unix, :darwin} ->
        # macOS doesn't support the -b flag for du
        {output, 0} = System.cmd("du", ["-sk", dir])
        size_kb = output |> String.split("\t") |> List.first() |> String.to_integer()
        size_kb * 1024  # Convert KB to bytes
      _ ->
        # Linux and other Unix-like systems
        {output, 0} = System.cmd("du", ["-sb", dir])
        output |> String.split("\t") |> List.first() |> String.to_integer()
    end
  end
  
  # Map language to file extensions
  defp language_extensions(language) do
    case String.downcase(language) do
      "elixir" -> [".ex", ".exs"]
      "javascript" -> [".js", ".jsx", ".mjs"]
      "typescript" -> [".ts", ".tsx"]
      "python" -> [".py"]
      "ruby" -> [".rb"]
      "go" -> [".go"]
      _ -> []
    end
  end
  
  # Map language to comment patterns
  defp language_comment_patterns(language) do
    case String.downcase(language) do
      "elixir" -> ["#", "//"]
      "javascript" -> ["//", "/*"]
      "typescript" -> ["//", "/*"]
      "python" -> ["#"]
      "ruby" -> ["#"]
      "go" -> ["//", "/*"]
      _ -> ["#", "//", "/*"]
    end
  end
  
  # Run file analysis on the codebase
  defp analyze_files(repo_dir, codebase) do
    # Determine which files to analyze based on language
    language = codebase["language"]
    extensions = language_extensions(language)
    
    if Enum.empty?(extensions) do
      []
    else
      # Find all files with matching extensions
      files = find_files_by_extensions(repo_dir, extensions)
      
      # Take a sample of files if the codebase is very large
      files = 
        if length(files) > 1000 do
          IO.puts("    ⚠️  Large codebase detected (#{length(files)} files). Taking a sample of 1000 files.")
          Enum.take_random(files, 1000)
        else
          files
        end
      
      # Analyze each file
      _focus_areas = codebase["focus_areas"] || ["performance", "maintainability"]
      
      # Run analysis with ACE
      Enum.map(files, fn file_path ->
        relative_path = Path.relative_to(file_path, repo_dir)
        IO.write("\r    Analyzing file #{relative_path}" <> String.duplicate(" ", 40))
        
        try do
          case File.read(file_path) do
            {:ok, content} ->
              # Here we call ACE to analyze the file
              # In a real implementation, we would use ACE's API directly
              # For this example, we'll create a placeholder result
              %{
                file_path: relative_path,
                language: language,
                content_size: byte_size(content),
                line_count: content |> String.split("\n") |> length(),
                opportunities: []
              }
              
            {:error, reason} ->
              IO.puts("\n    ⚠️  Error reading file #{file_path}: #{reason}")
              nil
          end
        rescue
          e ->
            IO.puts("\n    ⚠️  Error analyzing file #{file_path}: #{inspect(e)}")
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
    end
  end
  
  # Find files by extensions
  defp find_files_by_extensions(dir, extensions) do
    extension_pattern = Enum.map_join(extensions, "|", &"\\#{&1}$")
    
    {output, _} = System.cmd("find", [
      dir, 
      "-type", "f", 
      "-not", "-path", "*/\\.*", 
      "-not", "-path", "*/deps/*",
      "-not", "-path", "*/node_modules/*",
      "-not", "-path", "*/build/*",
      "-not", "-path", "*/dist/*",
      "-regextype", "posix-extended",
      "-regex", ".*\\.(#{extension_pattern})"
    ], stderr_to_stdout: true)
    
    String.split(output, "\n", trim: true)
  end
  
  # Detect relationships between files
  defp detect_relationships(file_analyses, codebase) do
    # Here we would call ACE's relationship detection
    # For this example, we'll create placeholder relationships
    
    _language = codebase["language"]
    relationship_types = ["imports", "extends", "implements", "uses", "references"]
    
    # Generate some sample relationships
    file_analyses
    |> Enum.flat_map(fn source_file ->
      # Generate 0-3 random relationships for each file
      relationship_count = :rand.uniform(4) - 1
      
      Enum.map(1..relationship_count, fn _ ->
        # Select a random target file different from the source
        target_file = 
          file_analyses
          |> Enum.reject(fn f -> f.file_path == source_file.file_path end)
          |> Enum.take_random(1)
          |> List.first()
        
        if target_file do
          %{
            source_file: source_file.file_path,
            target_file: target_file.file_path,
            relationship_type: Enum.random(relationship_types),
            details: %{
              confidence: :rand.uniform(100) / 100
            }
          }
        else
          nil
        end
      end)
      |> Enum.reject(&is_nil/1)
    end)
  end
  
  # Analyze cross-file opportunities
  defp analyze_cross_file(_file_analyses, relationships, _codebase) do
    # Here we would call ACE's cross-file analysis
    # For this example, we'll create placeholder opportunities
    
    # Group related files based on relationships
    file_groups = group_related_files(relationships)
    
    # Generate sample cross-file opportunities
    opportunity_types = ["duplicated_code", "inconsistent_patterns", "circular_dependency"]
    severities = ["low", "medium", "high"]
    
    file_groups
    |> Enum.take_random(Enum.min([5, length(file_groups)]))
    |> Enum.map(fn files ->
      %{
        type: Enum.random(opportunity_types),
        severity: Enum.random(severities),
        scope: "cross_file",
        primary_file: List.first(files),
        related_files: Enum.slice(files, 1..-1),
        description: "Sample cross-file opportunity in #{length(files)} files",
        rationale: "This is a placeholder rationale for testing",
        suggested_change: "This is a placeholder suggestion for testing"
      }
    end)
  end
  
  # Group related files based on relationships
  defp group_related_files(relationships) do
    # Build a graph of file relationships
    graph = Enum.reduce(relationships, %{}, fn rel, acc ->
      source = rel.source_file
      target = rel.target_file
      
      acc
      |> Map.update(source, [target], &[target | &1])
      |> Map.update(target, [source], &[source | &1])
    end)
    
    # Find connected components in the graph
    find_connected_components(graph)
  end
  
  # Find connected components in a graph using DFS
  defp find_connected_components(graph) do
    nodes = Map.keys(graph)
    
    {components, _} = 
      Enum.reduce(nodes, {[], MapSet.new()}, fn node, {components, visited} ->
        if MapSet.member?(visited, node) do
          {components, visited}
        else
          {component, new_visited} = dfs(graph, node, visited)
          {[component | components], new_visited}
        end
      end)
    
    components
  end
  
  # Depth-first search to find connected components
  defp dfs(graph, start, visited) do
    dfs_visit(graph, [start], [start], MapSet.put(visited, start))
  end
  
  defp dfs_visit(_graph, [], component, visited) do
    {component, visited}
  end
  
  defp dfs_visit(graph, [node | rest], component, visited) do
    neighbors = Map.get(graph, node, [])
    
    {new_stack, new_component, new_visited} =
      Enum.reduce(neighbors, {rest, component, visited}, fn neighbor, {stack, comp, vis} ->
        if MapSet.member?(vis, neighbor) do
          {stack, comp, vis}
        else
          {[neighbor | stack], [neighbor | comp], MapSet.put(vis, neighbor)}
        end
      end)
    
    dfs_visit(graph, new_stack, new_component, new_visited)
  end
  
  # Time a function and update metrics
  defp with_timing(results, metric_key, func) do
    start_time = :os.system_time(:millisecond)
    memory_before = :erlang.memory()
    
    result = func.()
    
    end_time = :os.system_time(:millisecond)
    memory_after = :erlang.memory()
    
    elapsed_ms = end_time - start_time
    memory_delta = memory_after[:total] - memory_before[:total]
    
    metrics = %{
      elapsed_ms: elapsed_ms,
      memory_delta_bytes: memory_delta
    }
    
    IO.puts("    Completed in #{elapsed_ms}ms")
    
    {put_in(results, [:metrics, metric_key], metrics), result}
  end
  
  # Calculate summary metrics
  defp calculate_summary_metrics(results) do
    # Extract key stats
    file_count = length(results.analysis_results.files)
    relationship_count = length(results.analysis_results.relationships)
    opportunity_count = length(results.analysis_results.opportunities)
    
    # Calculate timing totals
    total_elapsed_ms = 
      results.metrics
      |> Map.values()
      |> Enum.map(fn m -> Map.get(m, :elapsed_ms, 0) end)
      |> Enum.sum()
    
    # Calculate lines of code if available
    lines_of_code = get_in(results, [:stats, :line_count, :total]) || 0
    
    # Compute rates
    metrics_per_loc = %{
      elapsed_ms_per_1k_loc: (if lines_of_code > 0, do: total_elapsed_ms / (lines_of_code / 1000), else: 0),
      relationships_per_1k_loc: (if lines_of_code > 0, do: relationship_count / (lines_of_code / 1000), else: 0),
      opportunities_per_1k_loc: (if lines_of_code > 0, do: opportunity_count / (lines_of_code / 1000), else: 0)
    }
    
    # Add summary metrics to results
    put_in(results, [:metrics, :summary], %{
      total_elapsed_ms: total_elapsed_ms,
      file_count: file_count,
      relationship_count: relationship_count,
      opportunity_count: opportunity_count,
      per_1k_loc: metrics_per_loc
    })
  end
end