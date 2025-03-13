# Skip loading the web and GraphQL modules in test environment
Application.put_env(:ace, :skip_web, true)
Application.put_env(:ace, :skip_graphql, true)
Application.put_env(:phoenix, :json_library, Jason)
Application.put_env(:ace, :ai_provider, Ace.Infrastructure.AI.Providers.Mock)

# Add a compiler filter to exclude problematic modules during test
Code.compiler_options(ignore_module_conflict: true)

# Define mocks for problematic modules
defmodule Absinthe.Schema do
  defmacro __using__(_) do
    quote do
      # Empty mock
    end
  end
end

defmodule Absinthe.Schema.Notation do
  defmacro __using__(_) do
    quote do
      # Empty mock
    end
  end
end

defmodule AceWeb do
  defmacro __using__(_) do
    quote do
      # Empty mock
    end
  end
end

# Start ExUnit with configuration
ExUnit.start(exclude: [:web, :graphql, :integration])

# Configure and start Ecto for testing
Ecto.Adapters.SQL.Sandbox.mode(Ace.Repo, :manual)
