defmodule APIEndpointTester do
  @moduledoc """
  A test script to verify the new API endpoint for optimization suggestions.
  """
  
  @doc """
  Sends a test request to get optimization suggestions for a PR.
  """
  def run do
    IO.puts("Testing API endpoint for optimization suggestions...")
    
    # Step 1: Get the most recent PR from the database
    IO.puts("\nStep 1: Getting the most recent PR from the database...")
    pr = get_recent_pr()
    
    if pr do
      IO.puts("Found PR with ID: #{pr.id} and PR number: #{pr.number}")
      
      # Step 2: Make the API request
      IO.puts("\nStep 2: Testing API endpoint directly...")
      url = "http://localhost:4000/api/github/pull_requests/#{pr.id}/suggestions"
      
      IO.puts("Making request to: #{url}")
      IO.puts("Please check that the Phoenix server is running")
      IO.puts("And then run: curl #{url}")
      
      # Step 3: Verify data in the database
      IO.puts("\nStep 3: Verifying data in the database...")
      suggestions = Ace.GitHub.Models.OptimizationSuggestion.get_by_pr_id(pr.id)
      
      IO.puts("Found #{length(suggestions)} suggestions in the database for PR #{pr.id}")
      
      Enum.each(suggestions, fn suggestion ->
        IO.puts("\n  - Suggestion ID: #{suggestion.id}")
        IO.puts("    Description: #{suggestion.description}")
        IO.puts("    Type: #{suggestion.opportunity_type}")
        IO.puts("    Severity: #{suggestion.severity}")
        IO.puts("    Location: #{suggestion.location}")
      end)
    else
      IO.puts("No PRs found in database. Please run the debug_webhook_real_files.exs script first.")
    end
  end
  
  defp get_recent_pr do
    import Ecto.Query
    
    Ace.Repo.one(
      from p in Ace.GitHub.Models.PullRequest,
      order_by: [desc: p.inserted_at],
      limit: 1
    )
  end
end

APIEndpointTester.run() 