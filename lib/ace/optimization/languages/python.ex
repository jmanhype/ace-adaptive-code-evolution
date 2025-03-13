defmodule Ace.Optimization.Languages.Python do
  @moduledoc """
  Python-specific optimizer implementing the Optimizer behaviour.
  
  Provides specialized optimizations for Python code patterns.
  """
  @behaviour Ace.Optimization.Languages.Optimizer
  
  alias Ace.Infrastructure.AI.Orchestrator
  
  @doc """
  Optimizes Python code based on identified opportunities.
  
  Uses Python-specific optimization techniques and patterns.
  """
  @impl true
  def optimize(opportunity, original_code, strategy) do
    # Handle options if provided
    opportunity = if is_map(opportunity) && Map.has_key?(opportunity, :options) do
      opportunity
    else
      Map.put(opportunity, :options, %{})
    end
    
    # For performance-focused optimizations, apply Python-specific optimizers first
    if strategy == "performance" do
      case apply_python_specific_optimizations(opportunity, original_code) do
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
  def language, do: "python"
  
  # Private helpers
  
  defp fallback_to_ai(opportunity, original_code, strategy) do
    Orchestrator.generate_optimization(opportunity, original_code, strategy)
  end
  
  defp apply_python_specific_optimizations(opportunity, original_code) do
    cond do
      String.contains?(opportunity.description, "list comprehension") ->
        optimize_list_operations(original_code)
        
      String.contains?(opportunity.description, "loop performance") ->
        optimize_loop_performance(original_code)
        
      String.contains?(opportunity.description, "string concatenation") ->
        optimize_string_operations(original_code)
        
      String.contains?(opportunity.description, "dictionary operations") ->
        optimize_dict_operations(original_code)
        
      String.contains?(opportunity.description, "type hints") ->
        add_type_hints(original_code, opportunity.options)
        
      String.contains?(opportunity.description, "generators") ->
        optimize_with_generators(original_code)
        
      String.contains?(opportunity.description, "context manager") ->
        optimize_with_context_managers(original_code)
        
      true ->
        {:error, "No specific Python optimization available"}
    end
  end
  
  defp optimize_list_operations(code) do
    cond do
      # Replace list append in loop with list comprehension
      Regex.match?(~r/(\w+)\s*=\s*\[\]\s*for\s+(\w+)\s+in\s+([^:]+):\s*\n\s*[^#\n]*(\w+)\.append\(([^)]+)\)/s, code) ->
        [_, result_var, iterator, iterable, append_var, expression] =
          Regex.run(~r/(\w+)\s*=\s*\[\]\s*for\s+(\w+)\s+in\s+([^:]+):\s*\n\s*[^#\n]*(\w+)\.append\(([^)]+)\)/s, code)
        
        if result_var == append_var do
          optimized = """
          # Optimized to use list comprehension
          #{result_var} = [#{expression} for #{iterator} in #{iterable}]
          """
          
          {:ok, %{
            optimized_code: optimized,
            explanation: "Replaced list building loop with a list comprehension, which is more Pythonic and usually more efficient."
          }}
        else
          {:error, "No matching list operation pattern found"}
        end
        
      # Replace filter+map with list comprehension
      Regex.match?(~r/(\w+)\s*=\s*\[\]\s*for\s+(\w+)\s+in\s+([^:]+):\s*\n\s*if\s+([^:]+):\s*\n\s*[^#\n]*(\w+)\.append\(([^)]+)\)/s, code) ->
        [_, result_var, iterator, iterable, condition, append_var, expression] =
          Regex.run(~r/(\w+)\s*=\s*\[\]\s*for\s+(\w+)\s+in\s+([^:]+):\s*\n\s*if\s+([^:]+):\s*\n\s*[^#\n]*(\w+)\.append\(([^)]+)\)/s, code)
        
        if result_var == append_var do
          optimized = """
          # Optimized to use list comprehension with condition
          #{result_var} = [#{expression} for #{iterator} in #{iterable} if #{condition}]
          """
          
          {:ok, %{
            optimized_code: optimized,
            explanation: "Replaced conditional list building loop with a conditional list comprehension for better performance and readability."
          }}
        else
          {:error, "No matching list operation pattern found"}
        end
        
      true ->
        {:error, "No matching list operation pattern found"}
    end
  end
  
  defp optimize_loop_performance(code) do
    cond do
      # Replace range(len(x)) with enumerate
      Regex.match?(~r/for\s+(\w+)\s+in\s+range\(len\((\w+)\)\):/s, code) ->
        optimized_code = Regex.replace(
          ~r/for\s+(\w+)\s+in\s+range\(len\((\w+)\)\):\s*\n(\s+)[^#\n]*(\w+)\[(\w+)\]/s,
          code,
          """
          # Optimized to use enumerate
          for \\1, value in enumerate(\\2):\\3
          """
        )
        
        {:ok, %{
          optimized_code: optimized_code,
          explanation: "Replaced 'for i in range(len(x))' with 'for i, value in enumerate(x)', which avoids unnecessary function calls and is more Pythonic."
        }}
        
      # Replace multiple calls in loop
      Regex.match?(~r/for\s+(\w+)\s+in\s+([^:]+):\s*\n(\s+)([^#\n]*?)(\w+)\(([^)]+)\)/s, code) ->
        [_, iterator, iterable, indent, prefix, func_name, args] =
          Regex.run(~r/for\s+(\w+)\s+in\s+([^:]+):\s*\n(\s+)([^#\n]*?)(\w+)\(([^)]+)\)/s, code)
        
        if String.contains?(args, iterator) do
          optimized = """
          # Optimize to avoid redundant function calls
          #{func_name}_func = #{func_name}  # Cache function reference
          for #{iterator} in #{iterable}:
          #{indent}#{prefix}#{func_name}_func(#{args})
          """
          
          {:ok, %{
            optimized_code: optimized,
            explanation: "Cached the function reference outside the loop to avoid repeated lookup overhead."
          }}
        else
          {:error, "Function doesn't use loop iterator, not optimizing"}
        end
        
      true ->
        {:error, "No matching loop performance pattern found"}
    end
  end
  
  defp optimize_string_operations(code) do
    cond do
      # Replace string concatenation in loop with join
      Regex.match?(~r/(\w+)\s*=\s*['"][\'"]\s*for\s+(\w+)\s+in\s+([^:]+):\s*\n\s*[^#\n]*(\w+)\s*\+=\s*([^#\n]+)/s, code) ->
        [_, result_var, iterator, iterable, concat_var, expression] =
          Regex.run(~r/(\w+)\s*=\s*['"][\'"]\s*for\s+(\w+)\s+in\s+([^:]+):\s*\n\s*[^#\n]*(\w+)\s*\+=\s*([^#\n]+)/s, code)
        
        if result_var == concat_var do
          optimized = """
          # Optimized to use join for string concatenation
          #{result_var} = ''.join([#{String.trim(expression)} for #{iterator} in #{iterable}])
          """
          
          {:ok, %{
            optimized_code: optimized,
            explanation: "Replaced string concatenation in a loop with string join operation, which is much more efficient in Python."
          }}
        else
          {:error, "Variables don't match, not optimizing"}
        end
        
      # Replace multiple format with f-string
      Regex.match?(~r/(["'])([^"']*?)\{([^{}]+)\}([^"']*?)\1\.format\(([^)]+)\)/s, code) ->
        optimized_code = Regex.replace(
          ~r/(["'])([^"']*?)\{([^{}]+)\}([^"']*?)\1\.format\(([^)]+)\)/s,
          code,
          "f\\1\\2{\\5}\\4\\1"
        )
        
        {:ok, %{
          optimized_code: optimized_code,
          explanation: "Replaced .format() string formatting with f-strings, which are more readable and slightly more efficient."
        }}
        
      true ->
        {:error, "No matching string operation pattern found"}
    end
  end
  
  defp optimize_dict_operations(code) do
    cond do
      # Replace dict gets with dict.get and default
      Regex.match?(~r/(\w+)\s*=\s*(\w+)(?:\[['"](\w+)['"]\])(?:\s+if\s+['"](\w+)['"]\s+in\s+\w+\s+else\s+([^#\n]+))/s, code) ->
        [_, result_var, dict_var, key, key_check, default] =
          Regex.run(~r/(\w+)\s*=\s*(\w+)(?:\[['"](\w+)['"]\])(?:\s+if\s+['"](\w+)['"]\s+in\s+\w+\s+else\s+([^#\n]+))/s, code)
        
        if key == key_check do
          optimized = """
          # Optimized to use dict.get with default
          #{result_var} = #{dict_var}.get('#{key}', #{default})
          """
          
          {:ok, %{
            optimized_code: optimized,
            explanation: "Replaced conditional dictionary access with dict.get() and a default value, which is more concise and Pythonic."
          }}
        else
          {:error, "Keys don't match, not optimizing"}
        end
        
      # Replace dictionary construction in loop with dict comprehension
      Regex.match?(~r/(\w+)\s*=\s*\{\}\s*for\s+(\w+)\s+in\s+([^:]+):\s*\n\s*[^#\n]*(\w+)\[([^]]+)\]\s*=\s*([^#\n]+)/s, code) ->
        [_, result_var, iterator, iterable, dict_var, key, value] =
          Regex.run(~r/(\w+)\s*=\s*\{\}\s*for\s+(\w+)\s+in\s+([^:]+):\s*\n\s*[^#\n]*(\w+)\[([^]]+)\]\s*=\s*([^#\n]+)/s, code)
        
        if result_var == dict_var do
          optimized = """
          # Optimized to use dictionary comprehension
          #{result_var} = {#{key}: #{String.trim(value)} for #{iterator} in #{iterable}}
          """
          
          {:ok, %{
            optimized_code: optimized,
            explanation: "Replaced dictionary construction loop with a dictionary comprehension, which is more efficient and Pythonic."
          }}
        else
          {:error, "Variables don't match, not optimizing"}
        end
      
      # Use defaultdict for counting occurrences
      Regex.match?(~r/(\w+)\s*=\s*\{\}\s*for\s+(\w+)\s+in\s+([^:]+):\s*\n\s*[^#\n]*if\s+(\w+)\s+in\s+(\w+):\s*\n\s*[^#\n]*(\w+)\[(\w+)\]\s*\+=\s*1\s*\n\s*[^#\n]*else:\s*\n\s*[^#\n]*(\w+)\[(\w+)\]\s*=\s*1/s, code) ->
        [_, result_var, iterator, iterable, key, dict1, dict2, dict3, key2] =
          Regex.run(~r/(\w+)\s*=\s*\{\}\s*for\s+(\w+)\s+in\s+([^:]+):\s*\n\s*[^#\n]*if\s+(\w+)\s+in\s+(\w+):\s*\n\s*[^#\n]*(\w+)\[(\w+)\]\s*\+=\s*1\s*\n\s*[^#\n]*else:\s*\n\s*[^#\n]*(\w+)\[(\w+)\]\s*=\s*1/s, code)
        
        if dict1 == dict2 && dict2 == dict3 && key == key2 do
          optimized = """
          # Optimized to use defaultdict for counting
          from collections import defaultdict
          
          #{result_var} = defaultdict(int)
          for #{iterator} in #{iterable}:
              #{dict1}[#{key}] += 1
          """
          
          {:ok, %{
            optimized_code: optimized,
            explanation: "Replaced dictionary counting pattern with collections.defaultdict, which eliminates the need for checking if a key exists before incrementing."
          }}
        else
          {:error, "Variables don't match for defaultdict optimization"}
        end
        
      true ->
        {:error, "No matching dictionary operation pattern found"}
    end
  end
  
  # Add type hints to Python code
  defp add_type_hints(code, options) do
    # Flag to determine if we should add type hints
    use_type_hints = get_in(options, [:use_type_hints]) || false
    
    if !use_type_hints do
      {:error, "Type hints optimization disabled in options"}
    else
      # Extract function definitions and add type hints
      optimized_code = Regex.replace(
        ~r/def\s+(\w+)\s*\(([^)]*)\)(?:\s*->\s*[\w\[\], ]*)?:/,
        code,
        fn _, function_name, args_str ->
          typed_args = add_arg_type_hints(args_str)
          return_hint = guess_return_type(function_name)
          "def #{function_name}(#{typed_args}) -> #{return_hint}:"
        end
      )
      
      if optimized_code != code do
        # Add typing import if not already present
        optimized_code = if !String.contains?(optimized_code, "import typing") && !String.contains?(optimized_code, "from typing import") do
          "from typing import List, Dict, Tuple, Optional, Any\n\n" <> optimized_code
        else
          optimized_code
        end
        
        {:ok, %{
          optimized_code: optimized_code,
          explanation: "Added type hints to function parameters and return values to improve code maintainability and IDE support."
        }}
      else
        {:error, "No functions found for adding type hints"}
      end
    end
  end
  
  # Add type hints to function arguments
  defp add_arg_type_hints(args_str) do
    args_str
    |> String.split(",")
    |> Enum.map(fn arg ->
      arg = String.trim(arg)
      
      # Skip args that already have type hints
      if String.contains?(arg, ":") do
        arg
      else
        # Skip self/cls in class methods
        if arg in ["self", "cls"] do
          arg
        else
          # Skip args with default values for simplicity
          if String.contains?(arg, "=") do
            [name, default] = String.split(arg, "=", parts: 2)
            "#{String.trim(name)}: Any = #{String.trim(default)}"
          else
            # Guess type based on common naming conventions
            cond do
              String.starts_with?(arg, "is_") || String.starts_with?(arg, "has_") -> "#{arg}: bool"
              String.ends_with?(arg, "_list") || String.ends_with?(arg, "s") -> "#{arg}: List[Any]"
              String.ends_with?(arg, "_dict") -> "#{arg}: Dict[str, Any]"
              String.ends_with?(arg, "_id") || String.ends_with?(arg, "_count") -> "#{arg}: int"
              String.ends_with?(arg, "_name") || String.starts_with?(arg, "str") -> "#{arg}: str"
              true -> "#{arg}: Any"
            end
          end
        end
      end
    end)
    |> Enum.join(", ")
  end
  
  # Guess return type based on function name conventions
  defp guess_return_type(function_name) do
    cond do
      String.starts_with?(function_name, "is_") || String.starts_with?(function_name, "has_") || String.starts_with?(function_name, "can_") -> "bool"
      String.starts_with?(function_name, "get_") && String.ends_with?(function_name, "s") -> "List[Any]"
      String.starts_with?(function_name, "get_") && String.ends_with?(function_name, "_dict") -> "Dict[str, Any]"
      String.starts_with?(function_name, "get_") && String.ends_with?(function_name, "_count") -> "int"
      String.starts_with?(function_name, "get_") && String.ends_with?(function_name, "_str") -> "str"
      String.starts_with?(function_name, "to_") && String.ends_with?(function_name, "_dict") -> "Dict[str, Any]"
      String.starts_with?(function_name, "to_") && String.ends_with?(function_name, "_list") -> "List[Any]"
      String.starts_with?(function_name, "to_") && String.ends_with?(function_name, "_string") -> "str"
      String.starts_with?(function_name, "to_") && String.ends_with?(function_name, "_int") -> "int"
      String.contains?(function_name, "parse") -> "Dict[str, Any]"
      true -> "Any"
    end
  end
  
  # Optimize code by replacing lists with generators where appropriate
  defp optimize_with_generators(code) do
    cond do
      # Replace list comprehension with generator when used in sum/min/max/any/all
      Regex.match?(~r/(sum|min|max|any|all)\(\[([^\]]+)\]\)/s, code) ->
        optimized_code = Regex.replace(
          ~r/(sum|min|max|any|all)\(\[([^\]]+)\]\)/s,
          code,
          "\\1(\\2)"
        )
        
        {:ok, %{
          optimized_code: optimized_code,
          explanation: "Replaced list comprehensions with generator expressions in functions like sum(), min(), max(), any(), all() to reduce memory usage, as these functions process items one at a time."
        }}
      
      # Replace list iterations with direct iteration over iterables
      Regex.match?(~r/for\s+\w+\s+in\s+list\(([^)]+)\):/s, code) ->
        optimized_code = Regex.replace(
          ~r/for\s+(\w+)\s+in\s+list\(([^)]+)\):/s,
          code,
          "for \\1 in \\2:"
        )
        
        {:ok, %{
          optimized_code: optimized_code,
          explanation: "Removed unnecessary list() conversion when iterating over an iterable, saving memory by avoiding the creation of a temporary list."
        }}
        
      true ->
        {:error, "No matching pattern found for generator optimization"}
    end
  end
  
  # Optimize code by using context managers for resource handling
  defp optimize_with_context_managers(code) do
    cond do
      # Replace try/finally file handling with 'with' statement
      Regex.match?(~r/(\w+)\s*=\s*open\([^)]+\)\s*try:[^#]*finally:[^#]*\1\.close\(\)/s, code) ->
        [_, file_var] = Regex.run(~r/(\w+)\s*=\s*open\([^)]+\)/s, code)
        
        # Extract the open parameters and the code in the try block
        [_, open_params, try_code] = Regex.run(~r/\w+\s*=\s*open\(([^)]+)\)\s*try:([^#]*)finally:/s, code)
        
        # Remove any assignments to the file variable
        clean_try_code = Regex.replace(~r/\b#{file_var}\s*=\s*[^#\n]+\n?/s, try_code, "")
        
        optimized = """
        # Optimized to use context manager
        with open(#{open_params}) as #{file_var}:#{clean_try_code}
        """
        
        {:ok, %{
          optimized_code: optimized,
          explanation: "Replaced try/finally file handling with a 'with' statement context manager for more concise and reliable resource management."
        }}
        
      # Replace multiple try/except with a custom context manager
      Regex.match?(~r/try:[^#]+except\s+\w+Error:[^#]+try:[^#]+except\s+\w+Error:/s, code) ->
        # This is a complex transformation that would require deeper analysis
        # Just detect the pattern and delegate to AI for this case
        {:error, "Complex nested try/except pattern detected - delegating to AI"}
        
      true ->
        {:error, "No matching pattern found for context manager optimization"}
    end
  end
end