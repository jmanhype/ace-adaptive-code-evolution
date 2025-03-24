# Simple script to test the webhook handler locally
# Run with: mix run debug_webhook.exs

# Define a test PR payload
IO.puts("Testing webhook handler with PR opened event...")

test_payload = %{
  "action" => "opened",
  "pull_request" => %{
    "id" => 1234567,
    "number" => 123,
    "title" => "Test PR",
    "html_url" => "https://github.com/jmanhype/synaflow/pull/123",
    "diff_url" => "https://github.com/jmanhype/synaflow/pull/123.diff",
    "head" => %{
      "sha" => "6dcb09b5b57875f334f61aebed695e2e4193db5e"
    },
    "base" => %{
      "sha" => "6dcb09b5b57875f334f61aebed695e2e4193db5f"
    },
    "state" => "open",
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

try do
  result = AceWeb.WebhookController.process_pr_opened_debug(test_payload)
  IO.inspect(result, label: "Result")
rescue
  e ->
    IO.puts("Error processing webhook:")
    IO.inspect(e, label: "Exception")
    IO.inspect(System.stacktrace(), label: "Stack trace")
end 