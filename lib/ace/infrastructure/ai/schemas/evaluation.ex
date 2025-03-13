defmodule Ace.Infrastructure.AI.Schemas.Evaluation do
  @moduledoc """
  Schemas for evaluation-related AI responses.
  """

  @doc """
  Returns the schema for an evaluation.
  """
  def evaluation_schema do
    %{
      "title" => "OptimizationEvaluation",
      "type" => "object",
      "properties" => %{
        "success" => %{
          "type" => "boolean",
          "description" => "Whether the optimization is considered successful"
        },
        "performance_improvement" => %{
          "type" => "number",
          "description" => "Estimated percentage of performance improvement"
        },
        "maintainability_impact" => %{
          "type" => "string",
          "enum" => ["better", "neutral", "worse"],
          "description" => "Impact on code maintainability"
        },
        "recommendations" => %{
          "type" => "array",
          "items" => %{
            "type" => "string"
          },
          "description" => "Recommendations for further improvements"
        },
        "analysis" => %{
          "type" => "string",
          "description" => "Detailed analysis of the optimization"
        }
      },
      "required" => ["success", "analysis"]
    }
  end
end