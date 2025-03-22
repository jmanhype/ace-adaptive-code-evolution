require Logger
groq_key = System.get_env("GROQ_API_KEY")

IO.puts("Testing direct Groq API connection...")

# Define a simple optimization task
source_code = """
defmodule Demo do
  def inefficient_sum(list) do
    Enum.reduce(list, 0, fn num, acc -> acc + num end)
  end
end
"""

# Create a simplified prompt
system_prompt = """
You are an AI system specialized in optimizing Elixir code.
Respond with valid JSON containing: 
1. "optimized_code" - The optimized code implementation
2. "explanation" - Brief explanation of your changes
"""

prompt = """
Please optimize this Elixir code:

```elixir
#{source_code}
```

User feedback indicates performance issues. Improve it to be more efficient.
"""

# Define schema for the response
schema = %{
  "type" => "object",
  "properties" => %{
    "optimized_code" => %{
      "type" => "string",
      "description" => "The complete optimized implementation of the module"
    },
    "explanation" => %{
      "type" => "string",
      "description" => "Brief explanation of the changes made to address performance issues"
    }
  },
  "required" => ["optimized_code", "explanation"]
}

# Prepare the request
headers = [
  {"Authorization", "Bearer #{groq_key}"},
  {"Content-Type", "application/json"}
]

# Prepare structured system prompt
schema_json = Jason.encode!(schema)
system_content = "#{system_prompt}\n\nYou MUST respond with JSON that matches this schema: #{schema_json}"

# Create the request body
body = Jason.encode!(%{
  model: "llama3-70b-8192",
  messages: [
    %{role: "system", content: system_content},
    %{role: "user", content: prompt}
  ],
  temperature: 0.2,
  response_format: %{type: "json_object"},
  max_tokens: 4096
})

# Send the request to Groq API
url = "https://api.groq.com/openai/v1/chat/completions"

case HTTPoison.post(url, body, headers) do
  {:ok, response} ->
    IO.puts("Response status: #{response.status_code}")
    
    case Jason.decode(response.body) do
      {:ok, data} ->
        if Map.has_key?(data, "choices") do
          content = data["choices"]
            |> List.first()
            |> Map.get("message")
            |> Map.get("content")
          
          IO.puts("\nAI Response content:")
          IO.puts("===================")
          IO.puts(content)
          IO.puts("===================")
          
          # Try to parse the JSON from the content
          case Jason.decode(content) do
            {:ok, parsed} ->
              IO.puts("\nParsed JSON response:")
              IO.inspect(parsed, pretty: true)
              
              # Use it to create a proposal
              code = Map.get(parsed, "optimized_code")
              explanation = Map.get(parsed, "explanation")
              
              IO.puts("\n✅ Extracted optimized code:")
              IO.puts(code)
              
              IO.puts("\n✅ Extracted explanation:")
              IO.puts(explanation)
            
            {:error, error} ->
              IO.puts("❌ Error parsing JSON from response: #{inspect(error)}")
              IO.puts("Content that failed to parse:\n#{content}")
          end
        else
          IO.puts("❌ No choices in response: #{inspect(data)}")
        end
        
      {:error, error} ->
        IO.puts("❌ Failed to decode response body: #{inspect(error)}")
        IO.puts("Raw response body: #{response.body}")
    end
    
  {:error, error} ->
    IO.puts("❌ Request failed: #{inspect(error)}")
end