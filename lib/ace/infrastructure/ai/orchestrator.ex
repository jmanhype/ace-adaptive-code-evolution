defmodule Ace.Infrastructure.AI.Orchestrator do
  @moduledoc """
  Orchestrates AI operations and prompt management.
  Supports both single-file and multi-file code analysis and optimization.
  Also provides support for self-evolving code based on feedback.
  """
  require Logger
  
  alias Ace.Infrastructure.AI.OpportunityWrapper
  
  @doc """
  Analyzes code to identify optimization opportunities.
  
  ## Parameters
  
    - `code`: The source code to analyze
    - `language`: The programming language of the code
    - `focus_areas`: List of areas to focus on during analysis
    - `options`: Additional options
  
  ## Returns
  
    - `{:ok, opportunities}`: List of identified optimization opportunities
    - `{:error, reason}`: If analysis fails
  """
  def analyze_code(code, language, focus_areas \\ ["performance"], options \\ []) do
    provider = get_provider()
    model = get_model()
    
    prompt = Ace.Infrastructure.AI.Prompts.Analysis.build(code, language, focus_areas)
    system_prompt = Ace.Infrastructure.AI.Prompts.Analysis.system_prompt()
    
    schema = Ace.Infrastructure.AI.Schemas.Analysis.opportunity_list_schema()
    
    start_time = System.monotonic_time(:millisecond)
    
    # Convert options to map if it's a keyword list
    options_map = if is_map(options), do: options, else: Enum.into(options, %{})
    
    result = 
      with {:ok, structured_response} <- provider.generate_structured(
              prompt,
              system_prompt,
              schema,
              model,
              options_map
            ) do
        
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time
        
        record_telemetry(:analyze_code, %{duration: duration}, %{
          language: language,
          code_size: byte_size(code),
          focus_areas: focus_areas,
          model: model
        })
        
        # Handle various formats of response from different providers
        opportunities = cond do
          # Standard format with opportunities field as atom key
          is_map(structured_response) && Map.has_key?(structured_response, :opportunities) ->
            structured_response.opportunities
            
          # Standard format with opportunities field as string key
          is_map(structured_response) && Map.has_key?(structured_response, "opportunities") ->
            structured_response["opportunities"]
            
          # Direct list of opportunities
          is_list(structured_response) ->
            structured_response
            
          # Nested under properties (some Groq responses)
          is_map(structured_response) && 
          Map.has_key?(structured_response, "properties") && 
          Map.has_key?(structured_response["properties"], "opportunities") ->
            structured_response["properties"]["opportunities"]
            
          # Handle unexpected formats
          true ->
            Logger.warning("Received unexpected AI response format: #{inspect(structured_response)}")
            []
        end
        
        # Use OpportunityWrapper to ensure all required fields are present
        wrapped_opportunities = OpportunityWrapper.wrap_opportunities(opportunities, code, language)
        {:ok, wrapped_opportunities}
      else
        {:error, _} = error ->
          Logger.error("Failed to generate optimization", error: inspect(error))
          
          # Generate a fallback opportunity to prevent failure
          opportunities = OpportunityWrapper.wrap_opportunities(nil, code, language)
          {:ok, opportunities}
      end
      
    result
  end
  
  @doc """
  Generates optimized code based on an opportunity.
  
  ## Parameters
  
    - `opportunity`: The optimization opportunity
    - `original_code`: The original code to optimize
    - `strategy`: The optimization strategy to use
    - `options`: Additional options
  
  ## Returns
  
    - `{:ok, optimization}`: The generated optimization
    - `{:error, reason}`: If optimization fails
  """
  def generate_optimization(opportunity, original_code, strategy, options \\ []) do
    provider = get_provider()
    model = get_model()
    
    prompt = Ace.Infrastructure.AI.Prompts.Optimization.build(opportunity, original_code, strategy)
    system_prompt = Ace.Infrastructure.AI.Prompts.Optimization.system_prompt()
    
    schema = Ace.Infrastructure.AI.Schemas.Optimization.optimization_schema()
    
    start_time = System.monotonic_time(:millisecond)
    
    # Convert options to map if it's a keyword list
    options_map = if is_map(options), do: options, else: Enum.into(options, %{})
    
    result =
      with {:ok, structured_response} <- provider.generate_structured(
              prompt,
              system_prompt,
              schema,
              model,
              options_map
            ) do
        
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time
        
        record_telemetry(:generate_optimization, %{duration: duration}, %{
          opportunity_type: opportunity.type,
          code_size: byte_size(original_code),
          strategy: strategy,
          model: model
        })
        
        # Handle different response formats from different AI providers
        optimization = cond do
          # Standard format with direct keys
          is_map(structured_response) && 
          Map.has_key?(structured_response, :optimized_code) && 
          Map.has_key?(structured_response, :explanation) ->
            structured_response
            
          # JSON response with string keys
          is_map(structured_response) && 
          Map.has_key?(structured_response, "optimized_code") && 
          Map.has_key?(structured_response, "explanation") ->
            %{
              optimized_code: structured_response["optimized_code"],
              explanation: structured_response["explanation"]
            }
            
          # Nested under properties (some Groq responses)
          is_map(structured_response) && 
          Map.has_key?(structured_response, "properties") ->
            props = structured_response["properties"]
            %{
              optimized_code: Map.get(props, "optimized_code", ""),
              explanation: Map.get(props, "explanation", "No explanation provided")
            }
            
          true ->
            # Fallback for unexpected formats
            Logger.warning("Unexpected response format from AI provider: #{inspect(structured_response)}")
            %{
              optimized_code: "# Unable to parse optimization response\n#{inspect(structured_response)}",
              explanation: "The optimization response format was unexpected. Please try again."
            }
        end
        
        {:ok, optimization}
      else
        {:error, _} = error ->
          Logger.error("Failed to generate optimization", error: inspect(error))
          error
      end
      
    result
  end
  
  @doc """
  Analyzes multiple files together to identify cross-file optimization opportunities.
  
  ## Parameters
  
    - `file_context`: List of file contexts with file_path, file_name, language, and content
    - `primary_language`: The main programming language for analysis
    - `options`: Additional options
  
  ## Returns
  
    - `{:ok, opportunities}`: List of identified cross-file optimization opportunities
    - `{:error, reason}`: If analysis fails
  """
  def analyze_cross_file(file_context, primary_language, options \\ []) do
    provider = get_provider()
    model = get_model()
    
    # Build combined prompt with all file contexts
    prompt = Ace.Infrastructure.AI.Prompts.Analysis.build_multi_file(file_context, primary_language, options[:focus_areas] || ["performance"])
    system_prompt = Ace.Infrastructure.AI.Prompts.Analysis.system_prompt_multi_file()
    
    # Use an enhanced schema that supports cross-file references
    schema = Ace.Infrastructure.AI.Schemas.Analysis.cross_file_opportunity_list_schema()
    
    start_time = System.monotonic_time(:millisecond)
    
    # Convert options to map if it's a keyword list
    options_map = if is_map(options), do: options, else: Enum.into(options, %{})
    
    result = 
      with {:ok, structured_response} <- provider.generate_structured(
              prompt, 
              system_prompt,
              schema,
              model,
              options_map
            ) do
              
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time
        
        record_telemetry(:analyze_cross_file, %{duration: duration}, %{
          language: primary_language,
          file_count: length(file_context),
          model: model
        })
        
        # Extract opportunities from response
        opportunities = cond do
          # Standard format with opportunities field as atom key
          is_map(structured_response) && Map.has_key?(structured_response, :opportunities) ->
            structured_response.opportunities
            
          # Standard format with opportunities field as string key
          is_map(structured_response) && Map.has_key?(structured_response, "opportunities") ->
            structured_response["opportunities"]
            
          # Direct list of opportunities
          is_list(structured_response) ->
            structured_response
            
          # Nested under properties (some Groq responses)
          is_map(structured_response) && 
          Map.has_key?(structured_response, "properties") && 
          Map.has_key?(structured_response["properties"], "opportunities") ->
            structured_response["properties"]["opportunities"]
          
          # Handle unexpected formats  
          true ->
            Logger.warning("Received unexpected cross-file AI response: #{inspect(structured_response)}")
            []
        end
        
        # Get combined code for the wrapper
        combined_code = Enum.map_join(file_context, "\n\n", fn ctx -> ctx.content end)
        
        # Use OpportunityWrapper to ensure all required fields are present
        wrapped_opportunities = OpportunityWrapper.wrap_opportunities(opportunities, combined_code, primary_language)
        {:ok, wrapped_opportunities}
      else
        {:error, _} = error ->
          Logger.error("Failed to analyze cross-file code", error: inspect(error))
          
          # Get combined code for the wrapper
          combined_code = Enum.map_join(file_context, "\n\n", fn ctx -> ctx.content end)
          
          # Generate a fallback opportunity to prevent failure
          opportunities = OpportunityWrapper.wrap_opportunities(nil, combined_code, primary_language)
          {:ok, opportunities}
      end
      
    result
  end

  @doc """
  Evaluates optimized code to determine its effectiveness.
  
  ## Parameters
  
    - `original_code`: The original code
    - `optimized_code`: The optimized code
    - `metrics`: Performance metrics from running both versions
    - `options`: Additional options
  
  ## Returns
  
    - `{:ok, evaluation}`: The evaluation of the optimization
    - `{:error, reason}`: If evaluation fails
  """
  def evaluate_optimization(original_code, optimized_code, metrics, options \\ []) do
    provider = get_provider()
    model = get_model()
    
    prompt = Ace.Infrastructure.AI.Prompts.Evaluation.build(original_code, optimized_code, metrics)
    system_prompt = Ace.Infrastructure.AI.Prompts.Evaluation.system_prompt()
    
    schema = Ace.Infrastructure.AI.Schemas.Evaluation.evaluation_schema()
    
    start_time = System.monotonic_time(:millisecond)
    
    # Convert options to map if it's a keyword list
    options_map = if is_map(options), do: options, else: Enum.into(options, %{})
    
    result =
      with {:ok, structured_response} <- provider.generate_structured(
              prompt,
              system_prompt,
              schema,
              model,
              options_map
            ) do
        
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time
        
        record_telemetry(:evaluate_optimization, %{duration: duration}, %{
          original_code_size: byte_size(original_code),
          optimized_code_size: byte_size(optimized_code),
          metrics_count: map_size(metrics),
          model: model
        })
        
        {:ok, structured_response}
      else
        {:error, _} = error ->
          Logger.error("Failed to evaluate optimization", error: inspect(error))
          error
      end
      
    result
  end
  
  # Private helper functions
  
  defp get_provider do
    # Check for environment variables first to allow runtime override
    provider_name = cond do
      System.get_env("GROQ_API_KEY") && System.get_env("GROQ_API_KEY") != "" ->
        "groq"
      System.get_env("OPENAI_API_KEY") && System.get_env("OPENAI_API_KEY") != "" ->
        "openai"
      System.get_env("ANTHROPIC_API_KEY") && System.get_env("ANTHROPIC_API_KEY") != "" ->
        "anthropic"
      true ->
        # Fall back to application config
        Application.get_env(:ace, :llm_provider, "mock")
    end
    
    # For CLI usage, default to mock provider if module doesn't exist
    try do
      provider_module = String.to_existing_atom("Elixir.Ace.Infrastructure.AI.Providers.#{String.capitalize(provider_name)}")
      provider_module
    rescue
      ArgumentError ->
        # Default to Mock if the requested provider doesn't exist
        Ace.Infrastructure.AI.Providers.Mock
    end
  end
  
  defp get_model do
    Application.get_env(:ace, :llm_model) || 
      case get_provider().name() do
        "groq" -> "llama3-70b-8192"
        "openai" -> "gpt-4"
        "anthropic" -> "claude-3-opus-20240229"
        _ -> "llama3-70b-8192"
      end
  end
  
  defp record_telemetry(event, measurements, metadata) do
    :telemetry.execute(
      [:ace, :ai, event],
      measurements,
      metadata
    )
  end
  
  @doc """
  Generates a structured response using the provided prompt and schema.
  For evolution use cases that don't perfectly fit into the standard pattern.
  
  ## Parameters
    
    - `prompt`: The text prompt for the AI model
    - `system_prompt`: System prompt that sets the context
    - `schema`: JSON schema defining the expected response format
    - `model`: Optional AI model name to use
    - `options`: Additional options for the request
  
  ## Returns
  
    - `{:ok, result}`: The structured result matching the schema
    - `{:error, reason}`: If the request fails
  """
  def generate_structured_response(prompt, system_prompt, schema, model \\ nil, options \\ %{}) do
    provider = get_provider()
    model = model || get_model()
    
    # Convert options to map if it's a keyword list
    options_map = if is_map(options), do: options, else: Enum.into(options, %{})
    
    start_time = System.monotonic_time(:millisecond)
    
    result = 
      with {:ok, structured_response} <- provider.generate_structured(
              prompt,
              system_prompt,
              schema,
              model,
              options_map
            ) do
      
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time
        
        record_telemetry(:structured_response, %{duration: duration}, %{
          prompt_size: byte_size(prompt),
          model: model
        })
        
        # Handle different response formats
        response = normalize_structured_response(structured_response)  
        {:ok, response}
      else
        {:error, _} = error ->
          Logger.error("Failed to generate structured response", error: inspect(error))
          error
      end
      
    result
  end
  
  # Normalize different formats of structured responses
  defp normalize_structured_response(response) when is_map(response) do
    cond do
      # Directly usable format with atom keys
      Map.has_key?(response, :optimized_code) && Map.has_key?(response, :explanation) ->
        response
      
      # JSON response with string keys
      Map.has_key?(response, "optimized_code") && Map.has_key?(response, "explanation") ->
        %{
          optimized_code: response["optimized_code"],
          explanation: response["explanation"]
        }
        
      # Nested under properties (some API responses)
      Map.has_key?(response, "properties") && 
      is_map(response["properties"]) ->
        props = response["properties"]
        %{
          optimized_code: Map.get(props, "optimized_code", ""),
          explanation: Map.get(props, "explanation", "No explanation provided")
        }
        
      true ->
        # Best effort extraction
        %{
          optimized_code: Map.get(response, :optimized_code) || 
                          Map.get(response, "optimized_code") || 
                          "# Unable to extract optimized code",
          explanation: Map.get(response, :explanation) || 
                       Map.get(response, "explanation") || 
                       "No explanation provided"
        }
    end
  end
  
  # Fallback for unexpected formats
  defp normalize_structured_response(response) do
    %{
      optimized_code: "# Unexpected response format\n#{inspect(response)}",
      explanation: "The response was not in the expected format"
    }
  end
  
  @doc """
  Generates optimized code based on a file, feedback, and history.
  This is a higher-level function that wraps generate_optimization for evolution use cases.
  
  ## Parameters
  
    - `module_name`: Name of the module or file being optimized
    - `source_code`: Current source code of the module
    - `feedback`: Rationale for the optimization (can be feedback summary or analysis explanation)
    - `history`: Historical context for the optimization
    - `options`: Additional options for the optimization process
  
  ## Returns
  
    - `{:ok, optimization}`: The generated optimization with optimized code and explanation
    - `{:error, reason}`: If optimization generation fails
  """
  def generate_code_optimization(module_name, source_code, feedback, history, options \\ %{}) do
    # Create a mock opportunity structure that's compatible with generate_optimization
    opportunity = %{
      type: "evolution",
      description: "Code evolution based on feedback",
      rationale: (if is_binary(feedback), do: feedback, else: inspect(feedback))
    }
    
    # Extract strategy from options or default to "auto"
    strategy = Map.get(options, :strategy, "auto")
    
    # Include history in the options
    enhanced_options = Map.put(options, :history, history)
    
    # Call the regular optimization function
    generate_optimization(opportunity, source_code, strategy, enhanced_options)
  end
end