defmodule Ace.Evolution.SimpleAIService do
  @moduledoc """
  A simpler implementation for generating structured AI responses for evolution.
  """
  require Logger
  
  @doc """
  Generates optimized code for a given source using a structured JSON schema.
  
  Returns:
  - {:ok, %{optimized_code: String.t(), explanation: String.t()}} on success
  - {:error, reason} on failure
  """
  def generate_optimization(source_code, feedback) do
    # Extract feedback data
    %{
      nps_score: nps_score,
      recent_comments: comments
    } = feedback
    
    # Format comments for the prompt
    formatted_comments = format_comments(comments)
    
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
    
    User feedback indicates issues with this code:
    - NPS Score: #{nps_score}
    - User comments:
    #{formatted_comments}
    
    Improve the code to address these issues. Focus on performance and readability.
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
    
    # Call AI
    call_ai_api(prompt, system_prompt, schema)
  end
  
  # Private helper functions
  
  defp format_comments(comments) do
    comments
    |> Enum.map(fn %{score: score, comment: comment} ->
      "- Score #{score}/10: \"#{comment}\""
    end)
    |> Enum.join("\n")
  end
  
  defp call_ai_api(prompt, system_prompt, schema) do
    groq_key = System.get_env("GROQ_API_KEY")
    
    if is_nil(groq_key) || groq_key == "" do
      # No key available, return mock data
      {:ok, %{
        optimized_code: """
        defmodule Demo do
          @doc \"\"\"
          Calculates the sum of a list of numbers using the efficient built-in function.
          \"\"\"
          def inefficient_sum(list) do
            Enum.sum(list)
          end
        end
        """,
        explanation: "Replaced manual reduction with built-in Enum.sum/1 for better performance and readability."
      }}
    else
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
          case Jason.decode(response.body) do
            {:ok, data} ->
              if Map.has_key?(data, "choices") do
                content = data["choices"]
                  |> List.first()
                  |> Map.get("message")
                  |> Map.get("content")
                
                case Jason.decode(content) do
                  {:ok, parsed} ->
                    # Extract the data we need
                    optimized_code = Map.get(parsed, "optimized_code")
                    explanation = Map.get(parsed, "explanation")
                    
                    if optimized_code && explanation do
                      {:ok, %{
                        optimized_code: optimized_code,
                        explanation: explanation
                      }}
                    else
                      Logger.error("Missing required fields in response: #{inspect(parsed)}")
                      {:error, :invalid_response}
                    end
                  
                  {:error, error} ->
                    Logger.error("Error parsing JSON from response: #{inspect(error)}")
                    {:error, :json_parse_error}
                end
              else
                Logger.error("No choices in response: #{inspect(data)}")
                {:error, :no_choices}
              end
              
            {:error, error} ->
              Logger.error("Failed to decode response body: #{inspect(error)}")
              {:error, :decode_error}
          end
          
        {:error, error} ->
          Logger.error("Request failed: #{inspect(error)}")
          {:error, :request_failed}
      end
    end
  end
end