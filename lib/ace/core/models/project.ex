defmodule Ace.Core.Project do
  @moduledoc """
  Represents a project containing multiple related files for analysis.
  """
  use Ace.Schema
  
  schema "projects" do
    field :name, :string
    field :base_path, :string
    field :description, :string
    field :settings, :map, default: %{}
    
    has_many :analyses, Ace.Core.Analysis
    
    timestamps()
  end
  
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :base_path, :description, :settings])
    |> validate_required([:name, :base_path])
    |> validate_base_path()
  end
  
  defp validate_base_path(changeset) do
    case get_field(changeset, :base_path) do
      nil -> changeset
      base_path ->
        if File.dir?(base_path) do
          changeset
        else
          add_error(changeset, :base_path, "must be a valid directory")
        end
    end
  end
  
  @doc """
  Gets relative path from project base path
  """
  def relative_path(project, full_path) do
    case Path.relative_to(full_path, project.base_path) do
      ^full_path -> full_path  # Path wasn't actually relative to base_path
      rel_path -> rel_path
    end
  end
  
  @doc """
  Gets absolute path from relative path within project
  """
  def absolute_path(project, relative_path) do
    Path.join(project.base_path, relative_path)
  end
end