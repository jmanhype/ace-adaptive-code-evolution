import Config

config :ace,
  ecto_repos: [Ace.Repo]

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