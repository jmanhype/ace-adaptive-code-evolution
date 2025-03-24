defmodule AceWeb.PRController do
  @moduledoc """
  Simple controller for handling pull request creation via API.
  """
  use AceWeb, :controller
  
  alias Ace.GitHub.Service
  alias Ace.GitHub.Models.PullRequest
  require Logger

  @doc """
  Creates a new pull request in the database.
  """
  def create(conn, params) do
    Logger.info("Creating new PR: #{inspect(params)}")
    
    # Format the data for our schema
    pr_data = %{
      pr_id: params["pr_id"],
      number: params["number"],
      title: params["title"],
      html_url: params["html_url"],
      repo_name: params["repo_name"],
      head_sha: params["head_sha"],
      base_sha: params["base_sha"],
      user: params["user"],
      status: "pending"
    }
    
    # Register the PR in our system
    case Service.create_or_update_pull_request(pr_data) do
      {:ok, pr_record} ->
        Logger.info("PR ##{params["number"]} registered successfully with ID: #{pr_record.id}")
        
        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          message: "Pull request registered successfully",
          data: %{
            id: pr_record.id,
            pr_id: pr_record.pr_id,
            number: pr_record.number,
            title: pr_record.title,
            repo_name: pr_record.repo_name,
            user: pr_record.user,
            status: pr_record.status
          }
        })
        
      {:error, changeset} ->
        Logger.error("Failed to register PR: #{inspect(changeset)}")
        
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          message: "Failed to register pull request",
          errors: format_errors(changeset)
        })
    end
  end
  
  @doc """
  Retrieve a specific pull request.
  """
  def show(conn, %{"id" => id}) do
    case Ace.Repo.get(PullRequest, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Pull request not found"})
        
      pr ->
        conn
        |> json(%{
          id: pr.id,
          pr_id: pr.pr_id,
          number: pr.number,
          title: pr.title,
          repo_name: pr.repo_name,
          user: pr.user,
          status: pr.status
        })
    end
  end
  
  @doc """
  List all pull requests.
  """
  def index(conn, _params) do
    pull_requests = Ace.Repo.all(PullRequest)
    
    conn
    |> json(%{
      data: Enum.map(pull_requests, fn pr -> 
        %{
          id: pr.id,
          pr_id: pr.pr_id,
          number: pr.number,
          title: pr.title,
          repo_name: pr.repo_name,
          user: pr.user,
          status: pr.status
        }
      end)
    })
  end
  
  # Helper to format changeset errors for API responses
  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end 