# Debug script for testing PR comment webhook handling
# Usage: mix run debug_webhook_scientific_comment.exs

alias Ace.GitHub.Service
alias Ace.GitHub.Models.PullRequest
alias AceWeb.WebhookController

IO.puts("Testing webhook handler with PR comment event for scientific code optimization...")

# Generate GitHub App token for API requests
# Removed token generation as it seems to be handled internally

# Mock PR comment event data
comment_payload = %{
  "action" => "created",
  "issue" => %{
    "number" => 123,
    "html_url" => "https://github.com/jmanhype/synaflow/pull/123",
    "pull_request" => %{
      "url" => "https://api.github.com/repos/jmanhype/synaflow/pulls/123"
    }
  },
  "comment" => %{
    "id" => 1234567890,
    "body" => "/optimize Please optimize the scientific_qa.py and synaflow_api.js files for better performance",
    "created_at" => "2023-03-23T10:00:00Z",
    "user" => %{
      "login" => "test-user",
      "id" => 12345
    }
  },
  "repository" => %{
    "id" => 7890123,
    "name" => "synaflow",
    "full_name" => "jmanhype/synaflow",
    "html_url" => "https://github.com/jmanhype/synaflow"
  }
}

# Log the issue data we're testing with
IO.puts("Issue Data:")
IO.puts("PR URL: #{comment_payload["issue"]["html_url"]}")
IO.puts("PR number: #{comment_payload["issue"]["number"]}")

# Log the comment data
IO.puts("\nComment Data:")
IO.puts("Body: #{comment_payload["comment"]["body"]}")
IO.puts("Created at: #{comment_payload["comment"]["created_at"]}")
IO.puts("Author: #{comment_payload["comment"]["user"]["login"]}")

# Call the webhook handler with our mock payload
IO.puts("\nCalling webhook handler...")
try do
  # Use the debug version of the function that's specifically for scripts
  result = WebhookController.process_pr_comment_debug(comment_payload)
  IO.inspect(result, label: "Result")

  # Query DB to check if PR was properly updated
  case Service.get_pull_request_by_number(123, "jmanhype/synaflow") do
    {:ok, pr} -> 
      IO.puts("\nPR in database after processing:")
      IO.inspect(pr)
    _ -> 
      IO.puts("\nCould not find PR in database")
  end
rescue
  e ->
    IO.puts("Error processing webhook: #{inspect(e)}")
    IO.inspect(System.stacktrace(), label: "Stack trace")
end 