defmodule Ace.Infrastructure.AI.Schemas.Analysis do
  @moduledoc """
  Schemas for analysis-related AI responses, supporting both single-file and multi-file analysis.
  """

  @doc """
  Returns the schema for a list of optimization opportunities from single-file analysis.
  """
  def opportunity_list_schema do
    %{
      "title" => "OptimizationOpportunities",
      "type" => "object",
      "properties" => %{
        "opportunities" => %{
          "type" => "array",
          "items" => opportunity_schema()
        }
      },
      "required" => ["opportunities"]
    }
  end
  
  @doc """
  Returns the schema for a list of optimization opportunities from multi-file analysis.
  """
  def cross_file_opportunity_list_schema do
    %{
      "title" => "CrossFileOptimizationOpportunities",
      "type" => "object",
      "properties" => %{
        "opportunities" => %{
          "type" => "array",
          "items" => cross_file_opportunity_schema()
        }
      },
      "required" => ["opportunities"]
    }
  end

  @doc """
  Returns the schema for a single optimization opportunity.
  """
  def opportunity_schema do
    %{
      "type" => "object",
      "properties" => %{
        "location" => %{
          "type" => "string",
          "description" => "Location in the code (e.g., line number, function name)"
        },
        "type" => %{
          "type" => "string",
          "enum" => ["performance", "maintainability", "security", "reliability"],
          "description" => "Type of optimization opportunity"
        },
        "description" => %{
          "type" => "string",
          "description" => "Description of the optimization opportunity"
        },
        "severity" => %{
          "type" => "string",
          "enum" => ["low", "medium", "high"],
          "description" => "Severity of the issue"
        },
        "rationale" => %{
          "type" => "string",
          "description" => "Explanation of why this is an issue"
        },
        "suggested_change" => %{
          "type" => "string",
          "description" => "Suggestion on how to fix the issue"
        }
      },
      "required" => ["location", "type", "description", "severity"]
    }
  end
  
  @doc """
  Returns the schema for a single cross-file optimization opportunity.
  """
  def cross_file_opportunity_schema do
    %{
      "type" => "object",
      "properties" => %{
        "primary_file" => %{
          "type" => "string",
          "description" => "Main file where the issue exists"
        },
        "location" => %{
          "type" => "string",
          "description" => "Location in the primary file (e.g., line number, function name)"
        },
        "type" => %{
          "type" => "string",
          "enum" => ["performance", "maintainability", "security", "reliability"],
          "description" => "Type of optimization opportunity"
        },
        "description" => %{
          "type" => "string",
          "description" => "Description of the cross-file optimization opportunity"
        },
        "severity" => %{
          "type" => "string",
          "enum" => ["low", "medium", "high"],
          "description" => "Severity of the issue"
        },
        "rationale" => %{
          "type" => "string",
          "description" => "Explanation of why this is an issue across files"
        },
        "cross_file_references" => %{
          "type" => "array",
          "description" => "Related files involved in this opportunity",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "file" => %{
                "type" => "string",
                "description" => "Path or name of the related file"
              },
              "location" => %{
                "type" => "string",
                "description" => "Location in the related file (optional)"
              },
              "relationship" => %{
                "type" => "string",
                "description" => "How this file relates to the primary file for this issue"
              }
            },
            "required" => ["file"]
          }
        },
        "suggested_change" => %{
          "type" => "string",
          "description" => "Suggestion on how to fix the cross-file issue"
        }
      },
      "required" => ["primary_file", "location", "type", "description", "severity", "cross_file_references"]
    }
  end
end