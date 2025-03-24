# Debug script for testing file-specific optimization workflow
# Usage: mix run debug_webhook_real_files.exs

alias Ace.GitHub.Service
alias Ace.GitHub.Models.PullRequest
alias Ace.GitHub.Models.PRFile
alias Ace.Infrastructure.AI.CodeOptimizer

defmodule PRTestOptimization do
  def run do
    IO.puts("Testing file-specific optimization workflow...")
    
    # Create a unique ID based on system time
    unique_id = System.system_time(:second)
    
    # Define a test PR
    pr = %{
      id: "test-optimization-pr-#{unique_id}",
      pr_id: 12345678,
      number: 456,
      title: "Test Optimization PR",
      repo_name: "jmanhype/synaflow",
      html_url: "https://github.com/jmanhype/synaflow/pull/456",
      user: "test-user",
      head_sha: "current-sha-#{unique_id}",
      base_sha: "base-sha-#{unique_id}",
      status: "pending"
    }
    
    # File paths to optimize
    file_paths = [
      "demo_code/scientific_qa.py",
      "demo_code/synaflow_api.js"
    ]
    
    # Create or update the PR in the database
    IO.puts("Creating PR in the database...")
    IO.puts("PR Attrs for create_or_update: #{inspect(pr)}")
    {:ok, pr_record} = Service.create_or_update_pull_request(pr)
    IO.puts("Successfully created/updated PR with ID: #{pr_record.id}")
    IO.puts("PR created with ID: #{pr_record.id}")
    
    # Read files from disk
    IO.puts("\nReading files from disk...")
    
    files = [
      %{filename: "demo_code/scientific_qa.py", path: "demo_code/scientific_qa.py"},
      %{filename: "demo_code/synaflow_api.js", path: "demo_code/synaflow_api.js"}
    ]
    
    # Read the files
    file_contents = Enum.map(files, fn file ->
      case File.read(file.path) do
        {:ok, content} ->
          IO.puts("Successfully read file: #{file.filename}")
          Map.put(file, :content, content)
        {:error, reason} ->
          IO.puts("Error reading file #{file.filename}: #{reason}")
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    
    # Save files to PR
    IO.puts("\nSaving files to the PR...")
    
    files_with_language = Enum.map(file_contents, fn file ->
      # Detect language from file extension
      language = case Path.extname(file.filename) do
        ".py" -> "python"
        ".js" -> "javascript"
        ".rb" -> "ruby"
        ".ex" -> "elixir"
        ".exs" -> "elixir"
        ".go" -> "go"
        ".java" -> "java"
        ".php" -> "php"
        ".cs" -> "csharp"
        ".ts" -> "typescript"
        ".html" -> "html"
        ".css" -> "css"
        ".json" -> "json"
        ".md" -> "markdown"
        ".sql" -> "sql"
        ".sh" -> "shell"
        _ -> nil
      end
      
      Map.put(file, :language, language)
    end)
    
    Enum.each(files_with_language, fn file ->
      attrs = %{
        pr_id: pr_record.id,
        filename: file.filename,
        content: file.content,
        language: file.language,
        status: "modified",
        additions: String.split(file.content, "\n") |> length(),
        deletions: 0,
        changes: String.split(file.content, "\n") |> length()
      }
      
      case PRFile.upsert(attrs) do
        {:ok, _file} -> IO.puts("Saved file #{file.filename} to PR")
        {:error, changeset} -> IO.puts("Error saving file #{file.filename}: #{inspect(changeset.errors)}")
      end
    end)
    
    # Optimize files
    IO.puts("\nOptimizing files...")
    optimization_results = Enum.map(files_with_language, fn file ->
      # Determine file type based on extension
      file_type = case Path.extname(file.filename) do
        ".py" -> "python"
        ".js" -> "javascript"
        extension -> "unknown:#{extension}"
      end
      
      IO.puts("Optimizing #{file.filename} as #{file_type}...")
      
      # Call optimizing function with language
      case CodeOptimizer.optimize_code(file.content, %{
        filename: file.filename,
        language: file_type
      }) do
        {:ok, result} ->
          IO.puts("Successfully optimized #{file.filename}")
          %{
            file: file,
            result: result,
            optimization_suggestions: Enum.map(result.suggestions, fn sugg ->
              %{
                pr_id: pr_record.id,
                file_id: nil, # We'll set this after retrieving the file record
                opportunity_type: sugg.type || "performance",
                location: sugg.location || "unknown",
                description: sugg.description,
                severity: sugg.severity || "medium",
                original_code: sugg.original_code,
                optimized_code: sugg.optimized_code,
                explanation: sugg.explanation
              }
            end)
          }
        {:error, reason} ->
          IO.puts("Error optimizing #{file.filename}: #{reason}")
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    
    # Retrieve file records to get their IDs
    IO.puts("\nRetrieving PR file records...")
    Enum.each(optimization_results, fn result ->
      case PRFile.get_by_pr_and_filename(pr_record.id, result.file.filename) do
        nil -> 
          IO.puts("Error: Could not find file record for #{result.file.filename}")
        file_record ->
          IO.puts("Found file record for #{file_record.filename} with ID: #{file_record.id}")
          
          # Update optimization suggestions with file ID
          suggestions = Enum.map(result.optimization_suggestions, fn sugg ->
            Map.put(sugg, :file_id, file_record.id)
          end)
          
          # Save optimization suggestions
          IO.puts("\nSaving optimization suggestions...")
          Enum.each(suggestions, fn suggestion ->
            case Service.create_optimization_suggestion(suggestion) do
              {:ok, saved_suggestion} ->
                IO.puts("Saved optimization suggestion: #{saved_suggestion.id}")
              {:error, changeset} ->
                IO.puts("Error saving suggestion: #{inspect(changeset.errors)}")
            end
          end)
      end
    end)
    
    IO.puts("\nTest completed!")
  end
end

PRTestOptimization.run() 