defmodule Ace.Core.AnalysisRelationshipTest do
  use Ace.DataCase

  alias Ace.Core.{Analysis, AnalysisRelationship}

  describe "analysis_relationship schema" do
    setup do
      {:ok, source_analysis} = 
        %Analysis{}
        |> Analysis.changeset(%{
          file_path: "/path/to/source.ex",
          language: "elixir",
          content: "defmodule Source do\nend",
          focus_areas: ["performance"],
          severity_threshold: "medium"
        })
        |> Repo.insert()
        
      {:ok, target_analysis} = 
        %Analysis{}
        |> Analysis.changeset(%{
          file_path: "/path/to/target.ex",
          language: "elixir",
          content: "defmodule Target do\nend",
          focus_areas: ["performance"],
          severity_threshold: "medium"
        })
        |> Repo.insert()
        
      %{
        source_analysis: source_analysis,
        target_analysis: target_analysis
      }
    end

    @valid_attrs %{relationship_type: "imports", details: %{module: "Target"}}
    @invalid_attrs %{relationship_type: nil}

    test "changeset with valid attributes", %{source_analysis: source, target_analysis: target} do
      attrs = Map.merge(@valid_attrs, %{
        source_analysis_id: source.id,
        target_analysis_id: target.id
      })
      
      changeset = AnalysisRelationship.changeset(%AnalysisRelationship{}, attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes", %{source_analysis: source, target_analysis: target} do
      attrs = Map.merge(@invalid_attrs, %{
        source_analysis_id: source.id,
        target_analysis_id: target.id
      })
      
      changeset = AnalysisRelationship.changeset(%AnalysisRelationship{}, attrs)
      refute changeset.valid?
    end

    test "changeset requires source_analysis_id" do
      attrs = Map.put(@valid_attrs, :target_analysis_id, Ecto.UUID.generate())
      changeset = AnalysisRelationship.changeset(%AnalysisRelationship{}, attrs)
      assert %{source_analysis_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset requires target_analysis_id" do
      attrs = Map.put(@valid_attrs, :source_analysis_id, Ecto.UUID.generate())
      changeset = AnalysisRelationship.changeset(%AnalysisRelationship{}, attrs)
      assert %{target_analysis_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset validates relationship_type", %{source_analysis: source, target_analysis: target} do
      attrs = %{
        source_analysis_id: source.id,
        target_analysis_id: target.id,
        relationship_type: "invalid_type"
      }
      
      changeset = AnalysisRelationship.changeset(%AnalysisRelationship{}, attrs)
      assert %{relationship_type: ["is invalid"]} = errors_on(changeset)
    end

    test "changeset prevents self-referential relationships", %{source_analysis: source} do
      attrs = %{
        source_analysis_id: source.id,
        target_analysis_id: source.id,
        relationship_type: "imports"
      }
      
      changeset = AnalysisRelationship.changeset(%AnalysisRelationship{}, attrs)
      assert %{target_analysis_id: ["must be different from source_analysis_id"]} = errors_on(changeset)
    end

    test "enforce unique constraint on source, target and relationship_type", %{source_analysis: source, target_analysis: target} do
      attrs = Map.merge(@valid_attrs, %{
        source_analysis_id: source.id,
        target_analysis_id: target.id
      })
      
      {:ok, _relationship} = 
        %AnalysisRelationship{}
        |> AnalysisRelationship.changeset(attrs)
        |> Repo.insert()
        
      {:error, changeset} =
        %AnalysisRelationship{}
        |> AnalysisRelationship.changeset(attrs)
        |> Repo.insert()
        
      assert %{source_analysis_id: ["has already been taken"]} = errors_on(changeset)
    end
  end

  test "relationship_types returns list of valid relationship types" do
    types = AnalysisRelationship.relationship_types()
    assert is_list(types)
    assert "imports" in types
    assert "extends" in types
    assert "implements" in types
    assert "uses" in types
    assert "references" in types
    assert "depends_on" in types
  end
end