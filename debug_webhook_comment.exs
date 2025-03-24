IO.puts("Testing webhook handler with PR comment event...")

# Test payload simulating a GitHub webhook payload for a PR comment
test_payload = %{
  "action" => "created",
  "issue" => %{
    "number" => 123,
    "html_url" => "https://github.com/jmanhype/synaflow/pull/123",
    "pull_request" => %{
      "url" => "https://api.github.com/repos/jmanhype/synaflow/pulls/123"
    }
  },
  "comment" => %{
    "id" => 987654321,
    "body" => "/optimize Please optimize this code for performance",
    "user" => %{
      "login" => "test-user",
      "id" => 12345
    },
    "created_at" => "2025-03-23T16:30:00Z",
    "html_url" => "https://github.com/jmanhype/synaflow/pull/123#issuecomment-987654321"
  },
  "repository" => %{
    "id" => 7890123,
    "name" => "synaflow",
    "full_name" => "jmanhype/synaflow",
    "html_url" => "https://github.com/jmanhype/synaflow"
  },
  "sender" => %{
    "login" => "test-user",
    "id" => 12345
  }
}

try do
  # Process the PR comment using the debug version
  result = AceWeb.WebhookController.process_pr_comment_debug(test_payload)
  IO.inspect(result, label: "Comment Processing Result")
rescue
  e ->
    IO.puts("Error processing PR comment: #{inspect(e)}")
    IO.puts(Exception.format_stacktrace(__STACKTRACE__))
end 