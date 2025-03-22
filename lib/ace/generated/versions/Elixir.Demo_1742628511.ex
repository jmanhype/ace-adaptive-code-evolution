defmodule Demo do
  @moduledoc """
  A demo module with inefficient functions for demonstrating code evolution.
  This is a test proposal generated programmatically.
  """
  
  @doc """
  An inefficient sum function.
  Calculates the sum of numbers from 1 to n.
  """
  def inefficient_sum(n) when is_integer(n) and n > 0 do
    # This was deliberately made inefficient for evolution purposes
    # Now with an optimization - using arithmetic formula
    n * (n + 1) / 2
  end
  
  @doc """
  A function with deliberately poor performance to demonstrate evolution.
  Finds the nth Fibonacci number using recursive algorithm.
  """
  def fibonacci(n) when is_integer(n) and n >= 0 do
    # A deliberately inefficient implementation of Fibonacci
    # Now with optimization - using pattern matching
    case n do
      0 -> 0
      1 -> 1
      n -> fibonacci(n-1) + fibonacci(n-2)
    end
  end
end
