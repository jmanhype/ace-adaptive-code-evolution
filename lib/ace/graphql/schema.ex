defmodule Ace.GraphQL.Schema do
  @moduledoc """
  GraphQL schema for ACE system.
  
  This schema provides a comprehensive interface to the ACE system's functionality,
  allowing clients to perform analyses, optimizations, evaluations, and
  pipeline operations through a flexible GraphQL API.
  """
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern
  
  alias Ace.GraphQL.Resolvers
  
  # Import type definitions
  import_types(Absinthe.Type.Custom)
  import_types(Absinthe.Plug.Types)
  import_types(Ace.GraphQL.Types.Analysis)
  import_types(Ace.GraphQL.Types.Optimization)
  import_types(Ace.GraphQL.Types.Evaluation)
  
  # Custom scalar for JSON data
  scalar :json, name: "JSON" do
    description """
    The `JSON` scalar type represents arbitrary JSON data as a JSON string.
    """
    
    serialize &Jason.encode!/1
    parse &Jason.decode!/1
  end
  
  # Root queries
  query do
    @desc "Get system information"
    field :system_info, :json do
      resolve fn _, _, _ ->
        {:ok, %{
          version: Application.spec(:ace, :vsn) || "development",
          environment: Ace.Config.get("environment") || "development",
          ai_provider: Ace.Config.get("ai_provider"),
          supported_languages: ["elixir", "javascript", "python", "ruby", "go"]
        }}
      end
    end
    
    @desc "Get an analysis by ID"
    field :analysis, :analysis do
      arg :id, non_null(:id)
      resolve &Resolvers.Analysis.get_analysis/3
    end
    
    @desc "List analyses with optional filters"
    field :analyses, list_of(:analysis) do
      arg :filter, :analysis_filter_input
      arg :limit, :integer, default_value: 10
      arg :offset, :integer, default_value: 0
      resolve &Resolvers.Analysis.list_analyses/3
    end
    
    @desc "Get an opportunity by ID"
    field :opportunity, :opportunity do
      arg :id, non_null(:id)
      resolve &Resolvers.Analysis.get_opportunity/3
    end
    
    @desc "List opportunities with optional filters"
    field :opportunities, list_of(:opportunity) do
      arg :filter, :opportunity_filter_input
      arg :limit, :integer, default_value: 10
      arg :offset, :integer, default_value: 0
      resolve &Resolvers.Analysis.list_opportunities/3
    end
    
    @desc "Get an optimization by ID"
    field :optimization, :optimization do
      arg :id, non_null(:id)
      resolve &Resolvers.Optimization.get_optimization/3
    end
    
    @desc "List optimizations with optional filters"
    field :optimizations, list_of(:optimization) do
      arg :filter, :optimization_filter_input
      arg :limit, :integer, default_value: 10
      arg :offset, :integer, default_value: 0
      resolve &Resolvers.Optimization.list_optimizations/3
    end
    
    @desc "Get an evaluation by ID"
    field :evaluation, :evaluation do
      arg :id, non_null(:id)
      resolve &Resolvers.Evaluation.get_evaluation/3
    end
    
    @desc "List evaluations with optional filters"
    field :evaluations, list_of(:evaluation) do
      arg :filter, :json
      arg :limit, :integer, default_value: 10
      arg :offset, :integer, default_value: 0
      resolve &Resolvers.Evaluation.list_evaluations/3
    end
    
    @desc "Get an experiment by ID"
    field :experiment, :experiment do
      arg :id, non_null(:id)
      resolve &Resolvers.Evaluation.get_experiment/3
    end
  end
  
  # Root mutations
  mutation do
    @desc "Analyze code to identify optimization opportunities"
    field :analyze_code, :analysis do
      arg :input, non_null(:analyze_code_input)
      resolve &Resolvers.Analysis.analyze_code/3
    end
    
    @desc "Generate an optimization for an opportunity"
    field :optimize, :optimization do
      arg :input, non_null(:optimize_input)
      resolve &Resolvers.Optimization.optimize/3
    end
    
    @desc "Evaluate an optimization"
    field :evaluate, :evaluation do
      arg :input, non_null(:evaluate_input)
      resolve &Resolvers.Evaluation.evaluate/3
    end
    
    @desc "Apply an optimization to the codebase"
    field :apply_optimization, :optimization do
      arg :input, non_null(:apply_optimization_input)
      resolve &Resolvers.Optimization.apply_optimization/3
    end
    
    @desc "Run the complete pipeline"
    field :run_pipeline, :pipeline_result do
      arg :input, non_null(:run_pipeline_input)
      resolve &Resolvers.Evaluation.run_pipeline/3
    end
  end
  
  # Subscription support for real-time updates
  subscription do
    @desc "Subscribe to analysis events"
    field :analysis_event, :analysis do
      arg :analysis_id, :id
      
      config fn args, _info ->
        {:ok, topic: args[:analysis_id] || "*"}
      end
      
      trigger [:analyze_code], topic: fn
        %{id: id} -> [id, "*"]
        _ -> []
      end
      
      resolve fn analysis, _, _ ->
        {:ok, analysis}
      end
    end
    
    @desc "Subscribe to optimization events"
    field :optimization_event, :optimization do
      arg :opportunity_id, :id
      
      config fn args, _info ->
        {:ok, topic: args[:opportunity_id] || "*"}
      end
      
      trigger [:optimize], topic: fn
        %{opportunity_id: id} -> [id, "*"]
        _ -> []
      end
      
      resolve fn optimization, _, _ ->
        {:ok, optimization}
      end
    end
    
    @desc "Subscribe to evaluation events"
    field :evaluation_event, :evaluation do
      arg :optimization_id, :id
      
      config fn args, _info ->
        {:ok, topic: args[:optimization_id] || "*"}
      end
      
      trigger [:evaluate], topic: fn
        %{optimization_id: id} -> [id, "*"]
        _ -> []
      end
      
      resolve fn evaluation, _, _ ->
        {:ok, evaluation}
      end
    end
    
    @desc "Subscribe to pipeline events"
    field :pipeline_event, :pipeline_result do
      arg :file_path, :string
      
      config fn args, _info ->
        {:ok, topic: args[:file_path] || "*"}
      end
      
      trigger [:run_pipeline], topic: fn
        %{file_path: path} -> [path, "*"]
        _ -> []
      end
      
      resolve fn pipeline_result, _, _ ->
        {:ok, pipeline_result}
      end
    end
  end
end