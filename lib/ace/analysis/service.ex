defmodule Ace.Analysis.Service do
  @moduledoc """
  Service for analyzing code to identify optimization opportunities.
  Supports both single-file and multi-file analysis.
  """
  import Ace.Telemetry.FunctionTracer
  alias Ace.Core.{Analysis, Opportunity, Project, AnalysisRelationship}
  alias Ace.Infrastructure.AI.Orchestrator
  
  # Store custom analyzers
  @custom_analyzers_table :ace_custom_analyzers
  
  # Initialize ETS table for custom analyzers on module load
  @on_load :init_analyzers_table
  def init_analyzers_table do
    :ets.new(@custom_analyzers_table, [:named_table, :set, :public])
    :ok
  end

  @doc """
  Analyzes a file to identify optimization opportunities.
  
  ## Parameters
  
    - `file_path`: Path to the file to analyze
    - `options`: Analysis options
      - `:language`: Programming language (auto-detected if not specified)
      - `:focus_areas`: Areas to focus on (defaults to ["performance", "maintainability"])
      - `:severity_threshold`: Minimum severity to report (defaults to "medium")
      - `:project_id`: Optional project ID this file belongs to
  
  ## Returns
  
    - `{:ok, analysis}`: The completed analysis with opportunities
    - `{:error, reason}`: If analysis fails
  """
  deftrace analyze_file(file_path), do: analyze_file(file_path, [])
  
  deftrace analyze_file(file_path, options) do
    with {:ok, content} <- File.read(file_path),
         language = options[:language] || detect_language(file_path) do
      
      file_options = Map.new(options) |> Map.put(:file_path, file_path)
      analyze_code(content, language, file_options)
    else
      {:error, reason} when is_atom(reason) ->
        {:error, "Failed to read file: #{reason}"}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Analyzes multiple files as part of a single project.
  
  ## Parameters
  
    - `project`: The project to analyze (or project attributes to create one)
    - `file_paths`: List of file paths to analyze
    - `options`: Analysis options
      - `:focus_areas`: Areas to focus on (defaults to ["performance", "maintainability"])
      - `:severity_threshold`: Minimum severity to report (defaults to "medium")
      - `:detect_relationships`: Whether to detect relationships between files (defaults to true)
  
  ## Returns
  
    - `{:ok, %{project: project, analyses: analyses}}`: The completed project with analyses
    - `{:error, reason}`: If analysis fails
  """
  deftrace analyze_project(project_params, file_paths), do: analyze_project(project_params, file_paths, [])
  
  deftrace analyze_project(project_params, file_paths, options) do
    # Create or find project
    with {:ok, project} <- create_or_get_project(project_params),
         # Analyze each file individually
         {:ok, analyses} <- analyze_project_files(project, file_paths, options),
         # Detect relationships between files if requested
         {:ok, analysis_relationships} <- maybe_detect_relationships(project, analyses, options),
         # Perform multi-file analysis to find cross-file opportunities
         {:ok, cross_file_opportunities} <- analyze_cross_file(project, analyses, options) do
     
      # Return project with analyses
      {:ok, %{
        project: project, 
        analyses: analyses, 
        relationships: analysis_relationships,
        cross_file_opportunities: cross_file_opportunities
      }}
    end
  end
  
  @doc """
  Analyzes code content directly.
  
  ## Parameters
  
    - `content`: Source code to analyze
    - `language`: Programming language of the code
    - `options`: Analysis options
      - `:file_path`: Path to the file (defaults to "inline_code" if not provided)
      - `:focus_areas`: Areas to focus on (defaults to ["performance", "maintainability"])
      - `:severity_threshold`: Minimum severity to report (defaults to "medium")
      - `:analyzer`: Specific analyzer to use (uses auto or default if not specified)
      - `:project_id`: Optional project ID this analysis belongs to
      - `:is_multi_file`: Whether this is part of a multi-file analysis (defaults to false)
  
  ## Returns
  
    - `{:ok, analysis}`: The completed analysis with opportunities
    - `{:error, reason}`: If analysis fails
  """
  deftrace analyze_code(content, language), do: analyze_code(content, language, [])
  
  deftrace analyze_code(content, language, options) do
    focus_areas = options[:focus_areas] || ["performance", "maintainability"]
    severity_threshold = options[:severity_threshold] || "medium"
    skip_db = options[:skip_db] || false
    
    if skip_db do
      # Skip database storage for CLI usage
      mock_analyze_code(content, language, focus_areas, severity_threshold)
    else
      # Create analysis record
      params = %{
        file_path: options[:file_path] || "inline_code",
        language: language,
        content: content,
        focus_areas: focus_areas,
        severity_threshold: severity_threshold,
        project_id: options[:project_id],
        is_multi_file: options[:is_multi_file] || false
      }
      
      with {:ok, analysis} <- create_analysis(params),
           # Analyze code with analyzer
           {:ok, opportunities} <- perform_analysis(analysis, options[:analyzer]),
           # Save opportunities
           {:ok, _} <- save_opportunities(analysis, opportunities) do
        # Mark analysis as completed
        update_analysis_completion(analysis)
      end
    end
  end
  
  # Mock implementation for CLI usage without database
  defp mock_analyze_code(content, language, focus_areas, severity_threshold) do
    # Run analysis without database storage
    case perform_analysis_without_db(content, language, focus_areas) do
      {:ok, opportunities} -> 
        # Filter by severity
        filtered_opportunities = filter_by_severity(opportunities, severity_threshold)
        
        # Create a mock analysis result with opportunities
        mock_analysis = %{
          id: "mock-#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
          file_path: "analyzed_file.#{language}",
          language: language,
          content: content,
          focus_areas: focus_areas,
          severity_threshold: severity_threshold,
          completed_at: DateTime.utc_now(),
          opportunities: filtered_opportunities
        }
        
        {:ok, mock_analysis}
        
      error -> error
    end
  end
  
  # Perform analysis directly via AI provider without saving to database
  defp perform_analysis_without_db(content, language, focus_areas) do
    Ace.Infrastructure.AI.Orchestrator.analyze_code(
      content,
      language,
      focus_areas
    )
  end

  @doc """
  Gets an opportunity by ID.
  """
  deftrace get_opportunity(id) do
    case Ace.Repo.get(Opportunity, id) do
      nil -> {:error, :not_found}
      opportunity -> {:ok, opportunity}
    end
  end

  @doc """
  Lists opportunities based on specified criteria.
  """
  deftrace list_opportunities(params) do
    Opportunity
    |> apply_filters(params)
    |> Ace.Repo.all()
    |> case do
      opportunities when is_list(opportunities) -> {:ok, opportunities}
      error -> {:error, error}
    end
  end

  # Private helper functions

  defp create_analysis(params) do
    %Analysis{}
    |> Analysis.changeset(%{
      file_path: params.file_path,
      language: params.language,
      content: params.content,
      focus_areas: Map.get(params, :focus_areas, ["performance", "maintainability"]),
      severity_threshold: Map.get(params, :severity_threshold, "medium"),
      project_id: Map.get(params, :project_id),
      is_multi_file: Map.get(params, :is_multi_file, false)
    })
    |> Ace.Repo.insert()
  end
  
  @doc """
  Creates a new project or gets an existing one by ID.
  """
  def create_or_get_project(params) when is_map(params) do
    case params do
      %{id: id} when not is_nil(id) ->
        case Ace.Repo.get(Project, id) do
          nil -> {:error, :project_not_found}
          project -> {:ok, project}
        end
      
      _ ->
        %Project{}
        |> Project.changeset(params)
        |> Ace.Repo.insert()
    end
  end
  
  # Analyzes all files in a project.
  defp analyze_project_files(project, file_paths, options) do
    # Set up base options for file analysis
    base_options = 
      options
      |> Map.new()
      |> Map.put(:project_id, project.id)
      |> Map.put(:is_multi_file, true)
    
    # Process files concurrently
    results = 
      file_paths
      |> Task.async_stream(
        fn file_path ->
          analyze_file(file_path, base_options)
        end,
        ordered: true,
        timeout: 120_000
      )
      |> Enum.to_list()
    
    # Process results
    {successes, failures} =
      results
      |> Enum.split_with(fn
        {:ok, {:ok, _analysis}} -> true
        _ -> false
      end)
    
    analyses = Enum.map(successes, fn {:ok, {:ok, analysis}} -> analysis end)
    
    if Enum.empty?(failures) do
      {:ok, analyses}
    else
      error_details = Enum.map(failures, fn {:ok, {:error, reason}} -> reason end)
      {:error, "Failed to analyze some files: #{inspect(error_details)}"}
    end
  end
  
  # Detects relationships between analyzed files.
  defp maybe_detect_relationships(project, analyses, options) do
    detect_relationships = Map.get(options, :detect_relationships, true)
    
    if detect_relationships do
      detect_file_relationships(project, analyses)
    else
      {:ok, []}
    end
  end
  
  defp detect_file_relationships(project, analyses) do
    # Group analyses by language for language-specific relationship detection
    analyses_by_language = Enum.group_by(analyses, & &1.language)
    
    # Detect relationships for each language group
    relationships =
      analyses_by_language
      |> Enum.flat_map(fn {language, language_analyses} ->
        detect_language_specific_relationships(language, language_analyses, project)
      end)
    
    # Save all detected relationships
    results =
      relationships
      |> Enum.map(fn relationship_attrs ->
        %AnalysisRelationship{}
        |> AnalysisRelationship.changeset(relationship_attrs)
        |> Ace.Repo.insert()
      end)
    
    # Check if any failed
    {successes, failures} = 
      results
      |> Enum.split_with(fn
        {:ok, _} -> true
        {:error, _} -> false
      end)
    
    relationships = Enum.map(successes, fn {:ok, relationship} -> relationship end)
    
    if Enum.empty?(failures) do
      {:ok, relationships}
    else
      {:error, "Some relationships could not be saved"}
    end
  end
  
  defp detect_language_specific_relationships(language, analyses, project) do
    case language do
      "elixir" -> detect_elixir_relationships(analyses, project)
      "javascript" -> detect_javascript_relationships(analyses, project)
      "python" -> detect_python_relationships(analyses, project)
      "ruby" -> detect_ruby_relationships(analyses, project)
      "go" -> detect_go_relationships(analyses, project)
      _ -> []
    end
  end
  
  # Implementation for each language's relationship detection
  defp detect_elixir_relationships(analyses, _project) do
    # Extract modules, imports, uses, requires from each file
    analyses
    |> Enum.flat_map(fn source_analysis ->
      # Find imports and requires using simple regex patterns
      imports = extract_elixir_imports(source_analysis.content)
      
      # Map imported modules to their files
      imports
      |> Enum.flat_map(fn imported_module ->
        # Find which analysis contains this module
        target_analysis = find_elixir_module(imported_module, analyses)
        
        case target_analysis do
          nil -> []
          analysis when analysis.id == source_analysis.id -> []
          analysis -> 
            [%{
              source_analysis_id: source_analysis.id,
              target_analysis_id: analysis.id,
              relationship_type: "imports",
              details: %{
                module: imported_module
              }
            }]
        end
      end)
    end)
  end
  
  defp extract_elixir_imports(content) do
    # Simple regex patterns to find imports, requires, uses, and aliases in Elixir code
    import_pattern = ~r/^\s*(import|require|use|alias)\s+([A-Z][\w\.]+)/m
    
    Regex.scan(import_pattern, content, capture: :all_but_first)
    |> Enum.map(fn [_type, module] -> module end)
    |> Enum.uniq()
  end
  
  defp find_elixir_module(module_name, analyses) do
    module_pattern = ~r/^\s*(defmodule)\s+#{Regex.escape(module_name)}\s+do/m
    
    Enum.find(analyses, fn analysis ->
      Regex.match?(module_pattern, analysis.content)
    end)
  end
  
  # Similar functions for other languages
  defp detect_javascript_relationships(analyses, project) do
    analyses
    |> Enum.flat_map(fn source_analysis ->
      # Find imports in JS files
      imports = extract_javascript_imports(source_analysis.content)
      
      imports
      |> Enum.flat_map(fn {import_type, imported_path} ->
        # Find the matching file for the import
        target_analysis = find_javascript_module(imported_path, source_analysis, analyses, project)
        
        case target_analysis do
          nil -> []
          analysis when analysis.id == source_analysis.id -> []
          analysis -> 
            [%{
              source_analysis_id: source_analysis.id,
              target_analysis_id: analysis.id,
              relationship_type: "imports",
              details: %{
                import_type: import_type,
                import_path: imported_path
              }
            }]
        end
      end)
    end)
  end
  
  defp extract_javascript_imports(content) do
    # ES6 import
    es6_pattern = ~r/import\s+(?:(?:{[^}]+}|\*\s+as\s+\w+|\w+)\s+from\s+)?['"]([^'"]+)['"]/
    # CommonJS require
    cjs_pattern = ~r/(?:const|let|var)\s+(?:{[^}]+}|\w+)\s+=\s+require\(['"]([^'"]+)['"]\)/
    
    es6_imports = Regex.scan(es6_pattern, content, capture: :all_but_first)
                  |> Enum.map(fn [path] -> {"es6", path} end)
                  
    cjs_imports = Regex.scan(cjs_pattern, content, capture: :all_but_first)
                  |> Enum.map(fn [path] -> {"commonjs", path} end)
                  
    es6_imports ++ cjs_imports
  end
  
  defp find_javascript_module(import_path, source_analysis, analyses, project) do
    # Handle relative paths
    resolved_path = resolve_js_import_path(import_path, source_analysis.file_path, project)
    
    Enum.find(analyses, fn analysis ->
      # Match on exact path or with extension added
      analysis.file_path == resolved_path ||
        analysis.file_path == "#{resolved_path}.js" ||
        analysis.file_path == "#{resolved_path}.jsx" ||
        analysis.file_path == "#{resolved_path}.ts" ||
        analysis.file_path == "#{resolved_path}.tsx" ||
        # Handle index files in directories
        analysis.file_path == "#{resolved_path}/index.js" ||
        analysis.file_path == "#{resolved_path}/index.jsx" ||
        analysis.file_path == "#{resolved_path}/index.ts" ||
        analysis.file_path == "#{resolved_path}/index.tsx"
    end)
  end
  
  defp resolve_js_import_path(import_path, source_file_path, _project) do
    if String.starts_with?(import_path, ".") do
      # Relative import - resolve it relative to the source file
      source_dir = Path.dirname(source_file_path)
      Path.expand(Path.join(source_dir, import_path))
    else
      # Node module import - we don't try to resolve these across project files
      nil
    end
  end
  
  # Placeholder functions for other languages
  defp detect_python_relationships(_analyses, _project), do: []
  defp detect_ruby_relationships(_analyses, _project), do: []
  defp detect_go_relationships(_analyses, _project), do: []
  
  # Analyzes multiple files to find cross-file optimization opportunities.
  defp analyze_cross_file(project, analyses, options) do
    # Run cross-file analysis if there are multiple files and relationships
    if length(analyses) <= 1 do
      {:ok, []}
    else
      # Group related files for cross-file analysis
      analysis_groups = group_related_analyses(analyses)
      
      # For each group, perform cross-file analysis
      opportunities = 
        analysis_groups
        |> Enum.flat_map(fn group ->
          perform_cross_file_analysis(project, group, options)
        end)
      
      {:ok, opportunities}
    end
  end
  
  defp group_related_analyses(analyses) do
    # Basic grouping by language for now
    Enum.group_by(analyses, & &1.language)
    |> Map.values()
  end
  
  defp perform_cross_file_analysis(_project, analyses, options) do
    # For each language group, prepare code context and analyze
    if Enum.empty?(analyses) do
      []
    else
      language = List.first(analyses).language
      
      # Prepare context for cross-file analysis
      file_context = prepare_file_context(analyses)
      
      # Use AI to analyze the files together
      case Orchestrator.analyze_cross_file(file_context, language, options) do
        {:ok, opportunities} ->
          # Save cross-file opportunities
          opportunities
          |> Enum.flat_map(fn opp ->
            # Determine which analysis this belongs to (primary file)
            primary_file = Map.get(opp, :primary_file)
            analysis = Enum.find(analyses, fn a -> 
              Path.basename(a.file_path) == primary_file || a.file_path == primary_file
            end)
            
            if analysis do
              attrs = %{
                location: opp.location,
                type: opp.type,
                description: opp.description,
                severity: opp.severity,
                rationale: Map.get(opp, :rationale),
                suggested_change: Map.get(opp, :suggested_change),
                analysis_id: analysis.id,
                scope: "cross_file",
                cross_file_references: Map.get(opp, :cross_file_references, [])
              }
              
              case %Opportunity{} |> Opportunity.changeset(attrs) |> Ace.Repo.insert() do
                {:ok, saved_opp} -> [saved_opp]
                {:error, _} -> []
              end
            else
              []
            end
          end)
          
        {:error, _} ->
          []
      end
    end
  end
  
  defp prepare_file_context(analyses) do
    Enum.map(analyses, fn analysis ->
      %{
        file_path: analysis.file_path,
        file_name: Path.basename(analysis.file_path),
        language: analysis.language,
        content: analysis.content
      }
    end)
  end

  @doc """
  Registers a custom analyzer.
  
  ## Parameters
  
    - `name`: Name of the analyzer
    - `options`: Analyzer options
    - `function`: Function that implements the analyzer
  
  ## Returns
  
    - `:ok`: If the analyzer was registered successfully
    - `{:error, reason}`: If registration fails
  """
  def register_analyzer(name, options \\ [], function) when is_atom(name) and is_function(function, 2) do
    try do
      :ets.insert(@custom_analyzers_table, {name, %{options: options, function: function}})
      :ok
    rescue
      e -> {:error, "Failed to register analyzer: #{Exception.message(e)}"}
    end
  end
  
  # Perform the actual analysis using either a custom analyzer or the default AI approach
  defp perform_analysis(analysis, nil) do
    # No specific analyzer requested, use AI-based analysis
    Orchestrator.analyze_code(
      analysis.content,
      analysis.language,
      analysis.focus_areas,
      [severity_threshold: analysis.severity_threshold]
    )
  end
  
  defp perform_analysis(analysis, analyzer_name) when is_atom(analyzer_name) do
    # Use a named custom analyzer
    case :ets.lookup(@custom_analyzers_table, analyzer_name) do
      [{_, %{function: function}}] ->
        # Call the custom analyzer function
        try do
          case function.(analysis.content, analysis.language) do
            opportunities when is_list(opportunities) ->
              {:ok, filter_by_severity(opportunities, analysis.severity_threshold)}
            
            {:ok, opportunities} when is_list(opportunities) ->
              {:ok, filter_by_severity(opportunities, analysis.severity_threshold)}
            
            {:error, reason} ->
              {:error, reason}
            
            other ->
              {:error, "Custom analyzer returned invalid result: #{inspect(other)}"}
          end
        rescue
          e -> {:error, "Custom analyzer failed: #{Exception.message(e)}"}
        end
      
      [] ->
        {:error, "Custom analyzer '#{analyzer_name}' not found"}
    end
  end
  
  # Filter opportunities by severity threshold
  defp filter_by_severity(opportunities, threshold) do
    severity_value = %{
      "low" => 1,
      "medium" => 2,
      "high" => 3
    }
    
    min_severity = severity_value[threshold] || 2
    
    Enum.filter(opportunities, fn opp ->
      opp_severity = severity_value[opp.severity] || 0
      opp_severity >= min_severity
    end)
  end
  
  # Detect the programming language from file extension
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

  defp save_opportunities(analysis, opportunities) do
    # Extract items from tuple if needed
    items = case opportunities do
      {"items", items} when is_list(items) -> items
      items when is_list(items) -> items
      _ -> []
    end
    
    items
    |> Enum.map(fn opp ->
      %Opportunity{}
      |> Opportunity.changeset(%{
        location: Map.get(opp, "location"),
        type: Map.get(opp, "type"),
        description: Map.get(opp, "description"),
        severity: Map.get(opp, "severity"),
        rationale: Map.get(opp, "rationale"),
        suggested_change: Map.get(opp, "suggested_change"),
        analysis_id: analysis.id
      })
      |> Ace.Repo.insert()
    end)
    |> Enum.split_with(fn
      {:ok, _} -> true
      {:error, _} -> false
    end)
    |> case do
      {_successes, []} -> {:ok, opportunities}
      {_, errors} -> {:error, errors}
    end
  end

  defp update_analysis_completion(analysis) do
    analysis
    |> Analysis.changeset(%{completed_at: DateTime.utc_now()})
    |> Ace.Repo.update()
    |> case do
      {:ok, updated_analysis} ->
        # Reload with opportunities
        {:ok, Ace.Repo.preload(updated_analysis, :opportunities)}
      error -> error
    end
  end

  defp apply_filters(query, params) do
    Enum.reduce(params, query, fn
      {:analysis_id, id}, query ->
        import Ecto.Query
        from q in query, where: q.analysis_id == ^id

      {:severity, severity}, query ->
        import Ecto.Query
        from q in query, where: q.severity == ^severity

      {:type, type}, query ->
        import Ecto.Query
        from q in query, where: q.type == ^type

      _, query ->
        query
    end)
  end
end