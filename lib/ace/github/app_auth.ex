defmodule Ace.GitHub.AppAuth do
  @moduledoc """
  Handles GitHub authentication and token generation.
  Supports both GitHub App authentication and personal access tokens.
  Will try to use GitHub App authentication if configured, otherwise falls back to token-based auth.
  """
  require Logger

  @doc """
  Gets an authentication token for GitHub API requests.
  
  Returns:
    * {:ok, token} - The token to use for authentication
    * {:error, reason} - If token generation fails
  
  Priority:
    1. GitHub App installation token (if app_id and installation_id are configured)
    2. Personal access token from config
    3. GITHUB_TOKEN environment variable
  """
  def get_token do
    # Try GitHub App authentication first
    if github_app_configured?() do
      case generate_installation_token() do
        {:ok, token, _expires_at} -> {:ok, token}
        {:error, reason} ->
          Logger.error("Failed to generate GitHub App token: #{reason}")
          # Fall back to token-based auth
          get_personal_token()
      end
    else
      # Fall back to token-based authentication
      get_personal_token()
    end
  end
  
  @doc """
  Generates an installation access token for GitHub API authentication.
  
  Returns:
    * {:ok, token, expires_at} - The token and its expiration timestamp
    * {:error, reason} - If token generation fails
  """
  def generate_installation_token do
    app_id = Application.get_env(:ace, :github_app)[:app_id]
    installation_id = Application.get_env(:ace, :github_app)[:installation_id]
    
    if is_nil(app_id) or is_nil(installation_id) do
      {:error, "GitHub App not properly configured"}
    else
      private_key = get_private_key()
      
      # Generate a JWT for GitHub App
      jwt = generate_jwt(app_id, private_key)
      
      # Use the JWT to request an installation token
      case HTTPoison.post(
        "https://api.github.com/app/installations/#{installation_id}/access_tokens",
        "",
        [
          {"Authorization", "Bearer #{jwt}"},
          {"Accept", "application/vnd.github.v3+json"}
        ]
      ) do
        {:ok, %{status_code: 201, body: body}} ->
          response = Jason.decode!(body)
          {:ok, response["token"], response["expires_at"]}
          
        {:ok, %{status_code: status, body: body}} ->
          {:error, "Failed with status #{status}: #{body}"}
          
        {:error, %HTTPoison.Error{reason: reason}} ->
          {:error, "HTTP request failed: #{reason}"}
      end
    end
  end
  
  @doc """
  Gets a personal access token from config or environment.
  
  Returns:
    * {:ok, token} - The token to use
    * {:error, reason} - If no token is available
  """
  def get_personal_token do
    token = System.get_env("GITHUB_TOKEN") || 
            Application.get_env(:ace, :github_token)
    
    case token do
      nil -> 
        if Mix.env() in [:dev, :test] do
          Logger.warning("No GitHub token configured, using mock token for development")
          {:ok, "mock_github_token_for_development"}
        else
          {:error, "No GitHub token configured"}
        end
      token -> 
        {:ok, token}
    end
  end
  
  @doc """
  Checks if GitHub App authentication is configured.
  
  Returns:
    * true - If GitHub App is properly configured
    * false - Otherwise
  """
  def github_app_configured? do
    app_config = Application.get_env(:ace, :github_app, %{})
    app_id = app_config[:app_id]
    installation_id = app_config[:installation_id]
    private_key_path = app_config[:private_key_path]
    
    !is_nil(app_id) && !is_nil(installation_id) && !is_nil(private_key_path) &&
      File.exists?(private_key_path)
  end
  
  @doc """
  Generates a JWT token for GitHub App authentication.
  Used by the verification script.
  
  Returns:
    * token - The JWT token string
  """
  def generate_jwt_token do
    app_id = Application.get_env(:ace, :github_app)[:app_id]
    private_key = get_private_key()
    generate_jwt(app_id, private_key)
  end
  
  @doc """
  Gets an installation token for GitHub App authentication.
  Used by the verification script.
  
  Returns:
    * {:ok, token} - The token to use 
    * {:error, reason} - If token generation fails
  """
  def get_installation_token do
    case generate_installation_token() do
      {:ok, token, _expires_at} -> {:ok, token}
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Load private key from file
  defp get_private_key do
    path = Application.get_env(:ace, :github_app)[:private_key_path]
    File.read!(path)
  end
  
  # Generate a JWT for GitHub App authentication
  defp generate_jwt(app_id, private_key) do
    # Current time and expiration (10 minutes from now)
    now = DateTime.utc_now() |> DateTime.to_unix()
    exp = now + 600
    
    # Create the JWT claims
    claims = %{
      "iat" => now,
      "exp" => exp,
      "iss" => app_id
    }
    
    # Generate and sign the JWT
    signer = Joken.Signer.create("RS256", %{"pem" => private_key})
    {:ok, token, _claims} = Joken.generate_and_sign(%{}, claims, signer)
    token
  end
end 