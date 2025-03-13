defmodule Ace.Optimization.Service do
  @moduledoc """
  Service for generating and applying code optimizations.
  """
  import Ace.Telemetry.FunctionTracer
  alias Ace.Core.{Opportunity, Optimization}
  alias Ace.Infrastructure.AI.Orchestrator

  @doc """
  Generates an optimized implementation for an identified opportunity.
  
  ## Parameters
  
    - `params`: Map of parameters including:
      - `:opportunity_id` - ID of the opportunity to optimize
      - `:strategy` - Optimization strategy to use (optional, defaults to "auto")
  
  ## Returns
  
    - `{:ok, optimization}`: The created Optimization record
    - `{:error, reason}`: If optimization generation fails
  """
  deftrace optimize(params) do
    strategy = Map.get(params, :strategy, "auto")

    with {:ok, opportunity} <- get_opportunity(params.opportunity_id),
         {:ok, original_code} <- get_original_code(opportunity),
         {:ok, optimization_data} <- generate_optimization(opportunity, original_code, strategy) do
      create_optimization(opportunity, original_code, optimization_data, strategy)
    end
  end
  
  @doc """
  Generates an optimized implementation for an identified opportunity.
  
  ## Parameters
  
    - `opportunity_id` - ID of the opportunity to optimize
    - `strategy` - Optimization strategy to use
    - `options` - Additional options (optional)
  
  ## Returns
  
    - `{:ok, optimization}`: The created Optimization record
    - `{:error, reason}`: If optimization generation fails
  """
  deftrace optimize(opportunity_id, strategy, options) do
    params = %{
      opportunity_id: opportunity_id,
      strategy: strategy
    } |> Map.merge(options)
    
    optimize(params)
  end

  @doc """
  Applies an optimization to the actual code file.
  
  ## Parameters
  
    - `params`: Map of parameters including:
      - `:optimization_id` - ID of the optimization to apply
  
  ## Returns
  
    - `{:ok, optimization}`: The updated Optimization record
    - `{:error, reason}`: If applying the optimization fails
  """
  deftrace apply_optimization(params) do
    with {:ok, optimization} <- get_optimization(params.optimization_id),
         {:ok, opportunity} <- get_opportunity(optimization.opportunity_id),
         {:ok, analysis} <- get_analysis(opportunity.analysis_id),
         :ok <- apply_changes(analysis.file_path, opportunity.location, optimization.optimized_code) do
      mark_optimization_applied(optimization)
    end
  end
  
  @doc """
  Applies an optimization to the actual code file.
  
  ## Parameters
  
    - `optimization_id` - ID of the optimization to apply
    - `options` - Map of options:
      - `:backup` - Whether to backup the original file
  
  ## Returns
  
    - `{:ok, optimization}`: The updated Optimization record
    - `{:error, reason}`: If applying the optimization fails
  """
  deftrace apply_optimization(optimization_id, options) do
    params = %{
      optimization_id: optimization_id,
      options: options
    }
    
    apply_optimization(params)
  end

  @doc """
  Gets an optimization by ID.
  """
  deftrace get_optimization(id) do
    case Ace.Repo.get(Optimization, id) do
      nil -> {:error, :not_found}
      optimization -> {:ok, optimization}
    end
  end

  # Private helper functions

  defp get_opportunity(id) do
    case Ace.Repo.get(Opportunity, id) do
      nil -> {:error, :not_found}
      opportunity -> {:ok, opportunity}
    end
  end

  defp get_analysis(id) do
    case Ace.Repo.get(Ace.Core.Analysis, id) do
      nil -> {:error, :not_found}
      analysis -> {:ok, analysis}
    end
  end

  defp get_original_code(opportunity) do
    # We need to preload the analysis to get the file content
    opportunity = Ace.Repo.preload(opportunity, :analysis)
    
    with {:ok, location} <- parse_location(opportunity.location),
         {:ok, code} <- extract_code(opportunity.analysis.content, location) do
      {:ok, code}
    end
  end

  defp generate_optimization(opportunity, original_code, strategy) do
    # Get language-specific optimizer if available
    language = get_language_from_opportunity(opportunity)
    
    case get_language_specific_optimizer(language) do
      nil ->
        # Fallback to default AI-based optimization
        Orchestrator.generate_optimization(opportunity, original_code, strategy)
      optimizer_module ->
        try do
          # Check if module exists and has the required function
          # Store the module reference in a variable to suppress the nil warning
          optimizer_mod = if Code.ensure_loaded?(optimizer_module) && 
                            function_exported?(optimizer_module, :optimize, 3) do
            optimizer_module  # The module is valid and has the function
          else
            nil  # Mark as nil if not available
          end
          
          # Call either the custom optimizer or fallback
          if optimizer_mod do
            apply(optimizer_mod, :optimize, [opportunity, original_code, strategy])
          else
            Orchestrator.generate_optimization(opportunity, original_code, strategy)
          end
        rescue
          _ ->
            # Fallback to default AI-based optimization on error
            Orchestrator.generate_optimization(opportunity, original_code, strategy)
        end
    end
  end
  
  defp get_language_from_opportunity(opportunity) do
    opportunity = Ace.Repo.preload(opportunity, :analysis)
    opportunity.analysis.language
  end
  
  defp get_language_specific_optimizer(language) do
    # Map languages to their specific optimizer modules
    case language do
      "elixir" -> Ace.Optimization.Languages.Elixir
      "javascript" -> Ace.Optimization.Languages.JavaScript
      "python" -> Ace.Optimization.Languages.Python
      "ruby" -> Ace.Optimization.Languages.Ruby
      "go" -> Ace.Optimization.Languages.Go
      _ -> nil
    end
  end

  defp create_optimization(opportunity, original_code, optimization_data, strategy) do
    %Optimization{}
    |> Optimization.changeset(%{
      opportunity_id: opportunity.id,
      strategy: strategy,
      original_code: original_code,
      optimized_code: optimization_data.optimized_code,
      explanation: optimization_data.explanation,
      status: "pending"
    })
    |> Ace.Repo.insert()
  end

  defp apply_changes(file_path, location, optimized_code) do
    # Validate file path
    with :ok <- validate_file_path(file_path),
         {:ok, file_content} <- File.read(file_path),
         {:ok, location} <- parse_location(location),
         {:ok, new_content} <- replace_code(file_content, location, optimized_code) do
      # Create backup of the original file
      backup_path = "#{file_path}.bak.#{System.system_time(:second)}"
      File.write(backup_path, file_content)
      
      case File.write(file_path, new_content) do
        :ok -> :ok
        {:error, reason} ->
          # In case of error, try to restore from backup
          File.rename(backup_path, file_path)
          {:error, "Failed to write to file: #{reason}"}
      end
    end
  end
  
  defp validate_file_path(file_path) do
    cond do
      !is_binary(file_path) ->
        {:error, "File path must be a string"}
      String.trim(file_path) == "" ->
        {:error, "File path cannot be empty"}
      !File.exists?(file_path) ->
        {:error, "File does not exist: #{file_path}"}
      !File.regular?(file_path) ->
        {:error, "Path is not a regular file: #{file_path}"}
      # Check if file is readable
      not File.exists?(file_path) or (File.exists?(file_path) and match?({:error, _}, File.read(file_path))) ->
        {:error, "File is not readable: #{file_path}"}
      # Check if file is writable (only if it exists and is readable)
      File.exists?(file_path) and File.regular?(file_path) and not String.contains?(file_path, "/dev/null") and 
      match?({:error, _}, (try do File.write(file_path, "", [:append]) rescue _ -> {:error, :permission_denied} end)) ->
        {:error, "File is not writable: #{file_path}"}
      true ->
        :ok
    end
  rescue
    e -> {:error, "Error validating file path: #{Exception.message(e)}"}
  end

  defp mark_optimization_applied(optimization) do
    optimization
    |> Optimization.changeset(%{status: "applied"})
    |> Ace.Repo.update()
  end

  # Location parsing and code extraction helpers

  defp parse_location(location) do
    cond do
      # Handle line numbers like "lines 10-20"
      Regex.match?(~r/lines? (\d+)(?:-(\d+))?/i, location) ->
        case Regex.run(~r/lines? (\d+)(?:-(\d+))?/i, location) do
          [_, start_str, end_str] ->
            start = String.to_integer(start_str)
            stop = String.to_integer(end_str)
            {:ok, %{type: :lines, start: start, stop: stop}}
          [_, start_str] -> 
            start = String.to_integer(start_str)
            {:ok, %{type: :lines, start: start, stop: start}}
        end

      # Handle function names like "function calculate_total"
      Regex.match?(~r/function (\w+)/i, location) ->
        [_, function_name] = Regex.run(~r/function (\w+)/i, location)
        {:ok, %{type: :function, name: function_name}}

      # Handle file paths
      Regex.match?(~r/(\w+\.\w+):(\d+)(?:-(\d+))?/, location) ->
        case Regex.run(~r/(\w+\.\w+):(\d+)(?:-(\d+))?/, location) do
          [_, _filename, start_str, end_str] ->
            start = String.to_integer(start_str)
            stop = String.to_integer(end_str)
            {:ok, %{type: :lines, start: start, stop: stop}}
          [_, _filename, start_str] -> 
            start = String.to_integer(start_str)
            {:ok, %{type: :lines, start: start, stop: start}}
        end

      true ->
        {:error, "Unable to parse location: #{location}"}
    end
  end

  defp extract_code(content, %{type: :lines, start: start, stop: stop}) do
    lines = String.split(content, "\n")
    
    if start > 0 and start <= length(lines) and stop >= start and stop <= length(lines) do
      extracted = lines
      |> Enum.slice((start - 1)..(stop - 1))
      |> Enum.join("\n")
      
      {:ok, extracted}
    else
      {:error, "Line numbers out of range"}
    end
  end

  defp extract_code(content, %{type: :function, name: function_name}) do
    # Use AST parsing for more robust function extraction
    try do
      {:ok, ast} = Code.string_to_quoted(content, columns: true, token_metadata: true)
      function_code = extract_function_from_ast(ast, function_name, content)
      case function_code do
        nil -> {:error, "Function #{function_name} not found in content"}
        code -> {:ok, code}
      end
    rescue
      e ->
        # Fallback to regex if AST parsing fails
        IO.puts("AST parsing failed, falling back to regex: #{Exception.message(e)}")
        case Regex.run(~r/(?:def|defp)\s+#{function_name}\s*\([^\)]*\)(?:\s*when\s+[^,]+)?\s*do\s*\n(.*?)\n\s*end/s, content) do
          [full_match, _function_body] -> 
            {:ok, full_match}
          nil -> 
            {:error, "Function #{function_name} not found in content"}
        end
    end
  end

  # AST traversal helpers for function extraction
  defp extract_function_from_ast(ast, function_name, original_code) do
    {_, functions} = Macro.prewalk(ast, [], &collect_functions/2)
    
    # Find the target function
    function_def = Enum.find(functions, fn
      {{:def, _, [{:when, _, [{name, _, _} | _]}]}, _} -> 
        Atom.to_string(name) == function_name
      {{:defp, _, [{:when, _, [{name, _, _} | _]}]}, _} -> 
        Atom.to_string(name) == function_name
      {{:def, _, [{name, _, _} | _]}, _} -> 
        Atom.to_string(name) == function_name
      {{:defp, _, [{name, _, _} | _]}, _} -> 
        Atom.to_string(name) == function_name
      _ -> false
    end)
    
    case function_def do
      {_function_ast, metadata} ->
        # Extract the full source code using the line information
        start_line = metadata[:line]
        end_line = find_end_line(ast, start_line)
        
        if start_line && end_line do
          extract_lines(original_code, start_line, end_line)
        else
          nil
        end
      _ -> nil
    end
  end

  defp collect_functions({:def, meta, _} = node, acc), 
    do: {node, [{node, meta} | acc]}
  defp collect_functions({:defp, meta, _} = node, acc), 
    do: {node, [{node, meta} | acc]}
  defp collect_functions(node, acc), 
    do: {node, acc}

  defp find_end_line(ast, start_line) do
    # Simplified approach - in a real implementation you'd scan for the 'end' token
    # This is an approximation - we assume the function ends before the next def/defp
    {_, next_def_line} = Macro.prewalk(ast, nil, fn
      {:def, meta, _}, nil ->
        if meta[:line] > start_line, do: {nil, meta[:line]}, else: {nil, nil}
      {:defp, meta, _}, nil ->
        if meta[:line] > start_line, do: {nil, meta[:line]}, else: {nil, nil}
      node, acc -> {node, acc}
    end)
    
    next_def_line || start_line + 50  # Fallback if we can't find the next def
  end

  defp extract_lines(code, start_line, end_line) do
    code
    |> String.split("\n")
    |> Enum.slice((start_line - 1)..(end_line - 2))
    |> Enum.join("\n")
  end

  defp replace_code(content, %{type: :lines, start: start, stop: stop}, new_code) do
    lines = String.split(content, "\n")
    
    if start > 0 and start <= length(lines) and stop >= start and stop <= length(lines) do
      {before_lines, _} = Enum.split(lines, start - 1)
      {_, after_lines} = Enum.split(lines, stop)
      
      new_lines = before_lines ++ String.split(new_code, "\n") ++ after_lines
      {:ok, Enum.join(new_lines, "\n")}
    else
      {:error, "Line numbers out of range"}
    end
  end

  defp replace_code(content, %{type: :function, name: function_name}, new_code) do
    pattern = ~r/(?:def|defp)\s+#{function_name}\s*\([^\)]*\)(?:\s*when\s+[^,]+)?\s*do\s*\n.*?\n\s*end/s
    
    case Regex.run(pattern, content) do
      [match | _] -> 
        {:ok, String.replace(content, match, new_code, global: false)}
      nil -> 
        {:error, "Function #{function_name} not found in content"}
    end
  end
end