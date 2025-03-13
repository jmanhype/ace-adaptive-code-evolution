defmodule AceWeb.Router do
  use AceWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AceWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # GraphQL API
  pipeline :graphql do
    plug :accepts, ["json"]
  end

  scope "/", AceWeb do
    pipe_through :browser

    live "/", DashboardLive, :index
    live "/projects", DashboardLive, :projects
    live "/files", DashboardLive, :files
    live "/opportunities", DashboardLive, :opportunities
    live "/optimizations", DashboardLive, :optimizations
    live "/evaluations", DashboardLive, :evaluations
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