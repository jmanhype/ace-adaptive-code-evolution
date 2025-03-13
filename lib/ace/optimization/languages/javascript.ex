defmodule Ace.Optimization.Languages.JavaScript do
  @moduledoc """
  JavaScript-specific optimizer implementing the Optimizer behaviour.
  
  Provides specialized optimizations for JavaScript code patterns.
  """
  @behaviour Ace.Optimization.Languages.Optimizer
  
  alias Ace.Infrastructure.AI.Orchestrator
  
  @doc """
  Optimizes JavaScript code based on identified opportunities.
  
  Uses JavaScript-specific optimization techniques and patterns.
  """
  @impl true
  def optimize(opportunity, original_code, strategy) do
    # For performance-focused optimizations, apply JavaScript-specific optimizers first
    if strategy == "performance" do
      case apply_js_specific_optimizations(opportunity, original_code) do
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
  def language, do: "javascript"
  
  # Private helpers
  
  defp fallback_to_ai(opportunity, original_code, strategy) do
    Orchestrator.generate_optimization(opportunity, original_code, strategy)
  end
  
  defp apply_js_specific_optimizations(opportunity, original_code) do
    cond do
      String.contains?(opportunity.description, "array iteration") ->
        optimize_array_iteration(original_code)
        
      String.contains?(opportunity.description, "DOM manipulation") ->
        optimize_dom_operations(original_code)
        
      String.contains?(opportunity.description, "object literals") ->
        optimize_object_operations(original_code)
        
      String.contains?(opportunity.description, "async operations") ->
        optimize_async_operations(original_code)
        
      true ->
        {:error, "No specific JavaScript optimization available"}
    end
  end
  
  defp optimize_array_iteration(code) do
    cond do
      # Replace multiple iterations with a single reduce operation
      Regex.match?(~r/(\w+)\.map\((.+?)\)\.filter\((.+?)\)/s, code) ->
        [_, array, map_fn, filter_fn] =
          Regex.run(~r/(\w+)\.map\((.+?)\)\.filter\((.+?)\)/s, code)
        
        optimized = """
        // Optimized to use a single array iteration
        #{array}.reduce((acc, element) => {
          const transformed = #{String.replace(map_fn, "function", "")}(element);
          if (#{String.replace(filter_fn, "function", "")}(transformed)) {
            acc.push(transformed);
          }
          return acc;
        }, [])
        """
        
        {:ok, %{
          optimized_code: optimized,
          explanation: "Optimized array.map().filter() to use a single reduce operation, improving performance by avoiding multiple array iterations."
        }}
        
      # Replace forEach with for...of
      Regex.match?(~r/(\w+)\.forEach\((.+?)\)/s, code) ->
        [_, array, callback] =
          Regex.run(~r/(\w+)\.forEach\((.+?)\)/s, code)
        
        # Parse callback to extract parameter
        param = case Regex.run(~r/(?:function\s*\(([^)]+)\)|(?:\(([^)]+)\)\s*=>))/, callback) do
          [_, param_name] -> param_name
          [_, _, param_name] -> param_name
          _ -> "item"
        end
        
        body = Regex.replace(~r/(?:function\s*\([^)]+\)\s*{(.*)}|(?:\([^)]+\)\s*=>\s*(?:{(.*)})|(.*)))/, callback, "\\1\\2\\3")
        
        optimized = """
        // Optimized to use for...of loop (faster than forEach in most JS engines)
        for (const #{param} of #{array}) {
          #{body}
        }
        """
        
        {:ok, %{
          optimized_code: optimized,
          explanation: "Replaced .forEach() with a for...of loop, which generally has better performance in most JavaScript engines."
        }}
        
      true ->
        {:error, "No matching array iteration pattern found"}
    end
  end
  
  defp optimize_dom_operations(code) do
    cond do
      # Replace multiple querySelector calls with a single call
      Regex.match?(~r/document\.querySelector(?:All)?\(['"]([^'"]+)['"]\)[^d]*document\.querySelector(?:All)?\(['"]([^'"]+)['"]\)/s, code) ->
        optimized_code = Regex.replace(
          ~r/const\s+(\w+)\s*=\s*document\.querySelector\(['"]([^'"]+)['"]\);?\s*const\s+(\w+)\s*=\s*document\.querySelector\(['"]([^'"]+)['"]\);?/s,
          code,
          """
          // Optimized to use a single DOM operation
          const [\\1, \\3] = [document.querySelector('\\2'), document.querySelector('\\4')];
          """
        )
        
        {:ok, %{
          optimized_code: optimized_code,
          explanation: "Optimized multiple document.querySelector calls into a single DOM operation, reducing layout thrashing."
        }}
        
      # Replace multiple appendChild with DocumentFragment
      Regex.match?(~r/(\w+)\.appendChild\((\w+)[^a]*appendChild/s, code) ->
        [_, parent, _] =
          Regex.run(~r/(\w+)\.appendChild\((\w+)/s, code)
        
        # This is a simplified version - in real implementation we'd extract all appendChild calls
        optimized = """
        // Optimized to use DocumentFragment for batch DOM updates
        const fragment = document.createDocumentFragment();
        #{Regex.replace(~r/#{parent}\.appendChild/sg, code, "fragment.appendChild")}
        #{parent}.appendChild(fragment);
        """
        
        {:ok, %{
          optimized_code: optimized,
          explanation: "Replaced multiple appendChild operations with a DocumentFragment for batch DOM updates, improving rendering performance."
        }}
        
      true ->
        {:error, "No matching DOM operation pattern found"}
    end
  end
  
  defp optimize_object_operations(code) do
    cond do
      # Replace Object.assign with spread syntax
      Regex.match?(~r/Object\.assign\(({[^}]*}|[^,]+), ({[^}]*}|[^,)]+)\)/s, code) ->
        optimized_code = Regex.replace(
          ~r/Object\.assign\(({[^}]*}|[^,]+), ({[^}]*}|[^,)]+)\)/s,
          code,
          "{...\\1, ...\\2}"
        )
        
        {:ok, %{
          optimized_code: optimized_code,
          explanation: "Replaced Object.assign() with object spread syntax for better readability and potentially better performance."
        }}
        
      true ->
        {:error, "No matching object operation pattern found"}
    end
  end
  
  defp optimize_async_operations(code) do
    cond do
      # Replace Promise chains with async/await
      Regex.match?(~r/(\w+)\.then\((.+?)\)\.then\((.+?)\)/s, code) ->
        [_, promise, then1, then2] =
          Regex.run(~r/(\w+)\.then\((.+?)\)\.then\((.+?)\)/s, code)
          
        # Extract parameter and function body
        param1 = case Regex.run(~r/(?:function\s*\(([^)]+)\)|(?:\(([^)]+)\)\s*=>))/, then1) do
          [_, param_name] -> param_name
          [_, _, param_name] -> param_name
          _ -> "result1"
        end
        
        body1 = Regex.replace(~r/(?:function\s*\([^)]+\)\s*{(.*?)}|(?:\([^)]+\)\s*=>\s*(?:{(.*?)}|(.*?))))/, then1, "\\1\\2\\3")
        |> String.trim()
        |> String.replace(~r/return\s+/, "const result = ")
        
        param2 = case Regex.run(~r/(?:function\s*\(([^)]+)\)|(?:\(([^)]+)\)\s*=>))/, then2) do
          [_, param_name] -> param_name
          [_, _, param_name] -> param_name
          _ -> "result2"
        end
        
        body2 = Regex.replace(~r/(?:function\s*\([^)]+\)\s*{(.*?)}|(?:\([^)]+\)\s*=>\s*(?:{(.*?)}|(.*?))))/, then2, "\\1\\2\\3")
        |> String.trim()
        
        optimized = """
        // Optimized to use async/await
        (async () => {
          const #{param1} = await #{promise};
          #{body1}
          const #{param2} = await result;
          #{body2}
        })();
        """
        
        {:ok, %{
          optimized_code: optimized,
          explanation: "Replaced Promise chain with async/await for better readability and easier error handling."
        }}
        
      true ->
        {:error, "No matching async operation pattern found"}
    end
  end
end