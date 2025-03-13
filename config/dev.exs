import Config

# Development configuration for ACE
config :ace, 
  environment: "development",
  ai_provider: "mock",
  supported_languages: ["elixir", "javascript", "python", "ruby", "go"]

# Phoenix configuration
config :ace, AceWeb.Endpoint,
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