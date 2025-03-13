defmodule Ace.Analysis.ServiceTest do
  use Ace.DataCase

  alias Ace.Analysis.Service
  alias Ace.Core.{Analysis, Opportunity}
  
  # Mock for the AI Orchestrator
  defmodule MockOrchestrator do
    def analyze_code(_content, _language, _focus_areas, _options) do
      {:ok, [
        %{
          location: "function test_function/1",
          type: "performance",
          description: "This is a test opportunity",
          severity: "medium",
          rationale: "Test rationale",
          suggested_change: "Test suggestion"
        }
      ]}
    end
  end

  setup do
    # Store original orchestrator module
    original_orchestrator = Application.get_env(:ace, :ai_orchestrator)
    
    # Set up test configuration
    Application.put_env(:ace, :ai_orchestrator, MockOrchestrator)
    
    on_exit(fn ->
      # Restore original config
      Application.put_env(:ace, :ai_orchestrator, original_orchestrator)
    end)
    
    :ok
  end

  describe "analyze_file/2" do
    setup do
      # Create a temporary test file
      test_file = Path.join(System.tmp_dir!(), "test_#{:rand.uniform(1000)}.ex")
      test_content = """
      defmodule Test do
        def test_function(x) do
          x * 2
        end
      end
      """
      
      File.write!(test_file, test_content)
      
      on_exit(fn -> File.rm(test_file) end)
      
      %{file_path: test_file, content: test_content}
    end
    
    test "analyzes a file successfully", %{file_path: file_path} do
      assert {:ok, analysis} = Service.analyze_file(file_path)
      
      # Check that it's properly stored in the database
      assert %Analysis{} = analysis
      assert analysis.file_path == file_path
      assert analysis.language == "elixir"
      assert analysis.completed_at != nil
      
      # Check that opportunities were created
      assert [opportunity] = analysis.opportunities
      assert opportunity.type == "performance"
      assert opportunity.severity == "medium"
      
      # Default scope should be single_file
      assert opportunity.scope == "single_file"
    end
    
    test "analyzes a file with project_id option", %{file_path: file_path} do
      # First create a project
      {:ok, project} =
        %Ace.Core.Project{}
        |> Ace.Core.Project.changeset(%{name: "Test Project", base_path: "/tmp"})
        |> Repo.insert()
      
      # Analyze file with project_id
      assert {:ok, analysis} = Service.analyze_file(file_path, project_id: project.id)
      
      # Verify the project_id was set
      assert analysis.project_id == project.id
    end
    
    test "handles file read errors" do
      non_existent_file = "/path/to/non_existent_file.ex"
      assert {:error, message} = Service.analyze_file(non_existent_file)
      assert message =~ "Failed to read file"
    end
  end

  describe "analyze_code/3" do
    test "analyzes code content directly" do
      content = """
      defmodule Test do
        def test_function(x) do
          x * 2
        end
      end
      """
      
      assert {:ok, analysis} = Service.analyze_code(content, "elixir")
      
      # Check that it's properly stored in the database
      assert %Analysis{} = analysis
      assert analysis.language == "elixir"
      assert analysis.completed_at != nil
      
      # Check that opportunities were created
      assert [opportunity] = analysis.opportunities
      assert opportunity.type == "performance"
      assert opportunity.severity == "medium"
    end
    
    test "analyzes code with custom focus areas" do
      content = "def test() do :ok end"
      focus_areas = ["security", "reliability"]
      
      assert {:ok, analysis} = Service.analyze_code(content, "elixir", focus_areas: focus_areas)
      assert analysis.focus_areas == focus_areas
    end
    
    test "accepts is_multi_file option" do
      content = "def test() do :ok end"
      
      assert {:ok, analysis} = Service.analyze_code(content, "elixir", is_multi_file: true)
      assert analysis.is_multi_file == true
    end
  end

  describe "get_opportunity/1" do
    test "gets an opportunity by ID" do
      # First create an analysis and opportunity
      {:ok, analysis} = 
        %Analysis{}
        |> Analysis.changeset(%{
          file_path: "/test/path.ex",
          language: "elixir",
          content: "def test() do :ok end",
          focus_areas: ["performance"],
          severity_threshold: "medium"
        })
        |> Repo.insert()
        
      {:ok, opportunity} = 
        %Opportunity{}
        |> Opportunity.changeset(%{
          location: "function test/0",
          type: "performance",
          description: "Test description",
          severity: "medium",
          analysis_id: analysis.id
        })
        |> Repo.insert()
      
      # Test get_opportunity
      assert {:ok, found} = Service.get_opportunity(opportunity.id)
      assert found.id == opportunity.id
    end
    
    test "returns error for non-existent opportunity" do
      assert {:error, :not_found} = Service.get_opportunity(Ecto.UUID.generate())
    end
  end

  describe "list_opportunities/1" do
    setup do
      # Create an analysis with multiple opportunities
      {:ok, analysis} = 
        %Analysis{}
        |> Analysis.changeset(%{
          file_path: "/test/path.ex",
          language: "elixir",
          content: "def test() do :ok end",
          focus_areas: ["performance"],
          severity_threshold: "medium"
        })
        |> Repo.insert()
      
      # Create opportunities with different types and severities
      {:ok, performance_high} = 
        %Opportunity{}
        |> Opportunity.changeset(%{
          location: "function test1/0",
          type: "performance",
          description: "Performance opportunity",
          severity: "high",
          analysis_id: analysis.id
        })
        |> Repo.insert()
        
      {:ok, maintainability_medium} = 
        %Opportunity{}
        |> Opportunity.changeset(%{
          location: "function test2/0",
          type: "maintainability",
          description: "Maintainability opportunity",
          severity: "medium",
          analysis_id: analysis.id
        })
        |> Repo.insert()
        
      {:ok, security_low} = 
        %Opportunity{}
        |> Opportunity.changeset(%{
          location: "function test3/0",
          type: "security",
          description: "Security opportunity",
          severity: "low",
          analysis_id: analysis.id
        })
        |> Repo.insert()
      
      %{
        analysis: analysis,
        performance_high: performance_high,
        maintainability_medium: maintainability_medium,
        security_low: security_low
      }
    end
    
    test "lists all opportunities without filters", context do
      assert {:ok, opportunities} = Service.list_opportunities(%{})
      assert length(opportunities) >= 3
      
      opportunity_ids = Enum.map(opportunities, & &1.id)
      assert context.performance_high.id in opportunity_ids
      assert context.maintainability_medium.id in opportunity_ids
      assert context.security_low.id in opportunity_ids
    end
    
    test "filters opportunities by analysis_id", context do
      assert {:ok, opportunities} = Service.list_opportunities(%{analysis_id: context.analysis.id})
      assert length(opportunities) == 3
      
      opportunity_ids = Enum.map(opportunities, & &1.id)
      assert context.performance_high.id in opportunity_ids
      assert context.maintainability_medium.id in opportunity_ids
      assert context.security_low.id in opportunity_ids
    end
    
    test "filters opportunities by type", context do
      assert {:ok, opportunities} = Service.list_opportunities(%{type: "performance"})
      assert length(opportunities) == 1
      
      [opportunity] = opportunities
      assert opportunity.id == context.performance_high.id
    end
    
    test "filters opportunities by severity", context do
      assert {:ok, opportunities} = Service.list_opportunities(%{severity: "medium"})
      assert length(opportunities) == 1
      
      [opportunity] = opportunities
      assert opportunity.id == context.maintainability_medium.id
    end
    
    test "combines multiple filters", context do
      # Create another performance opportunity with medium severity
      {:ok, _performance_medium} = 
        %Opportunity{}
        |> Opportunity.changeset(%{
          location: "function test4/0",
          type: "performance",
          description: "Another performance opportunity",
          severity: "medium",
          analysis_id: context.analysis.id
        })
        |> Repo.insert()
      
      # Filter by both type and severity
      assert {:ok, opportunities} = Service.list_opportunities(%{
        type: "performance",
        severity: "medium"
      })
      
      assert length(opportunities) == 1
      [opportunity] = opportunities
      assert opportunity.type == "performance"
      assert opportunity.severity == "medium"
    end
  end
end