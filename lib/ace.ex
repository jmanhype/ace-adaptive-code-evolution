defmodule Ace do
  @moduledoc """
  Adaptive Code Evolution (ACE) System

  A standalone system for AI-powered code analysis, optimization, and evolution.
  ACE uses large language models to identify optimization opportunities in code,
  generate optimized implementations, and evaluate their effectiveness through
  automated experiments.
  """

  alias Ace.Analysis
  alias Ace.Optimization
  alias Ace.Evaluation
  
  @doc """
  Analyzes code to identify optimization opportunities.
  
  ## Parameters
  
    - `file_path`: Path to the file to analyze
    - `options`: Analysis options
      - `:language`: Programming language (auto-detected if not specified)
      - `:focus_areas`: Areas to focus on (defaults to ["performance", "maintainability"])
      - `:severity_threshold`: Minimum severity to report (defaults to "medium")
  
  ## Returns
  
    - `{:ok, analysis}`: The completed analysis with opportunities
    - `{:error, reason}`: If analysis fails
  """
  def analyze_file(file_path, options \\ []) do
    Analysis.Service.analyze_file(file_path, options)
  end
  
  @doc """
  Analyzes code content directly.
  
  ## Parameters
  
    - `content`: Source code to analyze
    - `language`: Programming language of the code
    - `options`: Analysis options
      - `:focus_areas`: Areas to focus on (defaults to ["performance", "maintainability"])
      - `:severity_threshold`: Minimum severity to report (defaults to "medium")
  
  ## Returns
  
    - `{:ok, analysis}`: The completed analysis with opportunities
    - `{:error, reason}`: If analysis fails
  """
  def analyze_code(content, language, options \\ []) do
    Analysis.Service.analyze_code(content, language, options)
  end
  
  @doc """
  Lists optimization opportunities identified in analyses.
  
  ## Parameters
  
    - `options`: Filter options
      - `:analysis_id`: Filter by analysis ID
      - `:severity`: Filter by severity
      - `:type`: Filter by type
  
  ## Returns
  
    - `{:ok, opportunities}`: List of optimization opportunities
    - `{:error, reason}`: If retrieving opportunities fails
  """
  def list_opportunities(options \\ []) do
    Analysis.Service.list_opportunities(options)
  end
  
  @doc """
  Generates an optimized implementation for an opportunity.
  
  ## Parameters
  
    - `opportunity_id`: ID of the opportunity to optimize
    - `strategy`: Optimization strategy (defaults to "auto")
    - `options`: Additional options
  
  ## Returns
  
    - `{:ok, optimization}`: The generated optimization
    - `{:error, reason}`: If optimization generation fails
  """
  def optimize(opportunity_id, strategy \\ "auto", options \\ []) do
    # Check if we should skip database operations
    skip_db = Keyword.get(options, :skip_db, false)
    
    if skip_db do
      # Return mock optimization for CLI usage
      mock_optimize(opportunity_id, strategy)
    else
      # Use the regular service
      Optimization.Service.optimize(opportunity_id, strategy, options)
    end
  end
  
  # Generate a mock optimization response for CLI without DB access
  defp mock_optimize(opportunity_id, strategy) do
    # Create a mock optimization
    {:ok, %{
      id: "mock-opt-#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
      opportunity_id: opportunity_id,
      strategy: strategy,
      original_code: "# Original code would be fetched from the database",
      optimized_code: "# This is a mock optimized implementation\ndef optimized_function() do\n  # Optimized based on #{strategy} strategy\n  :improved\nend",
      explanation: "This optimization uses #{strategy} strategy to improve code quality and performance.",
      status: "pending"
    }}
  end
  
  @doc """
  Evaluates an optimization to determine its effectiveness.
  
  ## Parameters
  
    - `optimization_id`: ID of the optimization to evaluate
    - `options`: Evaluation options
  
  ## Returns
  
    - `{:ok, evaluation}`: The evaluation results
    - `{:error, reason}`: If evaluation fails
  """
  def evaluate_optimization(optimization_id, options \\ []) do
    # Check if we should skip database operations
    skip_db = Keyword.get(options, :skip_db, false)
    
    if skip_db do
      # Return mock evaluation for CLI usage
      mock_evaluate(optimization_id)
    else
      # Use the regular service
      Evaluation.Service.evaluate(optimization_id, options)
    end
  end
  
  # Generate a mock evaluation response for CLI without DB access
  defp mock_evaluate(optimization_id) do
    # Create a mock evaluation
    {:ok, %{
      id: "mock-eval-#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
      optimization_id: optimization_id,
      success: true,
      metrics: %{
        execution_time_original: 0.324,
        execution_time_optimized: 0.187,
        improvement_percentage: 42.3
      },
      report: "Mock evaluation report: The optimized implementation is 42.3% faster than the original."
    }}
  end
  
  @doc """
  Applies an optimization to the actual codebase.
  
  ## Parameters
  
    - `optimization_id`: ID of the optimization to apply
    - `options`: Application options
      - `:backup`: Whether to create a backup of the original file (defaults to true)
  
  ## Returns
  
    - `{:ok, applied_optimization}`: The applied optimization
    - `{:error, reason}`: If application fails
  """
  def apply_optimization(optimization_id, options \\ []) do
    # Check if we should skip database operations
    skip_db = Keyword.get(options, :skip_db, false)
    
    if skip_db do
      # Return mock applied optimization for CLI usage
      mock_apply(optimization_id)
    else
      # Use the regular service
      Optimization.Service.apply_optimization(optimization_id, options)
    end
  end
  
  # Generate a mock applied optimization response for CLI without DB access
  defp mock_apply(optimization_id) do
    # Create a mock applied optimization result
    {:ok, %{
      id: "mock-applied-#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
      optimization_id: optimization_id,
      file_path: "mock_file.ex",
      applied_at: DateTime.utc_now(),
      backup_path: "mock_file.ex.bak"
    }}
  end
  
  @doc """
  Creates a definition for a custom analyzer.
  
  ## Parameters
  
    - `name`: Name of the analyzer
    - `options`: Analyzer options
    - `definition`: Function that defines the analyzer behavior
  
  ## Examples
  
      iex> Ace.define_analyzer :performance_analyzer,
      ...>   focus_areas: ["performance"],
      ...>   severity_threshold: "medium",
      ...>   fn code, language ->
      ...>     # Custom analysis logic
      ...>   end
  """
  defmacro define_analyzer(name, options \\ [], definition) do
    quote do
      Analysis.Service.register_analyzer(unquote(name), unquote(options), unquote(definition))
    end
  end
  
  @doc """
  Creates a definition for a custom optimization strategy.
  
  ## Parameters
  
    - `name`: Name of the strategy
    - `options`: Strategy options
    - `definition`: Function that defines the strategy behavior
  
  ## Examples
  
      iex> Ace.define_strategy :memory_optimization,
      ...>   priority: ["memory_usage", "speed"],
      ...>   fn opportunity, original_code ->
      ...>     # Custom optimization logic
      ...>   end
  """
  defmacro define_strategy(name, options \\ [], definition) do
    quote do
      Optimization.Service.register_strategy(unquote(name), unquote(options), unquote(definition))
    end
  end
  
  @doc """
  Runs the complete ACE pipeline: analyze, optimize, evaluate, and apply.
  
  ## Parameters
  
    - `file_path`: Path to the file to process
    - `options`: Pipeline options
      - `:auto_apply`: Whether to automatically apply successful optimizations (defaults to false)
      - `:focus_areas`: Areas to focus on for analysis
      - `:strategy`: Optimization strategy to use
      - `:severity_threshold`: Minimum severity to process
  
  ## Returns
  
    - `{:ok, results}`: Results of the pipeline
    - `{:error, reason}`: If the pipeline fails at any stage
  """
  def run_pipeline(file_path, options \\ []) do
    auto_apply = Keyword.get(options, :auto_apply, false)
    # Add skip_db option to default options (true for CLI operations)
    skip_db = Keyword.get(options, :skip_db, true)
    
    # Add skip_db to options if not already present
    options = Keyword.put_new(options, :skip_db, skip_db)
    
    # Get opportunities based on whether we're using DB or not
    opportunities_result = fn analysis ->
      if skip_db do
        {:ok, Map.get(analysis, :opportunities, [])}
      else
        list_opportunities(analysis_id: analysis.id)
      end
    end

    with {:ok, analysis} <- analyze_file(file_path, options),
         {:ok, opportunities} <- opportunities_result.(analysis),
         {:ok, optimizations} <- optimize_all(opportunities, options),
         {:ok, evaluations} <- evaluate_all(optimizations, options),
         {:ok, applied} <- maybe_apply(evaluations, auto_apply, options) do
      
      {:ok, %{
        analysis: analysis,
        opportunities: opportunities,
        optimizations: optimizations,
        evaluations: evaluations,
        applied: applied
      }}
    end
  end
  
  # Helper functions for the pipeline
  
  defp optimize_all(opportunities, options) do
    strategy = Keyword.get(options, :strategy, "auto")
    
    results = Enum.map(opportunities, fn opportunity ->
      # Pass along skip_db option
      opt_id = if is_map(opportunity), do: Map.get(opportunity, :id), else: opportunity
      case optimize(opt_id, strategy, options) do
        {:ok, optimization} -> {:ok, opt_id, optimization}
        {:error, reason} -> {:error, opt_id, reason}
      end
    end)
    
    # Replace deprecated filter_map with filter + map combination
    optimizations = results
      |> Enum.filter(fn result -> match?({:ok, _, _}, result) end)
      |> Enum.map(fn {:ok, _, optimization} -> optimization end)
    
    {:ok, optimizations}
  end
  
  defp evaluate_all(optimizations, options) do
    results = Enum.map(optimizations, fn optimization ->
      # Pass along skip_db option
      opt_id = if is_map(optimization), do: Map.get(optimization, :id), else: optimization
      case evaluate_optimization(opt_id, options) do
        {:ok, evaluation} -> {:ok, opt_id, evaluation}
        {:error, reason} -> {:error, opt_id, reason}
      end
    end)
    
    # Replace deprecated filter_map with filter + map combination
    evaluations = results
      |> Enum.filter(fn result -> match?({:ok, _, _}, result) end)
      |> Enum.map(fn {:ok, _, evaluation} -> evaluation end)
    
    {:ok, evaluations}
  end
  
  defp maybe_apply(_evaluations, false, _options), do: {:ok, []}
  defp maybe_apply(evaluations, true, options) do
    # Only apply successful evaluations
    successful_evaluations = Enum.filter(evaluations, fn eval -> 
      is_map(eval) && Map.get(eval, :success, false)
    end)
    
    results = Enum.map(successful_evaluations, fn evaluation ->
      # Pass along skip_db option
      eval_opt_id = if is_map(evaluation), do: Map.get(evaluation, :optimization_id), else: nil
      case apply_optimization(eval_opt_id, options) do
        {:ok, applied} -> {:ok, eval_opt_id, applied}
        {:error, reason} -> {:error, eval_opt_id, reason}
      end
    end)
    
    # Replace deprecated filter_map with filter + map combination
    applied = results
      |> Enum.filter(fn result -> match?({:ok, _, _}, result) end)
      |> Enum.map(fn {:ok, _, applied} -> applied end)
    
    {:ok, applied}
  end
end
