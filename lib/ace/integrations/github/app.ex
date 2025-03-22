defmodule Ace.Integrations.GitHub.App do
  @moduledoc """
  GitHub App configuration and management.
  
  This module handles GitHub App settings, authentication, and installation management.
  It provides functionality to:
  
  - Configure GitHub App credentials
  - Generate installation tokens
  - Manage app installations
  - Handle GitHub authentication flows
  """
  
  require Logger
  
  @doc """
  Retrieve app configuration from environment.
  
  Returns a map with the GitHub App configuration.
  
  ## Returns
  
    * `{:ok, config}` - Map containing app_id, private_key, etc.
    * `{:error, reason}` - If configuration is missing or invalid
  """
  @spec get_config() :: {:ok, map()} | {:error, String.t()}
  def get_config do
    app_id = Application.get_env(:ace, :github_app_id)
    private_key = Application.get_env(:ace, :github_private_key)
    webhook_secret = Application.get_env(:ace, :github_webhook_secret)
    
    cond do
      is_nil(app_id) ->
        {:error, "GitHub App ID not configured"}
      
      is_nil(private_key) ->
        {:error, "GitHub App private key not configured"}
        
      is_nil(webhook_secret) ->
        {:error, "GitHub webhook secret not configured"}
        
      true ->
        {:ok, %{
          app_id: app_id,
          private_key: private_key,
          webhook_secret: webhook_secret
        }}
    end
  end
  
  @doc """
  Generate a JWT for GitHub App authentication.
  
  ## Returns
  
    * `{:ok, jwt}` - JWT string for GitHub API authentication
    * `{:error, reason}` - If JWT generation fails
  """
  @spec generate_jwt() :: {:ok, String.t()} | {:error, String.t()}
  def generate_jwt do
    with {:ok, config} <- get_config(),
         {:ok, private_key} <- decode_private_key(config.private_key) do
      
      # JWT claims
      now = System.system_time(:second)
      claims = %{
        "iat" => now - 60,       # Issued at time (60 seconds in the past for clock drift)
        "exp" => now + 10 * 60,  # Expires in 10 minutes
        "iss" => config.app_id   # Issuer is the app ID
      }
      
      # Generate JWT
      {:ok, JOSE.JWT.sign(private_key, %{"alg" => "RS256"}, claims) |> JOSE.JWS.compact() |> elem(1)}
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Get an installation access token for a specific installation.
  
  ## Parameters
  
    * `installation_id` - The GitHub installation ID
  
  ## Returns
  
    * `{:ok, token, expires_at}` - Access token and expiration timestamp
    * `{:error, reason}` - If token generation fails
  """
  @spec get_installation_token(integer()) :: {:ok, String.t(), integer()} | {:error, String.t() | atom()}
  def get_installation_token(installation_id) do
    with {:ok, jwt} <- generate_jwt(),
         {:ok, response} <- make_request(
           :post,
           "https://api.github.com/app/installations/#{installation_id}/access_tokens",
           "",
           [{"Authorization", "Bearer #{jwt}"}, {"Accept", "application/vnd.github.v3+json"}]
         ),
         {:ok, body} <- Jason.decode(response.body),
         %{"token" => token, "expires_at" => expires_at} <- body do
      
      # Parse the expiration time
      {:ok, datetime, _} = DateTime.from_iso8601(expires_at)
      expiration = DateTime.to_unix(datetime)
      
      {:ok, token, expiration}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, :invalid_response}
    end
  end
  
  @doc """
  Verify a webhook signature from GitHub.
  
  ## Parameters
  
    * `payload` - The raw request body
    * `signature` - The signature from the X-Hub-Signature-256 header
  
  ## Returns
  
    * `true` - If signature is valid
    * `false` - If signature is invalid
  """
  @spec verify_webhook_signature(binary(), String.t()) :: boolean()
  def verify_webhook_signature(payload, signature) when is_binary(payload) and is_binary(signature) do
    with {:ok, config} <- get_config(),
         "sha256=" <> signature_hex <- signature,
         {:ok, expected_hmac} <- Base.decode16(String.upcase(signature_hex)),
         hmac = :crypto.mac(:hmac, :sha256, config.webhook_secret, payload) do
      
      Plug.Crypto.secure_compare(hmac, expected_hmac)
    else
      _ -> false
    end
  end
  
  # Helper functions
  
  defp decode_private_key(private_key) do
    try do
      key = JOSE.JWK.from_pem(private_key)
      {:ok, key}
    rescue
      _ -> {:error, "Invalid private key format"}
    end
  end
  
  defp make_request(method, url, body, headers) do
    # This is a placeholder - you'll need to implement actual HTTP requests
    # You could use HTTPoison, Finch, or another HTTP client
    try do
      # Placeholder for HTTP client implementation
      Logger.info("Making #{method} request to #{url}")
      {:error, :not_implemented}
    rescue
      e -> 
        Logger.error("HTTP request failed: #{inspect(e)}")
        {:error, :request_failed}
    end
  end
end 