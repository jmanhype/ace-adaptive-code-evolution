defmodule Ace.Infrastructure.AI.OrchestratorTest do
  use ExUnit.Case, async: true

  alias Ace.Infrastructure.AI.Orchestrator

  # Mock provider modules
  defmodule MockProvider do
    @moduledoc false
    
    def name, do: "mock"
    
    def generate_structured(model, _prompt, schema, options) do
      case model do
        "success_model" ->
          case schema do
            %{"title" => "OptimizationOpportunities"} ->
              {:ok, %{
                opportunities: [
                  %{
                    description: "Test opportunity",
                    type: "performance",
                    location: "test_function",
                    severity: "medium"
                  }
                ]
              }}
              
            %{"title" => "CrossFileOptimizationOpportunities"} ->
              {:ok, %{
                opportunities: [
                  %{
                    primary_file: "file1.ex",
                    description: "Cross-file opportunity",
                    type: "performance",
                    location: "test_function",
                    severity: "high",
                    cross_file_references: [
                      %{file: "file2.ex", location: "similar_function"}
                    ]
                  }
                ]
              }}
              
            _ ->
              {:ok, %{
                optimized_code: "def optimized() do :ok end",
                explanation: "Test explanation"
              }}
          end
        
        "error_model" ->
          {:error, "Mock error"}
          
        _ ->
          {:error, "Unknown model"}
      end
    end
  end

  setup do
    # Store original provider and model
    original_provider_module = Application.get_env(:ace, :llm_provider)
    original_model = Application.get_env(:ace, :llm_model)
    
    # Set up test configuration
    Application.put_env(:ace, :llm_provider, "mock")
    Application.put_env(:ace, :llm_model, "success_model")
    
    # Override provider lookup to return our mock
    old_get_provider = Function.capture(Orchestrator, :get_provider, 0)
    
    :meck.new(Orchestrator, [:passthrough])
    :meck.expect(Orchestrator, :get_provider, fn -> MockProvider end)
    
    on_exit(fn ->
      # Restore original config
      Application.put_env(:ace, :llm_provider, original_provider_module)
      Application.put_env(:ace, :llm_model, original_model)
      :meck.unload(Orchestrator)
    end)
    
    %{old_get_provider: old_get_provider}
  end
  
  describe "analyze_code/4" do
    test "returns opportunities when successful" do
      code = "def test() do :ok end"
      language = "elixir"
      focus_areas = ["performance"]
      
      assert {:ok, opportunities} = Orchestrator.analyze_code(code, language, focus_areas)
      assert is_list(opportunities)
      assert length(opportunities) > 0
      
      opportunity = hd(opportunities)
      assert opportunity.type == "performance"
      assert opportunity.location == "test_function"
    end
    
    test "returns error when provider fails" do
      # Override the model to trigger an error
      Application.put_env(:ace, :llm_model, "error_model")
      
      code = "def test() do :ok end"
      language = "elixir"
      
      assert {:error, _reason} = Orchestrator.analyze_code(code, language)
    end
  end
  
  describe "analyze_cross_file/3" do
    test "analyzes multiple files together" do
      file_context = [
        %{file_path: "/path/to/file1.ex", file_name: "file1.ex", language: "elixir", content: "def test() do :ok end"},
        %{file_path: "/path/to/file2.ex", file_name: "file2.ex", language: "elixir", content: "def similar() do :ok end"}
      ]
      language = "elixir"
      
      assert {:ok, opportunities} = Orchestrator.analyze_cross_file(file_context, language)
      assert is_list(opportunities)
      assert length(opportunities) > 0
      
      opportunity = hd(opportunities)
      assert opportunity.primary_file == "file1.ex"
      assert opportunity.type == "performance"
      assert opportunity.severity == "high"
      assert is_list(opportunity.cross_file_references)
      
      reference = hd(opportunity.cross_file_references)
      assert reference.file == "file2.ex"
    end
    
    test "returns error when provider fails" do
      # Override the model to trigger an error
      Application.put_env(:ace, :llm_model, "error_model")
      
      file_context = [
        %{file_path: "/path/to/file1.ex", file_name: "file1.ex", language: "elixir", content: "def test() do :ok end"},
        %{file_path: "/path/to/file2.ex", file_name: "file2.ex", language: "elixir", content: "def similar() do :ok end"}
      ]
      language = "elixir"
      
      assert {:error, _reason} = Orchestrator.analyze_cross_file(file_context, language)
    end
  end
  
  describe "generate_optimization/4" do
    test "generates optimized code when successful" do
      opportunity = %{
        description: "Test opportunity",
        type: "performance",
        location: "test_function",
        severity: "medium"
      }
      
      original_code = "def test() do :ok end"
      strategy = "auto"
      
      assert {:ok, optimization} = Orchestrator.generate_optimization(opportunity, original_code, strategy)
      assert optimization.optimized_code == "def optimized() do :ok end"
      assert optimization.explanation == "Test explanation"
    end
    
    test "returns error when provider fails" do
      # Override the model to trigger an error
      Application.put_env(:ace, :llm_model, "error_model")
      
      opportunity = %{
        description: "Test opportunity",
        type: "performance",
        location: "test_function",
        severity: "medium"
      }
      
      original_code = "def test() do :ok end"
      strategy = "auto"
      
      assert {:error, _reason} = Orchestrator.generate_optimization(opportunity, original_code, strategy)
    end
  end
  
  describe "evaluate_optimization/4" do
    test "evaluates optimization when successful" do
      original_code = "def original() do :ok end"
      optimized_code = "def optimized() do :ok end"
      metrics = %{performance: 50}
      
      assert {:ok, evaluation} = Orchestrator.evaluate_optimization(original_code, optimized_code, metrics)
      assert evaluation.explanation == "Test explanation"
    end
    
    test "returns error when provider fails" do
      # Override the model to trigger an error
      Application.put_env(:ace, :llm_model, "error_model")
      
      original_code = "def original() do :ok end"
      optimized_code = "def optimized() do :ok end"
      metrics = %{performance: 50}
      
      assert {:error, _reason} = Orchestrator.evaluate_optimization(original_code, optimized_code, metrics)
    end
  end
end