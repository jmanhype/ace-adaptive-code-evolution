# Script to seed database with sample GitHub pull requests
alias Ace.Repo
alias Ace.GitHub.PullRequest
alias Ace.GitHub.PRFile

# Start the application (not needed if run with mix run)
Application.ensure_all_started(:ace)

# Delete existing records
IO.puts("Deleting existing pull requests...")
Repo.delete_all("pr_files")
Repo.delete_all("pull_requests")

# Function to create a pull request with associated files
defmodule SeedHelper do
  def create_pull_request(attrs) do
    default_attrs = %{
      head_sha: "abc123def456", # Add a default head_sha 
      base_sha: "zzz999yyy888"  # Add a default base_sha
    }
    
    attrs = Map.merge(default_attrs, attrs)
    
    case Ace.GitHub.PullRequest.changeset(%PullRequest{}, attrs) |> Repo.insert() do
      {:ok, pr} ->
        # If files are provided, create them
        if Map.has_key?(attrs, :files) do
          Enum.each(attrs.files, fn file_attrs ->
            %PRFile{}
            |> PRFile.changeset(Map.put(file_attrs, :pr_id, pr.id))
            |> Repo.insert()
          end)
        end
        
        pr
        
      {:error, changeset} ->
        IO.inspect(changeset)
        raise "Failed to create pull request"
    end
  end
end

# Create sample pull requests
IO.puts("Creating sample pull requests...")

# PR 1 - Pending optimization
pr1 = SeedHelper.create_pull_request(%{
  pr_id: 12345,
  repo_name: "acme/backend-service",
  number: 123,
  title: "Add user profile API",
  html_url: "https://github.com/acme/backend-service/pull/123",
  user: "johndoe",
  status: "pending",
  files: [
    %{
      filename: "lib/api/user_profile.ex",
      patch_content: "@@ -1,5 +1,15 @@\ndefmodule Api.UserProfile do\n  @moduledoc \"\"\"\n  User profile API\n  \"\"\"\n+  \n+  def get_profile(user_id) do\n+    User\n+    |> where([u], u.id == ^user_id)\n+    |> Repo.one()\n+    |> case do\n+      nil -> {:error, :not_found}\n+      user -> {:ok, format_profile(user)}\n+    end\n+  end\nend",
      additions: 10,
      deletions: 0,
      language: "elixir"
    },
    %{
      filename: "test/api/user_profile_test.ex",
      patch_content: "@@ -0,0 +1,15 @@\ndefmodule Api.UserProfileTest do\n  use ExUnit.Case\n  \n  test \"get_profile returns user data\" do\n    assert {:ok, profile} = Api.UserProfile.get_profile(1)\n    assert profile.name == \"John Doe\"\n  end\n  \n  test \"get_profile returns error for invalid id\" do\n    assert {:error, :not_found} = Api.UserProfile.get_profile(999)\n  end\nend",
      additions: 15,
      deletions: 0,
      language: "elixir"
    }
  ]
})

# PR 2 - Processing
pr2 = SeedHelper.create_pull_request(%{
  pr_id: 12346,
  repo_name: "acme/web-client",
  number: 45,
  title: "Improve page load performance",
  html_url: "https://github.com/acme/web-client/pull/45",
  user: "janedoe",
  status: "processing",
  files: [
    %{
      filename: "src/components/Dashboard.js",
      patch_content: "@@ -15,10 +15,7 @@\n  const Dashboard = () => {\n-  const [data, setData] = useState(null);\n-  const [loading, setLoading] = useState(true);\n-  const [error, setError] = useState(null);\n-  \n+  const [data, setData, loading, setLoading, error, setError] = useApiData('/api/dashboard');\n  \n   useEffect(() => {\n-    fetchDashboardData();\n+    // Data loading handled by custom hook\n   }, []);\n",
      additions: 2,
      deletions: 5,
      language: "javascript"
    }
  ]
})

# PR 3 - Optimized
pr3 = SeedHelper.create_pull_request(%{
  pr_id: 12347,
  repo_name: "acme/data-processor",
  number: 78,
  title: "Refactor data pipeline for better throughput",
  html_url: "https://github.com/acme/data-processor/pull/78",
  user: "samsmith",
  status: "optimized",
  files: [
    %{
      filename: "lib/pipeline/processor.ex",
      patch_content: "@@ -25,15 +25,8 @@\n  def process_batch(records) do\n-    results = Enum.map(records, fn record ->\n-      record\n-      |> validate()\n-      |> transform()\n-      |> save()\n-    end)\n-    \n-    {\n-      :ok,\n-      Enum.filter(results, fn {status, _} -> status == :ok end)\n-    }\n+    results = Task.async_stream(records, &process_record/1, max_concurrency: 10)\n+    |> Enum.filter(fn {status, _} -> status == :ok end)\n+    {:ok, results}\n   end\n",
      additions: 3,
      deletions: 10,
      language: "elixir"
    }
  ]
})

IO.puts("Created #{length([pr1, pr2, pr3])} pull requests")
IO.puts("Done!") 