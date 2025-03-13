defmodule Ace.Infrastructure.AI.Providers.Groq do
  @moduledoc """
  Groq LLM provider integration.
  """
  @behaviour Ace.Infrastructure.AI.Provider
  
  @impl true
  def name, do: "groq"
  
  @impl true
  def supported_models do
    [
      "llama3-70b-8192",
      "llama3-8b-8192",
      "mixtral-8x7b-32768",
      "gemma-7b-it"
    ]
  end
  
  @impl true
  def generate(model, prompt, options \\ %{}) do
    api_key = get_api_key()
  
    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]
  
    body = Jason.encode!(%{
      model: model,
      messages: [
        %{role: "system", content: options[:system_prompt] || "You are a helpful assistant."},
        %{role: "user", content: prompt}
      ],
      temperature: options[:temperature] || 0.7,
      max_tokens: options[:max_tokens] || 4096
    })
  
    url = "https://api.groq.com/openai/v1/chat/completions"
  
    with {:ok, response} <- HTTPoison.post(url, body, headers),
         {:ok, data} <- Jason.decode(response.body),
         %{"choices" => [%{"message" => %{"content" => content}} | _]} <- data do
      {:ok, content}
    else
      {:error, %Jason.DecodeError{}} ->
        {:error, :invalid_response}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, {:http_error, reason}}
      error ->
        handle_error(error)
    end
  end
  
  @impl true
  def generate_structured(prompt, system_prompt, schema, model, _options \\ %{}) do
    # Use our InstructorHelper for structured generation
    alias Ace.Infrastructure.AI.Helpers.InstructorHelper

    # Use default system prompt if none provided
    system_msg = system_prompt || "You are a helpful assistant."
    
    # Pass along to InstructorHelper which handles the actual API calls
    InstructorHelper.gen(schema, system_msg, prompt, model)
  end
  
  # Helper functions
  
  defp get_api_key do
    System.get_env("GROQ_API_KEY") ||
      Application.get_env(:ace, :groq_api_key) ||
      raise "Missing Groq API key. Set the GROQ_API_KEY environment variable or configure it in your application config."
  end
  
  defp handle_error(%{"error" => %{"message" => message, "type" => type}}) do
    {:error, {String.to_atom(type), message}}
  end
  
  defp handle_error(error) do
    {:error, {:unknown_error, inspect(error)}}
  end
end