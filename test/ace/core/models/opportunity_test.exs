defmodule Ace.Core.OpportunityTest do
  use Ace.DataCase

  alias Ace.Core.{Analysis, Opportunity}

  setup do
    {:ok, analysis} = 
      %Analysis{}
      |> Analysis.changeset(%{
        file_path: "/path/to/test.ex",
        language: "elixir",
        content: "defmodule Test do\nend",
        focus_areas: ["performance"],
        severity_threshold: "medium"
      })
      |> Repo.insert()
      
    %{analysis: analysis}
  end

  describe "opportunity schema" do
    @valid_attrs %{
      location: "function test/1",
      type: "performance",
      description: "Test opportunity description",
      severity: "medium",
      rationale: "This function could be improved",
      suggested_change: "Use pattern matching instead"
    }
    @invalid_attrs %{
      location: nil,
      type: nil,
      description: nil,
      severity: nil
    }

    test "changeset with valid attributes for single-file opportunity", %{analysis: analysis} do
      attrs = Map.put(@valid_attrs, :analysis_id, analysis.id)
      changeset = Opportunity.changeset(%Opportunity{}, attrs)
      assert changeset.valid?
      
      # Default scope should be single_file
      assert Ecto.Changeset.get_field(changeset, :scope) == "single_file"
      
      # Cross file references should be empty by default
      assert Ecto.Changeset.get_field(changeset, :cross_file_references) == []
    end
    
    test "changeset with valid attributes for cross-file opportunity", %{analysis: analysis} do
      attrs = Map.merge(@valid_attrs, %{
        analysis_id: analysis.id,
        scope: "cross_file",
        cross_file_references: [
          %{file: "other_file.ex", location: "similar_function", relationship: "duplicated code"}
        ]
      })
      
      changeset = Opportunity.changeset(%Opportunity{}, attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes", %{analysis: analysis} do
      attrs = Map.put(@invalid_attrs, :analysis_id, analysis.id)
      changeset = Opportunity.changeset(%Opportunity{}, attrs)
      refute changeset.valid?
    end

    test "changeset validates type", %{analysis: analysis} do
      attrs = Map.merge(@valid_attrs, %{type: "invalid", analysis_id: analysis.id})
      changeset = Opportunity.changeset(%Opportunity{}, attrs)
      assert %{type: ["is invalid"]} = errors_on(changeset)
    end

    test "changeset validates severity", %{analysis: analysis} do
      attrs = Map.merge(@valid_attrs, %{severity: "invalid", analysis_id: analysis.id})
      changeset = Opportunity.changeset(%Opportunity{}, attrs)
      assert %{severity: ["is invalid"]} = errors_on(changeset)
    end
    
    test "changeset validates scope", %{analysis: analysis} do
      attrs = Map.merge(@valid_attrs, %{scope: "invalid", analysis_id: analysis.id})
      changeset = Opportunity.changeset(%Opportunity{}, attrs)
      assert %{scope: ["is invalid"]} = errors_on(changeset)
    end
    
    test "changeset validates cross_file_references when scope is cross_file", %{analysis: analysis} do
      # Empty cross_file_references with cross-file scope should be invalid
      attrs = Map.merge(@valid_attrs, %{
        analysis_id: analysis.id,
        scope: "cross_file",
        cross_file_references: []
      })
      
      changeset = Opportunity.changeset(%Opportunity{}, attrs)
      assert %{cross_file_references: ["must not be empty for cross-file opportunities"]} = errors_on(changeset)
    end
    
    test "changeset validates cross_file_references when scope is single_file", %{analysis: analysis} do
      # Non-empty cross_file_references with single-file scope should be invalid
      attrs = Map.merge(@valid_attrs, %{
        analysis_id: analysis.id,
        scope: "single_file",
        cross_file_references: [
          %{file: "other_file.ex", location: "similar_function"}
        ]
      })
      
      changeset = Opportunity.changeset(%Opportunity{}, attrs)
      assert %{cross_file_references: ["must be empty for single-file opportunities"]} = errors_on(changeset)
    end
  end
end