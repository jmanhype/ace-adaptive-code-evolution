defmodule Ace.Core.Optimization do
  @moduledoc """
  Represents an optimization generated from an opportunity.
  """
  use Ace.Schema
  
  schema "optimizations" do
    field :strategy, :string
    field :original_code, :string
    field :optimized_code, :string
    field :explanation, :string
    field :status, :string, default: "pending"
  
    belongs_to :opportunity, Ace.Core.Opportunity
    has_one :evaluation, Ace.Core.Evaluation
  
    timestamps()
  end
  
  def changeset(optimization, attrs) do
    optimization
    |> cast(attrs, [:strategy, :original_code, :optimized_code, :explanation, :status, :opportunity_id])
    |> validate_required([:strategy, :original_code, :optimized_code, :opportunity_id])
    |> validate_inclusion(:status, ["pending", "applied", "rejected"])
    |> foreign_key_constraint(:opportunity_id)
  end
end