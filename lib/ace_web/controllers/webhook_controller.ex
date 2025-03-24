defmodule AceWeb.WebhookController do
  @moduledoc """
  Controller for handling GitHub webhook events.
  Processes incoming webhook requests from GitHub App.
  """
  use AceWeb, :controller
  require Logger
  alias Ace.GitHub.Service

  @doc """
  Handles GitHub webhook POST requests.
  Verifies the webhook signature and processes the event based on its type.
  """
  def github(conn, _params) do
    payload = conn.body_params
    IO.inspect(payload, label: "Webhook Payload")
    event_type = get_req_header(conn, "x-github-event") |> List.first()
    IO.puts("Event Type: #{event_type}")
    
    if verify_webhook_signature(conn) do
      try do
        handle_github_event(event_type, payload)
        json(conn, %{status: "success", message: "Event received"})
      rescue
        e ->
          Logger.error("Error processing webhook: #{inspect(e)}")
          Logger.error(Exception.format_stacktrace(__STACKTRACE__))
          send_resp(conn, 500, "Error processing webhook")
      end
    else
      Logger.error("Invalid webhook signature")
      send_resp(conn, 403, "Invalid signature")
    end
  end
  
  # Verify the webhook signature from GitHub
  defp verify_webhook_signature(conn) do
    signature_header = get_req_header(conn, "x-hub-signature-256") |> List.first()
    
    if is_nil(signature_header) do
      # For development/testing, we might want to bypass verification
      if Mix.env() == :dev do
        Logger.warn("Webhook signature verification bypassed in development mode")
        true
      else
        false
      end
    else
      signature = String.replace_prefix(signature_header, "sha256=", "")
      
      secret = Application.get_env(:ace, :github_webhook_secret)
      raw_body = conn.assigns[:raw_body]
      
      expected_signature =
        :crypto.mac(:hmac, :sha256, secret, raw_body)
        |> Base.encode16(case: :lower)
      
      Plug.Crypto.secure_compare(expected_signature, signature)
    end
  end
  
  # Handle different GitHub event types
  defp handle_github_event("pull_request", payload) do
    action = payload["action"]
    pr = payload["pull_request"]
    
    Logger.info("Processing pull request event: #{action} for PR ##{pr["number"]}")
    
    case action do
      "opened" -> process_pr_opened(payload)
      "synchronize" -> process_pr_synchronized(payload)
      "closed" -> process_pr_closed(payload)
      "labeled" -> process_pr_labeled(payload)
      "edited" -> process_pr_edited(payload)
      _ -> Logger.info("No action taken for pull_request.#{action}")
    end
  end
  
  defp handle_github_event("issue_comment", payload) do
    action = payload["action"]
    issue = payload["issue"]
    comment = payload["comment"]
    repo = payload["repository"]
    
    # Check if this is a comment on a pull request (issues and PRs share the comment system in GitHub)
    if issue["pull_request"] do
      Logger.info("Processing PR comment: #{action} on PR ##{issue["number"]}")
      
      case action do
        "created" -> process_pr_comment_created(payload)
        _ -> Logger.info("No action taken for issue_comment.#{action}")
      end
    else
      Logger.info("Comment on regular issue ##{issue["number"]}, ignoring")
    end
  end
  
  defp handle_github_event("push", payload) do
    ref = payload["ref"]
    repo = payload["repository"]
    commits = payload["commits"]
    
    Logger.info("Processing push event to #{ref} in #{repo["full_name"]} with #{length(commits)} commits")
    
    # For now we're just logging; implement processing logic as needed
  end
  
  defp handle_github_event(event_type, _payload) do
    Logger.info("Received unsupported GitHub event: #{event_type}")
  end
  
  # Process a newly opened PR
  defp process_pr_opened(
         %{
           "pull_request" => pr_data,
           "repository" => repo_data
         } = payload
       ) do
    Logger.info("Processing PR opened/synchronized event")

    # Extract PR attributes from the payload
    pr_attrs = %{
      "pr_id" => pr_data["id"],
      "number" => pr_data["number"],
      "title" => pr_data["title"],
      "html_url" => pr_data["html_url"],
      "repo_name" => repo_data["full_name"],
      "head_sha" => pr_data["head"]["sha"],
      "base_sha" => pr_data["base"]["sha"],
      "user" => pr_data["user"]["login"],
      "status" => "open"
    }

    Logger.debug("PR attributes extracted: #{inspect(pr_attrs)}")

    # Attempt to register the PR
    case Service.create_or_update_pull_request(pr_attrs) do
      {:ok, pull_request} ->
        Logger.info("Successfully registered PR: ##{pull_request.number}")
        
        # Automatically trigger optimization for newly opened PRs
        Logger.info("Automatically triggering optimization for PR ##{pull_request.number}")
        Task.start(fn -> 
          result = Service.optimize_pull_request(pull_request.id)
          Logger.info("Optimization triggered: #{inspect(result)}")
        end)
        
        {:ok, pull_request}

      {:error, reason} ->
        Logger.error("Failed to register PR: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  # Process a synchronized PR (new commits pushed)
  defp process_pr_synchronized(payload) do
    pr = payload["pull_request"]
    
    Logger.info("PR ##{pr["number"]} synchronized - new commits detected")
    
    # Find the PR in our system
    case Service.get_pull_request_by_github_id(pr["id"]) do
      {:ok, pr_record} ->
        # Always re-analyze when new commits are pushed
        Logger.info("Automatically re-analyzing PR ##{pr["number"]} due to new commits")
        Service.optimize_pull_request(pr_record.id)
        
      {:error, :not_found} ->
        # PR not found, so register it first
        process_pr_opened(payload)
        
      {:error, reason} ->
        Logger.error("Error finding PR: #{inspect(reason)}")
    end
  end
  
  # Process a PR that's been closed
  defp process_pr_closed(payload) do
    pr = payload["pull_request"]
    
    Logger.info("PR ##{pr["number"]} closed")
    
    # Update PR status in our system
    case Service.get_pull_request_by_github_id(pr["id"]) do
      {:ok, pr_record} ->
        Service.update_pull_request(pr_record.id, %{state: "closed"})
        
      {:error, :not_found} ->
        Logger.warn("Closed PR ##{pr["number"]} not found in our system")
        
      {:error, reason} ->
        Logger.error("Error finding PR: #{inspect(reason)}")
    end
  end
  
  # Process a labeled PR
  defp process_pr_labeled(payload) do
    pr = payload["pull_request"]
    label = payload["label"]
    
    Logger.info("PR ##{pr["number"]} labeled with '#{label["name"]}'")
    
    # Check if the label is our trigger label (e.g., "optimize")
    optimize_label = Application.get_env(:ace, :optimize_label, "optimize")
    
    if label["name"] == optimize_label do
      case Service.get_pull_request_by_github_id(pr["id"]) do
        {:ok, pr_record} ->
          Logger.info("Starting optimization for PR ##{pr["number"]}")
          Service.optimize_pull_request(pr_record.id)
          
        {:error, :not_found} ->
          # PR not found, so register it first and then optimize
          process_pr_opened(payload)
          
        {:error, reason} ->
          Logger.error("Error finding PR: #{inspect(reason)}")
      end
    end
  end

  # Process a PR that's been edited
  defp process_pr_edited(payload) do
    pr = payload["pull_request"]
    repo = payload["repository"]
    
    IO.inspect(pr, label: "Edited Pull Request Data")
    
    # Format the data from the pull request into a map that matches our schema
    pr_data = %{
      pr_id: pr["id"],
      number: pr["number"],
      title: pr["title"],
      html_url: pr["html_url"],
      repo_name: repo["full_name"],
      head_sha: pr["head"]["sha"],
      base_sha: pr["base"]["sha"],
      user: pr["user"]["login"],
    }
    
    IO.inspect(pr_data, label: "Formatted Edited PR Data")
    
    # Update the PR in our system
    case Service.create_or_update_pull_request(pr_data) do
      {:ok, pr_record} ->
        Logger.info("PR ##{pr["number"]} updated successfully")
        IO.inspect(pr_record, label: "Updated PR Record")
        
      {:error, reason} ->
        Logger.error("Failed to update PR: #{inspect(reason)}")
        IO.inspect(reason, label: "PR Update Error")
    end
  end

  # Process a newly created comment on a PR
  defp process_pr_comment_created(payload) do
    issue = payload["issue"]
    comment = payload["comment"]
    repo = payload["repository"]
    
    Logger.info("New comment on PR ##{issue["number"]} by #{comment["user"]["login"]}")
    IO.inspect(comment, label: "Comment Data")
    
    # Look for command triggers in the comment body, e.g., "/optimize" or "/help"
    comment_body = comment["body"] |> String.trim()
    
    cond do
      String.starts_with?(comment_body, "/optimize") ->
        handle_optimize_command(issue, comment, repo)
        
      String.starts_with?(comment_body, "/help") ->
        handle_help_command(issue, comment, repo)
        
      true ->
        Logger.info("No command detected in comment")
    end
  end
  
  # Handle the /optimize command in comments
  defp handle_optimize_command(issue, comment, repo) do
    # Find the PR in our system
    case Service.get_pull_request_by_number(issue["number"], repo["full_name"]) do
      {:ok, pr_record} ->
        Logger.info("Starting optimization for PR ##{issue["number"]} triggered by comment")
        Service.optimize_pull_request(pr_record.id)
        
      {:error, :not_found} ->
        Logger.error("PR ##{issue["number"]} not found for optimize command")
        
      {:error, reason} ->
        Logger.error("Error finding PR: #{inspect(reason)}")
    end
  end
  
  # Handle the /help command in comments
  defp handle_help_command(issue, comment, repo) do
    # Log the help request
    Logger.info("Help command received for PR ##{issue["number"]}")
    # Future: could post a comment back with available commands
  end
  
  @doc """
  Debug version of process_pr_comment_created for use with scripts.
  """
  def process_pr_comment_debug(payload) do
    issue = payload["issue"]
    comment = payload["comment"]
    repo = payload["repository"]
    
    IO.inspect(issue, label: "Issue Data")
    IO.inspect(comment, label: "Comment Data")
    IO.inspect(repo, label: "Repository Data")
    
    # Extract the comment body
    comment_body = comment["body"] |> String.trim()
    IO.puts("Comment body: #{comment_body}")
    
    # Check for commands
    cond do
      String.starts_with?(comment_body, "/optimize") ->
        IO.puts("Optimize command detected")
        handle_optimize_command(issue, comment, repo)
        
      String.starts_with?(comment_body, "/help") ->
        IO.puts("Help command detected")
        handle_help_command(issue, comment, repo)
        
      true ->
        IO.puts("No command detected in comment")
    end
  end

  @doc """
  Debug version of process_pr_opened for use with scripts.
  """
  def process_pr_opened_debug(payload) do
    pr = payload["pull_request"]
    repo = payload["repository"]
    
    IO.inspect(pr, label: "Pull Request Data")
    IO.inspect(repo, label: "Repository Data")
    
    # Format the data from the pull request into a map that matches our schema
    pr_data = %{
      pr_id: pr["id"],
      number: pr["number"],
      title: pr["title"],
      html_url: pr["html_url"],
      repo_name: repo["full_name"],
      head_sha: pr["head"]["sha"],
      base_sha: pr["base"]["sha"],
      user: pr["user"]["login"],
    }
    
    IO.inspect(pr_data, label: "Formatted PR Data")
    
    # Register the PR in our system
    case Service.create_or_update_pull_request(pr_data) do
      {:ok, pull_request} ->
        IO.puts("Successfully registered PR: #{pull_request.id}")
        {:ok, pull_request}
        
      {:error, changeset} ->
        IO.inspect(changeset, label: "Error registering PR")
        {:error, changeset}
    end
  end
  
  @doc """
  Debug version of process_pr_edited for use with scripts.
  """
  def process_pr_edited_debug(payload) do
    pr = payload["pull_request"]
    repo = payload["repository"]
    
    IO.inspect(pr, label: "Edited Pull Request Data")
    IO.inspect(repo, label: "Repository Data")
    
    # Format the data from the pull request into a map that matches our schema
    pr_data = %{
      pr_id: pr["id"],
      number: pr["number"],
      title: pr["title"],
      html_url: pr["html_url"],
      repo_name: repo["full_name"],
      head_sha: pr["head"]["sha"],
      base_sha: pr["base"]["sha"],
      user: pr["user"]["login"],
    }
    
    IO.inspect(pr_data, label: "Formatted Edited PR Data")
    
    # Update the PR in our system
    case Service.create_or_update_pull_request(pr_data) do
      {:ok, pull_request} ->
        IO.puts("Successfully updated PR: #{pull_request.id}")
        {:ok, pull_request}
        
      {:error, changeset} ->
        IO.inspect(changeset, label: "Error updating PR")
        {:error, changeset}
    end
  end
end 