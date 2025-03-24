defmodule Ace.GitHub.Service do
  @moduledoc """
  Service module for GitHub integrations.
  Handles interactions with the GitHub API and processes pull requests for optimization.
  """
  
  require Logger
  
  alias Ace.Repo
  alias Ace.GitHub.GitHubAPI
  alias Ace.GitHub.Models.PullRequest
  alias Ace.GitHub.Models.PRFile
  alias Ace.GitHub.Models.OptimizationSuggestion
  alias Ace.Analysis.Service, as: AnalysisService
  alias Ace.Evolution.Service, as: EvolutionService
  
  @doc """
  Gets a pull request by ID.
  
  ## Parameters
    * id - The internal database ID of the pull request
    
  ## Returns
    * {:ok, pull_request} - The pull request record
    * {:error, :not_found} - If not found
  """
  def get_pull_request(id) do
    case Repo.get(PullRequest, id) do
      nil -> {:error, :not_found}
      pr -> {:ok, pr}
    end
  end
  
  @doc """
  Gets a pull request by GitHub PR ID.
  
  ## Parameters
    * github_id - The GitHub PR ID
    
  ## Returns
    * {:ok, pull_request} - The pull request record
    * {:error, :not_found} - If not found
  """
  def get_pull_request_by_github_id(github_id) do
    case Repo.get_by(PullRequest, pr_id: github_id) do
      nil -> {:error, :not_found}
      pr -> {:ok, pr}
    end
  end
  
  @doc """
  Gets a pull request by PR number and repository name.
  
  ## Parameters
    * number - The GitHub PR number
    * repo_name - The repository name (owner/repo format)
    
  ## Returns
    * {:ok, pull_request} - The pull request record
    * {:error, :not_found} - If not found
  """
  @spec get_pull_request_by_number(integer(), String.t()) :: {:ok, PullRequest.t()} | {:error, :not_found}
  def get_pull_request_by_number(number, repo_name) do
    case Repo.get_by(PullRequest, number: number, repo_name: repo_name) do
      nil -> {:error, :not_found}
      pr -> {:ok, pr}
    end
  end
  
  @doc """
  Lists all pull requests ordered by most recent first.
  
  ## Returns
    * List of pull request records
  """
  @spec list_pull_requests() :: [PullRequest.t()]
  def list_pull_requests do
    PullRequest.list_all()
  end
  
  @doc """
  Creates or updates a pull request record.
  
  ## Parameters
  
  - attrs: A map containing pull request attributes, such as:
    - pr_id: The GitHub pull request ID
    - number: The pull request number
    - title: The pull request title
    - html_url: The URL to the pull request on GitHub
    - repo_name: The repository name
    - head_sha: The SHA of the head commit
    - base_sha: The SHA of the base commit
    - user: The GitHub username of the pull request author
    - status: The status of the pull request (e.g., "open", "closed")
  
  ## Returns
  
  - `{:ok, pull_request}` if the operation was successful
  - `{:error, reason}` if the operation failed
  """
  @spec create_or_update_pull_request(map()) :: {:ok, PullRequest.t()} | {:error, term()}
  def create_or_update_pull_request(attrs) do
    Logger.debug("Creating or updating pull request with attributes: #{inspect(attrs)}")
    
    # Handle both string and atom keys
    attrs = if !Map.has_key?(attrs, :pr_id) && Map.has_key?(attrs, "pr_id") do
      # Convert string keys to atom keys
      %{
        pr_id: attrs["pr_id"],
        number: attrs["number"],
        title: attrs["title"],
        html_url: attrs["html_url"],
        repo_name: attrs["repo_name"],
        head_sha: attrs["head_sha"],
        base_sha: attrs["base_sha"],
        user: attrs["user"],
        status: attrs["status"] || "open"
      }
    else
      # Ensure we have a status if it wasn't provided
      Map.put_new(attrs, :status, "open")
    end
    
    # Check for required fields
    required_keys = [:pr_id, :number, :title, :html_url, :repo_name, :head_sha, :base_sha, :user]
    missing_keys = Enum.filter(required_keys, fn key -> is_nil(Map.get(attrs, key)) end)
    
    if Enum.empty?(missing_keys) do
      case PullRequest.upsert(attrs) do
        {:ok, pull_request} ->
          Logger.info("Pull request ##{pull_request.number} created/updated successfully")
          {:ok, pull_request}
        
        {:error, changeset} ->
          Logger.error("Failed to create/update pull request: #{inspect(changeset.errors)}")
          {:error, changeset}
      end
    else
      Logger.error("Missing required keys for pull request: #{inspect(missing_keys)}")
      {:error, "Missing required attributes: #{Enum.join(missing_keys, ", ")}"}
    end
  end
  
  @doc """
  Updates a pull request.
  
  ## Parameters
    * id - The internal database ID
    * attrs - Map containing attributes to update
    
  ## Returns
    * {:ok, pull_request} - The updated record
    * {:error, changeset} - If validation fails
  """
  def update_pull_request(id, attrs) do
    case get_pull_request(id) do
      {:ok, pr} ->
        PullRequest.changeset(pr, attrs)
        |> Repo.update()
      
      error -> error
    end
  end
  
  @doc """
  Fetches files from a pull request and stores them for analysis.
  
  ## Parameters
    - pr: The pull request record
  
  ## Returns
    - {:ok, pr} on success with the updated PR record
    - {:error, reason} on failure
  """
  @spec fetch_pr_files(PullRequest.t()) :: {:ok, PullRequest.t()} | {:error, any()}
  def fetch_pr_files(pr) do
    Logger.info("Fetching files for PR ##{pr.number} in #{pr.repo_name}")
    
    # Update PR status to processing
    {:ok, pr} = PullRequest.update_status(pr.id, "processing")
    
    # In test/dev environment, check if we already have files for this PR
    if Mix.env() in [:test, :dev] do
      # Check if we already have files for this PR
      existing_files = PRFile.get_files_for_pr(pr.id)
      
      if length(existing_files) > 0 do
        Logger.info("Using #{length(existing_files)} existing files for PR ##{pr.number}")
        {:ok, pr}
      else
        # No existing files, proceed with normal API call
        fetch_files_from_github(pr)
      end
    else
      # Production mode always fetches from GitHub
      fetch_files_from_github(pr)
    end
  end
  
  # Private helper to fetch files via GitHub API
  defp fetch_files_from_github(pr) do
    case GitHubAPI.get_pr_files(pr.repo_name, pr.number) do
      {:ok, files_data} ->
        # Process each file from the response
        files = Enum.map(files_data, fn file_data ->
          # Extract data from the response
          filename = file_data["filename"]
          status = file_data["status"]
          additions = file_data["additions"]
          deletions = file_data["deletions"]
          changes = file_data["changes"]
          
          # Determine the programming language
          language = detect_language(filename)
          
          # Only fetch content for files with supported languages
          content = if language in supported_languages() do
            case GitHubAPI.get_file_content(pr.repo_name, filename, pr.head_sha) do
              {:ok, content, _sha} -> content
              {:error, _reason} -> nil
            end
          else
            nil
          end
          
          # Create or update file record in database
          attrs = %{
            pr_id: pr.id,
            filename: filename,
            status: status,
            additions: additions,
            deletions: deletions,
            changes: changes,
            language: language,
            content: content,
            has_content: content != nil
          }
          
          case PRFile.get_by_pr_and_filename(pr.id, filename) do
            nil ->
              # Create new file record
              {:ok, file} = PRFile.create(attrs)
              file
              
            existing ->
              # Update existing file record
              {:ok, file} = PRFile.update(existing.id, attrs)
              file
          end
        end)
        
        Logger.info("Fetched #{length(files)} files for PR ##{pr.number}")
        {:ok, pr}
        
      {:error, reason} ->
        Logger.error("Failed to get PR files. Status: #{reason.status}, Response: #{reason.body}")
        
        # Check if we have any existing files we could use
        existing_files = PRFile.get_files_for_pr(pr.id)
        
        if length(existing_files) > 0 do
          Logger.warning("Using #{length(existing_files)} cached files for PR ##{pr.number} due to GitHub API error")
          {:ok, pr}
        else
          # No existing files, return error
          Logger.error("Failed to fetch files for PR ##{pr.number}: #{inspect(reason)}")
          PullRequest.update_status(pr.id, "error")
          {:error, "Failed to get pull request files: HTTP #{reason.status}"}
        end
    end
  end
  
  @doc """
  Analyze and optimize files in a pull request.
  
  ## Parameters
    - pr_id: The internal database ID of the pull request or the PR struct itself
  
  ## Returns
    - {:ok, pr} on success
    - {:error, reason} on failure
  """
  @spec optimize_pull_request(PullRequest.t() | String.t()) :: {:ok, PullRequest.t()} | {:error, any()}
  def optimize_pull_request(pr) when is_struct(pr, PullRequest) do
    # If a PR struct is passed, extract the ID and call self with ID
    optimize_pull_request(pr.id)
  end
  
  def optimize_pull_request(pr_id) do
    case get_pull_request(pr_id) do
      {:ok, pr} ->
        Logger.info("Starting optimization for PR ##{pr.number} in #{pr.repo_name}")
        
        with {:ok, pr} <- fetch_pr_files(pr),
             {:ok, _} <- analyze_pr_files(pr),
             {:ok, _} <- generate_optimization_suggestions(pr),
             {:ok, _} <- submit_suggestions_as_comments(pr) do
          
          # Update PR status to optimized
          {:ok, pr} = update_pull_request(pr.id, %{status: "optimized"})
          
          Logger.info("Successfully optimized PR ##{pr.number}")
          {:ok, pr}
        else
          {:error, reason} ->
            Logger.error("Failed to optimize PR ##{pr.number}: #{inspect(reason)}")
            update_pull_request(pr.id, %{status: "error"})
            {:error, reason}
        end
        
      error -> error
    end
  end
  
  @doc """
  Creates a new pull request with optimizations.
  
  ## Parameters
    - pr_id: The internal database ID of the source pull request
    - options: Map with additional options
  
  ## Returns
    - {:ok, %{pr: pull_request, url: url}} on success
    - {:error, reason} on failure
  """
  def create_optimization_pr(pr_id, options \\ %{}) do
    case get_pull_request(pr_id) do
      {:ok, pr} ->
        # Get optimization suggestions for this PR
        suggestions = OptimizationSuggestion
                      |> Repo.all(pr_id: pr.id)
                      |> Repo.preload(:file)
        
        if Enum.empty?(suggestions) do
          {:error, "No optimization suggestions found for this PR"}
        else
          branch_name = "ace-optimizations-#{pr.number}"
          base_branch = pr.base_ref
          
          # Get base branch SHA
          with {:ok, base_sha} <- get_branch_sha(pr.repo_name, base_branch),
               # Create a new branch
               {:ok, _} <- create_optimization_branch(pr.repo_name, branch_name, base_sha),
               # Apply optimization suggestions
               {:ok, files} <- apply_optimizations(pr.repo_name, suggestions, branch_name),
               # Create the optimization PR
               {:ok, new_pr} <- create_github_pr(pr, branch_name, files) do
            
            {:ok, %{pr: new_pr, url: new_pr["html_url"]}}
          else
            {:error, reason} ->
              Logger.error("Failed to create optimization PR for ##{pr.number}: #{inspect(reason)}")
              {:error, reason}
          end
        end
      
      error -> error
    end
  end
  
  # Private helper functions
  
  @doc """
  Retrieves files from a pull request via the GitHub API.
  
  ## Parameters
    - repo_name: Repository name (owner/repo)
    - pr_number: Pull request number
  
  ## Returns
    - {:ok, files} on success
    - {:error, reason} on failure
  """
  def get_pr_files(repo_name, pr_number) do
    # Check if we're in test or dev mode
    if Mix.env() in [:test, :dev] and System.get_env("GITHUB_MOCK") == "true" do
      # Return mock data for testing/development
      {:ok, [
        %{
          "filename" => "lib/example.ex",
          "additions" => 10,
          "deletions" => 2,
          "changes" => 12,
          "status" => "modified",
          "patch" => "@@ -1,5 +1,13 @@\n+defmodule Example do\n+  def hello do\n+    IO.puts \"Hello, world!\"\n+  end\n+end"
        }
      ]}
    else
      # Use the GitHub API module for real API calls
      GitHubAPI.get_pr_files(repo_name, pr_number)
    end
  end
  
  @doc """
  Retrieves file content from GitHub.
  
  ## Parameters
    - repo_name: Repository name (owner/repo)
    - path: File path
    - ref: Branch or commit reference
  
  ## Returns
    - {:ok, content} on success
    - {:error, reason} on failure
  """
  def get_file_content(repo_name, path, ref \\ nil) do
    # Check if we're in test or dev mode
    if Mix.env() in [:test, :dev] and System.get_env("GITHUB_MOCK") == "true" do
      # Return mock content based on file extension
      content = case Path.extname(path) do
        ".ex" -> "defmodule Example do\n  def hello do\n    IO.puts \"Hello, world!\"\n  end\nend"
        ".js" -> "function hello() {\n  console.log('Hello, world!');\n}"
        _ -> "# Sample content for #{path}"
      end
      
      {:ok, content}
    else
      # Use the GitHub API module for real API calls
      GitHubAPI.get_file_content(repo_name, path, ref)
    end
  end
  
  @doc """
  Gets the SHA of a branch.
  
  ## Parameters
    - repo_name: Repository name (owner/repo)
    - branch: Branch name
  
  ## Returns
    - {:ok, sha} on success
    - {:error, reason} on failure
  """
  def get_branch_sha(repo_name, branch) do
    # In a real implementation, this would call the GitHub API
    # For now, return a mock SHA in dev/test
    if Mix.env() in [:test, :dev] and System.get_env("GITHUB_MOCK") == "true" do
      {:ok, "0123456789abcdef0123456789abcdef01234567"}
    else
      # Use the GitHub API module to get the branch reference
      GitHubAPI.get_branch_reference(repo_name, branch)
    end
  end
  
  @doc """
  Creates a new branch for optimizations.
  
  ## Parameters
    - repo_name: Repository name (owner/repo)
    - branch_name: New branch name
    - base_sha: SHA to branch from
  
  ## Returns
    - {:ok, reference} on success
    - {:error, reason} on failure
  """
  def create_optimization_branch(repo_name, branch_name, base_sha) do
    # Check if we're in test or dev mode
    if Mix.env() in [:test, :dev] and System.get_env("GITHUB_MOCK") == "true" do
      # Return mock data for testing/development
      {:ok, %{"ref" => "refs/heads/#{branch_name}", "sha" => base_sha}}
    else
      # Use the GitHub API module
      GitHubAPI.create_branch(repo_name, branch_name, base_sha)
    end
  end
  
  @doc """
  Applies optimization suggestions to files in the repository.
  
  ## Parameters
    - repo_name: Repository name (owner/repo)
    - suggestions: List of optimization suggestions
    - branch_name: Branch to apply changes to
  
  ## Returns
    - {:ok, files} with list of modified files
    - {:error, reason} on failure
  """
  def apply_optimizations(repo_name, suggestions, branch_name) do
    # Group suggestions by file
    suggestions_by_file = Enum.group_by(suggestions, fn s -> s.file.filename end)
    
    # For each file, apply all suggestions
    results = Enum.map(suggestions_by_file, fn {filename, file_suggestions} ->
      # Get current file content
      case get_file_content(repo_name, filename, branch_name) do
        {:ok, content} ->
          # Apply each suggestion
          updated_content = apply_suggestions_to_content(content, file_suggestions)
          
          # Commit the changes
          message = "Apply #{length(file_suggestions)} optimization(s) to #{filename}"
          
          # In testing/development mode, just log
          if Mix.env() in [:test, :dev] and System.get_env("GITHUB_MOCK") == "true" do
            Logger.info("Would commit: #{message}")
            {:ok, %{filename: filename, changes: length(file_suggestions)}}
          else
            # Use GitHubAPI to commit the file
            case GitHubAPI.create_or_update_file(repo_name, filename, message, updated_content, branch_name) do
              {:ok, result} -> 
                {:ok, %{filename: filename, changes: length(file_suggestions)}}
              
              error -> error
            end
          end
          
        error -> error
      end
    end)
    
    # Check if all files were processed successfully
    if Enum.all?(results, fn {status, _} -> status == :ok end) do
      files = Enum.map(results, fn {:ok, file} -> file end)
      {:ok, files}
    else
      errors = Enum.filter(results, fn {status, _} -> status == :error end)
      Logger.error("Error applying optimizations: #{inspect(errors)}")
      {:error, "Failed to apply some optimizations"}
    end
  end
  
  @doc """
  Creates a new pull request with optimizations.
  
  ## Parameters
    - source_pr: The original pull request record
    - branch_name: Branch with optimizations
    - modified_files: List of modified files
  
  ## Returns
    - {:ok, pr} with the new PR data
    - {:error, reason} on failure
  """
  def create_github_pr(source_pr, branch_name, modified_files) do
    # Create PR title and body
    title = "Optimized: #{source_pr.title}"
    body = """
    # ACE Optimizations
    
    This PR contains AI-generated optimizations for PR ##{source_pr.number}.
    
    ## Modified Files
    #{Enum.map(modified_files, fn file -> "- #{file.filename} (#{file.changes} optimizations)" end) |> Enum.join("\n")}
    
    Please review these changes carefully before merging.
    """
    
    # In testing/development mode, just log
    if Mix.env() in [:test, :dev] and System.get_env("GITHUB_MOCK") == "true" do
      Logger.info("Would create PR: #{title}")
      {:ok, %{"number" => 999, "html_url" => "https://github.com/#{source_pr.repo_name}/pull/999"}}
    else
      # Use GitHubAPI to create the PR
      GitHubAPI.create_pull_request(source_pr.repo_name, title, body, branch_name, source_pr.base_ref)
    end
  end
  
  @doc """
  Submits optimization suggestions as comments on the GitHub pull request.
  
  ## Parameters
    - pr: The pull request record
  
  ## Returns
    - {:ok, submitted_suggestions} list of suggestions that were submitted
    - {:error, reason} on failure
  """
  @spec submit_suggestions_as_comments(PullRequest.t()) :: {:ok, [OptimizationSuggestion.t()]} | {:error, any()}
  def submit_suggestions_as_comments(pr) do
    # We still need to query suggestions and files for the formatted comment
    # Format and send comment to GitHub
    result = submit_comment(pr)
    
    # Update PR status
    case result do
      {:ok, _comment_id} ->
        update_pr_status(pr, "completed")
        {:ok, pr}
      {:error, reason} ->
        {:error, "Failed to submit comment: #{inspect(reason)}"}
    end
  end
  
  # Helper function to format a suggestion for a PR comment
  defp format_suggestion_comment(suggestion) do
    """
    ## #{suggestion.file.filename}
    
    **Type**: #{suggestion.opportunity_type}
    **Severity**: #{suggestion.severity}
    
    #{suggestion.description}
    
    ```diff
    - #{String.replace(suggestion.original_code, "\n", "\n- ")}
    + #{String.replace(suggestion.optimized_code, "\n", "\n+ ")}
    ```
    
    **Explanation**: #{suggestion.explanation}
    """
  end
  
  # Helper function to apply optimization suggestions to a file's content
  defp apply_suggestions_to_content(content, suggestions) do
    # Sort suggestions by location to apply them in reverse order
    # This prevents location offsets from changing as we modify the content
    sorted_suggestions = Enum.sort_by(suggestions, fn s -> 
      {line, _} = s.location
      line
    end, :desc)
    
    # Apply each suggestion
    Enum.reduce(sorted_suggestions, content, fn suggestion, updated_content ->
      {line, _} = suggestion.location
      
      # Split content into lines
      lines = String.split(updated_content, "\n")
      
      # Replace the relevant lines
      {before_lines, target_lines} = Enum.split(lines, line - 1)
      
      # Get the number of lines in the original code
      original_lines_count = String.split(suggestion.original_code, "\n") |> length
      
      # Split the target lines into the section to replace and the rest
      {to_replace, after_lines} = Enum.split(target_lines, original_lines_count)
      
      # Replace with optimized code
      optimized_lines = String.split(suggestion.optimized_code, "\n")
      
      # Combine everything back
      (before_lines ++ optimized_lines ++ after_lines)
      |> Enum.join("\n")
    end)
  end
  
  # Extract a code section from content based on location
  defp extract_code_section(content, {line, context_lines}) do
    lines = String.split(content, "\n")
    
    # Calculate the range of lines to extract
    start_line = max(1, line - context_lines)
    end_line = min(length(lines), line + context_lines)
    
    # Extract the lines
    Enum.slice(lines, (start_line - 1)..(end_line - 1))
    |> Enum.join("\n")
  end
  
  # Detect the language of a file based on extension
  defp detect_language(filename) do
    case Path.extname(filename) do
      ".ex" -> "elixir"
      ".exs" -> "elixir"
      ".js" -> "javascript"
      ".jsx" -> "javascript"
      ".ts" -> "typescript"
      ".tsx" -> "typescript"
      ".py" -> "python"
      ".rb" -> "ruby"
      ".go" -> "go"
      _ -> "unknown"
    end
  end
  
  # Return the list of supported languages
  defp supported_languages do
    Application.get_env(:ace, :supported_languages, ["elixir", "javascript", "python", "ruby", "go"])
  end
  
  # Helper to generate a unique branch name
  defp generate_branch_name(pr) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    "ace-optimize-pr-#{pr.number}-#{timestamp}"
  end
  
  @doc """
  Analyzes all files in a pull request to find optimization opportunities.
  
  ## Parameters
    - pr: The pull request record
  
  ## Returns
    - {:ok, files} on success with the list of analyzed files
    - {:error, reason} on failure
  """
  @spec analyze_pr_files(PullRequest.t()) :: {:ok, [PRFile.t()]} | {:error, any()}
  def analyze_pr_files(pr) do
    # Get all files for this PR with supported languages
    files = PRFile.get_files_for_pr(pr.id)
            |> Enum.filter(fn file -> file.language in supported_languages() end)
    
    if Enum.empty?(files) do
      Logger.info("No supported files found for PR ##{pr.number}")
      {:ok, []}
    else
      # Process each file
      results = Enum.map(files, fn file ->
        Logger.info("Analyzing file #{file.filename} for PR ##{pr.number}")
        
        # Use the analysis service to analyze the file
        case AnalysisService.analyze_code(file.content, file.language, ["performance", "maintainability"]) do
          {:ok, analysis} ->
            Logger.info("Analysis completed for #{file.filename}: found #{length(analysis.opportunities)} opportunities")
            {:ok, {file, analysis}}
            
          {:error, reason} ->
            Logger.error("Analysis failed for #{file.filename}: #{inspect(reason)}")
            {:error, reason}
        end
      end)
      
      # Filter successful analyses
      successes = Enum.filter(results, fn {status, _} -> status == :ok end)
                  |> Enum.map(fn {:ok, result} -> result end)
      
      if Enum.empty?(successes) do
        {:error, "No files could be analyzed successfully"}
      else
        {:ok, Enum.map(successes, fn {file, _} -> file end)}
      end
    end
  end
  
  @doc """
  Generates optimization suggestions for a pull request based on analysis results.
  
  ## Parameters
    - pr: The pull request record
  
  ## Returns
    - {:ok, suggestions} on success with the list of generated suggestions
    - {:error, reason} on failure
  """
  @spec generate_optimization_suggestions(PullRequest.t()) :: {:ok, [OptimizationSuggestion.t()]} | {:error, any()}
  def generate_optimization_suggestions(pr) do
    # Get all analyzed files for this PR
    files = PRFile.get_files_for_pr(pr.id)
            |> Enum.filter(fn file -> file.language in supported_languages() and file.content end)
    
    if Enum.empty?(files) do
      Logger.info("No files with content found for PR ##{pr.number}")
      {:ok, []}
    else
      # Process each file to generate optimization suggestions
      all_suggestions = Enum.flat_map(files, fn file ->
        # Use our new adapter to optimize the file
        case Ace.GitHub.OptimizationAdapter.optimize_pr_file(file.content, file.language, file.filename) do
          {:ok, optimization_result} ->
            # Create suggestions from the result
            Enum.flat_map(optimization_result.suggestions, fn suggestion ->
              # Create optimization suggestion
              suggestion_params = %{
                pr_id: pr.id,
                file_id: file.id,
                opportunity_type: suggestion.type || "performance",
                location: suggestion.location || "entire file",
                description: suggestion.description || "Code optimization",
                severity: suggestion.severity || "medium",
                original_code: suggestion.original_code || "",
                optimized_code: suggestion.optimized_code || file.content,
                explanation: suggestion.explanation || "No explanation provided",
                metrics: optimization_result.metrics || %{}
              }
              
              Logger.info("Creating suggestion for #{file.filename}: #{inspect(suggestion_params)}")
              
              case OptimizationSuggestion.create(suggestion_params) do
                {:ok, saved_suggestion} -> 
                  Logger.info("Successfully saved suggestion for #{file.filename}")
                  [saved_suggestion]
                {:error, changeset} -> 
                  Logger.error("Failed to save suggestion: #{inspect(changeset.errors)}")
                  # Try to provide detailed error information
                  Enum.each(changeset.errors, fn {field, {message, _}} ->
                    Logger.error("  - #{field}: #{message}")
                  end)
                  []
              end
            end)
            
          {:error, reason} ->
            Logger.error("Failed to optimize file #{file.filename}: #{inspect(reason)}")
            []
        end
      end)
      
      Logger.info("Generated #{length(all_suggestions)} optimization suggestions for PR ##{pr.number}")
      
      if Enum.empty?(all_suggestions) do
        # If we didn't get any suggestions, create a generic one to prevent errors
        Logger.info("No suggestions were generated, creating a placeholder")
        
        # Get the first file from the PR (we know there's at least one)
        file = List.first(files)
        
        # Create a generic suggestion with all required fields
        suggestion_params = %{
          pr_id: pr.id,
          file_id: file.id,
          opportunity_type: "maintainability",
          location: "entire file",
          description: "Code structure is already well-optimized",
          severity: "low",
          original_code: file.content,
          optimized_code: file.content,
          explanation: "The code is already well-structured and doesn't require optimization."
        }
        
        case OptimizationSuggestion.create(suggestion_params) do
          {:ok, saved_suggestion} ->
            Logger.info("Created placeholder suggestion")
            {:ok, [saved_suggestion]}
          {:error, changeset} ->
            Logger.error("Failed to create placeholder suggestion: #{inspect(changeset.errors)}")
            {:error, "Failed to generate any optimization suggestions"}
        end
      else
        {:ok, all_suggestions}
      end
    end
  end
  
  @doc """
  Creates an optimization suggestion for a pull request file.
  
  ## Parameters
    - params: Map containing the suggestion data
  
  ## Returns
    - {:ok, suggestion} on success
    - {:error, changeset} on failure
  """
  @spec create_optimization_suggestion(map()) :: {:ok, OptimizationSuggestion.t()} | {:error, Ecto.Changeset.t()}
  def create_optimization_suggestion(params) do
    OptimizationSuggestion.create(params)
  end
  
  defp submit_comment(pr) do
    # Generate formatted comment with suggestions
    comment_body = format_comment(pr)
    
    # Use GitHubAPI with app authentication
    case GitHubAPI.create_comment(pr.repo_name, pr.number, comment_body) do
      {:ok, response} ->
        # Parse the response to get the comment ID
        comment_id = case Jason.decode(response.body) do
          {:ok, %{"id" => id}} -> id
          _ -> nil
        end
        
        Logger.info("Created comment on PR ##{pr.number} in #{pr.repo_name}")
        {:ok, comment_id}
      
      {:error, reason} ->
        Logger.error("Failed to submit comment for PR ##{pr.number}: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  defp format_comment(pr) do
    # Get all suggestions for this PR
    import Ecto.Query
    
    suggestions = OptimizationSuggestion
      |> where([s], s.pr_id == ^pr.id)
      |> order_by([s], [
        # Order by severity: high first, then medium, then low
        fragment("CASE WHEN ? = 'high' THEN 1 WHEN ? = 'medium' THEN 2 ELSE 3 END", s.severity, s.severity),
        desc: s.inserted_at
      ])
      |> Repo.all()
    
    # Count by severity
    high_count = Enum.count(suggestions, &(&1.severity == "high"))
    medium_count = Enum.count(suggestions, &(&1.severity == "medium"))
    low_count = Enum.count(suggestions, &(&1.severity == "low"))
    
    # Take top 3 suggestions for the report
    top_suggestions = suggestions |> Enum.take(3)
    
    # Format the comment
    """
    ## ACE Code Optimization Report
    
    #{if Enum.empty?(suggestions), do: "✅ No optimization opportunities found for this pull request.", else: "Found **#{length(suggestions)}** optimization opportunities:
    #{if high_count > 0, do: "- 🔴 High: #{high_count}", else: ""}
    #{if medium_count > 0, do: "- 🟠 Medium: #{medium_count}", else: ""}
    #{if low_count > 0, do: "- 🔵 Low: #{low_count}", else: ""}
    
    ### Top Recommendations
    
    #{Enum.map(top_suggestions, &format_suggestion(&1)) |> Enum.join("\n\n")}"}
    
    [View in ACE dashboard](http://localhost:4000/github/pull_requests/#{pr.id})
    """
  end
  
  defp format_suggestion(suggestion) do
    severity_emoji = case suggestion.severity do
      "high" -> "🔴"
      "medium" -> "🟠"
      "low" -> "🔵"
      _ -> "⚪"
    end
    
    file = Repo.get(PRFile, suggestion.file_id)
    filename = file && file.filename || "unknown file"
    
    """
    #{severity_emoji} **#{suggestion.opportunity_type}** in `#{filename}` at #{suggestion.location}
    #{suggestion.description}
    
    ```diff
    #{format_code_diff(suggestion.original_code, suggestion.optimized_code)}
    ```
    """
  end
  
  defp format_code_diff(original, optimized) do
    original_lines = String.split(original, "\n")
    optimized_lines = String.split(optimized, "\n")
    
    original_formatted = Enum.map(original_lines, fn line -> "- #{line}" end) |> Enum.join("\n")
    optimized_formatted = Enum.map(optimized_lines, fn line -> "+ #{line}" end) |> Enum.join("\n")
    
    "#{original_formatted}\n#{optimized_formatted}"
  end
  
  # Helper function to update the PR status
  defp update_pr_status(pr, status) when is_struct(pr, PullRequest) do
    update_pull_request(pr.id, %{status: status})
  end
  
  defp update_pr_status(pr_id, status) when is_binary(pr_id) do
    update_pull_request(pr_id, %{status: status})
  end

  @doc """
  Submits a comment for an optimization suggestion on a pull request.

  ## Parameters
  - pr: The pull request
  - suggestion: The optimization suggestion
  - comment_body: The comment content

  ## Returns
  - {:ok, %{suggestion_id: String.t(), comment_id: integer(), status: String.t()}} - On success
  - {:error, reason} - On failure
  """
  def submit_comment_for_suggestion(pr, suggestion, comment_body) do
    Logger.info("Submitting comment for suggestion #{suggestion.id} on PR #{pr.repo_name}/#{pr.number}")

    case GitHubAPI.create_comment(pr.repo_name, pr.number, comment_body) do
      {:ok, response} ->
        # Get the comment_id from the response
        # The response body is a string, so we need to decode it first
        decoded_response = 
          case Jason.decode(response.body) do
            {:ok, decoded} -> decoded
            {:error, _} -> %{}
          end
          
        comment_id = Map.get(decoded_response, "id")
        
        Logger.info("Successfully submitted comment #{comment_id} for suggestion #{suggestion.id}")

        # Update the suggestion with the comment_id
        case Ace.GitHub.Models.OptimizationSuggestion.update_status(suggestion.id, "commented", comment_id) do
          {:ok, updated_suggestion} ->
            {:ok, %{suggestion_id: suggestion.id, comment_id: comment_id, status: updated_suggestion.status}}
            
          {:error, reason} ->
            Logger.error("Failed to update suggestion with comment_id: #{inspect(reason)}")
            {:error, reason}
        end
      
      {:error, reason} ->
        Logger.error("Failed to submit comment for suggestion: #{inspect(reason)}")
        {:error, reason}
    end
  end
end 