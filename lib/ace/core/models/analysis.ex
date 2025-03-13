defmodule Ace.Core.Analysis do
  @moduledoc """
  Represents an analysis of a code component.
  """
  use Ace.Schema
  
  schema "analyses" do
    field :file_path, :string
    field :language, :string
    field :content, :string
    field :focus_areas, {:array, :string}, default: ["performance", "maintainability"]
    field :severity_threshold, :string, default: "medium"
    field :completed_at, :utc_datetime_usec
    field :is_multi_file, :boolean, default: false
    
    belongs_to :project, Ace.Core.Project
    has_many :opportunities, Ace.Core.Opportunity
    
    # Self-referential relationships for handling file dependencies
    has_many :source_relationships, Ace.Core.AnalysisRelationship, foreign_key: :source_analysis_id
    has_many :target_relationships, Ace.Core.AnalysisRelationship, foreign_key: :target_analysis_id
    
    # Virtual fields for related analyses
    has_many :related_analyses, through: [:source_relationships, :target_analysis]
    has_many :dependent_analyses, through: [:target_relationships, :source_analysis]
  
    timestamps()
  end
  
  def changeset(analysis, attrs) do
    analysis
    |> cast(attrs, [
      :file_path, 
      :language, 
      :content, 
      :focus_areas, 
      :severity_threshold, 
      :completed_at, 
      :is_multi_file,
      :project_id
    ])
    |> validate_required([:file_path, :language, :content])
    |> validate_inclusion(:severity_threshold, ["low", "medium", "high"])
    |> validate_inclusion(:language, supported_languages())
    |> validate_change(:focus_areas, &validate_focus_areas/2)
    |> foreign_key_constraint(:project_id)
  end
  
  defp supported_languages do
    ["elixir", "javascript", "python", "ruby", "go"]
  end
  
  defp validate_focus_areas(:focus_areas, focus_areas) do
    valid_areas = ["performance", "maintainability", "security", "reliability"]
  
    case Enum.all?(focus_areas, &(&1 in valid_areas)) do
      true -> []
      false -> [focus_areas: "contains unsupported focus areas"]
    end
  end
end