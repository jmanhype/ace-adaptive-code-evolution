# Test script for ACE API integration
# Usage: mix run scripts/test_api.exs

IO.puts("ACE API Integration Test")
IO.puts("=======================\n")

# Check for API keys
api_keys = %{
  "GROQ_API_KEY" => System.get_env("GROQ_API_KEY"),
  "OPENAI_API_KEY" => System.get_env("OPENAI_API_KEY"),
  "ANTHROPIC_API_KEY" => System.get_env("ANTHROPIC_API_KEY")
}

# Print available API keys
IO.puts("Available API keys:")
Enum.each(api_keys, fn {name, value} ->
  status = if value && value != "", do: "✅ Available", else: "❌ Not found"
  IO.puts("  #{name}: #{status}")
end)

# Check if any API keys are available
if Enum.all?(api_keys, fn {_, v} -> is_nil(v) || v == "" end) do
  IO.puts("\nNo API keys found. Using mock provider.")
  IO.puts("To use real AI, set one of these environment variables:")
  IO.puts("  export GROQ_API_KEY=your_api_key")
  IO.puts("  export OPENAI_API_KEY=your_api_key")
  IO.puts("  export ANTHROPIC_API_KEY=your_api_key")
  System.halt(1)
end

# Test code optimization
IO.puts("\nTesting code optimization...")

code = """
defmodule Inefficient do
  def sum_of_squares_of_even_numbers(list) do
    filtered = Enum.filter(list, fn x -> rem(x, 2) == 0 end)
    squared = Enum.map(filtered, fn x -> x * x end)
    Enum.reduce(squared, 0, fn x, acc -> x + acc end)
  end
end
"""

opportunity = %{
  id: "test-opt-1",
  type: "performance",
  description: "Inefficient pipeline in sum_of_squares_of_even_numbers",
  location: "function sum_of_squares_of_even_numbers/1",
  severity: "medium",
  rationale: "Using separate operations creates unnecessary intermediate lists",
  suggested_change: "Use a pipeline with filter, map, and sum"
}

# Call the orchestrator directly
{:ok, result} = Ace.Infrastructure.AI.Orchestrator.generate_optimization(opportunity, code, "performance")

IO.puts("\nOptimization Results:")
IO.puts("--------------------")
IO.puts("Explanation: #{result.explanation}")
IO.puts("\nOptimized code:")
IO.puts(result.optimized_code)

# Test cross-file analysis
IO.puts("\nTesting cross-file analysis...")

file_contexts = [
  %{
    file_path: "utils.ex",
    file_name: "utils.ex",
    language: "elixir",
    content: """
    defmodule Utils do
      def factorial(0), do: 1
      def factorial(n) when n > 0, do: n * factorial(n - 1)
      
      def prime?(n) when n <= 1, do: false
      def prime?(2), do: true
      def prime?(n) do
        2..trunc(:math.sqrt(n))
        |> Enum.all?(fn x -> rem(n, x) != 0 end)
      end
    end
    """
  },
  %{
    file_path: "app.ex",
    file_name: "app.ex",
    language: "elixir",
    content: """
    defmodule App do
      def is_prime?(n) when n <= 1, do: false
      def is_prime?(2), do: true
      def is_prime?(n) do
        2..trunc(:math.sqrt(n))
        |> Enum.all?(fn x -> rem(n, x) != 0 end)
      end
    end
    """
  }
]

{:ok, opportunities} = Ace.Infrastructure.AI.Orchestrator.analyze_cross_file(
  file_contexts,
  "elixir",
  [focus_areas: ["performance", "maintainability"]]
)

IO.puts("\nCross-file Analysis Results:")
IO.puts("---------------------------")
IO.puts("Found #{length(opportunities)} opportunities:\n")

Enum.each(opportunities, fn opp ->
  IO.puts("Type: #{opp.type || opp["type"]} (Severity: #{opp.severity || opp["severity"]})")
  IO.puts("Description: #{opp.description || opp["description"]}")
  IO.puts("")
end)

IO.puts("\nAPI Integration test completed successfully!✅")