defmodule OptimizedAlgorithms do
  @moduledoc """
  A module containing optimized algorithm implementations
  corresponding to the inefficient ones in InefficientAlgorithms.
  """
  
  @doc """
  Calculates the nth Fibonacci number using an optimized approach
  with memoization to avoid repeated calculations.
  
  ## Parameters
  
    - n: The position in the Fibonacci sequence
  
  ## Examples
  
      iex> OptimizedAlgorithms.fibonacci(10)
      55
  """
  def fibonacci(n), do: fibonacci(n, %{0 => 0, 1 => 1})

  defp fibonacci(n, memo) when is_map_key(memo, n), do: memo[n]
  
  defp fibonacci(n, memo) do
    {result, new_memo} = fibonacci_calc(n, memo)
    result
  end
  
  defp fibonacci_calc(n, memo) do
    {fib_1, memo1} = 
      if is_map_key(memo, n-1) do
        {memo[n-1], memo}
      else
        fibonacci_calc(n-1, memo)
      end
      
    {fib_2, memo2} = 
      if is_map_key(memo1, n-2) do
        {memo1[n-2], memo1}
      else
        fibonacci_calc(n-2, memo1)
      end
      
    result = fib_1 + fib_2
    {result, Map.put(memo2, n, result)}
  end
  
  @doc """
  Finds duplicate elements in a list using a more efficient
  approach with a single pass and a set for O(n) complexity.
  
  ## Parameters
  
    - list: The input list to search for duplicates
  
  ## Examples
  
      iex> OptimizedAlgorithms.find_duplicates([1, 2, 3, 2, 4, 1, 5])
      [1, 2]
  """
  def find_duplicates(list) do
    {dupes, _} = Enum.reduce(list, {[], MapSet.new()}, fn item, {dupes, seen} ->
      if MapSet.member?(seen, item) do
        if Enum.member?(dupes, item) do
          {dupes, seen}
        else
          {[item | dupes], seen}
        end
      else
        {dupes, MapSet.put(seen, item)}
      end
    end)
    
    Enum.reverse(dupes)
  end
  
  @doc """
  Converts a list of two-element tuples into a map using a more efficient
  approach with Enum.into for a single pass.
  
  ## Parameters
  
    - tuple_list: A list of {key, value} tuples
  
  ## Examples
  
      iex> OptimizedAlgorithms.list_to_map([{:a, 1}, {:b, 2}, {:c, 3}])
      %{a: 1, b: 2, c: 3}
  """
  def list_to_map(tuple_list) do
    Enum.into(tuple_list, %{})
  end
end

# Create and save the module file
IO.puts("Running example to test the optimized implementations...")

# Test the Fibonacci function
{time, result} = :timer.tc(fn -> OptimizedAlgorithms.fibonacci(20) end)
IO.puts("Fibonacci(20) = #{result} (calculated in #{time / 1000} ms)")

# Test the duplicate finder
{time, result} = :timer.tc(fn -> OptimizedAlgorithms.find_duplicates([1, 2, 3, 2, 4, 1, 5, 6, 7, 8, 9, 10, 10]) end)
IO.puts("find_duplicates result: #{inspect(result)} (calculated in #{time / 1000} ms)")

# Test the list to map conversion  
{time, result} = :timer.tc(fn -> OptimizedAlgorithms.list_to_map([{:a, 1}, {:b, 2}, {:c, 3}, {:d, 4}, {:e, 5}]) end)
IO.puts("list_to_map result: #{inspect(result)} (calculated in #{time / 1000} ms)")
