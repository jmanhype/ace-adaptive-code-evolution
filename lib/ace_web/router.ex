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

  # GitHub webhook pipeline - doesn't need CSRF protection
  pipeline :webhook do
    plug :accepts, ["json"]
    plug :put_secure_browser_headers
    plug AceWeb.RawBodyPlug
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

    live "/", DashboardLive, :index
    live "/projects", DashboardLive, :projects
    live "/files", DashboardLive, :files
    live "/opportunities", DashboardLive, :opportunities
    live "/optimizations", DashboardLive, :optimizations
    live "/evaluations", DashboardLive, :evaluations
    live "/evolution", DashboardLive, :evolution
    live "/evolution/proposals", DashboardLive, :evolution_proposals
    get "/evolution/generate", EvolutionController, :generate_proposal
    
    # GitHub PR visualization
    live "/github/pull_requests", GitHubLive, :pull_requests
    live "/github/pull_requests/:id", GitHubLive, :show_pull_request
  end

  # REST API endpoints
  scope "/api", AceWeb do
    pipe_through :api
    
    resources "/pull_requests", PRController, only: [:index, :show, :create]
    post "/analyses/:id/optimize", AnalysisController, :optimize
    
    # GitHub API endpoints
    get "/github/pull_requests", GitHubAPIController, :index
    post "/github/pull_requests", GitHubAPIController, :create
    get "/github/pull_requests/:id", GitHubAPIController, :show
    post "/github/pull_requests/:id/optimize", GitHubAPIController, :optimize
    post "/github/pull_requests/:id/create_optimization_pr", GitHubAPIController, :create_optimization_pr
    post "/github/webhook", WebhookController, :github
    get "/github/pull_requests/:pr_id/suggestions", GitHubAPIController, :get_optimization_suggestions
    get "/github/pull_requests/:pr_id/ui", GitHubAPIController, :render_optimization_ui
    post "/github/pull_requests/:pr_id/suggestions/:suggestion_id/comment", GitHubAPIController, :post_suggestion_comment
    get "/github/branches/:repo_name", GitHubAPIController, :list_branches
    post "/github/branches", GitHubAPIController, :create_branch
    get "/github/repos/:repo_name/pull_requests", GitHubAPIController, :list_repo_pull_requests
    # Optimization routes
    post "/github/optimize", GitHubAPIController, :optimize_pull_request
  end

  # GitHub webhook endpoint
  scope "/webhooks", AceWeb do
    pipe_through :webhook
    
    # Use our new WebhookController
    post "/github", WebhookController, :github
  end

  # GraphQL endpoint
  scope "/api" do
    pipe_through :graphql

    forward "/graphql", Absinthe.Plug, schema: Ace.GraphQL.Schema
    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: Ace.GraphQL.Schema,
      interface: :playground
  end

  # UI Routes
  scope "/", AceWeb do
    pipe_through :browser
    
    get "/", PageController, :index
    
    # Optimization UI
    get "/optimize/:pr_id", GitHubAPIController, :render_optimization_ui
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