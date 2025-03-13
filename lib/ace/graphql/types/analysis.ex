defmodule Ace.GraphQL.Types.Analysis do
  @moduledoc """
  GraphQL types for Analysis domain entities.
  """
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  
  @desc "An analysis of code to identify optimization opportunities"
  object :analysis do
    field :id, non_null(:id), description: "Unique identifier"
    field :file_path, non_null(:string), description: "Path to the analyzed file"
    field :language, non_null(:string), description: "Programming language of the code"
    field :content, :string, description: "Content of the analyzed code"
    field :focus_areas, list_of(:string), description: "Areas to focus on during analysis"
    field :severity_threshold, :string, description: "Minimum severity threshold for opportunities"
    field :completed_at, :datetime, description: "When the analysis was completed"
    field :inserted_at, non_null(:datetime), description: "When the analysis was created"
    field :updated_at, non_null(:datetime), description: "When the analysis was last updated"
    
    field :opportunities, list_of(:opportunity), description: "Opportunities identified during analysis" do
      resolve fn analysis, _, _ ->
        opportunities = Ace.Repo.preload(analysis, :opportunities).opportunities
        {:ok, opportunities}
      end
    end
  end
  
  @desc "An optimization opportunity identified during analysis"
  object :opportunity do
    field :id, non_null(:id), description: "Unique identifier"
    field :location, non_null(:string), description: "Location in the code (e.g., line number, function name)"
    field :type, non_null(:string), description: "Type of opportunity (performance, maintainability, etc.)"
    field :description, non_null(:string), description: "Description of the opportunity"
    field :severity, non_null(:string), description: "Severity level (low, medium, high)"
    field :rationale, :string, description: "Rationale explaining why this is an issue"
    field :suggested_change, :string, description: "Suggested change to address the issue"
    field :inserted_at, non_null(:datetime), description: "When the opportunity was created"
    field :updated_at, non_null(:datetime), description: "When the opportunity was last updated"
    
    field :analysis, :analysis, description: "Analysis that identified this opportunity" do
      resolve fn opportunity, _, _ ->
        analysis = Ace.Repo.preload(opportunity, :analysis).analysis
        {:ok, analysis}
      end
    end
    
    field :optimizations, list_of(:optimization), description: "Optimizations generated for this opportunity" do
      resolve fn opportunity, _, _ ->
        optimizations = Ace.Repo.preload(opportunity, :optimizations).optimizations
        {:ok, optimizations}
      end
    end
  end
  
  @desc "Input for analyzing code"
  input_object :analyze_code_input do
    field :content, non_null(:string), description: "Code content to analyze"
    field :language, non_null(:string), description: "Programming language of the code"
    field :file_path, :string, description: "Path to the file (optional)"
    field :focus_areas, list_of(:string), description: "Areas to focus on during analysis"
    field :severity_threshold, :string, description: "Minimum severity threshold for opportunities" 
  end
  
  @desc "Input for filtering analyses"
  input_object :analysis_filter_input do
    field :file_path, :string, description: "Filter by file path (exact match)"
    field :file_path_contains, :string, description: "Filter by file path (contains)"
    field :language, :string, description: "Filter by programming language"
    field :created_after, :datetime, description: "Filter by creation date (after)"
    field :created_before, :datetime, description: "Filter by creation date (before)"
  end
  
  @desc "Input for filtering opportunities"
  input_object :opportunity_filter_input do
    field :analysis_id, :id, description: "Filter by analysis ID"
    field :type, :string, description: "Filter by opportunity type"
    field :severity, :string, description: "Filter by severity level"
    field :location_contains, :string, description: "Filter by location (contains)"
    field :description_contains, :string, description: "Filter by description (contains)"
  end
end