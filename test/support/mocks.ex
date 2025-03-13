defmodule Ace.Test.Mocks do
  @moduledoc """
  Provides mock implementations for external services and dependencies.
  """
  
  # Mock GraphQL modules to avoid compilation errors
  defmodule Absinthe.Schema do
    defmacro __using__(_) do
      quote do
        # Empty to avoid compilation errors
      end
    end
  end
  
  defmodule Absinthe.Schema.Notation do
    defmacro __using__(_) do
      quote do
        # Empty to avoid compilation errors
      end
    end
  end
  
  # Mock AceWeb module
  defmodule AceWeb do
    defmacro __using__(:live_view) do
      quote do
        # Empty to avoid compilation errors
      end
    end
  end
  
  defmodule MockInstructorHelper do
    @moduledoc """
    Mock implementation of Ace.Infrastructure.AI.Helpers.InstructorHelper.
    
    This mock simulates responses from LLMs for testing purposes.
    """
    require Logger
    
    @doc """
    Mock implementation of gen/4 that returns predefined responses based on input.
    """
    @spec gen(map() | struct(), String.t(), String.t(), String.t() | nil) ::
            {:ok, any()} | {:error, any()}
    def gen(response_model, _sys_msg, user_msg, _model \\ nil) do
      Logger.debug("MOCK: Using MockInstructorHelper.gen instead of real API call")
      Logger.debug("MOCK: Response model type: #{inspect(response_model)}")
      Logger.debug("MOCK: User message: #{String.slice(user_msg, 0, 100)}...")
      
      # Generate a mock response based on the response_model type
      mock_response = generate_mock_response(response_model, user_msg)
      {:ok, mock_response}
    end
    
    # Generate appropriate mock responses based on the response model
    defp generate_mock_response(response_model, _user_msg) do
      cond do
        # Analysis opportunities
        is_map(response_model) && Map.has_key?(response_model, "opportunities") ->
          %{
            opportunities: [
              %{
                location: "function test_function/1",
                type: "performance",
                description: "Inefficient algorithm detected",
                severity: "medium",
                rationale: "This is a mock rationale for testing",
                suggested_change: "Replace with a more efficient algorithm"
              },
              %{
                location: "lines 15-20",
                type: "maintainability",
                description: "Complex code that's difficult to understand",
                severity: "high",
                rationale: "Overly complex implementation makes maintenance difficult",
                suggested_change: "Refactor into smaller, more focused functions"
              }
            ]
          }
          
        # Cross-file optimization opportunities  
        is_map(response_model) && Map.has_key?(response_model, "primary_file") ->
          %{
            opportunities: [
              %{
                primary_file: "file1.ex",
                location: "function main/1",
                type: "performance",
                description: "Duplicated code across files",
                severity: "high",
                rationale: "Same logic implemented in multiple files",
                cross_file_references: [
                  %{
                    file: "file2.ex",
                    location: "function helper/1",
                    relationship: "duplicated code"
                  }
                ],
                suggested_change: "Extract common functionality into a shared module"
              }
            ]
          }
          
        # Optimization response
        is_map(response_model) && Map.has_key?(response_model, "optimized_code") ->
          %{
            optimized_code: """
            defmodule Optimized do
              def optimized_function(a, b) do
                # This is a mock optimized implementation
                a * b * 2
              end
            end
            """,
            explanation: "This is a mock explanation for optimized code"
          }
          
        # Evaluation response  
        is_map(response_model) && Map.has_key?(response_model, "evaluation") ->
          %{
            explanation: "This is a mock explanation for evaluation",
            evaluation: %{
              success_rating: 0.85,
              recommendation: "apply",
              risks: ["Mock risk 1", "Mock risk 2"],
              improvement_areas: ["Mock improvement area 1", "Mock improvement area 2"]
            }
          }
          
        # Default case for unknown response models
        true ->
          Logger.warning("MOCK: Unknown response model type: #{inspect(response_model)}")
          
          %{
            result: "Mock response",
            details: "Generated mock response for unknown model type",
            content: "This is mock content generated for testing purposes"
          }
      end
    end
  end
end