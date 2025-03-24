defmodule Ace.GitHub.GitHubAPI do
  @moduledoc """
  Provides API access to GitHub using GitHub App authentication.
  This module handles all communications with GitHub's REST API.
  """
  require Logger
  alias Ace.GitHub.AppAuth

  @github_api_url "https://api.github.com"

  @doc """
  Creates a pull request in the specified repository.
  
  ## Parameters
    * repo_full_name - The full name of the repository (e.g., "owner/repo")
    * title - The title of the pull request
    * body - The description body of the pull request
    * head - The name of the branch where your changes are implemented
    * base - The name of the branch you want to merge changes into
  
  ## Returns
    * {:ok, pull_request} - A map containing the created pull request data
    * {:error, reason} - Error information
  """
  def create_pull_request(repo_full_name, title, body, head, base) do
    with {:ok, token} <- AppAuth.get_token() do
      url = "#{@github_api_url}/repos/#{repo_full_name}/pulls"
      
      payload = %{
        title: title,
        body: body,
        head: head,
        base: base
      }
      
      headers = [
        {"Authorization", "Bearer #{token}"},
        {"Accept", "application/vnd.github.v3+json"},
        {"Content-Type", "application/json"}
      ]
      
      case HTTPoison.post(url, Jason.encode!(payload), headers) do
        {:ok, %{status_code: 201, body: response_body}} ->
          {:ok, Jason.decode!(response_body)}
          
        {:ok, %{status_code: status, body: response_body}} ->
          Logger.error("Failed to create PR. Status: #{status}, Response: #{response_body}")
          {:error, "Failed to create pull request: HTTP #{status}", response_body}
          
        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("HTTP request failed: #{inspect(reason)}")
          {:error, "HTTP request failed: #{inspect(reason)}", nil}
      end
    end
  end

  @doc """
  Gets details about a pull request.
  
  ## Parameters
    * repo_full_name - The full name of the repository (e.g., "owner/repo")
    * pr_number - The pull request number
  
  ## Returns
    * {:ok, pull_request} - A map containing the pull request data
    * {:error, reason} - Error information
  """
  def get_pull_request(repo_full_name, pr_number) do
    with {:ok, token} <- AppAuth.get_token() do
      url = "#{@github_api_url}/repos/#{repo_full_name}/pulls/#{pr_number}"
      
      headers = [
        {"Authorization", "Bearer #{token}"},
        {"Accept", "application/vnd.github.v3+json"}
      ]
      
      case HTTPoison.get(url, headers) do
        {:ok, %{status_code: 200, body: response_body}} ->
          {:ok, Jason.decode!(response_body)}
          
        {:ok, %{status_code: status, body: response_body}} ->
          Logger.error("Failed to get PR. Status: #{status}, Response: #{response_body}")
          {:error, "Failed to get pull request: HTTP #{status}"}
          
        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("HTTP request failed: #{inspect(reason)}")
          {:error, "HTTP request failed: #{inspect(reason)}"}
      end
    end
  end

  @doc """
  Gets the files changed in a pull request.
  
  ## Parameters
    * repo_full_name - The full name of the repository (e.g., "owner/repo")
    * pr_number - The pull request number
  
  ## Returns
    * {:ok, files} - A list of files changed in the pull request
    * {:error, reason} - Error information
  """
  def get_pr_files(repo_full_name, pr_number) do
    with {:ok, token} <- AppAuth.get_token() do
      url = "#{@github_api_url}/repos/#{repo_full_name}/pulls/#{pr_number}/files"
      
      headers = [
        {"Authorization", "Bearer #{token}"},
        {"Accept", "application/vnd.github.v3+json"}
      ]
      
      case HTTPoison.get(url, headers) do
        {:ok, %{status_code: 200, body: response_body}} ->
          {:ok, Jason.decode!(response_body)}
          
        {:ok, %{status_code: status, body: response_body}} ->
          Logger.error("Failed to get PR files. Status: #{status}, Response: #{response_body}")
          {:error, "Failed to get pull request files: HTTP #{status}"}
          
        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("HTTP request failed: #{inspect(reason)}")
          {:error, "HTTP request failed: #{inspect(reason)}"}
      end
    end
  end

  @doc """
  Gets the content of a file from a repository.
  
  ## Parameters
    * repo_full_name - The full name of the repository (e.g., "owner/repo")
    * path - The path to the file
    * ref - Optional reference (branch, tag, or commit SHA)
  
  ## Returns
    * {:ok, content} - The content of the file
    * {:error, reason} - Error information
  """
  def get_file_content(repo_full_name, path, ref \\ nil) do
    with {:ok, token} <- AppAuth.get_token() do
      url = "#{@github_api_url}/repos/#{repo_full_name}/contents/#{path}"
      url = if ref, do: "#{url}?ref=#{ref}", else: url
      
      headers = [
        {"Authorization", "Bearer #{token}"},
        {"Accept", "application/vnd.github.v3.raw"}
      ]
      
      case HTTPoison.get(url, headers, [timeout: 15000, recv_timeout: 15000]) do
        {:ok, %{status_code: 200, body: content}} ->
          {:ok, content, nil}
          
        {:ok, %{status_code: 404}} ->
          Logger.error("File not found: #{path} in #{repo_full_name}")
          {:error, "File not found"}
          
        {:ok, %{status_code: status, body: response_body}} ->
          Logger.error("Failed to get file content. Status: #{status}, Response: #{response_body}")
          {:error, "Failed to get file content: HTTP #{status}"}
          
        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("HTTP error when getting file content: #{inspect(reason)}")
          {:error, "HTTP error: #{inspect(reason)}"}
      end
    end
  end

  @doc """
  Creates a new branch in a repository.
  
  ## Parameters
    * repo_full_name - The full name of the repository (e.g., "owner/repo")
    * branch_name - The name of the new branch
    * sha - The SHA of the commit to branch from
  
  ## Returns
    * {:ok, reference} - A map containing the reference data
    * {:error, reason} - Error information
  """
  @spec create_branch(String.t(), String.t(), String.t()) :: {:ok, map()} | {:error, String.t(), String.t() | nil}
  def create_branch(repo_full_name, branch_name, sha) do
    with {:ok, token} <- AppAuth.get_token(),
         url <- "https://api.github.com/repos/#{repo_full_name}/git/refs",
         headers <- [
           {"Authorization", "Bearer #{token}"},
           {"Accept", "application/vnd.github.v3+json"},
           {"Content-Type", "application/json"}
         ],
         body <- Jason.encode!(%{
           "ref" => "refs/heads/#{branch_name}",
           "sha" => sha
         }),
         {:ok, %HTTPoison.Response{status_code: status, body: response_body}} when status in 200..299 <-
           HTTPoison.post(url, body, headers) do
      {:ok, Jason.decode!(response_body)}
    else
      {:ok, %HTTPoison.Response{status_code: status, body: response_body}} ->
        Logger.error("Failed to create branch: HTTP #{status} - #{response_body}")
        {:error, "Failed to create branch: HTTP #{status}", response_body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Failed to create branch: #{inspect(reason)}")
        {:error, "Failed to create branch: #{inspect(reason)}", nil}
    end
  end

  @doc """
  Creates or updates a file in a repository.
  
  ## Parameters
    * repo_full_name - The full name of the repository (e.g., "owner/repo")
    * path - The path to the file
    * message - The commit message
    * content - The new content of the file
    * branch - The branch name
    * sha - The SHA of the file to update (nil for a new file)
  
  ## Returns
    * {:ok, commit} - A map containing the commit data
    * {:error, reason} - Error information
  """
  def create_or_update_file(repo_full_name, path, message, content, branch, sha \\ nil) do
    with {:ok, token} <- AppAuth.get_token() do
      url = "#{@github_api_url}/repos/#{repo_full_name}/contents/#{path}"
      
      payload = %{
        message: message,
        content: Base.encode64(content),
        branch: branch
      }
      
      payload = if sha, do: Map.put(payload, :sha, sha), else: payload
      
      headers = [
        {"Authorization", "Bearer #{token}"},
        {"Accept", "application/vnd.github.v3+json"},
        {"Content-Type", "application/json"}
      ]
      
      case HTTPoison.put(url, Jason.encode!(payload), headers) do
        {:ok, %{status_code: code, body: response_body}} when code in [200, 201] ->
          {:ok, Jason.decode!(response_body)}
          
        {:ok, %{status_code: status, body: response_body}} ->
          Logger.error("Failed to create/update file. Status: #{status}, Response: #{response_body}")
          {:error, "Failed to create/update file: HTTP #{status}", response_body}
          
        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("HTTP request failed: #{inspect(reason)}")
          {:error, "HTTP request failed: #{inspect(reason)}", nil}
      end
    end
  end

  @doc """
  Creates a comment on a pull request.
  
  ## Parameters
    * repo_full_name - The full name of the repository (e.g., "owner/repo")
    * pr_number - The pull request number
    * body - The text of the comment
  
  ## Returns
    * {:ok, comment} - A map containing the comment data
    * {:error, reason} - Error information
  """
  def create_comment(repo, pr_number, body) do
    with {:ok, token} <- AppAuth.get_token() do
      url = "#{@github_api_url}/repos/#{repo}/issues/#{pr_number}/comments"
      
      headers = [
        {"Authorization", "token #{token}"},
        {"Accept", "application/vnd.github.v3+json"},
        {"Content-Type", "application/json"}
      ]
      
      payload = Jason.encode!(%{body: body})
      
      Logger.info("Posting comment to GitHub PR ##{pr_number} in #{repo}")
      case HTTPoison.post(url, payload, headers) do
        {:ok, %{status_code: 201} = response} ->
          {:ok, response}
        {:ok, response} ->
          Logger.error("Failed to create PR comment. Status: #{response.status_code}, Response: #{response.body}")
          {:error, "Failed to create PR comment: HTTP #{response.status_code}", response.body}
        {:error, error} ->
          Logger.error("Failed to create PR comment: #{inspect(error)}")
          {:error, "Failed to create PR comment: #{inspect(error)}", nil}
      end
    end
  end
  
  @doc """
  Creates a commit status on a reference.
  
  ## Parameters
    * repo_full_name - The full name of the repository (e.g., "owner/repo")
    * sha - The SHA of the commit
    * state - The state of the status (one of: "error", "failure", "pending", "success")
    * description - A short description of the status
    * context - A label to differentiate this status from others
    * target_url - Optional URL to link from the status
  
  ## Returns
    * {:ok, status} - A map containing the status data
    * {:error, reason} - Error information
  """
  def create_commit_status(repo_full_name, sha, state, description, context, target_url \\ nil) do
    with {:ok, token} <- AppAuth.get_token() do
      url = "#{@github_api_url}/repos/#{repo_full_name}/statuses/#{sha}"
      
      payload = %{
        state: state,
        description: description,
        context: context
      }
      
      payload = if target_url, do: Map.put(payload, :target_url, target_url), else: payload
      
      headers = [
        {"Authorization", "Bearer #{token}"},
        {"Accept", "application/vnd.github.v3+json"},
        {"Content-Type", "application/json"}
      ]
      
      case HTTPoison.post(url, Jason.encode!(payload), headers) do
        {:ok, %{status_code: 201, body: response_body}} ->
          {:ok, Jason.decode!(response_body)}
          
        {:ok, %{status_code: status, body: response_body}} ->
          Logger.error("Failed to create commit status. Status: #{status}, Response: #{response_body}")
          {:error, "Failed to create commit status: HTTP #{status}"}
          
        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.error("HTTP request failed: #{inspect(reason)}")
          {:error, "HTTP request failed: #{inspect(reason)}"}
      end
    end
  end

  @doc """
  Lists branches in a repository.
  
  ## Parameters
    * repo_full_name - The full name of the repository (e.g., "owner/repo")
  
  ## Returns
    * {:ok, branches} - A list of branches in the repository
    * {:error, reason} - Error information
  """
  @spec list_branches(String.t()) :: {:ok, list(map())} | {:error, String.t(), String.t() | nil}
  def list_branches(repo_full_name) do
    with {:ok, token} <- AppAuth.get_token(),
         url <- "https://api.github.com/repos/#{repo_full_name}/branches",
         headers <- [
           {"Authorization", "Bearer #{token}"},
           {"Accept", "application/vnd.github.v3+json"}
         ],
         {:ok, %HTTPoison.Response{status_code: status, body: body}} when status in 200..299 <-
           HTTPoison.get(url, headers) do
      {:ok, Jason.decode!(body)}
    else
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        Logger.error("Failed to list branches: HTTP #{status} - #{body}")
        {:error, "Failed to list branches: HTTP #{status}", body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Failed to list branches: #{inspect(reason)}")
        {:error, "Failed to list branches: #{inspect(reason)}", nil}
    end
  end

  @doc """
  Lists pull requests in a repository.
  
  ## Parameters
    * repo_full_name - The full name of the repository (e.g., "owner/repo")
    * state - State of the pull requests (open, closed, or all) - defaults to "open"
  
  ## Returns
    * {:ok, pull_requests} - A list of pull requests in the repository
    * {:error, reason} - Error information
  """
  @spec list_pull_requests(String.t(), String.t()) :: {:ok, list(map())} | {:error, String.t(), String.t() | nil}
  def list_pull_requests(repo_full_name, state \\ "open") do
    with {:ok, token} <- AppAuth.get_token(),
         url <- "https://api.github.com/repos/#{repo_full_name}/pulls?state=#{state}",
         headers <- [
           {"Authorization", "Bearer #{token}"},
           {"Accept", "application/vnd.github.v3+json"}
         ],
         {:ok, %HTTPoison.Response{status_code: status, body: body}} when status in 200..299 <-
           HTTPoison.get(url, headers) do
      {:ok, Jason.decode!(body)}
    else
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        Logger.error("Failed to list pull requests: HTTP #{status} - #{body}")
        {:error, "Failed to list pull requests: HTTP #{status}", body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Failed to list pull requests: #{inspect(reason)}")
        {:error, "Failed to list pull requests: #{inspect(reason)}", nil}
    end
  end
end 