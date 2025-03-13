defmodule Ace.Core.AnalysisRelationship do
  @moduledoc """
  Represents relationships between analyzed files, such as imports, extends, etc.
  """
  use Ace.Schema
  
  @relationship_types [
    "imports",       # File imports/requires functionality from another file
    "extends",       # File extends/inherits from another file
    "implements",    # File implements an interface defined in another file
    "uses",          # File uses classes/functions from another file
    "references",    # File references constants or types from another file
    "depends_on"     # Generic dependency relationship
  ]
  
  schema "analysis_relationships" do
    field :relationship_type, :string
    field :details, :map, default: %{}
    
    belongs_to :source_analysis, Ace.Core.Analysis
    belongs_to :target_analysis, Ace.Core.Analysis
    
    timestamps()
  end
  
  def changeset(relationship, attrs) do
    relationship
    |> cast(attrs, [:source_analysis_id, :target_analysis_id, :relationship_type, :details])
    |> validate_required([:source_analysis_id, :target_analysis_id, :relationship_type])
    |> validate_inclusion(:relationship_type, @relationship_types)
    |> foreign_key_constraint(:source_analysis_id)
    |> foreign_key_constraint(:target_analysis_id)
    |> unique_constraint([:source_analysis_id, :target_analysis_id, :relationship_type], 
                         name: :analysis_relationship_unique_index)
    |> validate_different_analyses()
  end
  
  defp validate_different_analyses(changeset) do
    source_id = get_field(changeset, :source_analysis_id)
    target_id = get_field(changeset, :target_analysis_id)
    
    if source_id && target_id && source_id == target_id do
      add_error(changeset, :target_analysis_id, "must be different from source_analysis_id")
    else
      changeset
    end
  end
  
  @doc """
  Returns a list of all supported relationship types
  """
  def relationship_types, do: @relationship_types
end