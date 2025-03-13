defmodule Ace.Core.Experiment do
  @moduledoc """
  Represents an experiment for testing an optimization.
  """
  use Ace.Schema
  
  schema "experiments" do
    field :setup_data, :map
    field :results, :map
    field :status, :string, default: "pending"
    field :experiment_path, :string
    
    belongs_to :evaluation, Ace.Core.Evaluation
    
    timestamps()
  end
  
  def changeset(experiment, attrs) do
    experiment
    |> cast(attrs, [:setup_data, :results, :status, :experiment_path, :evaluation_id])
    |> validate_required([:status, :evaluation_id])
    |> validate_inclusion(:status, ["pending", "running", "completed", "failed"])
    |> foreign_key_constraint(:evaluation_id)
  end
end