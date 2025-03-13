# Load both implementations
Code.require_file("../example.ex")
Code.require_file("optimized_module.exs")

defmodule Benchmark do
  def run do
    IO.puts("=== Performance Comparison ===\n")
    
    # Test Fibonacci
    test_fibonacci(20)
    
    # Test find_duplicates
    test_find_duplicates([1, 2, 3, 2, 4, 1, 5, 6, 7, 8, 9, 10, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20])
    
    # Test list_to_map
    test_list_to_map(Enum.map(1..1000, fn i -> {:"key#{i}", i} end))
  end
  
  def test_fibonacci(n) do
    IO.puts("=== Testing fibonacci(#{n}) ===")
    
    {time_inefficient, result_inefficient} = :timer.tc(fn -> InefficientAlgorithms.fibonacci(n) end)
    {time_optimized, result_optimized} = :timer.tc(fn -> OptimizedAlgorithms.fibonacci(n) end)
    
    improvement = calculate_improvement(time_inefficient, time_optimized)
    
    IO.puts("Original implementation: #{time_inefficient / 1000} ms")
    IO.puts("Optimized implementation: #{time_optimized / 1000} ms")
    IO.puts("Performance improvement: #{improvement}%")
    IO.puts("Results match: #{result_inefficient == result_optimized}\n")
  end
  
  def test_find_duplicates(list) do
    IO.puts("=== Testing find_duplicates ===")
    
    {time_inefficient, result_inefficient} = :timer.tc(fn -> InefficientAlgorithms.find_duplicates(list) end)
    {time_optimized, result_optimized} = :timer.tc(fn -> OptimizedAlgorithms.find_duplicates(list) end)
    
    # Sort results for comparison since order might be different
    sorted_inefficient = Enum.sort(result_inefficient)
    sorted_optimized = Enum.sort(result_optimized)
    
    improvement = calculate_improvement(time_inefficient, time_optimized)
    
    IO.puts("Original implementation: #{time_inefficient / 1000} ms")
    IO.puts("Optimized implementation: #{time_optimized / 1000} ms")
    IO.puts("Performance improvement: #{improvement}%")
    IO.puts("Results match: #{sorted_inefficient == sorted_optimized}\n")
  end
  
  def test_list_to_map(list) do
    IO.puts("=== Testing list_to_map ===")
    
    {time_inefficient, result_inefficient} = :timer.tc(fn -> InefficientAlgorithms.list_to_map(list) end)
    {time_optimized, result_optimized} = :timer.tc(fn -> OptimizedAlgorithms.list_to_map(list) end)
    
    improvement = calculate_improvement(time_inefficient, time_optimized)
    
    IO.puts("Original implementation: #{time_inefficient / 1000} ms")
    IO.puts("Optimized implementation: #{time_optimized / 1000} ms")
    IO.puts("Performance improvement: #{improvement}%")
    IO.puts("Results match: #{result_inefficient == result_optimized}\n")
  end
  
  defp calculate_improvement(time_before, time_after) do
    improvement = (time_before - time_after) / time_before * 100
    Float.round(improvement, 2)
  end
end

# Run the benchmark
Benchmark.run()
