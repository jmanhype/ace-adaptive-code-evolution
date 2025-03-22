defmodule AceWeb.AnalysesController do
  @moduledoc """
  Controller for REST API endpoints to manage code analyses.
  """
  use AceWeb, :controller

  alias Ace.Analysis.Service

  @doc """
  Creates a new analysis for the given file.
  """
  def create(conn, %{"file_path" => file_path} = params) do
    # Extract optional parameters with defaults
    language = Map.get(params, "language", "elixir")
    focus_areas = Map.get(params, "focus_areas", ["performance", "maintainability"])
    severity_threshold = Map.get(params, "severity_threshold", "medium")
    
    # Start the analysis using the Analysis Service
    case Service.analyze_file(file_path, [
      language: language,
      focus_areas: focus_areas,
      severity_threshold: severity_threshold
    ]) do
      {:ok, analysis} ->
        # Broadcast to PubSub for LiveView to pick up
        Phoenix.PubSub.broadcast(Ace.PubSub, "ace:analyses", {:analysis_created, analysis})
        
        # Return the analysis ID
        conn
        |> put_status(:created)
        |> json(%{id: analysis.id, file_path: analysis.file_path, status: "completed"})
        
      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end

  @doc """
  Gets a specific analysis by ID.
  """
  def show(conn, %{"id" => id}) do
    case Ace.Repo.get(Ace.Core.Analysis, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Analysis not found"})
        
      analysis ->
        conn
        |> json(%{
          id: analysis.id,
          file_path: analysis.file_path,
          language: analysis.language,
          completed_at: analysis.completed_at,
          project_id: analysis.project_id
        })
    end
  end

  @doc """
  Lists all analyses.
  """
  def index(conn, _params) do
    analyses = Ace.Repo.all(Ace.Core.Analysis)
    
    # Transform to simple map format
    analyses_data = Enum.map(analyses, fn analysis ->
      %{
        id: analysis.id,
        file_path: analysis.file_path,
        language: analysis.language,
        completed_at: analysis.completed_at,
        project_id: analysis.project_id
      }
    end)
    
    conn
    |> json(%{analyses: analyses_data})
  end
end 