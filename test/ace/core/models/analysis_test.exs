defmodule Ace.Core.AnalysisTest do
  use Ace.DataCase

  alias Ace.Core.Analysis

  # Create a temporary directory for testing
  setup do
    test_dir = "/tmp/ace_test_dir"
    File.mkdir_p!(test_dir)
    on_exit(fn -> File.rm_rf!(test_dir) end)
    {:ok, test_dir: test_dir}
  end

  describe "analysis schema" do
    @valid_attrs %{
      file_path: "/path/to/test.ex",
      language: "elixir",
      content: "defmodule Test do\nend",
      focus_areas: ["performance", "maintainability"],
      severity_threshold: "medium"
    }
    @invalid_attrs %{file_path: nil, language: nil, content: nil}

    test "changeset with valid attributes" do
      changeset = Analysis.changeset(%Analysis{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Analysis.changeset(%Analysis{}, @invalid_attrs)
      refute changeset.valid?
    end

    test "changeset validates language" do
      attrs = Map.put(@valid_attrs, :language, "invalid")
      changeset = Analysis.changeset(%Analysis{}, attrs)
      assert %{language: ["is invalid"]} = errors_on(changeset)
    end

    test "changeset validates focus_areas" do
      attrs = Map.put(@valid_attrs, :focus_areas, ["invalid"])
      changeset = Analysis.changeset(%Analysis{}, attrs)
      assert %{focus_areas: ["contains unsupported focus areas"]} = errors_on(changeset)
    end

    test "changeset validates severity_threshold" do
      attrs = Map.put(@valid_attrs, :severity_threshold, "invalid")
      changeset = Analysis.changeset(%Analysis{}, attrs)
      assert %{severity_threshold: ["is invalid"]} = errors_on(changeset)
    end
    
    test "changeset with multi-file attributes" do
      # Create a project for the test
      {:ok, project} = 
        %Ace.Core.Project{}
        |> Ace.Core.Project.changeset(%{name: "Test Project", base_path: "/tmp/ace_test_dir"})
        |> Repo.insert()
        
      attrs = Map.merge(@valid_attrs, %{
        is_multi_file: true,
        project_id: project.id
      })
      
      changeset = Analysis.changeset(%Analysis{}, attrs)
      assert changeset.valid?
      
      assert Ecto.Changeset.get_field(changeset, :is_multi_file) == true
      assert Ecto.Changeset.get_field(changeset, :project_id) == project.id
    end
  end

  describe "relationships" do
    test "has_many opportunities relationship" do
      # Create an analysis
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
        
      # Create opportunities for this analysis
      {:ok, _opportunity1} = 
        %Ace.Core.Opportunity{}
        |> Ace.Core.Opportunity.changeset(%{
          location: "function test1/0",
          type: "performance",
          description: "Test opportunity 1",
          severity: "medium",
          analysis_id: analysis.id
        })
        |> Repo.insert()
        
      {:ok, _opportunity2} = 
        %Ace.Core.Opportunity{}
        |> Ace.Core.Opportunity.changeset(%{
          location: "function test2/0",
          type: "maintainability",
          description: "Test opportunity 2",
          severity: "high",
          analysis_id: analysis.id
        })
        |> Repo.insert()
      
      # Reload analysis with opportunities
      analysis = Ace.Repo.preload(analysis, :opportunities)
      
      # Verify the relationship
      assert length(analysis.opportunities) == 2
      assert Enum.all?(analysis.opportunities, fn o -> o.analysis_id == analysis.id end)
    end
    
    test "belongs_to project relationship", %{test_dir: test_dir} do
      # Create a project
      {:ok, project} = 
        %Ace.Core.Project{}
        |> Ace.Core.Project.changeset(%{name: "Test Project", base_path: test_dir})
        |> Repo.insert()
        
      # Create an analysis associated with this project
      {:ok, analysis} = 
        %Analysis{}
        |> Analysis.changeset(%{
          file_path: "#{test_dir}/file.ex",
          language: "elixir",
          content: "defmodule Test do\nend",
          focus_areas: ["performance"],
          severity_threshold: "medium",
          project_id: project.id,
          is_multi_file: true
        })
        |> Repo.insert()
        
      # Reload analysis with project
      analysis = Ace.Repo.preload(analysis, :project)
      
      # Verify the relationship
      assert analysis.project.id == project.id
      assert analysis.project.name == "Test Project"
    end
    
    test "has_many relationship connections", %{test_dir: test_dir} do
      # Create two analyses
      {:ok, source_analysis} = 
        %Analysis{}
        |> Analysis.changeset(%{
          file_path: "#{test_dir}/src.ex",
          language: "elixir",
          content: "defmodule Source do\nimport Target\nend",
          focus_areas: ["performance"],
          severity_threshold: "medium"
        })
        |> Repo.insert()
        
      {:ok, target_analysis} = 
        %Analysis{}
        |> Analysis.changeset(%{
          file_path: "#{test_dir}/target.ex",
          language: "elixir",
          content: "defmodule Target do\ndef function() do :ok end\nend",
          focus_areas: ["performance"],
          severity_threshold: "medium"
        })
        |> Repo.insert()
        
      # Create a relationship between them
      {:ok, _relationship} = 
        %Ace.Core.AnalysisRelationship{}
        |> Ace.Core.AnalysisRelationship.changeset(%{
          source_analysis_id: source_analysis.id,
          target_analysis_id: target_analysis.id,
          relationship_type: "imports",
          details: %{module: "Target"}
        })
        |> Repo.insert()
        
      # Reload both analyses with their relationships
      source_analysis = Ace.Repo.preload(source_analysis, [:source_relationships, :target_relationships])
      target_analysis = Ace.Repo.preload(target_analysis, [:source_relationships, :target_relationships])
      
      # Verify the relationships
      assert length(source_analysis.source_relationships) == 1
      assert length(source_analysis.target_relationships) == 0
      assert length(target_analysis.source_relationships) == 0
      assert length(target_analysis.target_relationships) == 1
      
      # Check the relationship data
      relationship = hd(source_analysis.source_relationships)
      assert relationship.source_analysis_id == source_analysis.id
      assert relationship.target_analysis_id == target_analysis.id
      assert relationship.relationship_type == "imports"
    end
  end
end