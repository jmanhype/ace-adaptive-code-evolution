defmodule Ace.Infrastructure.AI.Prompts.Analysis do
  @moduledoc """
  Prompts for code analysis operations, including both single-file and multi-file analysis.
  """

  @doc """
  Returns the system prompt for single-file code analysis.
  """
  def system_prompt do
    """
    You are an expert code analyzer specialized in identifying optimization opportunities.
    Focus on these key areas:
    1. Performance issues (inefficient algorithms, unnecessary computations)
    2. Maintainability issues (complex code, poor structure)
    3. Security concerns (potential vulnerabilities)
    4. Reliability issues (error handling, edge cases)

    When analyzing code, be thorough but specific. Provide actionable insights.
    Include the exact location, a clear description of the issue, and a rationale
    explaining why it's a problem. For significant issues, suggest specific changes.
    """
  end
  
  @doc """
  Returns the system prompt for multi-file code analysis.
  """
  def system_prompt_multi_file do
    """
    You are an expert code analyzer specialized in identifying cross-file optimization opportunities.
    Focus on these key areas across multiple files:
    1. Performance issues (inefficient algorithms, unnecessary computations)
    2. Maintainability issues (complex code, poor structure, code duplication)
    3. Security concerns (potential vulnerabilities, unsafe cross-file interactions)
    4. Reliability issues (error handling, edge cases, inconsistent interfaces)

    When analyzing code across files, look for:
    - Duplicated logic that could be centralized
    - Inconsistent patterns between related files
    - Cross-file dependencies that create performance bottlenecks
    - Architectural issues that affect multiple files
    - Interface misalignments between components

    For each opportunity, identify:
    1. The primary file where the issue exists
    2. Related files that are involved
    3. Clear description of the cross-file issue
    4. Why it's problematic across the file boundaries
    5. Suggestions for improvement that consider the full context

    Be thorough but specific. Focus on actionable insights that would 
    improve the multi-file architecture and interactions.
    """
  end

  @doc """
  Builds a prompt for analyzing single file code.

  ## Parameters

    - `code`: The source code to analyze
    - `language`: The programming language of the code
    - `focus_areas`: List of areas to focus on during analysis
    - `options`: Additional options

  ## Returns

    - A string prompt for the language model
  """
  def build(code, language, focus_areas, options \\ []) do
    """
    Analyze the following #{language} code to identify optimization opportunities:

    ```#{language}
    #{code}
    ```

    Focus on these specific areas: #{Enum.join(focus_areas, ", ")}.
    #{if options[:severity_threshold], do: "Only report issues with severity: #{options[:severity_threshold]} or higher.", else: ""}

    For each optimization opportunity you identify, provide:
    1. Location: Line number or function name where the issue occurs
    2. Type: The category of issue (performance, maintainability, security, reliability)
    3. Description: A clear explanation of what the issue is
    4. Severity: How serious the issue is (low, medium, high)
    5. Rationale: Why this is problematic
    6. Suggested Change: A specific recommendation for improvement

    Only include actual issues that would meaningfully improve the code. Prioritize the most important issues.
    """
  end
  
  @doc """
  Builds a prompt for analyzing multiple files together.

  ## Parameters

    - `file_context`: List of maps containing file_path, file_name, language, and content
    - `primary_language`: The main programming language for analysis
    - `focus_areas`: List of areas to focus on during analysis
    - `options`: Additional options

  ## Returns

    - A string prompt for the language model
  """
  def build_multi_file(file_context, primary_language, focus_areas, options \\ []) do
    # Build file sections
    file_sections = 
      file_context
      |> Enum.map(fn file ->
        """
        FILE: #{file.file_name}
        PATH: #{file.file_path}
        LANGUAGE: #{file.language}

        ```#{file.language}
        #{file.content}
        ```
        """
      end)
      |> Enum.join("\n\n--- Next File ---\n\n")
    
    """
    Analyze the following set of related #{primary_language} files to identify cross-file optimization opportunities:

    #{file_sections}

    Focus on these specific areas across the files: #{Enum.join(focus_areas, ", ")}.
    #{if options[:severity_threshold], do: "Only report issues with severity: #{options[:severity_threshold]} or higher.", else: ""}

    Look specifically for opportunities that span multiple files, such as:
    - Duplicated code across files that could be centralized
    - Inconsistent patterns between related files
    - Interface mismatches between components
    - Cross-file dependencies that create performance bottlenecks
    - Architectural issues that affect multiple files

    For each cross-file optimization opportunity you identify, provide:
    1. Primary File: The main file where the issue exists
    2. Location: Line number or function name where the issue occurs in the primary file
    3. Type: The category of issue (performance, maintainability, security, reliability)
    4. Description: A clear explanation of what the cross-file issue is
    5. Severity: How serious the issue is (low, medium, high)
    6. Rationale: Why this is problematic across files
    7. Cross-File References: List of related files and locations that are involved
    8. Suggested Change: A specific recommendation for improvement that addresses the cross-file issue

    Only include significant cross-file issues that would meaningfully improve the code architecture.
    Prioritize the most important issues that affect multiple components.
    """
  end
end