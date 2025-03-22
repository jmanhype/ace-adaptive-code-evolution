defmodule Demo.V1741961610 do
  @moduledoc """
  Optimized demonstration module
  """
  
  @doc """
  Efficiently sums a list of numbers using built-in Enum.sum/1
  
  ## Examples
      
      iex> Demo.inefficient_sum([1, 2, 3, 4, 5])
      15
      
  """
  def inefficient_sum(list) do
    Enum.sum(list)
  end
  
  @doc """
  Handles empty lists gracefully by returning 0
  """
  def inefficient_sum([]), do: 0
end
