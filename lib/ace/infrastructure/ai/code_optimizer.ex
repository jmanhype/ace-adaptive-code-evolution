defmodule Ace.Infrastructure.AI.CodeOptimizer do
  @moduledoc """
  Module for optimizing code.
  This is a mock implementation for testing purposes.
  """
  require Logger
  
  @doc """
  Optimizes code for better performance or maintainability.
  
  ## Parameters
  
    - `code`: Source code to optimize
    - `options`: Optimization options
      - `:language`: Programming language of the code
      - `:filename`: File name or path (used for context)
  
  ## Returns
  
    - `{:ok, result}`: Successfully optimized code with suggestions
    - `{:error, reason}`: If optimization fails
  """
  def optimize_code(code, options) do
    language = options[:language] || "unknown"
    filename = options[:filename] || "unknown"
    
    Logger.info("Optimizing #{filename} (#{language})")
    
    # Generate mock optimization result based on language
    {:ok, generate_mock_optimization(code, language, filename)}
  end
  
  # Generates mock optimizations for testing
  defp generate_mock_optimization(code, language, filename) do
    # Base structure for result
    %{
      optimized_code: optimized_version(code, language),
      explanation: "Optimized code by improving algorithm efficiency and reducing redundant operations.",
      metrics: %{
        estimated_speedup: "~25%",
        readability_improvement: "Medium",
        complexity_reduction: "High"
      },
      suggestions: generate_mock_suggestions(code, language, filename)
    }
  end
  
  # Generates mock optimization suggestions based on language
  defp generate_mock_suggestions(code, language, filename) do
    case language do
      "python" ->
        [
          %{
            type: "performance",
            location: "lines 25-40",
            description: "Inefficient list building with repeated concatenation",
            severity: "high",
            original_code: extract_sample(code, 25, 40),
            optimized_code: "knowledge_base = []\nif \"knowledge_items\" in model_data:\n    # Use list comprehension instead of inefficient loop\n    self.knowledge_base = [item for item in model_data[\"knowledge_items\"]]",
            explanation: "Replaced inefficient string building and parsing with direct list comprehension. This reduces time complexity from O(n²) to O(n)."
          },
          %{
            type: "performance",
            location: "lines 45-55",
            description: "Redundant data structure creation and immediate clearing",
            severity: "medium",
            original_code: extract_sample(code, 45, 55),
            optimized_code: "self.citations = []\n# Skip the unnecessary creation and clearing of data",
            explanation: "Removed unnecessary loop that creates empty citations list only to clear it immediately after."
          },
          %{
            type: "memory",
            location: "lines 10-15",
            description: "Unbounded cache with potential memory leak",
            severity: "medium",
            original_code: extract_sample(code, 10, 15),
            optimized_code: "self.cache = LRUCache(maxsize=100)  # Limit cache size to prevent memory issues",
            explanation: "Added size limit to cache to prevent unbounded memory growth."
          }
        ]
        
      "javascript" ->
        [
          %{
            type: "performance",
            location: "lines 30-45",
            description: "Inefficient URL construction",
            severity: "medium",
            original_code: extract_sample(code, 30, 45),
            optimized_code: "const url = `${this.baseUrl}/v1/api/${endpoint}`;\n\n// Build query string efficiently\nconst params = new URLSearchParams();\nObject.entries(params).forEach(([key, value]) => {\n  params.append(key, value);\n});\nparams.append('api_key', this.apiKey);\n\n// Complete URL\nconst requestUrl = `${url}?${params.toString()}`;",
            explanation: "Used template literals and URLSearchParams for more efficient and safer URL construction."
          },
          %{
            type: "maintainability",
            location: "lines 15-25",
            description: "Redundant storage of the same information",
            severity: "low",
            original_code: extract_sample(code, 15, 25),
            optimized_code: "this.apiUrl = apiUrl;\nthis.apiKey = apiKey;\n\n// Use computed properties instead of storing duplicates\nget apiUrlWithBase() {\n  return `${this.apiUrl}/v1`;\n}\n\nget apiUrlWithBaseAndVersion() {\n  return `${this.apiUrl}/v1/api`;\n}",
            explanation: "Replaced redundant properties with computed getters to avoid data duplication."
          },
          %{
            type: "security",
            location: "lines 50-65",
            description: "Inconsistent use of URL encoding",
            severity: "high",
            original_code: extract_sample(code, 50, 65),
            optimized_code: "// Use URLSearchParams for proper encoding of all parameters\nconst params = new URLSearchParams();\nObject.entries(params).forEach(([key, value]) => {\n  params.append(key, value);\n});",
            explanation: "Used URLSearchParams to ensure all parameters are properly encoded, preventing potential security issues."
          }
        ]
        
      _ ->
        [
          %{
            type: "generic",
            location: "unknown",
            description: "Generic optimization opportunity",
            severity: "medium",
            original_code: String.slice(code, 0, 100) <> "...",
            optimized_code: String.slice(code, 0, 100) <> "...",
            explanation: "This is a mock optimization suggestion for testing."
          }
        ]
    end
  end
  
  # Generates a mock optimized version of the code
  defp optimized_version(code, language) do
    # For demonstration purposes, prepend a comment about optimization
    case language do
      "python" ->
        "# Optimized version with improved performance\n" <> 
        "# Changes include: memory optimization, algorithmic improvements, and code clarity\n\n" <>
        code
        
      "javascript" ->
        "/**\n * Optimized version with improved performance\n * Changes include: better URL handling, memory optimization, and code clarity\n */\n\n" <>
        code
        
      _ ->
        "/* Optimized version */\n" <> code
    end
  end
  
  # Extracts a sample of code between start and end lines (or best effort)
  defp extract_sample(code, start_line, end_line) do
    lines = String.split(code, "\n")
    
    start_idx = max(0, min(start_line - 1, length(lines) - 1))
    end_idx = max(0, min(end_line - 1, length(lines) - 1))
    
    lines
    |> Enum.slice(start_idx..end_idx)
    |> Enum.join("\n")
  end
end 