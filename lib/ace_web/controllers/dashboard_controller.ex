defmodule AceWeb.DashboardController do
  use AceWeb, :controller
  
  # Redirect to static pages since LiveView is having issues
  def index(conn, _params) do
    redirect(conn, to: "/pages/overview")
  end
  
  def files(conn, _params) do
    redirect(conn, to: "/pages/files")
  end
  
  def opportunities(conn, _params) do
    redirect(conn, to: "/pages/opportunities")
  end
  
  def optimizations(conn, _params) do
    redirect(conn, to: "/pages/optimizations")
  end
  
  def evaluations(conn, _params) do
    redirect(conn, to: "/pages/evaluations")
  end
  
  def projects(conn, _params) do
    redirect(conn, to: "/pages/projects")
  end
  
  def evolution(conn, _params) do
    redirect(conn, to: "/pages/evolution")
  end
  
  def evolution_proposals(conn, _params) do
    redirect(conn, to: "/pages/evolution-proposals")
  end
end