defmodule AceWeb.GitHubAPIControllerTest do
  use AceWeb.ConnCase

  alias Ace.GitHub.{PullRequest, PRFile, OptimizationSuggestion}
  alias Ace.Repo

  setup do
    # Create a test pull request
    {:ok, pr} = Repo.insert(%PullRequest{
      pr_id: 12345,
      number: 1,
      title: "Test PR",
      repo_name: "test/repo",
      user: "testuser",
      status: "optimized",
      html_url: "https://github.com/test/repo/pull/1"
    })

    # Create a test file
    {:ok, file} = Repo.insert(%PRFile{
      pr_id: pr.id,
      filename: "test_file.ex",
      status: "added",
      language: "elixir",
      content: "defmodule Test do\n  def test do\n    IO.puts(\"Hello\")\n  end\nend",
      additions: 5,
      deletions: 0,
      changes: 5
    })

    # Create test suggestions with different severities
    {:ok, high_suggestion} = Repo.insert(%OptimizationSuggestion{
      pr_id: pr.id,
      file_id: file.id,
      opportunity_type: "Performance Issue",
      location: "test_file.ex:3",
      description: "Use IO.inspect instead of IO.puts for better debugging",
      severity: "high",
      status: "pending",
      original_code: "    IO.puts(\"Hello\")",
      optimized_code: "    IO.inspect(\"Hello\", label: \"Debug:\")",
      explanation: "IO.inspect returns the value, which is more useful for debugging."
    })

    {:ok, medium_suggestion} = Repo.insert(%OptimizationSuggestion{
      pr_id: pr.id,
      file_id: file.id,
      opportunity_type: "Style Improvement",
      location: "test_file.ex:2-4",
      description: "Simplify function with a one-liner",
      severity: "medium",
      status: "pending",
      original_code: "  def test do\n    IO.puts(\"Hello\")\n  end",
      optimized_code: "  def test, do: IO.puts(\"Hello\")",
      explanation: "For simple functions, one-liners are more concise."
    })

    {:ok, low_suggestion} = Repo.insert(%OptimizationSuggestion{
      pr_id: pr.id,
      file_id: file.id,
      opportunity_type: "Documentation",
      location: "test_file.ex:2",
      description: "Add documentation to function",
      severity: "low",
      status: "pending",
      original_code: "  def test do",
      optimized_code: "  @doc \"\"\"Test function\"\"\"\n  def test do",
      explanation: "Documentation improves code readability."
    })

    %{
      pr: pr, 
      file: file, 
      high_suggestion: high_suggestion,
      medium_suggestion: medium_suggestion,
      low_suggestion: low_suggestion
    }
  end

  describe "show/2" do
    test "returns PR details with suggestions and formatted comment", %{
      conn: conn, 
      pr: pr,
      high_suggestion: high_suggestion,
      medium_suggestion: medium_suggestion,
      low_suggestion: low_suggestion
    } do
      conn = get(conn, Routes.github_api_path(conn, :show, pr.id))
      response = json_response(conn, 200)

      # Verify PR details
      assert response["data"]["id"] == pr.id
      assert response["data"]["title"] == "Test PR"
      assert response["data"]["number"] == 1
      assert response["data"]["status"] == "optimized"
      assert response["data"]["repo_name"] == "test/repo"

      # Verify suggestions are sorted by severity (high -> medium -> low)
      suggestions = response["data"]["suggestions"]
      assert length(suggestions) == 3
      assert Enum.at(suggestions, 0)["id"] == high_suggestion.id
      assert Enum.at(suggestions, 0)["severity"] == "high"
      assert Enum.at(suggestions, 1)["id"] == medium_suggestion.id
      assert Enum.at(suggestions, 1)["severity"] == "medium"
      assert Enum.at(suggestions, 2)["id"] == low_suggestion.id
      assert Enum.at(suggestions, 2)["severity"] == "low"

      # Verify formatted comment
      formatted_comment = response["data"]["formatted_comment"]
      
      # Check for summary section
      assert formatted_comment =~ "## ACE Code Optimization Report"
      assert formatted_comment =~ "Found **3** optimization opportunities:"
      assert formatted_comment =~ "🔴 High: 1"
      assert formatted_comment =~ "🟠 Medium: 1"
      assert formatted_comment =~ "🔵 Low: 1"
      
      # Check for recommendations section
      assert formatted_comment =~ "### Top Recommendations"
      assert formatted_comment =~ "🔴 **Performance Issue**"
      assert formatted_comment =~ "🟠 **Style Improvement**"
      assert formatted_comment =~ "🔵 **Documentation**"
      
      # Check that code examples are included
      assert formatted_comment =~ "IO.puts(\"Hello\")"
      assert formatted_comment =~ "IO.inspect(\"Hello\", label: \"Debug:\")"
      
      # Check for dashboard link
      assert formatted_comment =~ "View full report in ACE dashboard"
      assert formatted_comment =~ AceWeb.Endpoint.url()
    end

    test "formatted comment shows success message when no suggestions", %{conn: conn, pr: pr} do
      # Delete all suggestions
      Repo.delete_all(OptimizationSuggestion)
      
      conn = get(conn, Routes.github_api_path(conn, :show, pr.id))
      response = json_response(conn, 200)

      formatted_comment = response["data"]["formatted_comment"]
      
      # Check for no suggestions message
      assert formatted_comment =~ "## ACE Code Optimization Report"
      assert formatted_comment =~ "✅ No optimization opportunities found for this pull request."
      assert formatted_comment =~ "View in ACE dashboard"
    end
  end
end 