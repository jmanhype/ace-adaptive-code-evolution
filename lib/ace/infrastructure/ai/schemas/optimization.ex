defmodule Ace.Infrastructure.AI.Schemas.Optimization do
  @moduledoc """
  Schemas for optimization-related AI responses.
  """

  @doc """
  Returns the schema for an optimization.
  """
  def optimization_schema do
    %{
      "title" => "CodeOptimization",
      "type" => "object",
      "properties" => %{
        "optimized_code" => %{
          "type" => "string",
          "description" => "The optimized code implementation"
        },
        "explanation" => %{
          "type" => "string",
          "description" => "Explanation of the optimization changes and their benefits"
        },
        "changes" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "description" => %{
                "type" => "string",
                "description" => "Description of a specific change"
              },
              "reason" => %{
                "type" => "string",
                "description" => "Reason for making this change"
              },
              "impact" => %{
                "type" => "string",
                "description" => "Expected impact of this change"
              }
            },
            "required" => ["description", "reason"]
          },
          "description" => "List of specific changes made"
        },
        "warnings" => %{
          "type" => "array",
          "items" => %{
            "type" => "string"
          },
          "description" => "Any warnings or considerations about the optimization"
        }
      },
      "required" => ["optimized_code", "explanation"]
    }
  end
end