defmodule AceWeb.GitHubAPIController do
  @moduledoc """
  Controller for REST API endpoints related to GitHub integrations.
  Provides endpoints for listing pull requests, viewing details, and triggering optimizations.
  """
  use AceWeb, :controller

  alias Ace.GitHub.Models.PullRequest
  alias Ace.GitHub.Models.PRFile
  alias Ace.GitHub.Models.OptimizationSuggestion
  alias Ace.GitHub.Service
  alias Ace.GitHub.PRCreator
  alias Ace.GitHub.GitHubAPI
  alias Ace.Repo
  
  require Logger

  import Ecto.Query

  @doc """
  Creates a new pull request on GitHub or simulates creation if in mock mode.
  
  ## Request body parameters
    - repo_name: Name of the repository
    - title: Title of the pull request
    - body: Description of the pull request
    - head: The name of the branch where your changes are implemented (optional in mock mode)
    - base: The name of the branch you want the changes pulled into (optional in mock mode)
    - number: Pull request number (required in mock mode)
    - pr_id: GitHub's internal PR ID (required in mock mode)
    - html_url: URL to the pull request on GitHub (required in mock mode)
    - head_sha: SHA of the head commit (required in mock mode)
    - base_sha: SHA of the base commit (required in mock mode)
    - user: GitHub username of the PR author
    - simulate: Boolean to force simulation mode (default: false)
    - force_personal_token: Boolean to force using personal token instead of GitHub App (default: false)
  """
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, params) do
    Logger.info("Creating pull request with params: #{inspect(params)}")
    
    # Check if we're simulating a PR
    if Map.get(params, "simulate", false) do
      Logger.info("Using mock mode for PR creation")
      create_simulated_pr(conn, params)
    else
      Logger.info("Using GitHub App authentication for PR creation")
      create_real_pr(conn, params)
    end
  end

  defp create_real_pr(conn, params) do
    repo_name = Map.get(params, "repo_name")
    title = Map.get(params, "title", "Pull Request")
    body = Map.get(params, "body", "")
    head = Map.get(params, "head")
    base = Map.get(params, "base")
    
    case GitHubAPI.create_pull_request(repo_name, title, body, head, base) do
      {:ok, pr} ->
        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          message: "GitHub pull request created successfully",
          pull_request: pr
        })
        
      {:error, message, response_body} ->
        # Try to parse the GitHub API error response if it exists
        github_error = case response_body do
          nil -> nil
          body when is_binary(body) ->
            case Jason.decode(body) do
              {:ok, decoded} -> decoded
              {:error, _} -> body
            end
        end
        
        Logger.error("Failed to create GitHub pull request: #{inspect(message)}")
        
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          message: "Failed to create GitHub pull request",
          error: message,
          github_error: github_error
        })
    end
  end

  defp create_simulated_pr(conn, params) do
    # Validate required fields for mock mode
    required_fields = ["repo_name", "number", "pr_id", "title", "user"]
    missing_fields = Enum.filter(required_fields, &(!Map.has_key?(params, &1)))
    
    if length(missing_fields) > 0 do
      conn
      |> put_status(:bad_request)
      |> json(%{
        success: false,
        message: "Missing required parameters for mock mode: #{Enum.join(missing_fields, ", ")}"
      })
    else
      # Format data for the schema
      pr_data = %{
        repo_name: params["repo_name"],
        number: params["number"],
        pr_id: params["pr_id"],
        title: params["title"],
        html_url: params["html_url"] || "https://github.com/#{params["repo_name"]}/pull/#{params["number"]}",
        head_sha: params["head_sha"] || "mock_head_sha_#{:rand.uniform(100000)}",
        base_sha: params["base_sha"] || "mock_base_sha_#{:rand.uniform(100000)}",
        user: params["user"],
        status: "pending"
      }
      
      # Register the pull request
      case Service.create_or_update_pull_request(pr_data) do
        {:ok, pull_request} ->
          conn
          |> put_status(:created)
          |> json(%{
            success: true,
            message: "Pull request registered successfully (mock mode)",
            data: format_pull_request(pull_request)
          })
          
        {:error, changeset} ->
          Logger.error("Failed to create pull request: #{inspect(changeset)}")
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{
            success: false,
            errors: format_changeset_errors(changeset)
          })
      end
    end
  end

  @doc """
  List pull requests with optional filtering.
  
  Query parameters:
  - status: filter by status (pending, processing, optimized, etc.)
  - repo: filter by repository name
  - limit: limit the number of results (default: 20)
  """
  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    # Get 20 most recent PRs
    pull_requests = Service.list_pull_requests()
    
    conn
    |> json(%{
      success: true,
      data: Enum.map(pull_requests, &format_pull_request/1)
    })
  end

  @doc """
  Shows details of a specific pull request.
  
  ## Path Parameters
    - id: ID of the pull request to retrieve
  """
  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    case Repo.get(PullRequest, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Pull request not found"})
        
      pr ->
        # Load files
        files = Repo.all(from f in PRFile, where: f.pr_id == ^pr.id)
        
        # Load optimization suggestions with preloaded file data
        suggestions_query = from s in OptimizationSuggestion,
          where: s.pr_id == ^pr.id,
          order_by: [asc: fragment("CASE WHEN ? = 'high' THEN 1 WHEN ? = 'medium' THEN 2 WHEN ? = 'low' THEN 3 ELSE 4 END", s.severity, s.severity, s.severity),
                     desc: s.inserted_at]
        
        suggestions = Repo.all(suggestions_query) |> Repo.preload(:file)
        
        # Format suggestions for PR comment
        formatted_comment = format_suggestions_for_pr_comment(suggestions, pr)
        
        # Return JSON response with nested data
        json(conn, %{
          data: Map.merge(
            format_pull_request(pr),
            %{
              files: Enum.map(files, &format_file/1),
              suggestions: Enum.map(suggestions, &format_suggestion_with_file/1),
              formatted_comment: formatted_comment
            }
          )
        })
    end
  end

  @doc """
  Manually triggers optimization for a pull request.
  
  ## Request body parameters
    - repo_name: Full name of the repository (e.g. "owner/repo")
    - pr_number: Pull request number
  
  POST /api/github/optimize
  """
  def optimize_pull_request(conn, params) do
    repo_name = Map.get(params, "repo_name")
    pr_number = Map.get(params, "pr_number")
    
    # Validate required parameters
    cond do
      is_nil(repo_name) ->
        conn |> put_status(:bad_request) |> json(%{error: "repo_name is required"})
      is_nil(pr_number) ->
        conn |> put_status(:bad_request) |> json(%{error: "pr_number is required"})
      true ->
        Logger.info("Manually triggering optimization for PR ##{pr_number} in #{repo_name}")
        
        # First check if we have this PR in our database
        case Service.get_pull_request_by_number(pr_number, repo_name) do
          {:ok, pr} ->
            # We have the PR, so trigger optimization directly
            Task.start(fn -> 
              Logger.info("Starting optimization for PR ##{pr.number}")
              Service.optimize_pull_request(pr)
            end)
            
            conn
            |> json(%{
              success: true,
              message: "Optimization started for PR ##{pr_number}",
              pr_id: pr.id
            })
            
          {:error, :not_found} ->
            # PR not found in our database, fetch it from GitHub
            Logger.info("PR not found in database, fetching from GitHub")
            
            case GitHubAPI.get_pull_request(repo_name, pr_number) do
              {:ok, pr_data} ->
                # Create PR record with the GitHub data
                pr_params = %{
                  pr_id: pr_data["id"],
                  number: pr_data["number"],
                  title: pr_data["title"],
                  repo_name: repo_name,
                  user: pr_data["user"]["login"],
                  html_url: pr_data["html_url"],
                  base_sha: pr_data["base"]["sha"],
                  head_sha: pr_data["head"]["sha"],
                  status: "pending"
                }
                
                case Service.create_or_update_pull_request(pr_params) do
                  {:ok, pr} ->
                    # Successfully created PR record, trigger optimization
                    Task.start(fn -> 
                      Logger.info("Starting optimization for newly created PR ##{pr.number}")
                      Service.optimize_pull_request(pr)
                    end)
                    
                    conn
                    |> json(%{
                      success: true,
                      message: "PR record created and optimization started for PR ##{pr_number}",
                      pr_id: pr.id
                    })
                    
                  {:error, changeset} ->
                    Logger.error("Failed to create PR record: #{inspect(changeset.errors)}")
                    
                    conn
                    |> put_status(:unprocessable_entity)
                    |> json(%{
                      success: false,
                      message: "Failed to create PR record",
                      errors: format_changeset_errors(changeset)
                    })
                end
                
              {:error, error_message, error_body} ->
                decoded_error = 
                  if is_binary(error_body) do
                    case Jason.decode(error_body) do
                      {:ok, decoded} -> decoded
                      _ -> nil
                    end
                  else
                    nil
                  end
                  
                Logger.error("Error fetching PR from GitHub: #{error_message}, GitHub API response: #{inspect(decoded_error)}")
                
                conn
                |> put_status(:unprocessable_entity)
                |> json(%{
                  success: false,
                  error: "Failed to fetch PR from GitHub: #{error_message}",
                  github_error: decoded_error
                })
            end
        end
    end
  end

  @doc """
  Creates a pull request with all optimizations applied.
  
  ## Path Parameters
    - id: ID of the original pull request to create optimizations PR for
  """
  @spec create_optimization_pr(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create_optimization_pr(conn, %{"id" => id}) do
    case Repo.get(PullRequest, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Pull request not found"})
        
      pr ->
        # Trigger optimization PR creation
        case PRCreator.create_optimization_pr(pr.id) do
          {:ok, pr_number, pr_url} ->
            conn
            |> put_status(:created)
            |> json(%{
              message: "Optimization PR created successfully",
              pr_number: pr_number,
              pr_url: pr_url
            })
            
          {:error, reason} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{
              error: "Failed to create optimization PR",
              details: reason
            })
        end
    end
  end

  @doc """
  Get optimization suggestions for a PR.
  
  Returns a list of optimization suggestions for a specific pull request,
  grouped by file.
  """
  @spec get_optimization_suggestions(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get_optimization_suggestions(conn, %{"pr_id" => pr_id}) do
    require Logger
    Logger.info("Getting optimization suggestions for PR: #{pr_id}")
    
    try do
      # Get suggestions with preloaded file data
      suggestions_query = from s in OptimizationSuggestion,
        where: s.pr_id == ^pr_id,
        order_by: [asc: fragment("CASE WHEN ? = 'high' THEN 1 WHEN ? = 'medium' THEN 2 WHEN ? = 'low' THEN 3 ELSE 4 END", s.severity, s.severity, s.severity),
                   desc: s.inserted_at]
      
      suggestions = Repo.all(suggestions_query) |> Repo.preload(:file)
      Logger.info("Found #{length(suggestions)} suggestions")
      
      # Get all files for this PR to ensure we have complete file data
      files = PRFile.get_files_for_pr(pr_id)
      files_by_id = Enum.reduce(files, %{}, fn file, acc -> 
        Map.put(acc, file.id, file) 
      end)
      
      # Group suggestions by file_id
      suggestions_by_file = suggestions
      |> Enum.group_by(fn s -> s.file_id end)
      |> Enum.map(fn {file_id, file_suggestions} ->
        # Get the file data
        file = Map.get(files_by_id, file_id)
        
        if file do
          Logger.info("Processing suggestions for file: #{file.filename}, language: #{inspect(file.language)}")
          
          %{
            filename: file.filename,
            suggestions: Enum.map(file_suggestions, fn s -> 
              # Convert suggestion to map with necessary fields
              %{
                id: s.id,
                description: s.description,
                location: s.location,
                severity: s.severity,
                type: s.opportunity_type,
                explanation: s.explanation,
                original_code: s.original_code,
                optimized_code: s.optimized_code,
                status: s.status
              }
            end),
            language: file.language
          }
        else
          Logger.warning("File not found for file_id: #{file_id}")
          nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      
      Logger.info("Returning #{length(suggestions_by_file)} file groups")
      conn
      |> json(%{success: true, data: suggestions_by_file})
    rescue
      e ->
        Logger.error("Error getting optimization suggestions: #{inspect(e)}")
        Logger.error("Stacktrace: #{Exception.format_stacktrace(__STACKTRACE__)}")
        conn
        |> put_status(500)
        |> json(%{success: false, error: "Internal server error"})
    end
  end

  @doc """
  Renders an HTML page for displaying optimization suggestions for a pull request.
  """
  @spec render_optimization_ui(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def render_optimization_ui(conn, %{"pr_id" => pr_id}) do
    require Logger
    Logger.info("Rendering optimization UI for PR: #{pr_id}")
    
    try do
      suggestions = OptimizationSuggestion.get_by_id(pr_id)
      Logger.info("Found #{length(suggestions)} suggestions")
      
      # Group suggestions by filename
      suggestions_by_file = suggestions
      |> Enum.group_by(fn s -> s.filename end)
      |> Enum.map(fn {filename, file_suggestions} ->
        # Get the language from the first suggestion
        language = if length(file_suggestions) > 0 do
          pr_file = PRFile.get_by_pr_and_filename(pr_id, filename)
          lang = pr_file && pr_file.language
          Logger.info("Language for #{filename}: #{inspect(lang)}")
          lang
        else
          nil
        end
        
        %{
          filename: filename,
          suggestions: file_suggestions,
          language: language
        }
      end)
      
      # Generate HTML content
      file_sections = if Enum.empty?(suggestions_by_file) do
        "<p>No optimization suggestions found for this pull request.</p>"
      else
        suggestions_by_file
        |> Enum.map(fn file_data ->
          suggestions_html = file_data.suggestions
          |> Enum.map(fn suggestion ->
            severity_class = case suggestion.severity do
              "high" -> "severity-high"
              "medium" -> "severity-medium"
              _ -> "severity-low"
            end
            
            """
            <div class="suggestion">
              <div class="suggestion-header">
                <div class="suggestion-type">#{suggestion.type}: #{suggestion.description}</div>
                <div>
                  <span class="suggestion-location">#{suggestion.location}</span>
                  <span class="suggestion-severity #{severity_class}">#{suggestion.severity}</span>
                </div>
              </div>
              
              <div class="code-section">
                <div>
                  <div class="code-header">Original Code:</div>
                  <div class="code-block">
                    <pre>#{suggestion.original_code}</pre>
                  </div>
                </div>
                <div>
                  <div class="code-header">Optimized Code:</div>
                  <div class="code-block">
                    <pre>#{suggestion.optimized_code}</pre>
                  </div>
                </div>
              </div>
              
              <div class="explanation">
                <strong>Explanation:</strong> #{suggestion.explanation}
              </div>
            </div>
            """
          end)
          |> Enum.join("\n")
          
          language_badge = if file_data.language do
            "<span class=\"language-badge\">#{file_data.language}</span>"
          else
            "<span class=\"language-badge\">unknown</span>"
          end
          
          """
          <div class="file-section">
            <div class="file-header">
              <span>#{file_data.filename}</span>
              #{language_badge}
            </div>
            #{suggestions_html}
          </div>
          """
        end)
        |> Enum.join("\n")
      end
      
      html = """
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Code Optimization Suggestions</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
          }
          h1 {
            color: #2c3e50;
            border-bottom: 2px solid #ecf0f1;
            padding-bottom: 10px;
          }
          .file-section {
            margin-bottom: 30px;
            border: 1px solid #e1e4e8;
            border-radius: 6px;
            overflow: hidden;
          }
          .file-header {
            background-color: #f6f8fa;
            padding: 10px 15px;
            border-bottom: 1px solid #e1e4e8;
            font-weight: bold;
            display: flex;
            justify-content: space-between;
          }
          .suggestion {
            padding: 15px;
            border-bottom: 1px solid #e1e4e8;
          }
          .suggestion:last-child {
            border-bottom: none;
          }
          .suggestion-header {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
          }
          .suggestion-type {
            font-weight: bold;
          }
          .suggestion-location {
            color: #586069;
          }
          .suggestion-severity {
            padding: 3px 8px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 500;
          }
          .severity-high {
            background-color: #ffebe9;
            color: #cf222e;
          }
          .severity-medium {
            background-color: #fff8c5;
            color: #9a6700;
          }
          .severity-low {
            background-color: #ddf4ff;
            color: #0969da;
          }
          .code-section {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-top: 15px;
          }
          .code-block {
            background-color: #f6f8fa;
            border-radius: 6px;
            padding: 10px;
            overflow-x: auto;
          }
          .code-block pre {
            margin: 0;
            white-space: pre-wrap;
          }
          .code-header {
            font-weight: bold;
            margin-bottom: 5px;
            color: #586069;
          }
          .explanation {
            background-color: #f1f8ff;
            border-left: 4px solid #0366d6;
            padding: 10px 15px;
            margin-top: 15px;
            border-radius: 0 6px 6px 0;
          }
          .language-badge {
            background-color: #e1e4e8;
            color: #24292e;
            padding: 3px 6px;
            border-radius: 4px;
            font-size: 12px;
          }
        </style>
      </head>
      <body>
        <h1>Code Optimization Suggestions</h1>
        
        #{file_sections}
      </body>
      </html>
      """
      
      conn
      |> put_resp_content_type("text/html")
      |> send_resp(200, html)
    rescue
      e ->
        Logger.error("Error rendering optimization UI: #{inspect(e)}")
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(500, """
        <!DOCTYPE html>
        <html>
        <head>
          <title>Error</title>
        </head>
        <body>
          <h1>Error: #{inspect(e)}</h1>
          <p>An error occurred while processing your request.</p>
        </body>
        </html>
        """)
    end
  end

  def post_suggestion_comment(conn, %{"pr_id" => pr_id, "suggestion_id" => suggestion_id}) do
    # Get the pull request
    pr = Ace.GitHub.Models.PullRequest.get(pr_id)
    
    if pr == nil do
      conn
      |> put_status(:not_found)
      |> json(%{error: "Pull request not found"})
    else
      # Get the suggestion
      suggestion = Ace.GitHub.Models.OptimizationSuggestion.get_by_id(suggestion_id)
      
      cond do
        suggestion == nil ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "Suggestion not found"})
          
        suggestion.pr_id != pr_id ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: "Suggestion does not belong to this pull request"})
          
        true ->
          # Get the file
          file = Ace.GitHub.Models.PRFile.get_file(suggestion.file_id)
          
          if file == nil do
            conn
            |> put_status(:internal_server_error)
            |> json(%{error: "File not found for suggestion"})
          else
            # Format the comment
            comment_body = format_suggestion_comment(suggestion, file)
            
            # Submit the comment
            case Ace.GitHub.Service.submit_comment_for_suggestion(pr, suggestion, comment_body) do
              {:ok, result} ->
                conn
                |> put_status(:ok)
                |> json(%{
                  comment_id: result.comment_id,
                  suggestion_id: suggestion_id,
                  status: result.suggestion.status
                })
                
              {:error, reason} ->
                Ace.Logger.error("Failed to submit comment for suggestion", 
                  error: inspect(reason),
                  pr_id: pr_id,
                  suggestion_id: suggestion_id
                )
                
                conn
                |> put_status(:internal_server_error)
                |> json(%{error: "Failed to submit comment"})
            end
          end
      end
    end
  end

  # Format pull request for JSON response
  defp format_pull_request(pr) do
    %{
      id: pr.id,
      pr_id: pr.pr_id,
      number: pr.number,
      title: pr.title,
      repo_name: pr.repo_name,
      user: pr.user,
      html_url: pr.html_url,
      status: pr.status,
      inserted_at: pr.inserted_at,
      updated_at: pr.updated_at
    }
  end
  
  # Format file for JSON response
  defp format_file(file) do
    %{
      id: file.id,
      filename: file.filename,
      status: file.status,
      language: file.language,
      additions: file.additions,
      deletions: file.deletions,
      changes: file.changes,
      has_content: file.content != nil && file.content != ""
    }
  end
  
  defp format_suggestion_with_file(suggestion) do
    %{
      id: suggestion.id,
      opportunity_type: suggestion.opportunity_type,
      location: suggestion.location,
      description: suggestion.description,
      severity: suggestion.severity,
      status: suggestion.status,
      original_code: suggestion.original_code,
      optimized_code: suggestion.optimized_code,
      explanation: suggestion.explanation,
      comment_id: suggestion.comment_id,
      metrics: suggestion.metrics,
      inserted_at: suggestion.inserted_at,
      updated_at: suggestion.updated_at,
      file: format_file(suggestion.file)
    }
  end

  # Format suggestions for GitHub PR comment
  defp format_suggestions_for_pr_comment(suggestions, pr) do
    if Enum.empty?(suggestions) do
      """
      ## ACE Code Optimization Report
      
      ✅ No optimization opportunities found for this pull request.
      
      [View in ACE dashboard](#{AceWeb.Endpoint.url()}/github/pull_requests/#{pr.id})
      """
    else
      total_count = length(suggestions)
      
      # Count suggestions by severity
      severity_counts = Enum.reduce(suggestions, %{"high" => 0, "medium" => 0, "low" => 0}, fn suggestion, acc ->
        Map.update(acc, suggestion.severity || "low", 1, &(&1 + 1))
      end)
      
      # Format the top 5 suggestions
      top_suggestions = 
        suggestions
        |> Enum.take(5)
        |> Enum.map(fn suggestion ->
          icon = severity_icon(suggestion.severity)
          file_path = suggestion.file && suggestion.file.filename || "unknown file"
          location = suggestion.location || "unspecified location"
          
          """
          #{icon} **#{suggestion.opportunity_type}** in `#{file_path}` at #{location}
          #{suggestion.description}
          
          ```diff
          - #{suggestion.original_code |> String.split("\n") |> Enum.join("\n- ")}
          + #{suggestion.optimized_code |> String.split("\n") |> Enum.join("\n+ ")}
          ```
          """
        end)
        |> Enum.join("\n\n")
      
      """
      ## ACE Code Optimization Report
      
      Found **#{total_count}** optimization opportunities:
      - 🔴 High: #{severity_counts["high"]}
      - 🟠 Medium: #{severity_counts["medium"]}
      - 🔵 Low: #{severity_counts["low"]}
      
      ### Top Recommendations
      
      #{top_suggestions}
      
      [View full report in ACE dashboard](#{AceWeb.Endpoint.url()}/github/pull_requests/#{pr.id})
      """
    end
  end
  
  # Get severity icon for suggestion
  defp severity_icon(severity) do
    case severity do
      "high" -> "🔴"
      "medium" -> "🟠"
      "low" -> "🔵"
      _ -> "⚪"
    end
  end

  # Format suggestion for a PR comment
  @spec format_suggestion_comment(OptimizationSuggestion.t(), PRFile.t()) :: String.t()
  defp format_suggestion_comment(suggestion, file) do
    severity_emoji = case suggestion.severity do
      "high" -> "🔴"
      "medium" -> "🟠"
      "low" -> "🔵"
      _ -> "⚪"
    end
    
    """
    #{severity_emoji} **#{suggestion.opportunity_type}** in `#{file.filename}` at #{suggestion.location}
    
    #{suggestion.description}
    
    ```diff
    - #{String.replace(suggestion.original_code, "\n", "\n- ")}
    + #{String.replace(suggestion.optimized_code, "\n", "\n+ ")}
    ```
    
    **Explanation**: #{suggestion.explanation}
    """
  end
  
  # Helper function to format changeset errors
  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  @doc """
  GET /api/github/branches/:repo_name
  
  Lists branches in a GitHub repository
  """
  def list_branches(conn, %{"repo_name" => repo_name}) do
    case GitHubAPI.list_branches(repo_name) do
      {:ok, branches} ->
        json(conn, %{success: true, branches: branches})
        
      {:error, error_message, error_body} ->
        decoded_error = 
          if is_binary(error_body) do
            case Jason.decode(error_body) do
              {:ok, decoded} -> decoded
              _ -> nil
            end
          else
            nil
          end
          
        Logger.error("Error listing branches: #{error_message}, GitHub API response: #{inspect(decoded_error)}")
        
        json(conn, %{
          success: false,
          error: error_message,
          github_error: decoded_error
        })
    end
  end

  @doc """
  Creates a new branch in a GitHub repository.
  
  POST /api/github/branches
  """
  def create_branch(conn, %{"repo_name" => repo_name, "branch_name" => branch_name, "sha" => sha}) do
    case GitHubAPI.create_branch(repo_name, branch_name, sha) do
      {:ok, result} ->
        json(conn, %{success: true, branch: result})
        
      {:error, error_message, error_body} ->
        decoded_error = 
          if is_binary(error_body) do
            case Jason.decode(error_body) do
              {:ok, decoded} -> decoded
              _ -> nil
            end
          else
            nil
          end
          
        Logger.error("Error creating branch: #{error_message}, GitHub API response: #{inspect(decoded_error)}")
        
        json(conn, %{
          success: false,
          error: error_message,
          github_error: decoded_error
        })
    end
  end

  @doc """
  Lists pull requests in a GitHub repository.
  
  GET /api/github/repos/:repo_name/pull_requests
  """
  def list_repo_pull_requests(conn, %{"repo_name" => repo_name} = params) do
    state = Map.get(params, "state", "open")
    
    case GitHubAPI.list_pull_requests(repo_name, state) do
      {:ok, pull_requests} ->
        json(conn, %{success: true, pull_requests: pull_requests})
        
      {:error, error_message, error_body} ->
        decoded_error = 
          if is_binary(error_body) do
            case Jason.decode(error_body) do
              {:ok, decoded} -> decoded
              _ -> nil
            end
          else
            nil
          end
          
        Logger.error("Error listing pull requests: #{error_message}, GitHub API response: #{inspect(decoded_error)}")
        
        json(conn, %{
          success: false,
          error: error_message,
          github_error: decoded_error
        })
    end
  end

  @doc """
  Creates or updates a file in a GitHub repository.
  
  ## Request body parameters
    - repo_name: Full name of the repository (e.g. "owner/repo")
    - path: Path to the file in the repository
    - message: Commit message
    - content: File content (will be Base64 encoded)
    - branch: Branch name to commit to
    - sha: Optional SHA of the file (required when updating existing files)
  """
  def create_or_update_file(conn, params) do
    repo_name = Map.get(params, "repo_name")
    path = Map.get(params, "path")
    message = Map.get(params, "message", "Update #{path}")
    content = Map.get(params, "content")
    branch = Map.get(params, "branch")
    sha = Map.get(params, "sha")
    
    # Validate required parameters
    cond do
      is_nil(repo_name) ->
        conn |> put_status(:bad_request) |> json(%{error: "repo_name is required"})
      is_nil(path) ->
        conn |> put_status(:bad_request) |> json(%{error: "path is required"})  
      is_nil(content) ->
        conn |> put_status(:bad_request) |> json(%{error: "content is required"})
      is_nil(branch) ->
        conn |> put_status(:bad_request) |> json(%{error: "branch is required"})
      true ->
        case GitHubAPI.create_or_update_file(repo_name, path, message, content, branch, sha) do
          {:ok, result} ->
            conn
            |> put_status(:created)
            |> json(%{
              success: true,
              message: "File created/updated successfully",
              content: result["content"],
              commit: result["commit"]
            })
            
          {:error, error_message, response_body} ->
            # Try to parse the GitHub API error response if it exists
            github_error = case response_body do
              nil -> nil
              body when is_binary(body) ->
                case Jason.decode(body) do
                  {:ok, decoded} -> decoded
                  {:error, _} -> body
                end
            end
            
            Logger.error("Failed to create/update file: #{inspect(error_message)}")
            
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{
              success: false,
              message: "Failed to create/update file",
              error: error_message,
              github_error: github_error
            })
        end
    end
  end
end 