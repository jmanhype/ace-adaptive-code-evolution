defmodule Ace.Integrations.GitHub.PRAnalyzer do
  @moduledoc """
  Analyzes GitHub pull requests for code improvement opportunities.
  
  This module takes GitHub PR data, extracts the changed files,
  performs analysis using Ace's core functionality, and formats
  the results for GitHub comments/reviews.
  """
  
  require Logger
  alias Ace.Integrations.GitHub.APIClient
  alias Ace.Integrations.GitHub.CommentFormatter
  
  @doc """
  Analyze a pull request for optimization opportunities.
  
  ## Parameters
  
    * `installation_id` - GitHub App installation ID
    * `repo` - Repository data from webhook
    * `pr` - Pull request data from webhook
  
  ## Returns
  
    * `{:ok, analysis_id}` - Analysis scheduled/completed successfully
    * `{:error, reason}` - Analysis failed
  """
  @spec analyze_pull_request(integer(), map(), map()) :: {:ok, String.t()} | {:error, atom() | String.t()}
  def analyze_pull_request(installation_id, repo, pr) do
    repo_full_name = repo["full_name"]
    pr_number = pr["number"]
    
    Logger.info("Starting analysis of PR ##{pr_number} in #{repo_full_name}")
    
    # Generate a unique analysis ID
    analysis_id = generate_analysis_id(repo_full_name, pr_number)
    
    # This would typically be done in a background job
    # For this implementation, we'll do it synchronously
    try do
      # 1. Get the list of changed files
      case APIClient.get_pull_request_files(installation_id, repo_full_name, pr_number) do
        {:ok, files} ->
          Logger.info("Found #{length(files)} changed files in PR ##{pr_number}")
          
          # 2. Filter files based on configuration and supported types
          filtered_files = filter_files_for_analysis(files, load_repo_config(installation_id, repo_full_name, pr))
          
          # 3. Process each file and generate analysis
          with {:ok, analysis_results} <- analyze_files(installation_id, repo_full_name, filtered_files, pr),
               {:ok, _comment_id} <- post_analysis_results(installation_id, repo_full_name, pr_number, analysis_results) do
            
            # 4. Store analysis results for later reference (optional)
            # save_analysis_results(analysis_id, analysis_results)
            
            Logger.info("Successfully completed analysis #{analysis_id}")
            {:ok, analysis_id}
          else
            {:error, reason} ->
              Logger.error("Analysis failed: #{inspect(reason)}")
              {:error, reason}
          end
        
        {:error, reason} ->
          Logger.error("Failed to get PR files: #{inspect(reason)}")
          {:error, reason}
      end
    rescue
      e ->
        Logger.error("Unexpected error analyzing PR: #{inspect(e)}")
        {:error, :analysis_error}
    end
  end
  
  @doc """
  Analyze a specific file for improvement opportunities.
  
  ## Parameters
  
    * `installation_id` - GitHub App installation ID
    * `repo_full_name` - Repository name with owner
    * `file` - File data from GitHub API
    * `pr` - Pull request data
  
  ## Returns
  
    * `{:ok, results}` - Analysis results
    * `{:error, reason}` - Analysis failed
  """
  @spec analyze_file(integer(), String.t(), map(), map()) :: {:ok, map()} | {:error, atom() | String.t()}
  def analyze_file(installation_id, repo_full_name, file, pr) do
    path = file["filename"]
    Logger.info("Analyzing file: #{path}")
    
    # Get file content
    head_sha = pr["head"]["sha"]
    
    case APIClient.get_file_content(installation_id, repo_full_name, path, head_sha) do
      {:ok, content, _} ->
        # Determine the language based on file extension
        language = detect_language(path)
        
        # Perform analysis using Ace's core functionality
        # This is a placeholder - replace with actual analysis call
        case analyze_code(content, language, path) do
          {:ok, opportunities} ->
            file_result = %{
              path: path,
              language: language,
              opportunities: opportunities
            }
            {:ok, file_result}
            
          {:error, reason} ->
            Logger.error("Failed to analyze #{path}: #{inspect(reason)}")
            {:error, reason}
        end
        
      {:error, reason} ->
        Logger.error("Failed to get content for #{path}: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  # Private functions
  
  defp generate_analysis_id(repo_full_name, pr_number) do
    timestamp = System.system_time(:second)
    "#{repo_full_name}##{pr_number}_#{timestamp}"
  end
  
  defp filter_files_for_analysis(files, config) do
    # Skip files that are not supported or excluded by config
    Enum.filter(files, fn file ->
      path = file["filename"]
      
      # Check if file type is supported
      supported_language = detect_language(path) != :unknown
      
      # Check if path is excluded by patterns in config
      not_excluded = not Enum.any?(config.exclude_patterns, fn pattern ->
        String.match?(path, ~r/#{pattern}/)
      end)
      
      supported_language and not_excluded
    end)
  end
  
  defp detect_language(path) do
    cond do
      String.ends_with?(path, ".ex") -> :elixir
      String.ends_with?(path, ".exs") -> :elixir
      String.ends_with?(path, ".erl") -> :erlang
      String.ends_with?(path, ".js") -> :javascript
      String.ends_with?(path, ".ts") -> :typescript
      String.ends_with?(path, ".jsx") -> :javascript
      String.ends_with?(path, ".tsx") -> :typescript
      String.ends_with?(path, ".py") -> :python
      String.ends_with?(path, ".rb") -> :ruby
      String.ends_with?(path, ".go") -> :go
      String.ends_with?(path, ".rs") -> :rust
      String.ends_with?(path, ".java") -> :java
      String.ends_with?(path, ".kt") -> :kotlin
      String.ends_with?(path, ".php") -> :php
      true -> :unknown
    end
  end
  
  defp load_repo_config(installation_id, repo_full_name, pr) do
    # Try to load .ace-config.json from the repository
    # Fall back to default settings if not found
    
    # Default configuration
    default_config = %{
      exclude_patterns: [
        "^test/",
        "^docs/",
        "\\.md$",
        "\\.txt$",
        "\\.json$",
        "\\.yaml$",
        "\\.yml$"
      ],
      severity_threshold: "suggestion",
      max_comments_per_file: 10,
      max_total_comments: 30
    }
    
    # Try to load custom config from repo
    case APIClient.get_file_content(installation_id, repo_full_name, ".ace-config.json", pr["head"]["sha"]) do
      {:ok, content, _} ->
        case Jason.decode(content) do
          {:ok, custom_config} ->
            # Merge with default config, with custom taking precedence
            Map.merge(default_config, custom_config)
            
          {:error, _} ->
            Logger.warn("Invalid .ace-config.json format, using default config")
            default_config
        end
        
      {:error, _} ->
        # Config file not found, use default
        Logger.info("No .ace-config.json found, using default config")
        default_config
    end
  end
  
  defp analyze_files(installation_id, repo_full_name, files, pr) do
    # Analyze each file and collect results
    results = Enum.reduce_while(files, [], fn file, acc ->
      case analyze_file(installation_id, repo_full_name, file, pr) do
        {:ok, file_result} ->
          # Only include files with opportunities
          if Enum.empty?(file_result.opportunities) do
            {:cont, acc}
          else
            {:cont, [file_result | acc]}
          end
          
        {:error, reason} ->
          # Stop on error
          {:halt, {:error, reason}}
      end
    end)
    
    # Handle case where reduce_while halted with an error
    case results do
      {:error, reason} -> {:error, reason}
      file_results -> {:ok, Enum.reverse(file_results)}
    end
  end
  
  defp post_analysis_results(installation_id, repo_full_name, pr_number, analysis_results) do
    # Filter out files with no opportunities
    results_with_opportunities = Enum.filter(analysis_results, fn file_result ->
      not Enum.empty?(file_result.opportunities)
    end)
    
    if Enum.empty?(results_with_opportunities) do
      # No issues found, post a clean report
      message = """
      ## 🎉 Ace Analysis Complete
      
      No optimization opportunities found in this pull request. Great job!
      """
      
      APIClient.create_pr_comment(installation_id, repo_full_name, pr_number, message)
    else
      # Format results for GitHub comment
      comment_body = CommentFormatter.format_analysis_summary(results_with_opportunities)
      
      # Post summary comment
      case APIClient.create_pr_comment(installation_id, repo_full_name, pr_number, comment_body) do
        {:ok, comment_id} ->
          # Post individual review comments for specific lines
          post_review_comments(installation_id, repo_full_name, pr_number, results_with_opportunities)
          {:ok, comment_id}
          
        {:error, reason} ->
          {:error, reason}
      end
    end
  end
  
  defp post_review_comments(installation_id, repo_full_name, pr_number, file_results) do
    # This is a placeholder - in a real implementation, you would:
    # 1. Format each opportunity as a review comment
    # 2. Group comments by file
    # 3. Submit a review with all comments
    
    # For now, we'll just log that we would post comments
    total_opportunities = Enum.reduce(file_results, 0, fn file, acc ->
      acc + length(file.opportunities)
    end)
    
    Logger.info("Would post #{total_opportunities} review comments across #{length(file_results)} files")
    {:ok, "review_placeholder"}
  end
  
  defp analyze_code(content, language, path) do
    # This is a placeholder for the actual analysis implementation
    # In a real implementation, you would call out to Ace's core analysis functionality
    
    # For now, we'll return some fake opportunities
    fake_opportunities = [
      %{
        type: :style,
        severity: :suggestion,
        message: "Consider using pattern matching instead of conditional logic",
        line: 10,
        suggestion: "pattern = value"
      },
      %{
        type: :performance,
        severity: :warning,
        message: "Inefficient list traversal pattern detected",
        line: 25,
        suggestion: "Use Enum.reduce instead of recursive traversal"
      }
    ]
    
    # In a real implementation, we would filter these based on severity thresholds
    # and other configuration options
    
    {:ok, fake_opportunities}
  end
end 