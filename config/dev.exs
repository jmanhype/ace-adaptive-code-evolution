import Config

# Development configuration for ACE
config :ace, 
  environment: "development",
  ai_provider: "groq",
  supported_languages: ["elixir", "javascript", "python", "ruby", "go"],
  self_evolution_enabled: true,
  evolution_check_interval: 60 * 60 * 1000, # 1 hour
  evolution_modules: [
    [module: Ace.Core.Demo, feedback_source: "demo", threshold: 7.0]
  ],
  autonomous_deploy: true

# Phoenix configuration
config :ace, AceWeb.Endpoint,
  url: [host: "localhost", port: 4000],
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "eOTiYrC3LjzUUPK9Vx3SKuIgv267Wwl/kQJuUP8IH9cGBvC2YVK19GXPE+GxgXHq",
  pubsub_server: Ace.PubSub,
  live_view: [signing_salt: "GCx6kG1OXB4SQKDGQH3lFsm5Uq57ZI31"],
  watchers: [],
  live_reload: [
    patterns: [
      ~r"lib/ace_web/(controllers|live|components)/.*(ex|heex)$",
      ~r"lib/ace_web/templates/.*(eex)$",
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$"
    ]
  ]

config :ace, Ace.Repo,
  database: "ace_dev",
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :logger, :console, format: "[$level] $message\n"

# Configure GitHub token for dev environment
config :ace, :github_token, System.get_env("GITHUB_TOKEN") || "your-test-token-here"

# Configure environment for dev
config :ace, :env, :prod