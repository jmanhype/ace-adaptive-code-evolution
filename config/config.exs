import Config

config :ace,
  ecto_repos: [Ace.Repo],
  # Self-evolution configuration
  self_evolution_enabled: false,
  autonomous_deploy: false,
  evolution_check_interval: 86_400_000,  # 24 hours in milliseconds
  evolution_model: "llama3-70b-8192",
  notification_channels: ["slack"],
  slack_webhook_url: nil,
  notification_emails: [],
  evolution_modules: [
    # Example configuration:
    # %{
    #   module: MyApp.Feature,
    #   feedback_source: "feature_dashboard",
    #   threshold: 7.0
    # }
  ]

config :ace, Ace.Repo,
  database: "ace_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

# Phoenix configuration
config :phoenix, :json_library, Jason

# Absinthe configuration
config :absinthe, :schema, Ace.GraphQL.Schema
config :absinthe, :adapter, Absinthe.Adapter.LanguageConventions

# Import environment specific config
import_config "#{config_env()}.exs"