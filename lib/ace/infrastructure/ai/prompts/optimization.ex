defmodule Ace.Infrastructure.AI.Prompts.Optimization do
  @moduledoc """
  Prompts for code optimization operations.
  """

  @doc """
  Returns the system prompt for code optimization.
  """
  def system_prompt do
    """
    You are an expert code optimizer specialized in improving code quality and performance.
    Your task is to optimize code segments based on identified issues, while ensuring:
    1. The optimized code maintains the same functionality and behavior
    2. The code follows best practices for the language
    3. The optimization genuinely improves the specified issue
    4. The code is well-documented with appropriate comments

    Provide a clear explanation of your changes, focusing on why they improve the code
    and what specific benefits they bring. If there are tradeoffs, explain them.
    """
  end

  @doc """
  Builds a prompt for optimizing code based on an identified opportunity.

  ## Parameters

    - `opportunity`: The identified optimization opportunity
    - `original_code`: The original code to optimize
    - `strategy`: The optimization strategy to use
    - `options`: Additional options

  ## Returns

    - A string prompt for the language model
  """
  def build(opportunity, original_code, strategy, options \\ []) do
    """
    Optimize the following code segment to address the identified issue:

    ## Original Code
    ```
    #{original_code}
    ```

    ## Issue Information
    - Location: #{opportunity.location}
    - Type: #{opportunity.type}
    - Description: #{opportunity.description}
    - Severity: #{opportunity.severity}
    - Rationale: #{opportunity.rationale || "Not provided"}
    #{if opportunity.suggested_change, do: "- Suggested Change: #{opportunity.suggested_change}", else: ""}

    ## Optimization Strategy
    #{get_strategy_guidance(strategy)}

    Generate an optimized version of this code that addresses the identified issue.
    Provide an explanation of your changes and why they improve the code.
    List specific changes made and their expected impact.
    Include any warnings or considerations about your optimization.

    Your response should maintain the original functionality while improving #{opportunity.type}.
    #{if options[:additional_context], do: "\n## Additional Context\n#{options[:additional_context]}", else: ""}
    """
  end

  # Helper function to provide strategy-specific guidance
  defp get_strategy_guidance("performance") do
    """
    Focus on improving execution speed and resource efficiency:
    - Reduce computational complexity
    - Minimize memory usage
    - Avoid redundant operations
    - Use more efficient algorithms or data structures
    - Consider parallelization where appropriate
    """
  end

  defp get_strategy_guidance("maintainability") do
    """
    Focus on improving code readability and maintainability:
    - Simplify complex logic
    - Break down large functions
    - Improve naming conventions
    - Add appropriate documentation
    - Follow language conventions and best practices
    - Reduce duplication
    """
  end

  defp get_strategy_guidance("security") do
    """
    Focus on addressing security vulnerabilities:
    - Validate inputs
    - Handle sensitive data properly
    - Fix potential injection points
    - Address authentication/authorization issues
    - Follow security best practices
    """
  end

  defp get_strategy_guidance("reliability") do
    """
    Focus on improving code reliability:
    - Add proper error handling
    - Handle edge cases
    - Improve input validation
    - Make code more robust to unexpected conditions
    - Add appropriate logging
    """
  end

  defp get_strategy_guidance("auto") do
    """
    Determine the best optimization approach based on the identified issue:
    - For performance issues: Improve execution efficiency and resource usage
    - For maintainability issues: Enhance readability and structure
    - For security issues: Address vulnerabilities and follow security best practices
    - For reliability issues: Improve error handling and robustness
    
    Your solution should be well-balanced, prioritizing the primary issue while maintaining
    good practices in other areas.
    """
  end

  defp get_strategy_guidance(_strategy) do
    get_strategy_guidance("auto")
  end
end