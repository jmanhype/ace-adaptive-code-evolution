defmodule Ace.Infrastructure.AI.Provider do
  @moduledoc """
  Behaviour for LLM provider integrations.
  """
  
  @doc """
  Returns the name of the provider.
  """
  @callback name() :: String.t()
  
  @doc """
  Returns a list of supported models.
  """
  @callback supported_models() :: [String.t()]
  
  @doc """
  Generates a response from a prompt using the specified model.
  """
  @callback generate(model :: String.t(), prompt :: String.t(), options :: map()) :: 
    {:ok, String.t()} | {:error, term()}
  
  @doc """
  Generates a response with structured output using the specified model.
  """
  @callback generate_structured(
    prompt :: String.t(), 
    system_prompt :: String.t(), 
    schema :: map(), 
    model :: String.t(), 
    options :: map()
  ) :: {:ok, map()} | {:error, term()}
end