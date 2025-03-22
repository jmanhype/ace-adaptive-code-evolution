defmodule AceWeb.StaticPagesController do
  use AceWeb, :controller
  
  def index(conn, _params) do
    html = """
    <!DOCTYPE html>
    <html>
    <head>
      <title>ACE Dashboard</title>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
      <script src="https://cdn.jsdelivr.net/npm/chart.js@3.7.0/dist/chart.min.js"></script>
      <style>
        .card { @apply bg-white overflow-hidden shadow rounded-lg p-4; }
        .btn { @apply px-4 py-2 bg-blue-600 text-white rounded-md; }
        .btn:hover { @apply bg-blue-700; }
        .nav-link { @apply text-gray-300 hover:bg-gray-700 hover:text-white rounded-md px-3 py-2 text-sm font-medium; }
        .nav-link-active { @apply bg-gray-900 text-white rounded-md px-3 py-2 text-sm font-medium; }
      </style>
    </head>
    <body class="min-h-full bg-gray-100">
      <nav class="bg-gray-800">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div class="flex h-16 items-center justify-between">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <span class="text-white text-xl font-bold">ACE</span>
              </div>
              <div class="hidden md:block">
                <div class="ml-10 flex items-baseline space-x-4">
                  <a href="/pages/overview" class="nav-link-active">Overview</a>
                  <a href="/pages/evolution-proposals" class="nav-link">Proposals</a>
                  <a href="/pages/files" class="nav-link">Files</a>
                  <a href="/pages/opportunities" class="nav-link">Opportunities</a>
                  <a href="/pages/optimizations" class="nav-link">Optimizations</a>
                  <a href="/pages/evaluations" class="nav-link">Evaluations</a>
                  <a href="/pages/projects" class="nav-link">Projects</a>
                  <a href="/pages/evolution" class="nav-link">Evolution</a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </nav>
      
      <main>
        <div class="mx-auto max-w-7xl py-6 sm:px-6 lg:px-8">
          <header class="flex items-center justify-between pb-4 border-b border-gray-200">
            <div>
              <h1 class="text-2xl font-semibold text-gray-900">ACE Dashboard</h1>
              <p class="mt-1 text-sm text-gray-500">AI-powered code optimization and analysis</p>
            </div>
            <div class="flex items-center gap-2">
              <button class="btn">Start Analysis</button>
            </div>
          </header>
          
          <div class="mt-6 grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
            <div class="card">
              <div class="flex items-center">
                <div class="flex-shrink-0 rounded-md bg-blue-500 p-3">
                  <svg class="h-6 w-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="truncate text-sm font-medium text-gray-500">Analyses</dt>
                    <dd>
                      <div class="text-lg font-medium text-gray-900">0</div>
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
            
            <div class="card">
              <div class="flex items-center">
                <div class="flex-shrink-0 rounded-md bg-green-500 p-3">
                  <svg class="h-6 w-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="truncate text-sm font-medium text-gray-500">Opportunities</dt>
                    <dd>
                      <div class="text-lg font-medium text-gray-900">0</div>
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
            
            <div class="card">
              <div class="flex items-center">
                <div class="flex-shrink-0 rounded-md bg-purple-500 p-3">
                  <svg class="h-6 w-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path>
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="truncate text-sm font-medium text-gray-500">Optimizations</dt>
                    <dd>
                      <div class="text-lg font-medium text-gray-900">0</div>
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
          
          <div class="mt-8">
            <h2 class="text-lg font-medium text-gray-900">Recent Activities</h2>
            <div class="mt-3 bg-white shadow overflow-hidden sm:rounded-lg">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Target</th>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Time</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <tr>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">Analysis</td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">user_controller.ex</td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-green-600 font-medium">Complete</td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">2 hours ago</td>
                  </tr>
                  <tr>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">Optimization</td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">Sort algorithm</td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-green-600 font-medium">Complete</td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">3 hours ago</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </main>
    </body>
    </html>
    """
    
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end
  
  def page(conn, %{"page" => page}) do
    # Determine which navigation link should be active
    active_page = page
    
    # Set the page title and header based on the page
    page_title = case active_page do
      "overview" -> "Overview"
      "files" -> "Files"
      "opportunities" -> "Opportunities"
      "optimizations" -> "Optimizations"
      "evaluations" -> "Evaluations"
      "projects" -> "Projects"
      "evolution" -> "Evolution"
      "evolution-proposals" -> "Evolution Proposals"
      _ -> String.capitalize(active_page)
    end
    
    # Create the html with the appropriate active nav link
    html = """
    <!DOCTYPE html>
    <html>
    <head>
      <title>ACE - #{page_title}</title>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
      <script src="https://cdn.jsdelivr.net/npm/chart.js@3.7.0/dist/chart.min.js"></script>
      <style>
        .card { @apply bg-white overflow-hidden shadow rounded-lg p-4; }
        .btn { @apply px-4 py-2 bg-blue-600 text-white rounded-md; }
        .btn:hover { @apply bg-blue-700; }
        .nav-link { @apply text-gray-300 hover:bg-gray-700 hover:text-white rounded-md px-3 py-2 text-sm font-medium; }
        .nav-link-active { @apply bg-gray-900 text-white rounded-md px-3 py-2 text-sm font-medium; }
      </style>
    </head>
    <body class="min-h-full bg-gray-100">
      <nav class="bg-gray-800">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div class="flex h-16 items-center justify-between">
            <div class="flex items-center">
              <div class="flex-shrink-0">
                <span class="text-white text-xl font-bold">ACE</span>
              </div>
              <div class="hidden md:block">
                <div class="ml-10 flex items-baseline space-x-4">
                  <a href="/pages/overview" class="#{if active_page == "overview", do: "nav-link-active", else: "nav-link"}">Overview</a>
                  <a href="/pages/files" class="#{if active_page == "files", do: "nav-link-active", else: "nav-link"}">Files</a>
                  <a href="/pages/opportunities" class="#{if active_page == "opportunities", do: "nav-link-active", else: "nav-link"}">Opportunities</a>
                  <a href="/pages/optimizations" class="#{if active_page == "optimizations", do: "nav-link-active", else: "nav-link"}">Optimizations</a>
                  <a href="/pages/evaluations" class="#{if active_page == "evaluations", do: "nav-link-active", else: "nav-link"}">Evaluations</a>
                  <a href="/pages/projects" class="#{if active_page == "projects", do: "nav-link-active", else: "nav-link"}">Projects</a>
                  <a href="/pages/evolution" class="#{if active_page == "evolution", do: "nav-link-active", else: "nav-link"}">Evolution</a>
                  <a href="/pages/evolution-proposals" class="#{if active_page == "evolution-proposals", do: "nav-link-active", else: "nav-link"}">Proposals</a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </nav>
      
      <main>
        <div class="mx-auto max-w-7xl py-6 sm:px-6 lg:px-8">
          <header class="flex items-center justify-between pb-4 border-b border-gray-200">
            <div>
              <h1 class="text-2xl font-semibold text-gray-900">#{page_title}</h1>
              <p class="mt-1 text-sm text-gray-500">#{get_subtitle_for_page(active_page)}</p>
            </div>
            <div class="flex items-center gap-2">
              #{get_actions_for_page(active_page)}
            </div>
          </header>
          
          #{get_content_for_page(active_page)}
        </div>
      </main>
    </body>
    </html>
    """
    
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end
  
  # Helper functions to provide content for different pages
  
  # Get subtitle for each page
  defp get_subtitle_for_page(page) do
    case page do
      "overview" -> "AI-powered code optimization and analysis"
      "files" -> "Analyze and optimize your codebase"
      "opportunities" -> "Discover potential improvements"
      "optimizations" -> "Apply AI-generated code optimizations"
      "evaluations" -> "Measure performance improvements"
      "projects" -> "Manage your projects"
      "evolution" -> "User feedback analysis and code evolution"
      "evolution-proposals" -> "Review and manage code change proposals"
      _ -> "ACE static page"
    end
  end
  
  # Get action buttons for each page
  defp get_actions_for_page(page) do
    case page do
      "overview" -> ~s(<button class="btn">Start Analysis</button>)
      "files" -> ~s(<button class="btn">Upload Files</button>)
      "opportunities" -> ~s(<button class="btn">Refresh</button>)
      "optimizations" -> ~s(<button class="btn">Generate Optimization</button>)
      "evaluations" -> ~s(<button class="btn">Run Evaluation</button>)
      "projects" -> ~s(<button class="btn">New Project</button>)
      "evolution" -> ~s(<button class="btn">Refresh Data</button>)
      "evolution-proposals" -> ~s(<a href="/pages/evolution" class="mr-2 text-sm text-blue-600 hover:text-blue-800">← Back to Evolution Dashboard</a><button class="btn">Refresh Proposals</button>)
      _ -> ""
    end
  end
  
  # Get main content for each page
  defp get_content_for_page(page) do
    case page do
      "overview" -> get_overview_content()
      "evolution" -> get_evolution_content()
      "evolution-proposals" -> get_evolution_proposals_content()
      _ -> get_generic_content(page)
    end
  end
  
  # Content for the overview page
  defp get_overview_content do
    """
    <div class="mt-6 grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
      <div class="card">
        <div class="flex items-center">
          <div class="flex-shrink-0 rounded-md bg-blue-500 p-3">
            <svg class="h-6 w-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
            </svg>
          </div>
          <div class="ml-5 w-0 flex-1">
            <dl>
              <dt class="truncate text-sm font-medium text-gray-500">Analyses</dt>
              <dd>
                <div class="text-lg font-medium text-gray-900">0</div>
              </dd>
            </dl>
          </div>
        </div>
      </div>
      
      <div class="card">
        <div class="flex items-center">
          <div class="flex-shrink-0 rounded-md bg-green-500 p-3">
            <svg class="h-6 w-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
            </svg>
          </div>
          <div class="ml-5 w-0 flex-1">
            <dl>
              <dt class="truncate text-sm font-medium text-gray-500">Opportunities</dt>
              <dd>
                <div class="text-lg font-medium text-gray-900">0</div>
              </dd>
            </dl>
          </div>
        </div>
      </div>
      
      <div class="card">
        <div class="flex items-center">
          <div class="flex-shrink-0 rounded-md bg-purple-500 p-3">
            <svg class="h-6 w-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path>
            </svg>
          </div>
          <div class="ml-5 w-0 flex-1">
            <dl>
              <dt class="truncate text-sm font-medium text-gray-500">Optimizations</dt>
              <dd>
                <div class="text-lg font-medium text-gray-900">0</div>
              </dd>
            </dl>
          </div>
        </div>
      </div>
    </div>
    
    <div class="mt-8">
      <h2 class="text-lg font-medium text-gray-900">Recent Activities</h2>
      <div class="mt-3 bg-white shadow overflow-hidden sm:rounded-lg">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Target</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Time</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr>
              <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">Analysis</td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">user_controller.ex</td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-green-600 font-medium">Complete</td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">2 hours ago</td>
            </tr>
            <tr>
              <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">Optimization</td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">Sort algorithm</td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-green-600 font-medium">Complete</td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">3 hours ago</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
  
  # Content for the evolution page
  defp get_evolution_content do
    """
    <div class="mt-6 grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
      <div class="card">
        <div class="flex items-center">
          <div class="flex-shrink-0 rounded-md bg-blue-500 p-3">
            <svg class="h-6 w-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
            </svg>
          </div>
          <div class="ml-5 w-0 flex-1">
            <dl>
              <dt class="truncate text-sm font-medium text-gray-500">Feedback Collected</dt>
              <dd>
                <div class="text-lg font-medium text-gray-900">13</div>
              </dd>
            </dl>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="flex items-center">
          <div class="flex-shrink-0 rounded-md bg-green-500 p-3">
            <svg class="h-6 w-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5"></path>
            </svg>
          </div>
          <div class="ml-5 w-0 flex-1">
            <dl>
              <dt class="truncate text-sm font-medium text-gray-500">NPS Score</dt>
              <dd>
                <div class="text-lg font-medium text-gray-900">-30.8</div>
              </dd>
            </dl>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="flex items-center">
          <div class="flex-shrink-0 rounded-md bg-purple-500 p-3">
            <svg class="h-6 w-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path>
            </svg>
          </div>
          <div class="ml-5 w-0 flex-1">
            <dl>
              <dt class="truncate text-sm font-medium text-gray-500">Pending Proposals</dt>
              <dd>
                <div class="text-lg font-medium text-gray-900">1</div>
              </dd>
            </dl>
          </div>
        </div>
      </div>
    </div>

    <div class="mt-8">
      <div class="flex justify-between items-center">
        <h2 class="text-lg font-medium text-gray-900">Recent Feedback</h2>
        <a href="/pages/evolution-proposals" class="text-blue-600 hover:text-blue-800">
          View Pending Proposals →
        </a>
      </div>
      
      <div class="mt-3 bg-white shadow overflow-hidden sm:rounded-md">
        <ul role="list" class="divide-y divide-gray-200">
          <li>
            <div class="px-4 py-4 sm:px-6">
              <div class="flex items-center justify-between">
                <div class="flex items-center">
                  <div class="h-8 w-8 rounded-full bg-red-100 flex items-center justify-center mr-3">
                    <span class="text-red-600 font-bold">2</span>
                  </div>
                  <p class="text-sm font-medium text-gray-900 truncate">
                    Performance is not acceptable
                  </p>
                </div>
                <div class="ml-2 flex-shrink-0 flex">
                  <p class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800">
                    demo_feature
                  </p>
                </div>
              </div>
              <div class="mt-2 sm:flex sm:justify-between">
                <div class="sm:flex">
                  <p class="flex items-center text-sm text-gray-500">
                    <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
                    </svg>
                    user_61
                  </p>
                </div>
                <div class="mt-2 flex items-center text-sm text-gray-500 sm:mt-0">
                  <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                  </svg>
                  <p>
                    March 14, 2025
                  </p>
                </div>
              </div>
            </div>
          </li>
        </ul>
      </div>
    </div>
    """
  end
  
  # Content for the evolution proposals page
  defp get_evolution_proposals_content do
    """
    <div class="mt-8">
      <h2 class="text-lg font-medium text-gray-900">Pending Proposals</h2>
      
      <div class="mt-3 overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg">
        <table class="min-w-full divide-y divide-gray-300">
          <thead class="bg-gray-50">
            <tr>
              <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6">Module</th>
              <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Created</th>
              <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Status</th>
              <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 bg-white">
            <tr>
              <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-6">
                Demo
              </td>
              <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                Mar 14, 2025 15:03
              </td>
              <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                <span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-yellow-100 text-yellow-800">
                  Pending Review
                </span>
              </td>
              <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                <div class="flex space-x-2">
                  <button class="text-indigo-600 hover:text-indigo-900">
                    View
                  </button>
                  <button class="text-green-600 hover:text-green-900">
                    Approve
                  </button>
                  <button class="text-red-600 hover:text-red-900">
                    Reject
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
  
  # Generic content for other pages
  defp get_generic_content(page) do
    """
    <div class="mt-8">
      <div class="bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900">
            #{String.capitalize(page)} Content
          </h3>
          <div class="mt-2 max-w-xl text-sm text-gray-500">
            <p>
              This is a static placeholder for the #{page} page. In the real application, 
              this would show #{page}-specific content and functionality.
            </p>
          </div>
          <div class="mt-5">
            <button type="button" class="btn">
              Example Action
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end
end