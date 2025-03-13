defmodule Ace.Optimization.Languages.Elixir do
  @moduledoc """
  Elixir-specific optimizer implementing the Optimizer behaviour.
  """
  @behaviour Ace.Optimization.Languages.Optimizer
  
  alias Ace.Infrastructure.AI.Orchestrator
  
  @doc """
  Optimizes Elixir code based on identified opportunities.
  
  Uses Elixir-specific optimization techniques and patterns.
  """
  @impl true
  def optimize(opportunity, original_code, strategy) do
    # For performance-focused optimizations, apply Elixir-specific optimizers first
    if strategy == "performance" do
      case apply_elixir_specific_optimizations(opportunity, original_code) do
        {:ok, optimization_data} -> {:ok, optimization_data}
        _ -> fallback_to_ai(opportunity, original_code, strategy)
      end
    else
      fallback_to_ai(opportunity, original_code, strategy)
    end
  end
  
  @doc """
  Returns the language name.
  """
  @impl true
  def language, do: "elixir"
  
  # Private helpers
  
  defp fallback_to_ai(opportunity, original_code, strategy) do
    Orchestrator.generate_optimization(opportunity, original_code, strategy)
  end
  
  defp apply_elixir_specific_optimizations(opportunity, original_code) do
    cond do
      String.contains?(opportunity.description, "Enum.map followed by Enum.filter") ->
        optimize_enum_pipeline(original_code)
        
      String.contains?(opportunity.description, "unnecessary list traversal") ->
        optimize_list_traversal(original_code)
        
      String.contains?(opportunity.description, "tail recursion") ->
        optimize_tail_recursion(original_code)
        
      String.contains?(opportunity.description, "unnecessary map merging") ->
        optimize_map_operations(original_code)
        
      true ->
        {:error, "No specific Elixir optimization available"}
    end
  end
  
  defp optimize_enum_pipeline(code) do
    # Pattern match for Enum.map |> Enum.filter or Enum.filter |> Enum.map
    # and replace with Enum.filter_map or Enum.map_filter as appropriate
    cond do
      # Detect map followed by filter pattern
      Regex.match?(~r/Enum\.map\(([^,]+),\s*fn(.*?)\s*end\)\s*\|>\s*Enum\.filter\(fn(.*?)\s*end\)/s, code) ->
        [_, collection, map_fn, filter_fn] =
          Regex.run(~r/Enum\.map\(([^,]+),\s*fn(.*?)\s*end\)\s*\|>\s*Enum\.filter\(fn(.*?)\s*end\)/s, code)
        
        optimized = """
        # Optimized to use a single enumeration
        #{collection}
        |> Enum.reduce([], fn#{map_fn}
          acc = [transformed | acc]
          if#{filter_fn}
            acc
          else
            acc |> List.delete(transformed)
          end
        end)
        |> Enum.reverse()
        """
        
        {:ok, %{
          optimized_code: optimized,
          explanation: "Optimized Enum.map |> Enum.filter to use a single enumeration, reducing the number of list traversals."
        }}
      
      # Detect filter followed by map pattern
      Regex.match?(~r/Enum\.filter\(([^,]+),\s*fn(.*?)\s*end\)\s*\|>\s*Enum\.map\(fn(.*?)\s*end\)/s, code) ->
        [_, collection, filter_fn, map_fn] =
          Regex.run(~r/Enum\.filter\(([^,]+),\s*fn(.*?)\s*end\)\s*\|>\s*Enum\.map\(fn(.*?)\s*end\)/s, code)
        
        optimized = """
        # Optimized to use a single enumeration
        #{collection}
        |> Enum.reduce([], fn element, acc ->
          if#{filter_fn}
            [element#{map_fn} | acc]
          else
            acc
          end
        end)
        |> Enum.reverse()
        """
        
        {:ok, %{
          optimized_code: optimized,
          explanation: "Optimized Enum.filter |> Enum.map to use a single enumeration, reducing the number of list traversals."
        }}
        
      true ->
        {:error, "No matching Enum pipeline pattern found"}
    end
  end
  
  defp optimize_list_traversal(code) do
    # Handle List operations like multiple list traversals or length checks
    cond do
      # Replace list length > 0 with pattern matching
      Regex.match?(~r/length\(([^)]+)\)\s*[>|==]\s*0/, code) ->
        optimized_code = Regex.replace(~r/length\(([^)]+)\)\s*>\s*0/, code, "\\1 != []")
        optimized_code = Regex.replace(~r/length\(([^)]+)\)\s*==\s*0/, optimized_code, "\\1 == []")
        
        {:ok, %{
          optimized_code: optimized_code,
          explanation: "Replaced list length check with pattern matching, which avoids traversing the entire list."
        }}
        
      true ->
        {:error, "No matching list traversal optimization pattern found"}
    end
  end
  
  defp optimize_tail_recursion(_code) do
    # This is a simplistic approach - real implementation would parse the AST
    # to find recursive functions and convert them to tail recursive
    {:error, "Tail recursion optimization needs AST parsing - delegating to AI"}
  end
  
  defp optimize_map_operations(code) do
    # Handle Map operations like multiple update operations
    cond do
      # Replace multiple Map.put with map merging using %{}
      Regex.match?(~r/(\w+)\s*=\s*Map\.put\((\w+),\s*([^,]+),\s*([^)]+)\)[^M]*Map\.put\(\1,\s*([^,]+),\s*([^)]+)\)/, code) ->
        [_, result_var, input_var, key1, value1, key2, value2] =
          Regex.run(~r/(\w+)\s*=\s*Map\.put\((\w+),\s*([^,]+),\s*([^)]+)\)[^M]*Map\.put\(\1,\s*([^,]+),\s*([^)]+)\)/, code)
        
        optimized = """
        # Optimized to use a single map update
        #{result_var} = Map.merge(#{input_var}, %{
          #{key1} => #{value1},
          #{key2} => #{value2}
        })
        """
        
        {:ok, %{
          optimized_code: optimized,
          explanation: "Replaced multiple Map.put operations with a single Map.merge operation."
        }}
        
      true ->
        {:error, "No matching map operations optimization pattern found"}
    end
  end
end