defmodule AceWeb.TestController do
  use AceWeb, :controller
  
  def index(conn, _params) do
    html = """
    <!DOCTYPE html>
    <html>
    <head>
      <title>Navigation Test</title>
    </head>
    <body>
      <h1>Test Page</h1>
      <h2>LiveView Navigation (standard routes)</h2>
      <ul>
        <li><a href="/">Overview</a></li>
        <li><a href="/files">Files</a></li>
        <li><a href="/opportunities">Opportunities</a></li>
        <li><a href="/optimizations">Optimizations</a></li>
        <li><a href="/evaluations">Evaluations</a></li>
        <li><a href="/projects">Projects</a></li>
        <li><a href="/evolution">Evolution</a></li>
        <li><a href="/evolution/proposals">Evolution Proposals</a></li>
      </ul>
      
      <h2>Direct Navigation (non-LiveView)</h2>
      <ul>
        <li><a href="/direct/overview">Overview</a></li>
        <li><a href="/direct/files">Files</a></li>
        <li><a href="/direct/opportunities">Opportunities</a></li>
        <li><a href="/direct/optimizations">Optimizations</a></li>
        <li><a href="/direct/evaluations">Evaluations</a></li>
        <li><a href="/direct/projects">Projects</a></li>
        <li><a href="/direct/evolution">Evolution</a></li>
        <li><a href="/direct/evolution/proposals">Evolution Proposals</a></li>
      </ul>
    </body>
    </html>
    """
    
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end
  
  # Define handlers for all direct pages
  def overview(conn, _params), do: render_page(conn, "Overview")
  def files(conn, _params), do: render_page(conn, "Files") 
  def opportunities(conn, _params), do: render_page(conn, "Opportunities")
  def optimizations(conn, _params), do: render_page(conn, "Optimizations")
  def evaluations(conn, _params), do: render_page(conn, "Evaluations")
  def projects(conn, _params), do: render_page(conn, "Projects")
  def evolution(conn, _params), do: render_page(conn, "Evolution")
  def evolution_proposals(conn, _params), do: render_page(conn, "Evolution Proposals")
  
  # Helper to render a simple page with navigation
  defp render_page(conn, title) do
    html = """
    <!DOCTYPE html>
    <html>
    <head>
      <title>#{title}</title>
      <style>
        nav { background: #333; padding: 1rem; }
        nav a { color: white; margin-right: 1rem; text-decoration: none; }
        nav a:hover { text-decoration: underline; }
        main { padding: 2rem; }
      </style>
    </head>
    <body>
      <nav>
        <a href="/direct/overview">Overview</a>
        <a href="/direct/files">Files</a>
        <a href="/direct/opportunities">Opportunities</a>
        <a href="/direct/optimizations">Optimizations</a>
        <a href="/direct/evaluations">Evaluations</a>
        <a href="/direct/projects">Projects</a>
        <a href="/direct/evolution">Evolution</a>
        <a href="/direct/evolution/proposals">Evolution Proposals</a>
      </nav>
      <main>
        <h1>#{title}</h1>
        <p>This is a static page for #{title}.</p>
        <p><a href="/test">Back to test page</a></p>
      </main>
    </body>
    </html>
    """
    
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end
end