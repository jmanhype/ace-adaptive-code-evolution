defmodule Ace.Infrastructure.AI.OpportunityWrapperTest do
  use ExUnit.Case, async: true
  
  alias Ace.Infrastructure.AI.OpportunityWrapper
  
  describe "wrap_opportunities/3" do
    test "handles a list of complete opportunities" do
      opportunities = [
        %{
          "location" => "line 10",
          "type" => "performance",
          "description" => "This could be faster",
          "severity" => "medium",
          "rationale" => "Current implementation is inefficient"
        },
        %{
          "location" => "function foo()",
          "type" => "maintainability",
          "description" => "Complex code",
          "severity" => "high",
          "rationale" => "Hard to understand"
        }
      ]
      
      code = "function test() { return 1 + 1; }"
      language = "javascript"
      
      result = OpportunityWrapper.wrap_opportunities(opportunities, code, language)
      
      assert length(result) == 2
      assert Enum.all?(result, fn opp -> 
        Map.has_key?(opp, "location") && 
        Map.has_key?(opp, "type") && 
        Map.has_key?(opp, "description") && 
        Map.has_key?(opp, "severity")
      end)
      
      # Check that values are preserved
      assert hd(result)["location"] == "line 10"
      assert hd(result)["type"] == "performance"
    end
    
    test "handles a list of incomplete opportunities" do
      opportunities = [
        %{
          "description" => "This could be faster",
          "severity" => "medium"
        },
        %{
          "location" => "function foo()"
        }
      ]
      
      code = "function test() { return 1 + 1; }"
      language = "javascript"
      
      result = OpportunityWrapper.wrap_opportunities(opportunities, code, language)
      
      assert length(result) == 2
      assert Enum.all?(result, fn opp -> 
        Map.has_key?(opp, "location") && 
        Map.has_key?(opp, "type") && 
        Map.has_key?(opp, "description") && 
        Map.has_key?(opp, "severity")
      end)
      
      # Check that missing values got defaults
      assert hd(result)["location"] == "line 1"
      assert hd(result)["type"] == "performance"
    end
    
    test "handles nil opportunities" do
      code = "function test() { return 1 + 1; }"
      language = "javascript"
      
      result = OpportunityWrapper.wrap_opportunities(nil, code, language)
      
      assert length(result) == 1
      assert hd(result)["location"] == "line 1"
      assert hd(result)["type"] == "performance"
      assert hd(result)["description"] =~ "javascript"
      assert hd(result)["severity"] == "medium"
    end
    
    test "handles opportunities in a map" do
      opportunities = %{
        "opportunities" => [
          %{
            "location" => "line 10",
            "type" => "performance",
            "description" => "This could be faster",
            "severity" => "medium"
          }
        ]
      }
      
      code = "function test() { return 1 + 1; }"
      language = "javascript"
      
      result = OpportunityWrapper.wrap_opportunities(opportunities, code, language)
      
      assert length(result) == 1
      assert hd(result)["location"] == "line 10"
      assert hd(result)["type"] == "performance"
    end
    
    test "handles opportunities in a map with atom keys" do
      opportunities = %{
        opportunities: [
          %{
            location: "line 10",
            type: "performance",
            description: "This could be faster",
            severity: "medium"
          }
        ]
      }
      
      code = "function test() { return 1 + 1; }"
      language = "javascript"
      
      result = OpportunityWrapper.wrap_opportunities(opportunities, code, language)
      
      assert length(result) == 1
      assert hd(result)["location"] == "line 10"
      assert hd(result)["type"] == "performance"
    end
  end
  
  describe "wrap_opportunity/3" do
    test "completes an opportunity with all required fields" do
      opportunity = %{
        "location" => "line 10",
        "type" => "performance",
        "description" => "This could be faster",
        "severity" => "medium",
        "rationale" => "Current implementation is inefficient"
      }
      
      code = "function test() { return 1 + 1; }"
      language = "javascript"
      
      result = OpportunityWrapper.wrap_opportunity(opportunity, code, language)
      
      assert result["location"] == "line 10"
      assert result["type"] == "performance"
      assert result["description"] == "This could be faster"
      assert result["severity"] == "medium"
      assert result["rationale"] == "Current implementation is inefficient"
    end
    
    test "handles an incomplete opportunity" do
      opportunity = %{
        "description" => "This could be faster"
      }
      
      code = "function test() { return 1 + 1; }"
      language = "javascript"
      
      result = OpportunityWrapper.wrap_opportunity(opportunity, code, language)
      
      assert result["location"] == "line 1"
      assert result["type"] == "performance"
      assert result["description"] == "This could be faster"
      assert result["severity"] == "medium"
      assert result["rationale"] == nil
    end
    
    test "handles an empty opportunity" do
      opportunity = %{}
      
      code = "function test() { return 1 + 1; }"
      language = "javascript"
      
      result = OpportunityWrapper.wrap_opportunity(opportunity, code, language)
      
      assert result["location"] == "line 1"
      assert result["type"] == "performance"
      assert result["description"] =~ "javascript"
      assert result["severity"] == "medium"
      assert result["rationale"] == nil
    end
    
    test "handles opportunities with atom keys" do
      opportunity = %{
        location: "line 10",
        type: "performance",
        description: "This could be faster",
        severity: "medium"
      }
      
      code = "function test() { return 1 + 1; }"
      language = "javascript"
      
      result = OpportunityWrapper.wrap_opportunity(opportunity, code, language)
      
      assert result["location"] == "line 10"
      assert result["type"] == "performance"
      assert result["description"] == "This could be faster"
      assert result["severity"] == "medium"
    end
  end
end 