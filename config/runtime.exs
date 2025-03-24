import Config

# Set the binding IP address from environment, default to 127.0.0.1
ip_address = 
  case System.get_env("IP") do
    nil -> {127, 0, 0, 1}
    "0.0.0.0" -> {0, 0, 0, 0}
    ip -> 
      ip 
      |> String.split(".")
      |> Enum.map(&String.to_integer/1)
      |> List.to_tuple()
  end

# Configure the endpoint to use the IP from environment
config :ace, AceWeb.Endpoint,
  http: [ip: ip_address, port: String.to_integer(System.get_env("PORT") || "4000")]

# Configure LLM provider
llm_provider = System.get_env("ACE_LLM_PROVIDER")
if llm_provider do
  config :ace, :llm_provider, llm_provider
  
  llm_model = System.get_env("ACE_LLM_MODEL")
  if llm_model do
    config :ace, :llm_model, llm_model
  end
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :ace, Ace.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  # API port configuration
  config :ace, :api_port, String.to_integer(System.get_env("PORT") || "4000")

  # Configure GitHub App for production
  github_app_id =
    System.get_env("GITHUB_APP_ID") ||
      raise """
      environment variable GITHUB_APP_ID is missing.
      You need to set this variable to allow ACE to authenticate with GitHub.
      """

  github_installation_id =
    System.get_env("GITHUB_APP_INSTALLATION_ID") ||
      raise """
      environment variable GITHUB_APP_INSTALLATION_ID is missing.
      You need to set this variable to allow ACE to authenticate with GitHub.
      """
      
  github_private_key_path =
    System.get_env("GITHUB_APP_PRIVATE_KEY_PATH") ||
      raise """
      environment variable GITHUB_APP_PRIVATE_KEY_PATH is missing.
      You need to set this variable to allow ACE to authenticate with GitHub.
      """
      
  config :ace, :github_app,
    app_id: github_app_id,
    installation_id: github_installation_id,
    private_key_path: github_private_key_path
    
  # Configure GitHub webhook secret
  github_webhook_secret =
    System.get_env("GITHUB_WEBHOOK_SECRET") ||
      raise """
      environment variable GITHUB_WEBHOOK_SECRET is missing.
      You need to set this variable to validate GitHub webhook requests.
      """
      
  config :ace, :github_webhook_secret, github_webhook_secret
end