defmodule Ace.GitHub.OptimizationAdapter do
  @moduledoc """
  Adapter module that bridges between GitHub PR optimization and the different optimization services.
  
  This module provides a unified interface for optimizing code in PRs, delegating to the appropriate
  optimization service based on configuration and environment.
  
  It follows the Adapter pattern to harmonize different optimization interfaces:
  - CodeOptimizer: Simple mock implementation for testing
  - Optimization.Service: Comprehensive optimization service for identified opportunities 
  - Evolution.Service: Self-evolution service based on feedback
  """
  require Logger
  
  alias Ace.Infrastructure.AI.CodeOptimizer
  alias Ace.Optimization.Service, as: OptimizationService
  alias Ace.Evolution.Service, as: EvolutionService
  
  @doc """
  Optimizes code from a PR file.
  
  ## Parameters
  
    - `code`: The source code to optimize
    - `language`: The programming language of the code
    - `filename`: The filename for context
    - `optimization_type`: The type of optimization to perform (:mock, :evolution, or :optimization)
  
  ## Returns
  
    - `{:ok, optimization_result}`: Successfully optimized code with suggestions and metrics
    - `{:error, reason}`: If optimization fails
  """
  def optimize_pr_file(code, language, filename, optimization_type \\ nil) do
    # Determine optimization type if not specified
    type = if is_nil(optimization_type), do: get_optimization_type(), else: optimization_type
    
    Logger.info("OptimizationAdapter: Optimizing file #{filename} with #{type} service")
    
    case type do
      :mock ->
        # Use the simple CodeOptimizer mock implementation
        Logger.info("OptimizationAdapter: Using mock implementation")
        result = CodeOptimizer.optimize_code(code, %{language: language, filename: filename})
        Logger.info("OptimizationAdapter: Mock optimization complete: #{inspect(result)}")
        result
        
      :evolution ->
        # Use the Evolution.Service (for feedback-based optimization)
        # This approach doesn't use opportunities directly
        Logger.info("OptimizationAdapter: Using Evolution.Service")
        
        case EvolutionService.generate_optimization(
          filename,
          code,
          "PR optimization using evolution service", # Generic rationale
          %{}, # No history for PR optimizations
          %{}  # No special options
        ) do
          {:ok, optimization_data} ->
            # Extract line numbers for more specific location information
            # We'll determine a specific region of the code (first 10-20 lines as an example)
            location = determine_location(code)
            Logger.info("OptimizationAdapter: Generated location: #{location}")
            
            # Transform to match CodeOptimizer output format expected by GitHub service
            result = %{
              optimized_code: optimization_data.optimized_code,
              explanation: optimization_data.explanation,
              metrics: %{
                estimated_speedup: "~15%",  # Default metrics since Evolution.Service doesn't provide them
                readability_improvement: "Medium",
                complexity_reduction: "Medium"
              },
              suggestions: [
                %{
                  type: "performance",  # Default type
                  location: location, # More specific location based on code structure
                  description: "Code optimization via Evolution service",
                  severity: "medium",
                  original_code: code,
                  optimized_code: optimization_data.optimized_code,
                  explanation: optimization_data.explanation
                }
              ]
            }
            
            Logger.info("OptimizationAdapter: Evolution optimization complete with suggestions: #{inspect(result.suggestions, pretty: true)}")
            {:ok, result}
          
          error -> 
            Logger.error("OptimizationAdapter: Evolution optimization failed: #{inspect(error)}")
            error
        end
        
      :optimization ->
        # Use the comprehensive Optimization.Service for optimization
        Logger.info("OptimizationAdapter: Using Optimization.Service")
        
        # Step 1: Analyze code to identify opportunities
        # Create a temporary analysis for this PR file
        {:ok, analysis} = Ace.Analysis.Service.analyze_code(
          code, 
          language, 
          file_path: filename, 
          focus_areas: ["performance", "maintainability", "security"], 
          severity_threshold: "low"
        )
        
        # Step 2: Find opportunities from the analysis
        opportunities = get_opportunities_for_analysis(analysis.id)
        
        # If no opportunities found, return empty result with original code
        if Enum.empty?(opportunities) do
          Logger.info("OptimizationAdapter: No optimization opportunities found")
          {:ok, %{
            optimized_code: code,
            explanation: "No optimization opportunities identified",
            metrics: %{estimated_speedup: "0%", complexity_reduction: "None", readability_improvement: "None"},
            suggestions: []
          }}
        else
          # Step 3: Optimize each opportunity and collect results
          suggestions = Enum.map(opportunities, fn opportunity ->
            case OptimizationService.optimize(%{opportunity_id: opportunity.id, strategy: "auto"}) do
              {:ok, optimization} ->
                %{
                  type: opportunity.type,
                  location: opportunity.location,
                  description: opportunity.description,
                  severity: opportunity.severity,
                  original_code: optimization.original_code,
                  optimized_code: optimization.optimized_code,
                  explanation: optimization.explanation
                }
              _ -> nil
            end
          end) |> Enum.reject(&is_nil/1)
          
          # Calculate metrics based on opportunities and optimizations
          metrics = calculate_metrics_from_opportunities(opportunities)
          
          # Return results in the format expected by GitHub service
          {:ok, %{
            optimized_code: code, # For now, keep original code as we're just suggesting changes
            explanation: "Optimized code with #{length(suggestions)} suggestions",
            metrics: metrics,
            suggestions: suggestions
          }}
        end
    end
  end
  
  # Get the configured optimization type based on environment or config
  defp get_optimization_type do
    case Application.get_env(:ace, :pr_optimization_service) do
      "evolution" -> :evolution
      "optimization" -> :optimization
      "mock" -> :mock
      # Default to mock in development/test and evolution in production
      nil -> 
        case Mix.env() do
          :prod -> :evolution
          _ -> :mock
        end
    end
  end
  
  # Determine a reasonable location for a code suggestion based on the code content
  defp determine_location(code) do
    lines = String.split(code, "\n")
    line_count = length(lines)
    
    cond do
      # For very small files, use the entire file
      line_count <= 10 ->
        "lines 1-#{line_count}"
      
      # For medium files, use first function or meaningful section (approximation)
      line_count <= 50 ->
        "lines 1-20"
        
      # For larger files, use an approximation of an important section
      true ->
        # Try to find a function or class definition to target
        # This is a simple heuristic and could be improved
        first_def_index = Enum.find_index(lines, fn line -> 
          String.contains?(line, "def ") || 
          String.contains?(line, "function ") || 
          String.contains?(line, "class ")
        end)
        
        if first_def_index do
          start_line = first_def_index + 1
          end_line = min(first_def_index + 20, line_count)
          "lines #{start_line}-#{end_line}"
        else
          # Fallback to a reasonable section in the middle of the file
          start_line = div(line_count, 4)
          end_line = min(start_line + 20, line_count)
          "lines #{start_line}-#{end_line}"
        end
    end
  end
  
  # Calculate metrics based on opportunities
  defp calculate_metrics_from_opportunities(opportunities) do
    # Count severity levels
    severity_counts = Enum.reduce(opportunities, %{high: 0, medium: 0, low: 0}, fn opp, acc ->
      case opp.severity do
        "high" -> Map.update!(acc, :high, &(&1 + 1))
        "medium" -> Map.update!(acc, :medium, &(&1 + 1))
        "low" -> Map.update!(acc, :low, &(&1 + 1))
        _ -> acc
      end
    end)
    
    # Estimate speedup based on severity
    estimated_speedup = 
      severity_counts.high * 10 + 
      severity_counts.medium * 5 + 
      severity_counts.low * 2
    
    # Determine complexity reduction and readability
    {complexity, readability} = cond do
      severity_counts.high > 0 -> {"High", "Medium"}
      severity_counts.medium > 0 -> {"Medium", "Medium"}
      true -> {"Low", "Low"}
    end
    
    # Format estimated speedup
    speedup_str = if estimated_speedup > 0, do: "~#{estimated_speedup}%", else: "minimal"
    
    %{
      estimated_speedup: speedup_str,
      complexity_reduction: complexity,
      readability_improvement: readability
    }
  end
  
  # Get opportunities for a specific analysis ID
  defp get_opportunities_for_analysis(analysis_id) do
    alias Ace.Analysis.Models.Opportunity
    import Ecto.Query
    
    Opportunity
    |> where([o], o.analysis_id == ^analysis_id)
    |> Ace.Repo.all()
  end
end 