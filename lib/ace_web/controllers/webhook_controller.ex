defmodule AceWeb.WebhookController do
  use AceWeb, :controller
  require Logger
  
  alias Ace.Integrations.GitHub.WebhookHandler
  
  @doc """
  Handle GitHub webhook events.
  
  This endpoint receives webhook payloads from GitHub,
  validates their signatures, and processes them.
  """
  def github(conn, _params) do
    # Extract event type from header
    event_type = get_req_header(conn, "x-github-event") |> List.first()
    # Extract signature from header
    signature = get_req_header(conn, "x-hub-signature-256") |> List.first()
    
    Logger.info("Received GitHub webhook: #{event_type}")
    
    # Read the raw request body
    {:ok, body, conn} = read_body(conn)
    
    case WebhookHandler.process_webhook(body, event_type, signature) do
      {:ok, event_id} ->
        # Return 200 OK to acknowledge receipt
        conn
        |> put_status(:ok)
        |> json(%{message: "Webhook processed", event_id: event_id})
        
      {:error, :invalid_signature} ->
        # Return 401 Unauthorized for invalid signatures
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid webhook signature"})
        
      {:error, reason} ->
        # Return 422 Unprocessable Entity for other errors
        Logger.error("Webhook processing error: #{inspect(reason)}")
        
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to process webhook", reason: reason})
    end
  end
end 