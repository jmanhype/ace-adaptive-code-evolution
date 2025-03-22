defmodule Ace.Integrations.GitHub.CommentFormatter do
  @moduledoc """
  Formats analysis results for GitHub comments and reviews.
  
  This module provides formatting functions to convert analysis results
  into Markdown for GitHub comments and review suggestions.
  """
  
  @doc """
  Format a summary of analysis results as a GitHub comment.
  
  ## Parameters
  
    * `file_results` - List of file results with opportunities
  
  ## Returns
  
    * `String.t()` - Formatted Markdown for GitHub comment
  """
  @spec format_analysis_summary(list(map())) :: String.t()
  def format_analysis_summary(file_results) do
    total_opportunities = count_total_opportunities(file_results)
    
    # Start with header
    header = """
    ## 🔍 Ace Analysis Results
    
    Found **#{total_opportunities}** optimization opportunities across **#{length(file_results)}** files.
    """
    
    # Add file-by-file breakdown
    files_breakdown = Enum.map_join(file_results, "\n", fn file ->
      format_file_summary(file)
    end)
    
    # Add footer with helpful information
    footer = """
    
    ### About this analysis
    
    Ace automatically analyzed your code changes and identified potential improvements.
    Each suggestion includes a rationale and recommended solution.
    
    👉 Individual review comments have been added to specific lines in the changed files.
    👉 Configure this integration by adding an `.ace-config.json` file to your repository.
    """
    
    header <> "\n" <> files_breakdown <> "\n" <> footer
  end
  
  @doc """
  Format a file summary with opportunities.
  
  ## Parameters
  
    * `file_result` - Map with file path, language, and opportunities
  
  ## Returns
  
    * `String.t()` - Formatted Markdown for the file section
  """
  @spec format_file_summary(map()) :: String.t()
  def format_file_summary(file_result) do
    %{path: path, language: language, opportunities: opportunities} = file_result
    
    # Count opportunities by type and severity
    counts_by_type = Enum.reduce(opportunities, %{}, fn opp, acc ->
      Map.update(acc, opp.type, 1, &(&1 + 1))
    end)
    
    counts_by_severity = Enum.reduce(opportunities, %{}, fn opp, acc ->
      Map.update(acc, opp.severity, 1, &(&1 + 1))
    end)
    
    # Format the counts for display
    types_text = format_map_counts(counts_by_type)
    severity_text = format_map_counts(counts_by_severity)
    
    """
    ### 📁 `#{path}`
    
    **Language:** #{format_language(language)} | **Types:** #{types_text} | **Severity:** #{severity_text}
    
    #{format_opportunity_list(opportunities, path)}
    """
  end
  
  @doc """
  Format a single opportunity for inclusion in a GitHub review comment.
  
  ## Parameters
  
    * `opportunity` - Map with opportunity details
  
  ## Returns
  
    * `String.t()` - Formatted Markdown for GitHub review comment
  """
  @spec format_review_comment(map()) :: String.t()
  def format_review_comment(opportunity) do
    # Get emoji for the opportunity type
    type_emoji = case opportunity.type do
      :style -> "💅"
      :performance -> "⚡"
      :security -> "🔒"
      :maintainability -> "🔧"
      :bug -> "🐞"
      _ -> "💡"
    end
    
    # Get emoji for severity
    severity_emoji = case opportunity.severity do
      :error -> "❌"
      :warning -> "⚠️"
      :suggestion -> "💭"
      _ -> "ℹ️"
    end
    
    """
    #{type_emoji} **#{capitalize_atom(opportunity.type)} Opportunity** #{severity_emoji}
    
    #{opportunity.message}
    
    ```suggestion
    #{opportunity.suggestion}
    ```
    
    *This suggestion was generated by Ace Code Evolution.*
    """
  end
  
  # Private helper functions
  
  defp count_total_opportunities(file_results) do
    Enum.reduce(file_results, 0, fn %{opportunities: opportunities}, acc ->
      acc + length(opportunities)
    end)
  end
  
  defp format_map_counts(counts) do
    counts
    |> Enum.map(fn {key, count} -> "#{capitalize_atom(key)}: #{count}" end)
    |> Enum.join(", ")
  end
  
  defp capitalize_atom(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.capitalize()
  end
  
  defp format_language(language) do
    language
    |> Atom.to_string()
    |> String.capitalize()
  end
  
  defp format_opportunity_list(opportunities, path) do
    opportunities
    |> Enum.take(5) # Limit to 5 examples in the summary
    |> Enum.map_join("\n", fn opp ->
      "- **Line #{opp.line}:** #{opp.message}"
    end)
    |> append_more_text(length(opportunities), 5, path)
  end
  
  defp append_more_text(text, total, shown, path) when total > shown do
    text <> "\n- ... and #{total - shown} more in `#{path}`"
  end
  
  defp append_more_text(text, _, _, _), do: text
end 