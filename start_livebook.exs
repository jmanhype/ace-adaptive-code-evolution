# This script starts both the Phoenix server and a LiveBook server for the ACE application
# Usage: elixir start_livebook.exs

# Install required dependencies
Mix.install([
  {:livebook, "~> 0.9.0"},  # Using a much older version for compatibility
  {:kino, "~> 0.8.0"},      # Using compatible kino version
  {:kino_vega_lite, "~> 0.1.7"}
])

# Configure LiveBook
Application.put_env(:livebook, :runtime, runtime: :standalone)
Application.put_env(:livebook, :default_runtime, {:embedded, runtime: :standalone})
Application.put_env(:livebook, :port, 4001)

# Start LiveBook
Livebook.Config.reload()
{:ok, _} = Supervisor.start_link([{Livebook.Supervisor, []}], strategy: :one_for_one)

# Load the Phoenix application configuration
Application.put_env(:phoenix, :serve_endpoints, true)
Code.eval_file("config/config.exs")
Code.eval_file("config/dev.exs")

# Set up Ace application
Application.put_env(:ace, :environment, "development")

# Start the Phoenix application
{:ok, _} = Application.ensure_all_started(:ace)

IO.puts("\n")
IO.puts("🚀 ACE is running at: http://localhost:4000")
IO.puts("📚 LiveBook is running at: http://localhost:4001")
IO.puts("\n")
IO.puts("Press Ctrl+C twice to stop the servers.")

# Keep the process alive
Process.sleep(:infinity) 