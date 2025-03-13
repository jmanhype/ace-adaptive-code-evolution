defmodule Ace.Optimization.Languages.Optimizer do
  @moduledoc """
  Behaviour defining the interface for language-specific optimizers.
  
  Each language implementation should implement this behaviour to provide
  language-specific optimization capabilities.
  """
  
  @doc """
  Optimizes code based on an identified opportunity.
  
  ## Parameters
  
    - `opportunity`: The opportunity to optimize
    - `original_code`: The code to optimize
    - `strategy`: The optimization strategy to use
  
  ## Returns
  
    - `{:ok, optimization_data}`: The optimization data with optimized code and explanation
    - `{:error, reason}`: If optimization generation fails
  """
  @callback optimize(opportunity :: struct(), original_code :: String.t(), strategy :: String.t()) ::
    {:ok, %{optimized_code: String.t(), explanation: String.t()}} | {:error, String.t()}
  
  @doc """
  Get the language name associated with this optimizer.
  
  ## Returns
  
    - `String.t()`: The language name
  """
  @callback language() :: String.t()
end