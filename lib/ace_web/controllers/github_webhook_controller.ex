defmodule AceWeb.GitHubWebhookController do
  @moduledoc """
  Controller that handles webhook events from GitHub.
  Processes events such as pull request creation or updates
  and triggers optimization workflows.
  """
  
  use AceWeb, :controller
  
  require Logger
  
  alias Ace.GitHub.Models.PullRequest
  alias Ace.GitHub.Service
  
  @doc """
  Handles incoming webhook events from GitHub.
  Validates the webhook signature and processes the event based on its type.
  """
  @spec handle(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def handle(conn, _params) do
    # Verify GitHub signature
    case verify_github_signature(conn) do
      {:ok, conn} ->
        # Get the event type from headers
        event_type = List.first(Plug.Conn.get_req_header(conn, "x-github-event")) || ""
        # Get the delivery ID from headers
        delivery_id = List.first(Plug.Conn.get_req_header(conn, "x-github-delivery")) || ""
        
        Logger.info("Received GitHub webhook: #{event_type}, delivery ID: #{delivery_id}")
        
        # Read and parse the request body
        {:ok, body, conn} = parse_request_body(conn)
        payload = Jason.decode!(body)
        
        # Process based on event type
        handle_event(conn, event_type, payload)
        
      {:error, reason} ->
        Logger.error("GitHub webhook signature verification failed: #{reason}")
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid signature"})
    end
  end
  
  # Handle different event types
  
  # Pull request events
  defp handle_event(conn, "pull_request", payload) do
    action = payload["action"]
    pr_data = payload["pull_request"]
    repo_data = payload["repository"]
    
    Logger.info("Processing pull_request.#{action} event")
    
    case action do
      # Only process opened or synchronized (updated) PRs
      action when action in ["opened", "synchronize"] ->
        # Process the PR and get the record
        pr_record = handle_pull_request(pr_data, repo_data)
        
        if pr_record do
          # Always automatically start optimization in background
          Task.start(fn -> 
            Logger.info("Starting automatic optimization for PR ##{pr_record.number}")
            Service.optimize_pull_request(pr_record)
          end)
          
          conn
          |> put_status(:ok)
          |> json(%{status: "Processing and automatically optimizing pull request #{pr_data["number"]}"})
        else
          conn
          |> put_status(:ok)
          |> json(%{status: "Processed pull request #{pr_data["number"]} but failed to create record"})
        end
      
      # Handle labeled events to trigger optimization
      "labeled" ->
        label = payload["label"]["name"]
        if label == "optimize" do
          Logger.info("PR ##{pr_data["number"]} labeled with 'optimize', triggering optimization")
          handle_pull_request(pr_data, repo_data)
          
          # Find the PR in our system
          case PullRequest.get_by_github_id(pr_data["id"]) do
            nil -> 
              Logger.error("PR not found in system")
              conn
              |> put_status(:ok)
              |> json(%{status: "PR not found in system, created but optimization failed"})
              
            pr ->
              # Start optimization in background
              Task.start(fn -> 
                Logger.info("Starting optimization for PR ##{pr.number} via 'optimize' label")
                Service.optimize_pull_request(pr)
              end)
              
              conn
              |> put_status(:ok)
              |> json(%{status: "Optimization triggered for PR ##{pr_data["number"]}"})
          end
        else
          Logger.info("Ignoring pull_request.labeled event for label: #{label}")
          conn
          |> put_status(:ok)
          |> json(%{status: "Label not relevant for optimization"})
        end
        
      # Acknowledge but ignore other PR events
      _ ->
        Logger.info("Ignoring pull_request.#{action} event")
        conn
        |> put_status(:ok)
        |> json(%{status: "Event acknowledged, no action required"})
    end
  end
  
  # Label events
  defp handle_event(conn, "label", payload) do
    action = payload["action"]
    label = payload["label"]["name"]
    
    Logger.info("Received label.#{action} event for label: #{label}")
    conn
    |> put_status(:ok)
    |> json(%{status: "Label event acknowledged"})
  end
  
  # Ping event (sent when webhook is first created)
  defp handle_event(conn, "ping", _payload) do
    Logger.info("Received ping event from GitHub")
    conn
    |> put_status(:ok)
    |> json(%{status: "pong"})
  end
  
  # Handle unknown events
  defp handle_event(conn, event_type, _payload) do
    Logger.info("Received unsupported GitHub event: #{event_type}")
    conn
    |> put_status(:ok)
    |> json(%{status: "Event type not supported"})
  end
  
  # Process pull request data
  defp handle_pull_request(pr_data, repo_data) do
    # Extract PR details
    pr_params = %{
      pr_id: pr_data["id"],
      number: pr_data["number"],
      title: pr_data["title"],
      repo_name: repo_data["full_name"],
      user: pr_data["user"]["login"],
      html_url: pr_data["html_url"],
      base_sha: pr_data["base"]["sha"],
      head_sha: pr_data["head"]["sha"],
      status: "pending"
    }
    
    # Create or update PR record
    case PullRequest.upsert(pr_params) do
      {:ok, pr} ->
        # Return the PR record for further processing
        pr
      {:error, reason} ->
        Logger.error("Failed to create/update PR record: #{inspect(reason)}")
        nil
    end
  end
  
  # Verify the GitHub webhook signature
  defp verify_github_signature(conn) do
    # In development or test, we can bypass signature verification
    if Mix.env() in [:dev, :test] do
      Logger.info("Development mode: bypassing signature verification")
      {:ok, body, conn} = parse_request_body(conn)
      {:ok, Plug.Conn.assign(conn, :raw_body, body)}
    else
      signature = List.first(Plug.Conn.get_req_header(conn, "x-hub-signature-256"))
      
      if signature && webhook_secret() do
        {:ok, body, conn} = parse_request_body(conn)
        
        # Calculate expected signature
        expected = "sha256=" <> Base.encode16(:crypto.mac(:hmac, :sha256, webhook_secret(), body), case: :lower)
        
        if Plug.Crypto.secure_compare(expected, signature) do
          # Put the body back to conn so it can be read again
          {:ok, Plug.Conn.assign(conn, :raw_body, body)}
        else
          {:error, "Signature mismatch"}
        end
      else
        if webhook_secret() do
          {:error, "Missing signature header"}
        else
          # If no webhook secret is configured, skip verification
          Logger.warning("No webhook secret configured, skipping signature verification")
          {:ok, conn}
        end
      end
    end
  end
  
  # Get webhook secret from environment
  defp webhook_secret do
    System.get_env("GITHUB_WEBHOOK_SECRET") || 
      Application.get_env(:ace, :github_webhook_secret)
  end
  
  # Read body while preserving it for later use
  defp parse_request_body(conn) do
    if conn.assigns[:raw_body] do
      {:ok, conn.assigns.raw_body, conn}
    else
      Plug.Conn.read_body(conn)
    end
  end
end 