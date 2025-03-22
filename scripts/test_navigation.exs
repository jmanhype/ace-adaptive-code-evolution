# Script to test navigation in the ACE application
# Run with: mix run scripts/test_navigation.exs

ExUnit.start()

defmodule NavigationTest do
  use ExUnit.Case, async: false
  
  @base_url "http://localhost:4000"
  
  # List of paths to test
  @paths [
    "/",
    "/files",
    "/opportunities",
    "/optimizations",
    "/evaluations",
    "/projects",
    "/evolution",
    "/evolution/proposals"
  ]
  
  test "all routes respond with 200 status" do
    # Print start message
    IO.puts "Starting navigation tests..."
    
    # Test each path
    Enum.each(@paths, fn path ->
      url = @base_url <> path
      IO.puts "Testing #{url}..."
      
      # Make the request
      case :httpc.request(:get, {String.to_charlist(url), []}, [], []) do
        {:ok, {{_, status_code, _}, _headers, _body}} ->
          # Assert we got a 200 status code
          assert status_code == 200
          IO.puts "  ✅ OK - Status: #{status_code}"
          
        {:error, reason} ->
          IO.puts "  ❌ Error: #{inspect(reason)}"
          assert false, "Failed to connect to #{url}: #{inspect(reason)}"
      end
    end)
    
    IO.puts "Navigation tests completed successfully!"
  end
end