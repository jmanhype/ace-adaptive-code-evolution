defmodule Ace.GitHub.PRCreator do
  @moduledoc """
  Module responsible for creating GitHub pull requests with optimized code.
  This creates a new pull request with all the optimizations applied, similar to CodeFlash.
  """
  alias Ace.GitHub.GitHubAPI
  alias Ace.GitHub.Models.{PullRequest, OptimizationSuggestion}
  require Logger
  
  @optimization_pr_title "Code Optimization Suggestions"
  @optimization_pr_body """
  This Pull Request contains code optimizations suggested by Ace.
  
  Each optimization includes:
  - A description of the opportunity
  - The optimized code
  
  Please review each change carefully before merging.
  """
  
  @doc """
  Creates a new pull request with all optimization suggestions applied.
  
  ## Parameters
    - pr_id: ID of the original pull request
    
  ## Returns
    - {:ok, map} on success with PR details
    - {:error, reason} on failure
  """
  @spec create_optimization_pr(String.t()) :: {:ok, map()} | {:error, any()}
  def create_optimization_pr(pr_id) do
    Logger.debug("Creating optimization PR for PR #{pr_id}")

    optimizations = OptimizationSuggestion.get_for_pr(pr_id)

    if Enum.empty?(optimizations) do
      Logger.info("No optimizations found for PR #{pr_id}")
      {:error, :no_optimizations}
    else
      # Get the pull request directly, not as a tuple
      case PullRequest.get(pr_id) do
        nil ->
          {:error, :pull_request_not_found}
        pr ->
          with {:ok, branch_name} <- create_optimization_branch(pr),
               :ok <- apply_optimizations(optimizations, pr, branch_name),
               {:ok, new_pr} <- create_pr(pr, branch_name) do
            Logger.info("Successfully created optimization PR #{new_pr["number"]} for PR #{pr_id}")
            {:ok, %{message: "Optimization PR created", pr_number: new_pr["number"], pr_url: new_pr["html_url"]}}
          else
            {:error, reason} = error ->
              Logger.error("Failed to create optimization PR: #{inspect(reason)}")
              error
          end
      end
    end
  end
  
  # Creates a new branch for optimizations based on the PR's head.
  @spec create_optimization_branch(PullRequest.t()) :: {:ok, String.t()} | {:error, any()}
  defp create_optimization_branch(pr) do
    %PullRequest{repo_name: repo, number: pr_number} = pr

    with {:ok, head_sha} <- get_head_sha(pr),
         branch_name = "ace-optimize-#{pr_number}-#{System.system_time(:second)}",
         {:ok, _} <- GitHubAPI.create_branch(repo, branch_name, head_sha) do
      Logger.debug("Created branch #{branch_name} in repo #{repo}")
      {:ok, branch_name}
    else
      {:error, reason} ->
        Logger.error("Failed to create branch: #{inspect(reason)}")
        {:error, "Failed to create branch: #{inspect(reason)}"}
    end
  end
  
  # Gets the HEAD SHA for the PR.
  @spec get_head_sha(PullRequest.t()) :: {:ok, String.t()} | {:error, any()}
  defp get_head_sha(pr) do
    %PullRequest{repo_name: repo, number: pr_number} = pr

    case GitHubAPI.get_pull_request(repo, pr_number) do
      {:ok, pr_data} ->
        {:ok, pr_data["head"]["sha"]}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  # Applies a list of optimizations to a PR.
  @spec apply_optimizations(list(OptimizationSuggestion.t()), PullRequest.t(), String.t()) :: :ok | {:error, any()}
  defp apply_optimizations(optimizations, pr, branch_name) do
    Enum.reduce_while(optimizations, :ok, fn optimization, _acc ->
      case apply_optimization(optimization, pr, branch_name) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
  
  # Applies a single optimization to a PR.
  @spec apply_optimization(OptimizationSuggestion.t(), PullRequest.t(), String.t()) :: :ok | {:error, any()}
  defp apply_optimization(optimization, pr, branch_name) do
    %PullRequest{repo_name: repo} = pr

    with {:ok, content} <- GitHubAPI.get_file_content(repo, optimization.file.filename, branch_name),
         new_content = apply_optimization_to_content(content, optimization),
         commit_message = create_commit_message(optimization),
         {:ok, _} <- GitHubAPI.create_or_update_file(repo, optimization.file.filename, commit_message, new_content, branch_name) do
      Logger.debug("Applied optimization to #{optimization.file.filename}")
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to apply optimization: #{inspect(reason)}")
        {:error, "Failed to apply optimization: #{inspect(reason)}"}
    end
  end
  
  # Creates a PR with the optimizations.
  @spec create_pr(PullRequest.t(), String.t()) :: {:ok, map()} | {:error, any()}
  defp create_pr(pr, branch_name) do
    %PullRequest{repo_name: repo} = pr
    # Use "main" as the base branch if not specified
    base_branch = "main"

    GitHubAPI.create_pull_request(repo, @optimization_pr_title, @optimization_pr_body, branch_name, base_branch)
  end
  
  # Applies the optimization to the file content.
  @spec apply_optimization_to_content(String.t(), OptimizationSuggestion.t()) :: String.t()
  defp apply_optimization_to_content(content, optimization) do
    String.replace(content, optimization.original_code, optimization.optimized_code)
  end

  # Creates a commit message for an optimization.
  @spec create_commit_message(OptimizationSuggestion.t()) :: String.t()
  defp create_commit_message(optimization) do
    "Optimize: #{optimization.description}"
  end
end 