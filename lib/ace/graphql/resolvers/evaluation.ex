defmodule Ace.GraphQL.Resolvers.Evaluation do
  @moduledoc """
  Resolvers for Evaluation-related GraphQL operations.
  """
  alias Ace.Core.{Evaluation, Experiment}
  alias Ace.Evaluation.Service, as: EvaluationService
  import Ecto.Query
  
  @doc """
  Get an evaluation by ID.
  """
  def get_evaluation(_, %{id: id}, _) do
    case Ace.Repo.get(Evaluation, id) do
      nil -> {:error, "Evaluation not found"}
      evaluation -> {:ok, evaluation}
    end
  end
  
  @doc """
  List evaluations with optional filters.
  """
  def list_evaluations(_, args, _) do
    filters = Map.get(args, :filter, %{})
    limit = Map.get(args, :limit, 10)
    offset = Map.get(args, :offset, 0)
    
    query = Evaluation
    |> apply_evaluation_filters(filters)
    |> limit(^limit)
    |> offset(^offset)
    |> order_by([e], desc: e.inserted_at)
    
    evaluations = Ace.Repo.all(query)
    {:ok, evaluations}
  end
  
  @doc """
  Get an experiment by ID.
  """
  def get_experiment(_, %{id: id}, _) do
    case Ace.Repo.get(Experiment, id) do
      nil -> {:error, "Experiment not found"}
      experiment -> {:ok, experiment}
    end
  end
  
  @doc """
  Evaluate an optimization.
  """
  def evaluate(_, %{input: input}, _) do
    optimization_id = input.optimization_id
    options = Map.get(input, :options, %{})
    
    # Call the evaluation service
    case EvaluationService.evaluate(optimization_id, options) do
      {:ok, evaluation} -> {:ok, evaluation}
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Run the complete pipeline.
  """
  def run_pipeline(_, %{input: input}, _) do
    file_path = input.file_path
    options = %{
      focus_areas: Map.get(input, :focus_areas),
      severity_threshold: Map.get(input, :severity_threshold),
      strategy: Map.get(input, :strategy),
      auto_apply: Map.get(input, :auto_apply, false)
    }
    |> Enum.filter(fn {_, v} -> not is_nil(v) end)
    |> Enum.into(%{})
    
    # Call the main pipeline function
    case Ace.run_pipeline(file_path, options) do
      {:ok, results} -> {:ok, results}
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Apply filters to an Evaluation query
  defp apply_evaluation_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:optimization_id, id}, query ->
        from q in query, where: q.optimization_id == ^id
      
      {:success, success}, query ->
        from q in query, where: q.success == ^success
      
      {:created_after, date}, query ->
        from q in query, where: q.inserted_at >= ^date
      
      {:created_before, date}, query ->
        from q in query, where: q.inserted_at <= ^date
      
      _, query ->
        query
    end)
  end
end