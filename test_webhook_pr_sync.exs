#!/usr/bin/env elixir

# Script to test GitHub webhook handling for PR synchronization
# This simulates what happens when a PR receives new commits and the webhook is triggered

# Load the application
Mix.install([:jason])
Application.ensure_all_started(:ace)

alias AceWeb.WebhookController
alias Ace.GitHub.Models.PullRequest
alias Ace.Repo

# First, check if we have any existing PRs to use
existing_prs = Repo.all(PullRequest)

pr_data = if length(existing_prs) > 0 do
  # Use the first existing PR
  pr = List.first(existing_prs)
  %{
    "id" => pr.pr_id,
    "number" => pr.number,
    "repo_name" => pr.repo_name
  }
else
  # Create new PR data
  pr_number = :rand.uniform(10000)
  pr_id = "test-pr-#{:rand.uniform(1000000)}"
  repo_name = "user/repo"
  
  %{
    "id" => pr_id,
    "number" => pr_number,
    "repo_name" => repo_name
  }
end

# Create a mock PR sync payload similar to what GitHub would send
mock_pr_sync_payload = %{
  "action" => "synchronize",
  "pull_request" => %{
    "id" => pr_data["id"],
    "number" => pr_data["number"],
    "title" => "Test PR with New Commits",
    "html_url" => "https://github.com/#{pr_data["repo_name"]}/pull/#{pr_data["number"]}",
    "head" => %{
      "sha" => "new_commit_sha_#{:rand.uniform(1000000)}",
      "ref" => "feature-branch"
    },
    "base" => %{
      "sha" => "base_sha",
      "ref" => "main"
    },
    "user" => %{
      "login" => "testuser"
    }
  },
  "repository" => %{
    "full_name" => pr_data["repo_name"],
    "name" => String.split(pr_data["repo_name"], "/") |> List.last(),
    "owner" => %{
      "login" => String.split(pr_data["repo_name"], "/") |> List.first()
    }
  }
}

IO.puts("\n=====================")
IO.puts("Testing PR synchronize webhook handler")
IO.puts("=====================\n")

IO.puts("PR ID: #{pr_data["id"]}")
IO.puts("PR Number: #{pr_data["number"]}")
IO.puts("Repo: #{pr_data["repo_name"]}")

# Use the webhook handler to process the sync event
# First check if this PR exists in our system
case Ace.GitHub.Service.get_pull_request_by_github_id(pr_data["id"]) do
  {:ok, existing_pr} ->
    IO.puts("\nFound existing PR in database, simulating new commits...")
    WebhookController.process_pr_synchronized(mock_pr_sync_payload)
    
    # Wait for optimization to run
    IO.puts("\nWaiting for re-optimization to run...")
    :timer.sleep(2000)
    
    # Check for new optimization suggestions
    alias Ace.GitHub.Models.OptimizationSuggestion
    suggestions = OptimizationSuggestion.get_by_pr_id(existing_pr.id)
    
    IO.puts("\nFound #{length(suggestions)} optimization suggestions")
    
  {:error, :not_found} ->
    IO.puts("\nPR not found in database, creating it first...")
    case WebhookController.process_pr_opened_debug(mock_pr_sync_payload) do
      {:ok, new_pr} ->
        IO.puts("Created new PR: #{new_pr.id}")
        
        # Wait for optimization to run
        IO.puts("\nWaiting for optimization to run...")
        :timer.sleep(2000)
        
        # Check for optimization suggestions
        alias Ace.GitHub.Models.OptimizationSuggestion
        suggestions = OptimizationSuggestion.get_by_pr_id(new_pr.id)
        
        IO.puts("\nFound #{length(suggestions)} optimization suggestions")
        
      {:error, reason} ->
        IO.puts("❌ Failed to create PR: #{inspect(reason)}")
    end
end

IO.puts("\n=====================")
IO.puts("Webhook sync test complete")
IO.puts("=====================\n") 