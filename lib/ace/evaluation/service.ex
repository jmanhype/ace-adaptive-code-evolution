defmodule Ace.Evaluation.Service do
  @moduledoc """
  Service for evaluating optimization effectiveness.
  """
  import Ace.Telemetry.FunctionTracer
  alias Ace.Core.{Optimization, Evaluation, Experiment}
  alias Ace.Infrastructure.AI.Orchestrator

  @doc """
  Evaluates an optimization to determine its effectiveness.
  
  ## Parameters
  
    - `params`: Map of parameters including:
      - `:optimization_id` - ID of the optimization to evaluate
  
  ## Returns
  
    - `{:ok, evaluation}`: The created Evaluation record
    - `{:error, reason}`: If evaluation fails
  """
  deftrace evaluate(params) when is_map(params) do
    with {:ok, optimization} <- get_optimization(params.optimization_id),
         {:ok, experiment} <- create_experiment(optimization),
         {:ok, results} <- run_experiment(experiment),
         {:ok, evaluation} <- create_evaluation(optimization, results),
         {:ok, _} <- update_experiment_with_evaluation(experiment, evaluation) do
      {:ok, evaluation}
    end
  end
  
  deftrace evaluate(optimization_id) when is_binary(optimization_id) do
    evaluate(%{optimization_id: optimization_id})
  end
  
  deftrace evaluate(optimization_id, options) do
    # Convert to the format expected by the original evaluate/1 function
    params = %{optimization_id: optimization_id}
    
    # Pass any additional options if needed
    evaluate(params)
  end

  @doc """
  Gets an evaluation by ID.
  """
  deftrace get_evaluation(id) do
    case Ace.Repo.get(Evaluation, id) do
      nil -> {:error, :not_found}
      evaluation -> {:ok, evaluation}
    end
  end

  # Private helper functions

  defp get_optimization(id) do
    case Ace.Repo.get(Optimization, id) do
      nil -> {:error, :not_found}
      optimization -> 
        # Preload opportunity and its analysis for language detection
        optimization = Ace.Repo.preload(optimization, opportunity: :analysis)
        {:ok, optimization}
    end
  end

  defp create_experiment(optimization) do
    language = optimization.opportunity.analysis.language
    
    # Create experiment record
    %Experiment{}
    |> Experiment.changeset(%{
      setup_data: %{},  # Will be populated by factory
      status: "pending"
    })
    |> Ace.Repo.insert()
    |> case do
      {:ok, experiment} ->
        # Create actual experiment files
        case Ace.Evaluation.ExperimentFactory.create(
          language, 
          optimization.original_code, 
          optimization.optimized_code
        ) do
          {:ok, setup_data} -> 
            # Update experiment with setup data
            experiment
            |> Experiment.changeset(%{
              setup_data: setup_data,
              experiment_path: setup_data.dir,
              status: "created"
            })
            |> Ace.Repo.update()
            
          error -> error
        end
        
      error -> error
    end
  end

  defp run_experiment(experiment) do
    # Update experiment status
    experiment
    |> Experiment.changeset(%{status: "running"})
    |> Ace.Repo.update()
    
    # Run the experiment and collect metrics
    case Ace.Evaluation.ExperimentRunner.run(experiment) do
      {:ok, results} ->
        # Update experiment with results
        experiment
        |> Experiment.changeset(%{
          results: results,
          status: "completed"
        })
        |> Ace.Repo.update()
        |> case do
          {:ok, _updated_experiment} -> {:ok, results}
          error -> error
        end
        
      {:error, reason} = error ->
        # Update experiment with error status
        experiment
        |> Experiment.changeset(%{
          results: %{error: reason},
          status: "failed"
        })
        |> Ace.Repo.update()
        
        error
    end
  end

  defp create_evaluation(optimization, results) do
    # Get AI-driven evaluation
    case Orchestrator.evaluate_optimization(
      optimization.original_code,
      optimization.optimized_code,
      results.metrics
    ) do
      {:ok, ai_evaluation} ->
        # Create evaluation record with AI and experimental results
        %Evaluation{}
        |> Evaluation.changeset(%{
          optimization_id: optimization.id,
          metrics: results.metrics,
          success: ai_evaluation.success,
          report: ai_evaluation.analysis
        })
        |> Ace.Repo.insert()
        
      error -> error
    end
  end

  defp update_experiment_with_evaluation(experiment, evaluation) do
    experiment
    |> Experiment.changeset(%{evaluation_id: evaluation.id})
    |> Ace.Repo.update()
  end
end