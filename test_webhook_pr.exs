#!/usr/bin/env elixir

# Script to test GitHub webhook handling for a new PR
# This simulates what happens when a PR is created and the webhook is triggered

# Load the application
# Mix.install([:jason])
Application.ensure_all_started(:ace)

import Ecto.Query
alias AceWeb.WebhookController
alias Ace.GitHub.Models.OptimizationSuggestion
alias Ace.GitHub.Models.PRFile
alias Ace.GitHub.Models.PullRequest
alias Ace.Repo
alias Ace.GitHub.OptimizationAdapter

# Generate a unique PR number
pr_number = :rand.uniform(10000)
pr_id = :rand.uniform(1000000)  # Changed to integer
repo_name = "user/repo"

# Create a mock PR payload similar to what GitHub would send
mock_pr_payload = %{
  "action" => "opened",
  "pull_request" => %{
    "id" => pr_id,  # Now it's an integer
    "number" => pr_number,
    "title" => "Test PR for Auto-Optimization",
    "html_url" => "https://github.com/#{repo_name}/pull/#{pr_number}",
    "head" => %{
      "sha" => "abc123def456",
      "ref" => "feature-branch"
    },
    "base" => %{
      "sha" => "base789sha",
      "ref" => "main"
    },
    "user" => %{
      "login" => "testuser"
    }
  },
  "repository" => %{
    "full_name" => repo_name,
    "name" => "repo",
    "owner" => %{
      "login" => "user"
    }
  }
}

IO.puts("\n=====================")
IO.puts("Testing PR webhook handler")
IO.puts("=====================\n")

