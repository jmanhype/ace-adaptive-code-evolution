defmodule Ace.Analysis.MultiFileAnalysisTest do
  use Ace.DataCase

  alias Ace.Analysis.Service
  alias Ace.Core.{Project, Analysis, AnalysisRelationship, Opportunity}
  
  # Create a mock module for the AI Orchestrator
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
    
    def analyze_cross_file(file_context, _language, _options) do
      # Return cross-file opportunities based on the file context
      opportunities = [
        %{
          primary_file: hd(file_context).file_name,
          location: "function test_function/1",
          type: "performance",
          description: "Cross-file optimization opportunity",
          severity: "high",
          rationale: "Cross-file rationale",
          cross_file_references: [
            %{
              file: List.last(file_context).file_name,
              location: "function similar_function/1",
              relationship: "duplicated code"
            }
          ],
          suggested_change: "Refactor to remove duplication"
        }
      ]
      
      {:ok, opportunities}
    end
  end

  describe "multi-file analysis" do
    setup do
      # Set up test environment with the mock orchestrator
      original_orchestrator = Application.get_env(:ace, :ai_orchestrator)
      Application.put_env(:ace, :ai_orchestrator, MockOrchestrator)
      
      on_exit(fn -> 
        Application.put_env(:ace, :ai_orchestrator, original_orchestrator)
      end)
      
      # Create temporary directory for test files
      test_dir = System.tmp_dir!() |> Path.join("ace_test_#{:rand.uniform(1000)}")
      File.mkdir_p!(test_dir)
      
      # Create test files
      source_file_path = Path.join(test_dir, "source.ex")
      source_content = """
      defmodule TestSource do
        def test_function(x) do
          x * 2
        end
      end
      """
      File.write!(source_file_path, source_content)
      
      target_file_path = Path.join(test_dir, "target.ex")
      target_content = """
      defmodule TestTarget do
        def similar_function(x) do
          x * 2
        end
        
        def another_function() do
          :ok
        end
      end
      """
      File.write!(target_file_path, target_content)
      
      on_exit(fn -> 
        File.rm_rf!(test_dir)
      end)
      
      %{
        test_dir: test_dir,
        source_file: source_file_path,
        target_file: target_file_path,
        source_content: source_content,
        target_content: target_content
      }
    end
    
    test "create_or_get_project with new project params creates a project", %{test_dir: test_dir} do
      project_params = %{
        name: "Test Project",
        base_path: test_dir,
        description: "Test description"
      }
      
      assert {:ok, project} = Service.create_or_get_project(project_params)
      assert project.name == "Test Project"
      assert project.base_path == test_dir
      assert project.description == "Test description"
    end
    
    test "create_or_get_project with existing ID returns project" do
      {:ok, project} = %Project{}
        |> Project.changeset(%{name: "Existing Project", base_path: "/tmp"})
        |> Repo.insert()
        
      assert {:ok, found_project} = Service.create_or_get_project(%{id: project.id})
      assert found_project.id == project.id
      assert found_project.name == "Existing Project"
    end
    
    test "analyze_project creates project and analyzes multiple files", context do
      project_params = %{
        name: "Multi-File Test",
        base_path: context.test_dir,
        description: "Testing multi-file analysis"
      }
      
      file_paths = [context.source_file, context.target_file]
      
      assert {:ok, result} = Service.analyze_project(project_params, file_paths)
      
      # Check result structure
      assert %{
        project: %Project{},
        analyses: analyses,
        relationships: relationships,
        cross_file_opportunities: opportunities
      } = result
      
      # Verify project
      assert result.project.name == "Multi-File Test"
      assert result.project.base_path == context.test_dir
      
      # Verify analyses
      assert length(analyses) == 2
      assert Enum.all?(analyses, fn a -> a.is_multi_file == true end)
      assert Enum.all?(analyses, fn a -> a.project_id == result.project.id end)
      
      # Verify relationships were detected
      refute Enum.empty?(relationships)
      
      # Verify cross-file opportunities were found
      refute Enum.empty?(opportunities)
      assert Enum.all?(opportunities, fn o -> o.scope == "cross_file" end)
      
      # Confirm the data was stored in the database
      assert Repo.aggregate(Project, :count) >= 1
      assert Repo.aggregate(Analysis, :count) >= 2
      assert Repo.aggregate(AnalysisRelationship, :count) >= 1
      assert Repo.aggregate(Opportunity, :count, scope: "cross_file") >= 1
    end
  end
  
  describe "file relationship detection" do
    setup do
      # Create test project and analyses for testing relationship detection
      {:ok, project} = %Project{}
        |> Project.changeset(%{name: "Relationship Test", base_path: "/tmp/test"})
        |> Repo.insert()
        
      {:ok, source_analysis} = %Analysis{}
        |> Analysis.changeset(%{
          file_path: "/tmp/test/source.ex",
          language: "elixir",
          content: """
          defmodule Source do
            import Target
            alias Another.Module
            
            def call_target do
              target_function()
            end
          end
          """,
          focus_areas: ["performance"],
          severity_threshold: "medium",
          project_id: project.id,
          is_multi_file: true
        })
        |> Repo.insert()
        
      {:ok, target_analysis} = %Analysis{}
        |> Analysis.changeset(%{
          file_path: "/tmp/test/target.ex",
          language: "elixir",
          content: """
          defmodule Target do
            def target_function do
              :ok
            end
          end
          """,
          focus_areas: ["performance"],
          severity_threshold: "medium",
          project_id: project.id,
          is_multi_file: true
        })
        |> Repo.insert()
      
      %{
        project: project,
        source_analysis: source_analysis,
        target_analysis: target_analysis
      }
    end
    
    test "detect_elixir_relationships finds imports", context do
      # Call the private function using :erlang.apply
      relationships = :erlang.apply(Service, :detect_elixir_relationships, [
        [context.source_analysis, context.target_analysis],
        context.project
      ])
      
      refute Enum.empty?(relationships)
      assert Enum.any?(relationships, fn rel ->
        rel.source_analysis_id == context.source_analysis.id &&
        rel.target_analysis_id == context.target_analysis.id &&
        rel.relationship_type == "imports"
      end)
    end
    
    test "extract_elixir_imports finds imports in content", _context do
      content = """
      defmodule Test do
        import One.Module
        require Another.Module
        use Third.Module
        alias Fourth.Module
      end
      """
      
      # Call the private function using :erlang.apply
      imports = :erlang.apply(Service, :extract_elixir_imports, [content])
      
      assert "One.Module" in imports
      assert "Another.Module" in imports
      assert "Third.Module" in imports
      assert "Fourth.Module" in imports
    end
  end
  
  describe "javascript relationship detection" do
    setup do
      # Create test project and analyses for testing JavaScript relationship detection
      {:ok, project} = %Project{}
        |> Project.changeset(%{name: "JS Relationship Test", base_path: "/tmp/js_test"})
        |> Repo.insert()
        
      {:ok, source_analysis} = %Analysis{}
        |> Analysis.changeset(%{
          file_path: "/tmp/js_test/app.js",
          language: "javascript",
          content: """
          import { Component } from './component';
          const utils = require('./utils');
          
          export default class App extends Component {
            constructor() {
              super();
              this.utils = utils;
            }
          }
          """,
          focus_areas: ["performance"],
          severity_threshold: "medium",
          project_id: project.id,
          is_multi_file: true
        })
        |> Repo.insert()
        
      {:ok, component_analysis} = %Analysis{}
        |> Analysis.changeset(%{
          file_path: "/tmp/js_test/component.js",
          language: "javascript",
          content: """
          export class Component {
            render() {
              return 'Component';
            }
          }
          """,
          focus_areas: ["performance"],
          severity_threshold: "medium",
          project_id: project.id,
          is_multi_file: true
        })
        |> Repo.insert()
        
      {:ok, utils_analysis} = %Analysis{}
        |> Analysis.changeset(%{
          file_path: "/tmp/js_test/utils.js",
          language: "javascript",
          content: """
          module.exports = {
            helper: function() {
              return 'helper';
            }
          };
          """,
          focus_areas: ["performance"],
          severity_threshold: "medium",
          project_id: project.id,
          is_multi_file: true
        })
        |> Repo.insert()
      
      %{
        project: project,
        source_analysis: source_analysis,
        component_analysis: component_analysis,
        utils_analysis: utils_analysis
      }
    end
    
    test "extract_javascript_imports finds ES6 and CommonJS imports", _context do
      content = """
      import { Component } from './component';
      import DefaultExport from './default';
      import * as everything from './module';
      const utils = require('./utils');
      """
      
      # Call the private function using :erlang.apply
      imports = :erlang.apply(Service, :extract_javascript_imports, [content])
      
      assert {"es6", "./component"} in imports
      assert {"es6", "./default"} in imports
      assert {"es6", "./module"} in imports
      assert {"commonjs", "./utils"} in imports
    end
    
    test "find_javascript_module resolves relative paths", context do
      # Mock find_javascript_module to test path resolution
      # Since we can't easily mock file system in the test,
      # we'll test by directly setting up the analyses and checking resolve_js_import_path
      
      # Call the private function to resolve a relative path 
      resolved_path = :erlang.apply(Service, :resolve_js_import_path, [
        "./component",
        context.source_analysis.file_path,
        context.project
      ])
      
      assert resolved_path == "/tmp/js_test/component"
    end
  end
end