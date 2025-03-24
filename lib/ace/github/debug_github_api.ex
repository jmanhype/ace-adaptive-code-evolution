defmodule Ace.GitHub.DebugGitHubAPI do
  @moduledoc """
  Debug wrapper around the GitHubAPI module for troubleshooting.
  This module is intended for development/testing only.
  """
  
  require Logger
  
  @doc """
  Debug wrapper for create_branch that logs parameters and bypasses the actual API call.
  """
  def create_branch(repo_full_name, branch_name, sha) do
    Logger.info("DEBUG: create_branch called with: repo=#{repo_full_name}, branch=#{branch_name}, sha=#{sha}")
    
    # For testing, we'll return a success response without calling the actual API
    {:ok, %{
      "ref" => "refs/heads/#{branch_name}",
      "node_id" => "MOCK_NODE_ID",
      "url" => "https://api.github.com/repos/#{repo_full_name}/git/refs/heads/#{branch_name}",
      "object" => %{
        "type" => "commit",
        "sha" => sha,
        "url" => "https://api.github.com/repos/#{repo_full_name}/git/commits/#{sha}"
      }
    }}
  end
  
  @doc """
  Debug wrapper for create_or_update_file that logs parameters and bypasses the actual API call.
  """
  def create_or_update_file(repo_full_name, path, message, content, branch, _sha \\ nil) do
    Logger.info("DEBUG: create_or_update_file called for file #{path} in branch #{branch}")
    
    # For testing, we'll return a success response without calling the actual API
    {:ok, %{
      "content" => %{
        "name" => Path.basename(path),
        "path" => path,
        "sha" => "mock-file-sha-#{:rand.uniform(1000)}",
        "size" => byte_size(content),
        "url" => "https://api.github.com/repos/#{repo_full_name}/contents/#{path}"
      },
      "commit" => %{
        "sha" => "mock-commit-sha-#{:rand.uniform(1000)}",
        "message" => message
      }
    }}
  end
  
  @doc """
  Debug wrapper for create_pull_request that logs parameters and bypasses the actual API call.
  """
  def create_pull_request(repo_full_name, title, body, head, base) do
    Logger.info("DEBUG: create_pull_request called from #{head} to #{base}")
    
    # For testing, we'll return a success response without calling the actual API
    pr_number = :rand.uniform(1000)
    
    {:ok, %{
      "id" => :rand.uniform(10000000),
      "number" => pr_number,
      "title" => title,
      "html_url" => "https://github.com/#{repo_full_name}/pull/#{pr_number}",
      "head" => %{"ref" => head},
      "base" => %{"ref" => base},
      "body" => String.slice(body, 0, 50) <> "..."
    }}
  end
  
  # Delegate all other function calls to the actual GitHubAPI module
  def get_file_content(_repo_full_name, path, ref \\ nil) do
    Logger.info("DEBUG: get_file_content called for #{path} with ref=#{ref || ~c"nil"}")
    {:ok, "Mock file content for #{path}", "mock-file-sha-#{:rand.uniform(1000)}"}
  end
end 