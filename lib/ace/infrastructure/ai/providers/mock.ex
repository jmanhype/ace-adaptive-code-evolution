defmodule Ace.Infrastructure.AI.Providers.Mock do
  @moduledoc """
  Mock provider for AI operations in test environment.
  
  This module implements the provider behavior and returns mock responses
  for testing purposes.
  """
  @behaviour Ace.Infrastructure.AI.Provider
  
  @impl true
  def generate(prompt, _system_prompt, _model, _options \\ []) do
    # Return a mock response based on the type of prompt
    cond do
      String.contains?(prompt, "analyze") ->
        mock_analysis_response()
      String.contains?(prompt, "optimize") ->
        mock_optimization_response()
      String.contains?(prompt, "evaluate") ->
        mock_evaluation_response()
      true ->
        mock_default_response()
    end
  end
  
  @impl true
  def generate_structured(prompt, _system_prompt, _schema, _model, _options \\ %{}) do
    # Return a mock response based on the type of prompt
    cond do
      String.contains?(prompt, "analyze") ->
        # Special case for analysis to catch all code paths
        cond do
          String.contains?(prompt, "optimize_complex_operations") ->
            # Our example file
            mock_analysis_for_example()
          String.contains?(prompt, "cross-file") || 
          String.contains?(prompt, "multi-file") || 
          String.match?(prompt, ~r/files?:\s*\d+/) ->
            # Cross-file analysis
            mock_cross_file_analysis()
          true ->
            mock_analysis_response()
        end
      String.contains?(prompt, "optimize") ->
        mock_optimization_response()
      String.contains?(prompt, "evaluate") ->
        mock_evaluation_response()
      true ->
        mock_default_response()
    end
  end
  
  # Special case for our example file with more detailed analysis
  defp mock_analysis_for_example do
    {:ok, %{
      opportunities: [
        %{
          description: "Inefficient pipeline in sum_of_squares_of_even_numbers",
          location: "lines 6-21",
          severity: "medium",
          type: "performance",
          rationale: "Using separate steps for filter, map, and reduce creates unnecessary intermediate lists",
          suggested_change: "Combine operations into a single pipeline with Enum.sum"
        },
        %{
          description: "Inefficient list concatenation in merge_alternating",
          location: "lines 35-37",
          severity: "high",
          type: "performance",
          rationale: "List concatenation with ++ is O(n) and creates many intermediate lists",
          suggested_change: "Use List.foldl with a list accumulator or Enum.zip + Enum.flat_map"
        },
        %{
          description: "Inefficient word frequency counting implementation",
          location: "lines 51-68",
          severity: "medium",
          type: "maintainability",
          rationale: "Manual map updates with repeated lookups are inefficient",
          suggested_change: "Use Enum.frequencies or Map.update with a default function"
        }
      ]
    }}
  end
  
  @impl true
  def name do
    "mock"
  end
  
  @impl true
  def supported_models do
    ["mock-model"]
  end
  
  # Mock responses for different operations
  
  defp mock_analysis_response do
    {:ok, %{
      opportunities: [
        %{
          description: "Inefficient pipeline in sum_of_squares_of_even_numbers",
          location: "lines 6-21",
          severity: "medium",
          type: "performance",
          rationale: "Using separate steps for filter, map, and reduce creates unnecessary intermediate lists",
          suggested_change: "Combine operations into a single pipeline with Enum.reduce"
        },
        %{
          description: "Inefficient list concatenation in merge_alternating",
          location: "lines 35-37",
          severity: "high",
          type: "performance",
          rationale: "List concatenation with ++ is O(n) and creates many intermediate lists",
          suggested_change: "Use List.foldl with a list accumulator or Enum.zip + Enum.flat_map"
        },
        %{
          description: "Inefficient word frequency counting implementation",
          location: "lines 51-68",
          severity: "medium",
          type: "maintainability",
          rationale: "Manual map updates with repeated lookups are inefficient",
          suggested_change: "Use Enum.frequencies or Map.update with a default function"
        }
      ]
    }}
  end
  
  defp mock_optimization_response do
    {:ok, %{
      optimized_code: """
      # Optimized implementation
      defmodule ComplexOperations do
        def sum_of_squares_of_even_numbers(list) do
          list
          |> Enum.filter(&(rem(&1, 2) == 0))
          |> Enum.map(&(&1 * &1))
          |> Enum.sum()
        end
        
        # Other functions...
      end
      """,
      explanation: "Combined the filter, map, and reduce operations into a more efficient pipeline using Enum.sum"
    }}
  end
  
  defp mock_evaluation_response do
    {:ok, %{
      success: true,
      metrics: %{
        execution_time_original: 0.324,
        execution_time_optimized: 0.187,
        improvement_percentage: 42.3
      },
      report: "The optimization successfully improved performance by 42.3% while maintaining the same behavior."
    }}
  end
  
  defp mock_cross_file_analysis do
    {:ok, %{
      opportunities: [
        %{
          type: "code_duplication",
          severity: "medium",
          description: "Duplicated prime number checking function",
          affected_files: ["app.ex", "utils.ex"],
          location: "is_prime?/1 in app.ex and prime?/1 in utils.ex",
          rationale: "The prime number checking logic is duplicated across modules",
          suggested_change: "Remove the duplicated implementation in TestApp.App and use TestApp.Utils.prime?/1 consistently"
        },
        %{
          type: "code_duplication",
          severity: "low",
          description: "Duplicated list formatting function",
          affected_files: ["app.ex", "utils.ex"],
          location: "format_items/1 in app.ex and format_list/1 in utils.ex",
          rationale: "Nearly identical list formatting functions in both modules",
          suggested_change: "Standardize on a single implementation, preferably in TestApp.Utils"
        },
        %{
          type: "inefficient_implementation",
          severity: "high",
          description: "Inefficient stats calculation in TestApp.Reports",
          affected_files: ["reports.ex", "app.ex", "utils.ex"],
          location: "calculate_stats/1 in reports.ex",
          rationale: "Reimplements functionality already available in other modules and performs duplicated work",
          suggested_change: "Refactor to use App.process_numbers/1 which already does most of this work efficiently"
        }
      ]
    }}
  end
  
  defp mock_default_response do
    {:ok, %{
      response: "Mock response for unrecognized prompt type"
    }}
  end
end