defmodule Ace.Integrations.GitHub.WebhookHandler do
  @moduledoc """
  Handles incoming GitHub webhook events.
  
  This module processes webhook payloads from GitHub and dispatches them
  to the appropriate handlers based on the event type.
  
  It specifically handles pull request events to trigger analysis.
  """
  
  require Logger
  alias Ace.Integrations.GitHub.App
  alias Ace.Integrations.GitHub.PRAnalyzer
  
  @doc """
  Process a webhook event from GitHub.
  
  ## Parameters
  
    * `payload` - The raw webhook payload (JSON string)
    * `event_type` - GitHub event type from X-GitHub-Event header
    * `signature` - The signature from X-Hub-Signature-256 header
  
  ## Returns
  
    * `{:ok, event_id}` - Successfully processed event
    * `{:error, reason}` - Processing failed
  """
  @spec process_webhook(binary(), String.t(), String.t()) :: {:ok, String.t()} | {:error, atom() | String.t()}
  def process_webhook(payload, event_type, signature) do
    with true <- App.verify_webhook_signature(payload),
         {:ok, data} <- Jason.decode(payload),
         event_id = Map.get(data, "id", "unknown") do
         
      # Log the event for debugging
      Logger.info("Processing GitHub webhook event: #{event_type} (#{event_id})")
      
      # Route to appropriate handler
      case event_type do
        "pull_request" -> handle_pull_request_event(data)
        "push" -> handle_push_event(data)
        "installation" -> handle_installation_event(data)
        _ -> 
          Logger.info("Ignoring unsupported event type: #{event_type}")
          {:ok, event_id}
      end
    else
      false -> 
        Logger.warn("Invalid webhook signature")
        {:error, :invalid_signature}
      {:error, %Jason.DecodeError{}} -> 
        Logger.error("Invalid JSON payload")
        {:error, :invalid_payload}
      error -> 
        Logger.error("Error processing webhook: #{inspect(error)}")
        {:error, :processing_failed}
    end
  end
  
  @doc """
  Handle a pull request event.
  
  ## Parameters
  
    * `data` - The decoded webhook payload
  
  ## Returns
  
    * `{:ok, pr_id}` - Successfully processed PR event
    * `{:error, reason}` - Processing failed
  """
  @spec handle_pull_request_event(map()) :: {:ok, String.t()} | {:error, atom() | String.t()}
  def handle_pull_request_event(data) do
    # Extract PR details
    %{
      "action" => action,
      "pull_request" => pr,
      "repository" => repo,
      "installation" => %{"id" => installation_id}
    } = data
    
    pr_id = "#{repo["full_name"]}##{pr["number"]}"
    
    # Only trigger analysis for specific actions
    if action in ["opened", "synchronize", "reopened"] do
      Logger.info("Processing PR #{pr_id} (#{action})")
      
      # Queue the analysis job
      # In a real implementation, you'd use a job queue or background process
      # This is a placeholder that directly calls the analyzer
      case PRAnalyzer.analyze_pull_request(installation_id, repo, pr) do
        {:ok, _analysis_id} -> 
          Logger.info("Scheduled analysis for PR #{pr_id}")
          {:ok, pr_id}
        
        {:error, reason} ->
          Logger.error("Failed to analyze PR #{pr_id}: #{inspect(reason)}")
          {:error, reason}
      end
    else
      # Ignore other PR actions
      Logger.info("Ignoring PR event with action: #{action}")
      {:ok, pr_id}
    end
  end
  
  @doc """
  Handle a push event.
  
  ## Parameters
  
    * `data` - The decoded webhook payload
  
  ## Returns
  
    * `{:ok, ref}` - Successfully processed push event
    * `{:error, reason}` - Processing failed
  """
  @spec handle_push_event(map()) :: {:ok, String.t()} | {:error, atom() | String.t()}
  def handle_push_event(data) do
    # Extract push details
    %{
      "ref" => ref,
      "repository" => repo
    } = data
    
    Logger.info("Received push event to #{ref} in #{repo["full_name"]}")
    # We don't need to do anything with push events yet
    # In the future, this could trigger branch analysis
    
    {:ok, ref}
  end
  
  @doc """
  Handle an installation event.
  
  ## Parameters
  
    * `data` - The decoded webhook payload
  
  ## Returns
  
    * `{:ok, installation_id}` - Successfully processed installation event
    * `{:error, reason}` - Processing failed
  """
  @spec handle_installation_event(map()) :: {:ok, integer()} | {:error, atom() | String.t()}
  def handle_installation_event(data) do
    # Extract installation details
    %{
      "action" => action,
      "installation" => %{"id" => installation_id},
      "repositories" => repositories
    } = data
    
    case action do
      "created" ->
        # New installation
        Logger.info("New installation created: #{installation_id}")
        repository_names = Enum.map(repositories, & &1["full_name"])
        Logger.info("Repositories: #{inspect(repository_names)}")
        
        # Here you would typically store the installation information
        # in your database for future reference
        
        {:ok, installation_id}
        
      "deleted" ->
        # Installation removed
        Logger.info("Installation removed: #{installation_id}")
        
        # Clean up any stored data related to this installation
        
        {:ok, installation_id}
        
      _ ->
        # Other installation events
        Logger.info("Installation event: #{action} for #{installation_id}")
        {:ok, installation_id}
    end
  end
end 