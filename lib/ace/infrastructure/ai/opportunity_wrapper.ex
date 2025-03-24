defmodule Ace.Infrastructure.AI.OpportunityWrapper do
  @moduledoc """
  Wrapper to ensure AI-generated opportunities have all required fields.
  
  This module processes raw AI output to ensure the opportunities it generates
  always have the required fields populated, even when the AI may not provide
  complete information.
  """
  require Logger

  @doc """
  Ensures all opportunities have required fields populated.
  
  ## Parameters
  
    - `opportunities`: List of opportunities from AI
    - `code`: Source code being analyzed 
    - `language`: Programming language of the code
  
  ## Returns
  
    - `wrapped_opportunities`: List of opportunities with all required fields
  """
  def wrap_opportunities(opportunities, code, language) when is_list(opportunities) do
    Enum.map(opportunities, &wrap_opportunity(&1, code, language))
  end
  
  def wrap_opportunities(nil, code, language) do
    Logger.warning("Received nil opportunities from AI, generating fallback")
    # Generate a fallback opportunity to prevent complete failure
    [wrap_opportunity(%{}, code, language)]
  end
  
  def wrap_opportunities(opportunities, code, language) do
    # Handle case where opportunities is a map with opportunities as a key
    cond do
      is_map(opportunities) && Map.has_key?(opportunities, :opportunities) ->
        wrap_opportunities(opportunities.opportunities, code, language)
      is_map(opportunities) && Map.has_key?(opportunities, "opportunities") ->
        wrap_opportunities(opportunities["opportunities"], code, language)
      true ->
        Logger.warning("Received unexpected opportunities format from AI: #{inspect(opportunities)}")
        [wrap_opportunity(%{}, code, language)]
    end
  end
  
  @doc """
  Ensures a single opportunity has all required fields.
  
  ## Parameters
  
    - `opportunity`: Single opportunity (possibly incomplete)
    - `code`: Source code being analyzed
    - `language`: Programming language of the code
  
  ## Returns
  
    - `wrapped_opportunity`: Opportunity with all required fields
  """
  def wrap_opportunity(opportunity, code, language) do
    # Extract values with fallbacks for all required fields
    location = extract_field(opportunity, "location", "line 1") 
    type = extract_field(opportunity, "type", "performance")
    description = extract_field(opportunity, "description", "Code can be optimized for better #{language} performance")
    severity = extract_field(opportunity, "severity", "medium")
    
    # Optional fields
    rationale = extract_field(opportunity, "rationale", nil)
    suggested_change = extract_field(opportunity, "suggested_change", nil)
    
    # Return wrapped opportunity with all required fields
    %{
      "location" => location,
      "type" => type, 
      "description" => description,
      "severity" => severity,
      "rationale" => rationale,
      "suggested_change" => suggested_change
    }
  end
  
  # Extract a field value with fallback if not present
  defp extract_field(map, key, default) do
    cond do
      is_map(map) && Map.has_key?(map, key) -> Map.get(map, key)
      is_map(map) && Map.has_key?(map, String.to_atom(key)) -> Map.get(map, String.to_atom(key))
      true -> default
    end
  end
end 