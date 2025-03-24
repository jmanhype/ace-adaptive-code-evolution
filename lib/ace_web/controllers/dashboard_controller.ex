defmodule AceWeb.DashboardController do
  use AceWeb, :controller
  
  def index(conn, _params) do
    # Render the overview template directly
    render(conn, :overview)
  end
  
  def files(conn, _params) do
    # Render the files template directly
    render(conn, :files)
  end
  
  def opportunities(conn, _params) do
    # Render the opportunities template directly
    render(conn, :opportunities)
  end
  
  def optimizations(conn, _params) do
    # Render the optimizations template directly
    render(conn, :optimizations)
  end
  
  def evaluations(conn, _params) do
    # Render the evaluations template directly
    render(conn, :evaluations)
  end
  
  def projects(conn, _params) do
    # Render the projects template directly
    render(conn, :projects)
  end
  
  def evolution(conn, _params) do
    # Render the evolution template directly
    render(conn, :evolution)
  end
  
  def evolution_proposals(conn, _params) do
    # Render the evolution proposals template directly
    render(conn, :evolution_proposals)
  end
end