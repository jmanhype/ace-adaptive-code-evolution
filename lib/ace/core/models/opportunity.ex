defmodule Ace.Core.Opportunity do
  @moduledoc """
  Represents an optimization opportunity identified during analysis.
  """
  use Ace.Schema
  
  schema "opportunities" do
    field :location, :string
    field :type, :string
    field :description, :string
    field :severity, :string
    field :rationale, :string
    field :suggested_change, :string
    field :cross_file_references, {:array, :map}, default: []
    field :scope, :string, default: "single_file"
  
    belongs_to :analysis, Ace.Core.Analysis
    has_many :optimizations, Ace.Core.Optimization
  
    timestamps()
  end
  
  def changeset(opportunity, attrs) do
    opportunity
    |> cast(attrs, [
      :location, 
      :type, 
      :description, 
      :severity, 
      :rationale, 
      :suggested_change, 
      :analysis_id,
      :cross_file_references,
      :scope
    ])
    |> validate_required([:location, :type, :description, :severity, :analysis_id])
    |> validate_inclusion(:severity, ["low", "medium", "high"])
    |> validate_inclusion(:type, ["performance", "maintainability", "security", "reliability"])
    |> validate_inclusion(:scope, ["single_file", "cross_file"])
    |> validate_cross_file_references()
    |> foreign_key_constraint(:analysis_id)
  end
  
  defp validate_cross_file_references(changeset) do
    scope = get_field(changeset, :scope)
    cross_file_refs = get_field(changeset, :cross_file_references) || []
    
    cond do
      scope == "cross_file" && Enum.empty?(cross_file_refs) ->
        add_error(changeset, :cross_file_references, "must not be empty for cross-file opportunities")
      scope == "single_file" && !Enum.empty?(cross_file_refs) ->
        add_error(changeset, :cross_file_references, "must be empty for single-file opportunities")
      true ->
        changeset
    end
  end
end