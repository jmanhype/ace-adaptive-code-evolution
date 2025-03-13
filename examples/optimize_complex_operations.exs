defmodule ComplexOperations do
  @doc """
  Finds the sum of squares of even numbers in a list.
  This implementation is inefficient and can be optimized.
  """
  def sum_of_squares_of_even_numbers(list) do
    # Filter even numbers
    even_numbers = Enum.filter(list, fn num -> 
      rem(num, 2) == 0
    end)
    
    # Calculate squares
    squares = Enum.map(even_numbers, fn num -> 
      num * num
    end)
    
    # Sum the squares
    Enum.reduce(squares, 0, fn square, acc -> 
      acc + square
    end)
  end
  
  @doc """
  Merges two lists by alternating their elements.
  This implementation is inefficient and can be optimized.
  """
  def merge_alternating(list1, list2) do
    # Get the length of the shorter list
    min_length = min(length(list1), length(list2))
    
    # Initialize result list
    result = []
    
    # Merge elements
    result = Enum.reduce(0..(min_length - 1), result, fn i, acc ->
      acc ++ [Enum.at(list1, i), Enum.at(list2, i)]
    end)
    
    # Append remaining elements from longer list
    if length(list1) > min_length do
      result ++ Enum.slice(list1, min_length..-1)
    else
      if length(list2) > min_length do
        result ++ Enum.slice(list2, min_length..-1)
      else
        result
      end
    end
  end
  
  @doc """
  Counts word frequency in a string.
  This implementation is inefficient and can be optimized.
  """
  def word_frequency(text) do
    # Split text into words
    words = String.split(text, ~r/\s+/, trim: true)
    
    # Count word frequencies
    Enum.reduce(words, %{}, fn word, acc ->
      word = String.downcase(word)
      if Map.has_key?(acc, word) do
        Map.put(acc, word, acc[word] + 1)
      else
        Map.put(acc, word, 1)
      end
    end)
  end
end