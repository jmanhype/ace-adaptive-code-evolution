defmodule Ace.Infrastructure.AI.Prompts.Evaluation do
  @moduledoc """
  Prompts for code evaluation operations.
  """

  @doc """
  Returns the system prompt for code evaluation.
  """
  def system_prompt do
    """
    You are an expert code evaluator specialized in assessing optimization changes.
    Your task is to evaluate code optimizations by comparing the original and optimized 
    versions, analyzing the metrics, and determining whether the changes are successful.
    
    Provide a thorough, objective assessment of the optimization focusing on:
    1. Correctness - Does the optimized code maintain the original functionality?
    2. Effectiveness - Does it address the intended issue?
    3. Performance - Is there a measurable improvement in performance?
    4. Maintainability - How does it affect code readability and structure?
    5. Trade-offs - What are the advantages and disadvantages of the changes?
    
    Base your assessment on the provided metrics and code analysis.
    Include specific recommendations for further improvements when relevant.
    """
  end

  @doc """
  Builds a prompt for evaluating optimization effectiveness.

  ## Parameters

    - `original_code`: The original code before optimization
    - `optimized_code`: The optimized code
    - `metrics`: Performance metrics from running both versions
    - `options`: Additional options

  ## Returns

    - A string prompt for the language model
  """
  def build(original_code, optimized_code, metrics, options \\ []) do
    """
    Evaluate the effectiveness of the following code optimization:

    ## Original Code
    ```
    #{original_code}
    ```

    ## Optimized Code
    ```
    #{optimized_code}
    ```

    ## Performance Metrics
    ```
    #{format_metrics(metrics)}
    ```

    Analyze the changes between the original and optimized code, considering:
    1. Whether the optimized code correctly maintains the original functionality
    2. The performance improvement based on the provided metrics
    3. The impact on code maintainability and readability
    4. Any potential issues or limitations in the optimized version
    5. Whether the optimization is successful overall

    Provide a detailed analysis explaining your assessment.
    Include a numerical estimate of performance improvement as a percentage.
    Classify the maintainability impact as "better", "neutral", or "worse".
    List specific recommendations for further improvements.
    Conclude with a boolean judgment on whether the optimization is successful.

    #{if options[:optimization_context], do: "\n## Optimization Context\n#{options[:optimization_context]}", else: ""}
    """
  end

  # Helper function to format metrics
  defp format_metrics(metrics) when is_map(metrics) do
    metrics
    |> Enum.map(fn {key, value} -> "#{key}: #{format_metric_value(value)}" end)
    |> Enum.join("\n")
  end

  defp format_metrics(metrics) do
    inspect(metrics, pretty: true)
  end

  defp format_metric_value(value) when is_float(value), do: Float.round(value, 4)
  defp format_metric_value(value), do: value
end