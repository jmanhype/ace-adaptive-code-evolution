defmodule Ace.Infrastructure.AI.Helpers.InstructorHelperTest do
  use ExUnit.Case, async: true
  
  alias Ace.Infrastructure.AI.Helpers.InstructorHelper
  
  # Setup test configuration
  setup do
    original_helper_module = Application.get_env(:ace, :instructor_helper_module)
    
    # Configure the test to use our mock
    Application.put_env(:ace, :instructor_helper_module, Ace.Test.Mocks.MockInstructorHelper)
    
    on_exit(fn ->
      # Reset the original configuration after the test
      if original_helper_module do
        Application.put_env(:ace, :instructor_helper_module, original_helper_module)
      else
        Application.delete_env(:ace, :instructor_helper_module)
      end
    end)
    
    :ok
  end
  
  describe "gen/4" do
    test "returns structured data for analysis response model" do
      response_model = %{"opportunities" => []}
      system_message = "You are an expert code analyzer."
      user_message = "Analyze this code: def test() do :ok end"
      
      {:ok, result} = InstructorHelper.gen(response_model, system_message, user_message)
      
      assert Map.has_key?(result, :opportunities)
      assert is_list(result.opportunities)
      assert length(result.opportunities) > 0
      
      # Check the structure of the first opportunity
      opportunity = hd(result.opportunities)
      assert Map.has_key?(opportunity, :location)
      assert Map.has_key?(opportunity, :type)
      assert Map.has_key?(opportunity, :description)
      assert Map.has_key?(opportunity, :severity)
    end
    
    test "returns structured data for cross-file analysis response model" do
      response_model = %{"primary_file" => ""}
      system_message = "You are an expert code analyzer."
      user_message = "Analyze these files: file1.ex and file2.ex"
      
      {:ok, result} = InstructorHelper.gen(response_model, system_message, user_message)
      
      assert Map.has_key?(result, :opportunities)
      assert is_list(result.opportunities)
      
      # Check the structure of the cross-file opportunity
      opportunity = hd(result.opportunities)
      assert Map.has_key?(opportunity, :primary_file)
      assert Map.has_key?(opportunity, :cross_file_references)
      assert is_list(opportunity.cross_file_references)
    end
    
    test "returns structured data for optimization response model" do
      response_model = %{"optimized_code" => ""}
      system_message = "You are an expert code optimizer."
      user_message = "Optimize this code: def test() do :ok end"
      
      {:ok, result} = InstructorHelper.gen(response_model, system_message, user_message)
      
      assert Map.has_key?(result, :optimized_code)
      assert Map.has_key?(result, :explanation)
      assert is_binary(result.optimized_code)
    end
    
    test "returns structured data for evaluation response model" do
      response_model = %{"evaluation" => %{}}
      system_message = "You are an expert code evaluator."
      user_message = "Evaluate this optimization"
      
      {:ok, result} = InstructorHelper.gen(response_model, system_message, user_message)
      
      assert Map.has_key?(result, :explanation)
      assert Map.has_key?(result, :evaluation)
      assert Map.has_key?(result.evaluation, :success_rating)
      assert Map.has_key?(result.evaluation, :recommendation)
    end
  end
  
  describe "api_keys_present?/0" do
    test "checks if any AI API keys are available" do
      # Test with all keys unavailable
      original_groq = System.get_env("GROQ_API_KEY")
      original_openai = System.get_env("OPENAI_API_KEY")
      original_anthropic = System.get_env("ANTHROPIC_API_KEY")
      
      System.delete_env("GROQ_API_KEY")
      System.delete_env("OPENAI_API_KEY")
      System.delete_env("ANTHROPIC_API_KEY")
      
      refute InstructorHelper.api_keys_present?()
      
      # Test with one key available
      System.put_env("GROQ_API_KEY", "test_key")
      assert InstructorHelper.api_keys_present?()
      
      # Restore original environment
      if original_groq, do: System.put_env("GROQ_API_KEY", original_groq), else: System.delete_env("GROQ_API_KEY")
      if original_openai, do: System.put_env("OPENAI_API_KEY", original_openai), else: System.delete_env("OPENAI_API_KEY")
      if original_anthropic, do: System.put_env("ANTHROPIC_API_KEY", original_anthropic), else: System.delete_env("ANTHROPIC_API_KEY")
    end
  end
  
  describe "groq_api_key_present?/0" do
    test "checks if Groq API key is available" do
      # Test with key unavailable
      original_groq = System.get_env("GROQ_API_KEY")
      System.delete_env("GROQ_API_KEY")
      
      refute InstructorHelper.groq_api_key_present?()
      
      # Test with key available
      System.put_env("GROQ_API_KEY", "test_key")
      assert InstructorHelper.groq_api_key_present?()
      
      # Restore original environment
      if original_groq, do: System.put_env("GROQ_API_KEY", original_groq), else: System.delete_env("GROQ_API_KEY")
    end
  end
end