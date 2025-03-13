defmodule Ace.Infrastructure.AI.Schemas.AnalysisTest do
  use ExUnit.Case, async: true

  alias Ace.Infrastructure.AI.Schemas.Analysis

  describe "opportunity_list_schema/0" do
    test "returns a valid JSON schema" do
      schema = Analysis.opportunity_list_schema()

      assert is_map(schema)
      assert schema["title"] == "OptimizationOpportunities"
      assert schema["type"] == "object"
      assert is_map(schema["properties"])
      assert is_map(schema["properties"]["opportunities"])
      assert schema["required"] == ["opportunities"]
    end

    test "schema includes opportunity item properties" do
      schema = Analysis.opportunity_list_schema()
      item_schema = schema["properties"]["opportunities"]["items"]

      assert item_schema["type"] == "object"
      assert is_map(item_schema["properties"])
      
      # Check required fields
      assert "location" in item_schema["required"]
      assert "type" in item_schema["required"]
      assert "description" in item_schema["required"]
      assert "severity" in item_schema["required"]
      
      # Check property definitions
      assert item_schema["properties"]["location"]["type"] == "string"
      assert item_schema["properties"]["type"]["type"] == "string"
      assert item_schema["properties"]["description"]["type"] == "string"
      assert item_schema["properties"]["severity"]["type"] == "string"
      
      # Check enums
      assert item_schema["properties"]["type"]["enum"] == ["performance", "maintainability", "security", "reliability"]
      assert item_schema["properties"]["severity"]["enum"] == ["low", "medium", "high"]
    end
  end
  
  describe "cross_file_opportunity_list_schema/0" do
    test "returns a valid JSON schema" do
      schema = Analysis.cross_file_opportunity_list_schema()

      assert is_map(schema)
      assert schema["title"] == "CrossFileOptimizationOpportunities"
      assert schema["type"] == "object"
      assert is_map(schema["properties"])
      assert is_map(schema["properties"]["opportunities"])
      assert schema["required"] == ["opportunities"]
    end
    
    test "schema includes cross-file specific fields" do
      schema = Analysis.cross_file_opportunity_list_schema()
      item_schema = schema["properties"]["opportunities"]["items"]
      
      # Check for cross-file specific fields
      assert "primary_file" in item_schema["required"]
      assert "cross_file_references" in item_schema["required"]
      
      # Check primary_file property
      assert item_schema["properties"]["primary_file"]["type"] == "string"
      
      # Check cross_file_references property
      cross_refs = item_schema["properties"]["cross_file_references"]
      assert cross_refs["type"] == "array"
      assert is_map(cross_refs["items"])
      assert cross_refs["items"]["properties"]["file"]["type"] == "string"
      assert "file" in cross_refs["items"]["required"]
    end
    
    test "crossfile schema has all required fields for opportunities" do
      schema = Analysis.cross_file_opportunity_list_schema()
      item_schema = schema["properties"]["opportunities"]["items"]
      
      # Check for all standard opportunity fields
      assert "location" in item_schema["required"]
      assert "type" in item_schema["required"]
      assert "description" in item_schema["required"]
      assert "severity" in item_schema["required"]
      
      # Check additional fields
      assert item_schema["properties"]["type"]["enum"] == ["performance", "maintainability", "security", "reliability"]
      assert item_schema["properties"]["severity"]["enum"] == ["low", "medium", "high"]
    end
  end

  describe "opportunity_schema/0" do
    test "returns a valid opportunity schema" do
      schema = Analysis.opportunity_schema()

      assert is_map(schema)
      assert schema["type"] == "object"
      assert is_map(schema["properties"])
      assert length(schema["required"]) == 4
      
      # Check properties
      assert schema["properties"]["location"]["type"] == "string"
      assert schema["properties"]["type"]["type"] == "string"
      assert schema["properties"]["description"]["type"] == "string"
      assert schema["properties"]["severity"]["type"] == "string"
      assert schema["properties"]["rationale"]["type"] == "string"
      assert schema["properties"]["suggested_change"]["type"] == "string"
    end
  end
  
  describe "cross_file_opportunity_schema/0" do
    test "returns a valid cross-file opportunity schema" do
      schema = Analysis.cross_file_opportunity_schema()

      assert is_map(schema)
      assert schema["type"] == "object"
      assert is_map(schema["properties"])
      assert length(schema["required"]) == 6
      
      # Check additional properties specific to cross-file
      assert schema["properties"]["primary_file"]["type"] == "string"
      assert schema["properties"]["cross_file_references"]["type"] == "array"
      
      # Check reference item schema
      reference_item = schema["properties"]["cross_file_references"]["items"]
      assert reference_item["properties"]["file"]["type"] == "string"
      assert reference_item["properties"]["location"]["type"] == "string"
      assert reference_item["properties"]["relationship"]["type"] == "string"
    end
  end
end