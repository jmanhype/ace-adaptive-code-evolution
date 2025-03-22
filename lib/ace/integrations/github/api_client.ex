defmodule Ace.Integrations.GitHub.APIClient do
  @moduledoc """
  GitHub API client for Ace integration.
  
  This module provides functions to interact with GitHub's API,
  handling authentication, rate limiting, and common operations
  related to repositories and pull requests.
  """
  
  require Logger
  alias Ace.Integrations.GitHub.App
  
  @github_api_url "https://api.github.com"
  @user_agent "Ace-GitHub-Integration/0.1.0"
  
  @doc """
  Get a pull request's details from GitHub.
  
  ## Parameters
  
    * `installation_id` - GitHub App installation ID
    * `repo_full_name` - Repository name with owner (e.g., "owner/repo")
    * `pr_number` - Pull request number
  
  ## Returns
  
    * `{:ok, pr_data}` - Pull request data as a map
    * `{:error, reason}` - If retrieval fails
  """
  @spec get_pull_request(integer(), String.t(), integer()) :: {:ok, map()} | {:error, atom() | String.t()}
  def get_pull_request(installation_id, repo_full_name, pr_number) do
    with {:ok, token, _} <- App.get_installation_token(installation_id),
         url = "#{@github_api_url}/repos/#{repo_full_name}/pulls/#{pr_number}",
         {:ok, response} <- make_authenticated_request(:get, url, "", token) do
      
      case response.status_code do
        200 -> Jason.decode(response.body)
        code ->
          Logger.error("Failed to get PR: HTTP #{code} - #{response.body}")
          {:error, :github_api_error}
      end
    end
  end
  
  @doc """
  Get files changed in a pull request.
  
  ## Parameters
  
    * `installation_id` - GitHub App installation ID
    * `repo_full_name` - Repository name with owner
    * `pr_number` - Pull request number
  
  ## Returns
  
    * `{:ok, files}` - List of file changes
    * `{:error, reason}` - If retrieval fails
  """
  @spec get_pull_request_files(integer(), String.t(), integer()) :: {:ok, list(map())} | {:error, atom() | String.t()}
  def get_pull_request_files(installation_id, repo_full_name, pr_number) do
    with {:ok, token, _} <- App.get_installation_token(installation_id),
         url = "#{@github_api_url}/repos/#{repo_full_name}/pulls/#{pr_number}/files",
         {:ok, response} <- make_authenticated_request(:get, url, "", token) do
      
      case response.status_code do
        200 -> Jason.decode(response.body)
        code ->
          Logger.error("Failed to get PR files: HTTP #{code} - #{response.body}")
          {:error, :github_api_error}
      end
    end
  end
  
  @doc """
  Get file content from a repository.
  
  ## Parameters
  
    * `installation_id` - GitHub App installation ID
    * `repo_full_name` - Repository name with owner
    * `path` - File path in the repository
    * `ref` - Git reference (branch, commit, tag)
  
  ## Returns
  
    * `{:ok, content, sha}` - File content and SHA
    * `{:error, reason}` - If retrieval fails
  """
  @spec get_file_content(integer(), String.t(), String.t(), String.t()) :: 
        {:ok, String.t(), String.t()} | {:error, atom() | String.t()}
  def get_file_content(installation_id, repo_full_name, path, ref) do
    with {:ok, token, _} <- App.get_installation_token(installation_id),
         url = "#{@github_api_url}/repos/#{repo_full_name}/contents/#{path}?ref=#{ref}",
         {:ok, response} <- make_authenticated_request(:get, url, "", token) do
      
      case response.status_code do
        200 -> 
          with {:ok, body} <- Jason.decode(response.body),
               %{"content" => encoded_content, "sha" => sha} <- body,
               {:ok, content} <- Base.decode64(encoded_content, padding: false) do
            {:ok, content, sha}
          else
            _ -> {:error, :invalid_content_format}
          end
          
        code ->
          Logger.error("Failed to get file content: HTTP #{code} - #{response.body}")
          {:error, :github_api_error}
      end
    end
  end
  
  @doc """
  Create a comment on a pull request.
  
  ## Parameters
  
    * `installation_id` - GitHub App installation ID
    * `repo_full_name` - Repository name with owner
    * `pr_number` - Pull request number
    * `body` - Comment text (markdown supported)
  
  ## Returns
  
    * `{:ok, comment_id}` - Comment created successfully
    * `{:error, reason}` - If creation fails
  """
  @spec create_pr_comment(integer(), String.t(), integer(), String.t()) :: 
        {:ok, String.t()} | {:error, atom() | String.t()}
  def create_pr_comment(installation_id, repo_full_name, pr_number, body) do
    with {:ok, token, _} <- App.get_installation_token(installation_id),
         url = "#{@github_api_url}/repos/#{repo_full_name}/issues/#{pr_number}/comments",
         payload = Jason.encode!(%{body: body}),
         {:ok, response} <- make_authenticated_request(:post, url, payload, token) do
      
      case response.status_code do
        201 -> 
          {:ok, comment_data} = Jason.decode(response.body)
          {:ok, Map.get(comment_data, "id")}
          
        code ->
          Logger.error("Failed to create comment: HTTP #{code} - #{response.body}")
          {:error, :github_api_error}
      end
    end
  end
  
  @doc """
  Create a review comment on a specific line of a pull request.
  
  ## Parameters
  
    * `installation_id` - GitHub App installation ID
    * `repo_full_name` - Repository name with owner
    * `pr_number` - Pull request number
    * `body` - Comment text (markdown supported)
    * `commit_id` - The SHA of the commit to comment on
    * `path` - The relative path to the file to comment on
    * `line` - Line number in the file to comment on
  
  ## Returns
  
    * `{:ok, comment_id}` - Comment created successfully
    * `{:error, reason}` - If creation fails
  """
  @spec create_review_comment(integer(), String.t(), integer(), String.t(), String.t(), String.t(), integer()) ::
        {:ok, String.t()} | {:error, atom() | String.t()}
  def create_review_comment(installation_id, repo_full_name, pr_number, body, commit_id, path, line) do
    with {:ok, token, _} <- App.get_installation_token(installation_id),
         url = "#{@github_api_url}/repos/#{repo_full_name}/pulls/#{pr_number}/comments",
         payload = Jason.encode!(%{
           body: body,
           commit_id: commit_id,
           path: path,
           line: line
         }),
         {:ok, response} <- make_authenticated_request(:post, url, payload, token) do
      
      case response.status_code do
        201 -> 
          {:ok, comment_data} = Jason.decode(response.body)
          {:ok, Map.get(comment_data, "id")}
          
        code ->
          Logger.error("Failed to create review comment: HTTP #{code} - #{response.body}")
          {:error, :github_api_error}
      end
    end
  end
  
  @doc """
  Create a pull request review with comments.
  
  ## Parameters
  
    * `installation_id` - GitHub App installation ID
    * `repo_full_name` - Repository name with owner
    * `pr_number` - Pull request number
    * `comments` - List of comment objects with path, line, body
    * `body` - Overall review body text
    * `event` - Review event type (COMMENT, APPROVE, REQUEST_CHANGES)
  
  ## Returns
  
    * `{:ok, review_id}` - Review created successfully
    * `{:error, reason}` - If creation fails
  """
  @spec create_review(integer(), String.t(), integer(), list(map()), String.t(), String.t()) ::
        {:ok, String.t()} | {:error, atom() | String.t()}
  def create_review(installation_id, repo_full_name, pr_number, comments, body, event) do
    with {:ok, token, _} <- App.get_installation_token(installation_id),
         url = "#{@github_api_url}/repos/#{repo_full_name}/pulls/#{pr_number}/reviews",
         payload = Jason.encode!(%{
           comments: comments,
           body: body,
           event: event
         }),
         {:ok, response} <- make_authenticated_request(:post, url, payload, token) do
      
      case response.status_code do
        200 -> 
          {:ok, review_data} = Jason.decode(response.body)
          {:ok, Map.get(review_data, "id")}
          
        code ->
          Logger.error("Failed to create review: HTTP #{code} - #{response.body}")
          {:error, :github_api_error}
      end
    end
  end
  
  # Helper functions
  
  defp make_authenticated_request(method, url, body, token) do
    headers = [
      {"Authorization", "token #{token}"},
      {"Accept", "application/vnd.github.v3+json"},
      {"User-Agent", @user_agent}
    ]
    
    # This is a placeholder - you'll need to implement actual HTTP requests
    # using HTTPoison, Finch, or another HTTP client
    try do
      # Placeholder for HTTP client implementation
      Logger.info("Making #{method} request to #{url}")
      {:error, :not_implemented}
    rescue
      e -> 
        Logger.error("HTTP request failed: #{inspect(e)}")
        {:error, :request_failed}
    end
  end
end 