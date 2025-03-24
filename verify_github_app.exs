# Run with: mix run verify_github_app.exs

# Load environment variables
System.put_env("GITHUB_APP_ID", System.get_env("GITHUB_APP_ID", ""))
System.put_env("GITHUB_APP_INSTALLATION_ID", System.get_env("GITHUB_APP_INSTALLATION_ID", ""))
System.put_env("GITHUB_APP_PRIVATE_KEY_PATH", System.get_env("GITHUB_APP_PRIVATE_KEY_PATH", "priv/github_app_key.pem"))

if System.get_env("GITHUB_APP_ID") == "" do
  IO.puts("\n\e[31mError: GITHUB_APP_ID environment variable is not set.\e[0m")
  IO.puts("Please run this script with the dev_server.sh script or set the environment variable.")
  System.halt(1)
end

if System.get_env("GITHUB_APP_INSTALLATION_ID") == "" do
  IO.puts("\n\e[31mError: GITHUB_APP_INSTALLATION_ID environment variable is not set.\e[0m")
  IO.puts("Please run this script with the dev_server.sh script or set the environment variable.")
  System.halt(1)
end

# Check if the private key file exists
private_key_path = System.get_env("GITHUB_APP_PRIVATE_KEY_PATH")
unless File.exists?(private_key_path) do
  IO.puts("\n\e[31mError: GitHub App private key file not found at #{private_key_path}\e[0m")
  IO.puts("Please download your private key from GitHub and save it to this location.")
  System.halt(1)
end

# Test loading the private key
private_key = case File.read(private_key_path) do
  {:ok, key} -> key
  {:error, reason} ->
    IO.puts("\n\e[31mError: Failed to read private key file: #{reason}\e[0m")
    System.halt(1)
end

IO.puts("\n\e[32m✓ Successfully loaded private key from #{private_key_path}\e[0m")

# Verify other configuration
IO.puts("\e[32m✓ GitHub App ID: #{System.get_env("GITHUB_APP_ID")}\e[0m")
IO.puts("\e[32m✓ GitHub App Installation ID: #{System.get_env("GITHUB_APP_INSTALLATION_ID")}\e[0m")

# Load app auth module
Code.require_file("lib/ace/github/app_auth.ex")

# Test JWT token generation
try do
  jwt = Ace.GitHub.AppAuth.generate_jwt_token()
  IO.puts("\e[32m✓ Successfully generated JWT token\e[0m")

  # Test installation token generation
  case Ace.GitHub.AppAuth.get_installation_token() do
    {:ok, token} ->
      IO.puts("\e[32m✓ Successfully generated installation token\e[0m")
      IO.puts("\n\e[32mAll GitHub App configuration tests passed! Your setup is working correctly.\e[0m")
    
    {:error, reason} ->
      IO.puts("\n\e[31mError: Failed to get installation token: #{inspect(reason)}\e[0m")
      IO.puts("\nPlease check your GitHub App installation ID and permissions.")
      System.halt(1)
  end
rescue
  e ->
    IO.puts("\n\e[31mError: #{inspect(e)}\e[0m")
    IO.puts("\nPlease check your GitHub App configuration.")
    System.halt(1)
end 