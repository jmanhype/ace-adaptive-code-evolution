import Config

config :ace, Ace.Repo,
  database: System.get_env("POSTGRES_DB", "ace_test"),
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

config :ace, :environment, :test

# Configure the LLM provider to use a mock in tests
config :ace, :llm_provider, "mock"
config :ace, :llm_model, "mock_model"

# Configure InstructorHelper to use the mock implementation in tests
config :ace, :instructor_helper_module, Ace.Test.Mocks.MockInstructorHelper

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :logger, level: :warning