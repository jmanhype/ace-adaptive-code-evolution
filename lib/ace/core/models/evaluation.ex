defmodule Ace.Core.Evaluation do
  @moduledoc """
  Represents an evaluation of an optimization.
  """
  use Ace.Schema
  
  schema "evaluations" do
    field :metrics, :map
    field :success, :boolean
    field :report, :string
  
    belongs_to :optimization, Ace.Core.Optimization
    has_one :experiment, Ace.Core.Experiment
  
    timestamps()
  end
  
  def changeset(evaluation, attrs) do
    evaluation
    |> cast(attrs, [:metrics, :success, :report, :optimization_id])
    |> validate_required([:metrics, :success, :optimization_id])
    |> foreign_key_constraint(:optimization_id)
  end
end