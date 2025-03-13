defmodule Ace.GraphQL.Resolvers.Optimization do
  @moduledoc """
  Resolvers for Optimization-related GraphQL operations.
  """
  alias Ace.Core.Optimization
  alias Ace.Optimization.Service, as: OptimizationService
  import Ecto.Query
  
  @doc """
  Get an optimization by ID.
  """
  def get_optimization(_, %{id: id}, _) do
    case Ace.Repo.get(Optimization, id) do
      nil -> {:error, "Optimization not found"}
      optimization -> {:ok, optimization}
    end
  end
  
  @doc """
  List optimizations with optional filters.
  """
  def list_optimizations(_, args, _) do
    filters = Map.get(args, :filter, %{})
    limit = Map.get(args, :limit, 10)
    offset = Map.get(args, :offset, 0)
    
    query = Optimization
    |> apply_optimization_filters(filters)
    |> limit(^limit)
    |> offset(^offset)
    |> order_by([o], desc: o.inserted_at)
    
    optimizations = Ace.Repo.all(query)
    {:ok, optimizations}
  end
  
  @doc """
  Generate an optimization for an opportunity.
  """
  def optimize(_, %{input: input}, _) do
    opportunity_id = input.opportunity_id
    strategy = Map.get(input, :strategy, "auto")
    options = Map.get(input, :custom_options, %{})
    
    # Call the optimization service
    case OptimizationService.optimize(opportunity_id, strategy, options) do
      {:ok, optimization} -> {:ok, optimization}
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Apply an optimization to the codebase.
  """
  def apply_optimization(_, %{input: input}, _) do
    optimization_id = input.optimization_id
    backup = Map.get(input, :backup, true)
    
    # Call the optimization service
    case OptimizationService.apply_optimization(optimization_id, backup: backup) do
      {:ok, optimization} -> {:ok, optimization}
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Apply filters to an Optimization query
  defp apply_optimization_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:opportunity_id, id}, query ->
        from q in query, where: q.opportunity_id == ^id
      
      {:strategy, strategy}, query ->
        from q in query, where: q.strategy == ^strategy
      
      {:status, status}, query ->
        from q in query, where: q.status == ^status
      
      {:created_after, date}, query ->
        from q in query, where: q.inserted_at >= ^date
      
      {:created_before, date}, query ->
        from q in query, where: q.inserted_at <= ^date
      
      _, query ->
        query
    end)
  end
end