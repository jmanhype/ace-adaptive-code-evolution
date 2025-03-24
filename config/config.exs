# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ace,
  ecto_repos: [Ace.Repo],
  # Self-evolution configuration
  self_evolution_enabled: true,
  autonomous_deploy: false,
  evolution_check_interval: 60,  # 60 minutes in milliseconds
  evolution_model: "llama3-70b-8192",
  notification_channels: ["slack"],
  slack_webhook_url: nil,
  notification_emails: [],
  evolution_modules: ["Demo"],
  # Enable or disable automatic code generation with LLM
  code_generation_enabled: true,
  # Provider to use for AI (can be :openai, :anthropic, :azure_openai)
  ai_provider: :openai,
  # Environment name (dev/test/prod)
  environment: "dev",
  # Languages the system can understand and optimize
  supported_languages: ["elixir", "python", "javascript", "typescript", "ruby", "go"],
  # GitHub integration settings
  github_webhook_secret: System.get_env("GITHUB_WEBHOOK_SECRET"),
  github_token: System.get_env("GITHUB_TOKEN"),
  # GitHub App configuration
  github_app: %{
    app_id: System.get_env("GITHUB_APP_ID"),
    installation_id: System.get_env("GITHUB_APP_INSTALLATION_ID"),
    private_key_path: System.get_env("GITHUB_APP_PRIVATE_KEY_PATH")
  },
  # PR optimization service to use - can be "mock" (CodeOptimizer), "evolution" (Evolution.Service), or "optimization" (Optimization.Service)
  pr_optimization_service: System.get_env("ACE_PR_OPTIMIZATION_SERVICE") || "optimization"

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