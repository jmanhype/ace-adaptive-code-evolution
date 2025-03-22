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
  ],
  # GitHub integration configuration
  github_app_id: System.get_env("GITHUB_APP_ID"),
  github_private_key: System.get_env("GITHUB_PRIVATE_KEY"),
  github_webhook_secret: System.get_env("GITHUB_WEBHOOK_SECRET"),
  github_integration_enabled: false,  # Set to true to enable GitHub integration
  github_max_concurrent_analyses: 5,  # Maximum number of concurrent analyses
  github_analysis_timeout: 300_000,   # Timeout for analysis in milliseconds (5 minutes)
  github_allowed_organizations: [],   # Empty list allows all organizations
  github_allowed_repositories: []     # Empty list allows all repositories

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