# Use the debug version of the webhook handler
case WebhookController.process_pr_opened_debug(mock_pr_payload) do
  {:ok, pr} ->
    IO.puts("\n✅ Successfully created PR and triggered optimization")
    IO.puts("PR ID: #{pr.id}")
    IO.puts("GitHub PR ID: #{pr.pr_id}")
    IO.puts("PR Number: #{pr.number}")
    
    # Add sample Python file to the PR
    python_code = """
    # A sample Python file with optimization opportunities
    import time
    import math
    
    # Cache for expensive calculations
    cache = {}
    
    def factorial(n):
        # Inefficient factorial calculation
        result = 1
        for i in range(1, n + 1):
            result = result * i
        return result
    
    def process_data(items):
        # Inefficient list building
        result = []
        for item in items:
            result = result + [item * 2]  # Inefficient list concatenation
        return result
    
    def clear_cache():
        # Create and immediately clear data structure
        temp_cache = {}
        for i in range(100):
            temp_cache[i] = i * i
        temp_cache.clear()
        
    def main():
        data = [1, 2, 3, 4, 5]
        processed = process_data(data)
        print(f"Processed data: {processed}")
        print(f"Factorial of 5: {factorial(5)}")
        clear_cache()
        
    if __name__ == "__main__":
        main()
    """
    
    # Add sample JavaScript file to the PR
    js_code = """
    // A sample JavaScript file with optimization opportunities
    
    // API client for SynaFlow
    class SynaFlowAPI {
      constructor(apiKey, baseUrl) {
        // Store redundant information
        this.apiKey = apiKey;
        this.credentials = { key: apiKey };
        this.auth = { apiKey: apiKey };
        
        this.baseUrl = baseUrl;
      }
      
      async fetchData(endpoint, params) {
        // Inefficient URL construction
        let url = this.baseUrl;
        url = url + "/" + endpoint;
        url = url + "?";
        
        // Build query string manually instead of using URLSearchParams
        for (const key in params) {
          url = url + key + "=" + params[key] + "&";
        }
        
        // Inconsistent URL encoding
        if (params.query) {
          url += "query=" + params.query;
        } else if (params.filter) {
          url += "filter=" + encodeURIComponent(params.filter);
        }
        
        const response = await fetch(url, {
          headers: {
            Authorization: `Bearer ${this.apiKey}`
          }
        });
        
        return response.json();
      }
    }
    
    // Example usage
    const api = new SynaFlowAPI("secret-key", "https://api.synaflow.com");
    api.fetchData("users", { limit: 10, filter: "active=true" })
      .then(data => console.log(data))
      .catch(err => console.error(err));
    """
    
    # Add the files to the PR
    python_file_attrs = %{
      pr_id: pr.id,
      filename: "scientific_qa.py",
      content: python_code,
      status: "added",
      language: "python"
    }
    
    js_file_attrs = %{
      pr_id: pr.id,
      filename: "synaflow_api.js",
      content: js_code,
      status: "added",
      language: "javascript"
    }
    
    # Save the files
    {:ok, python_file} = PRFile.upsert(python_file_attrs)
    {:ok, js_file} = PRFile.upsert(js_file_attrs)
    
    IO.puts("\n✅ Added sample files to PR:")
    IO.puts("  - #{python_file.filename} (#{python_file.language})")
    IO.puts("  - #{js_file.filename} (#{js_file.language})")
    
    # Manually trigger optimization
    IO.puts("\nTriggering optimization...")
    # Update PR status
    {:ok, updated_pr} = PullRequest.update(pr, %{status: "processing"})
    
    # Get all files for this PR
    files = Repo.all(from(f in PRFile, where: f.pr_id == ^pr.id))
    
    # Process each file and generate optimization suggestions
    IO.puts("\nProcessing files for optimization...")
    
    for file <- files do
      IO.puts("Optimizing #{file.filename}...")
      
      # Use the adapter to optimize the file
      case OptimizationAdapter.optimize_pr_file(file.content, file.language, file.filename, :mock) do
        {:ok, optimization_result} ->
          suggestions = optimization_result.suggestions
          
          # Save each suggestion to the database
          saved_count = 0
          
          Enum.each(suggestions, fn suggestion ->
            suggestion_attrs = %{
              pr_id: pr.id,
              file_id: file.id,
              opportunity_type: suggestion.type,
              location: suggestion.location,
              description: suggestion.description,
              severity: suggestion.severity,
              original_code: suggestion.original_code,
              optimized_code: suggestion.optimized_code,
              explanation: suggestion.explanation,
              status: "pending",
              metrics: optimization_result.metrics
            }
            
            # Create the suggestion
            case OptimizationSuggestion.create(suggestion_attrs) do
              {:ok, _saved} -> 
                # Successfully saved suggestion
                saved_count = saved_count + 1
              {:error, reason} -> 
                IO.puts("  Error saving suggestion: #{inspect(reason)}")
            end
          end)
          
          IO.puts("  ✅ Generated #{length(suggestions)} suggestions for #{file.filename}")
          
        {:error, reason} ->
          IO.puts("  ❌ Failed to optimize #{file.filename}: #{inspect(reason)}")
      end
    end
    
    # Update PR status to optimized
    {:ok, _optimized_pr} = PullRequest.update(pr, %{status: "optimized"})
    IO.puts("\n✅ Optimization complete")
    
    # Wait a moment for any background processes to complete
    :timer.sleep(1000)
    
    # Check for optimization suggestions
    suggestions = OptimizationSuggestion.get_by_pr_id(pr.id)
    
    IO.puts("\nFound #{length(suggestions)} optimization suggestions")
    
    if length(suggestions) > 0 do
      IO.puts("\n📊 Sample optimization suggestions:")
      
      # Group suggestions by file
      suggestions_by_file = Enum.group_by(suggestions, fn s -> 
        case Repo.get(PRFile, s.file_id) do
          nil -> "unknown"
          file -> file.filename
        end
      end)
      
      # Print sample suggestions for each file
      for {filename, file_suggestions} <- suggestions_by_file do
        IO.puts("\nFile: #{filename}")
        for suggestion <- Enum.take(file_suggestions, 2) do
          IO.puts("  - Type: #{suggestion.opportunity_type}")
          IO.puts("    Description: #{suggestion.description}")
          IO.puts("    Severity: #{suggestion.severity}")
        end
        
        if length(file_suggestions) > 2 do
          IO.puts("  ... and #{length(file_suggestions) - 2} more")
        end
      end
    end
    
  {:error, reason} ->
    IO.puts("❌ Failed to create PR: #{inspect(reason)}")
end

IO.puts("\n=====================")
IO.puts("Webhook test complete")
IO.puts("=====================\n") 