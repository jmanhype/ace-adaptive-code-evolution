defmodule Ace.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Build base children list
    base_children = [
      # Database
      Ace.Repo,
      
      # Core Supervisors
      Ace.Core.Supervisor,
      
      # Services
      Ace.Analysis.Supervisor,
      Ace.Optimization.Supervisor,
      Ace.Evaluation.Supervisor,
      Ace.Evolution.Supervisor,
      Ace.Telemetry.Supervisor,
      
      # Infrastructure
      Ace.Infrastructure.Supervisor
    ]
    
    # Add web-related children if not skipped
    web_children = 
      if Application.get_env(:ace, :skip_web, false) do
        []
      else
        [
          # PubSub
          {Phoenix.PubSub, name: Ace.PubSub},
          
          # Web Endpoints
          AceWeb.Endpoint
        ]
      end
    
    # Add GraphQL-related children if not skipped
    graphql_children = 
      if Application.get_env(:ace, :skip_graphql, false) do
        []
      else
        [
          # GraphQL
          {Absinthe.Subscription, [pubsub: Ace.PubSub]}
        ]
      end
    
    # Combine all children
    children = base_children ++ web_children ++ graphql_children
    
    # Start with one_for_one strategy
    opts = [strategy: :one_for_one, name: Ace.Supervisor]
    Supervisor.start_link(children, opts)
  end
  
  # Will be used when API is enabled
  # defp api_port, do: Application.get_env(:ace, :api_port, 4000)
end
