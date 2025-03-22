defmodule AceWeb.Router do
  use AceWeb, :router
  
  # Add logging for debugging
  require Logger
  
  pipeline :browser do
    plug :log_requests
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AceWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end
  
  # Custom plug to log requests
  def log_requests(conn, _opts) do
    Logger.info("Router processing: #{conn.method} #{conn.request_path}, params: #{inspect(conn.params)}")
    conn
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # GraphQL API
  pipeline :graphql do
    plug :accepts, ["json"]
  end

  # Static pages on subdomain
  scope "/", AceWeb, host: "static.localhost" do
    pipe_through :browser
    
    get "/", StaticPagesController, :index
    get "/:page", StaticPagesController, :page
  end

  # Main application using LiveView
  scope "/", AceWeb do
    pipe_through :browser

    get "/", PageController, :index
    
    live "/dashboard", DashboardLive, :index
    live "/dashboard/evolution", DashboardLive, :evolution
    live "/dashboard/evolution/proposals", DashboardLive, :evolution_proposals
    
    get "/evolution", EvolutionController, :index
    get "/evolution/proposals", EvolutionController, :proposals
    get "/evolution/history", EvolutionController, :history
    get "/evolution/generate", EvolutionController, :generate_proposal
  end

  # REST API endpoints
  scope "/api", AceWeb do
    pipe_through :api
    
    post "/analyses", AnalysesController, :create
    get "/analyses/:id", AnalysesController, :show
    get "/analyses", AnalysesController, :index
    
    # GitHub webhook endpoint
    post "/webhooks/github", WebhookController, :github
  end

  # GraphQL endpoint
  scope "/api" do
    pipe_through :graphql

    forward "/graphql", Absinthe.Plug, schema: Ace.GraphQL.Schema
    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: Ace.GraphQL.Schema,
      interface: :playground
  end

  # Enable LiveDashboard in development
  if Mix.env() == :dev do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: AceWeb.Telemetry
    end
  end
end 