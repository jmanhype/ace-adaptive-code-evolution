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
end