defmodule AceWeb.PageController do
  use AceWeb, :controller

  def index(conn, _params) do
    # Redirect to the dashboard as that seems to be the main page
    redirect(conn, to: "/dashboard")
  end
end 