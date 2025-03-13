defmodule Ace.GraphQL.Types.Optimization do
  @moduledoc """
  GraphQL types for Optimization domain entities.
  """
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  
  @desc "An optimization generated for an identified opportunity"
  object :optimization do
    field :id, non_null(:id), description: "Unique identifier"
    field :strategy, non_null(:string), description: "Strategy used for optimization"
    field :original_code, non_null(:string), description: "Original code before optimization"
    field :optimized_code, non_null(:string), description: "Optimized code after changes"
    field :explanation, :string, description: "Explanation of the optimization"
    field :status, non_null(:string), description: "Status of the optimization (pending, applied, rejected)"
    field :inserted_at, non_null(:datetime), description: "When the optimization was created"
    field :updated_at, non_null(:datetime), description: "When the optimization was last updated"
    
    field :opportunity, :opportunity, description: "The opportunity this optimization addresses" do
      resolve fn optimization, _, _ ->
        opportunity = Ace.Repo.preload(optimization, :opportunity).opportunity
        {:ok, opportunity}
      end
    end
    
    field :evaluation, :evaluation, description: "Evaluation of this optimization" do
      resolve fn optimization, _, _ ->
        evaluation = Ace.Repo.preload(optimization, :evaluation).evaluation
        {:ok, evaluation}
      end
    end
  end
  
  @desc "Input for filtering optimizations"
  input_object :optimization_filter_input do
    field :opportunity_id, :id, description: "Filter by opportunity ID"
    field :strategy, :string, description: "Filter by strategy used"
    field :status, :string, description: "Filter by status (pending, applied, rejected)"
    field :created_after, :datetime, description: "Filter by creation date (after)"
    field :created_before, :datetime, description: "Filter by creation date (before)"
  end
  
  @desc "Input for creating an optimization"
  input_object :optimize_input do
    field :opportunity_id, non_null(:id), description: "ID of the opportunity to optimize"
    field :strategy, :string, description: "Strategy to use for optimization"
    field :custom_options, :json, description: "Custom options for the optimization strategy"
  end
  
  @desc "Input for applying an optimization"
  input_object :apply_optimization_input do
    field :optimization_id, non_null(:id), description: "ID of the optimization to apply"
    field :backup, :boolean, description: "Whether to create a backup of the original file", default_value: true
  end
end