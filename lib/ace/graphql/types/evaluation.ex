defmodule Ace.GraphQL.Types.Evaluation do
  @moduledoc """
  GraphQL types for Evaluation domain entities.
  """
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  
  @desc "An evaluation of an optimization's effectiveness"
  object :evaluation do
    field :id, non_null(:id), description: "Unique identifier"
    field :metrics, :json, description: "Metrics collected during evaluation"
    field :success, non_null(:boolean), description: "Whether the optimization is successful"
    field :report, :string, description: "Detailed evaluation report"
    field :inserted_at, non_null(:datetime), description: "When the evaluation was created"
    field :updated_at, non_null(:datetime), description: "When the evaluation was last updated"
    
    field :optimization, :optimization, description: "The optimization being evaluated" do
      resolve fn evaluation, _, _ ->
        optimization = Ace.Repo.preload(evaluation, :optimization).optimization
        {:ok, optimization}
      end
    end
    
    field :experiment, :experiment, description: "The experiment setup for this evaluation" do
      resolve fn evaluation, _, _ ->
        experiment = Ace.Repo.preload(evaluation, :experiment).experiment
        {:ok, experiment}
      end
    end
    
    field :performance_improvement, :float, description: "Overall performance improvement percentage" do
      resolve fn evaluation, _, _ ->
        metrics = evaluation.metrics || %{}
        
        case metrics do
          %{"performance" => %{"overall_improvement" => improvement}} when is_number(improvement) ->
            {:ok, improvement}
          
          %{"overall_improvement" => improvement} when is_number(improvement) ->
            {:ok, improvement}
          
          _ ->
            {:ok, nil}
        end
      end
    end
    
    field :correctness, :boolean, description: "Whether the optimization maintains correctness" do
      resolve fn evaluation, _, _ ->
        metrics = evaluation.metrics || %{}
        
        case metrics do
          %{"correctness" => %{"passed" => passed}} when is_boolean(passed) ->
            {:ok, passed}
          
          _ ->
            {:ok, true}
        end
      end
    end
  end
  
  @desc "An experiment setup for evaluating an optimization"
  object :experiment do
    field :id, non_null(:id), description: "Unique identifier"
    field :setup_data, :json, description: "Setup data for the experiment"
    field :results, :json, description: "Raw results from the experiment"
    field :inserted_at, non_null(:datetime), description: "When the experiment was created"
    field :updated_at, non_null(:datetime), description: "When the experiment was last updated"
    
    field :evaluation, :evaluation, description: "The evaluation this experiment is for" do
      resolve fn experiment, _, _ ->
        evaluation = Ace.Repo.preload(experiment, :evaluation).evaluation
        {:ok, evaluation}
      end
    end
  end
  
  @desc "The result of running the complete pipeline"
  object :pipeline_result do
    field :analysis, :analysis, description: "The analysis that was performed"
    field :opportunities, list_of(:opportunity), description: "Opportunities identified during analysis"
    field :optimizations, list_of(:optimization), description: "Optimizations generated for opportunities"
    field :evaluations, list_of(:evaluation), description: "Evaluations of the optimizations"
    field :applied, list_of(:optimization), description: "Optimizations that were applied"
    
    field :success_rate, :float, description: "Percentage of successful optimizations" do
      resolve fn pipeline_result, _, _ ->
        evaluations = pipeline_result.evaluations || []
        
        case length(evaluations) do
          0 -> {:ok, 0.0}
          total ->
            success_count = Enum.count(evaluations, & &1.success)
            {:ok, success_count / total * 100.0}
        end
      end
    end
  end
  
  @desc "Input for evaluating an optimization"
  input_object :evaluate_input do
    field :optimization_id, non_null(:id), description: "ID of the optimization to evaluate"
    field :options, :json, description: "Options for the evaluation"
  end
  
  @desc "Input for running the complete pipeline"
  input_object :run_pipeline_input do
    field :file_path, non_null(:string), description: "Path to the file to process"
    field :focus_areas, list_of(:string), description: "Areas to focus on during analysis"
    field :severity_threshold, :string, description: "Minimum severity threshold for opportunities"
    field :strategy, :string, description: "Strategy to use for optimization"
    field :auto_apply, :boolean, description: "Whether to automatically apply successful optimizations"
  end
end