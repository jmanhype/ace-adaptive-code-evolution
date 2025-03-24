defmodule AceWeb.GitHubLive do
  @moduledoc """
  LiveView for GitHub integration features.
  Displays pull requests and their optimization suggestions.
  """
  use AceWeb, :live_view
  
  require Logger
  
  alias Ace.GitHub.Models.PullRequest
  alias Ace.GitHub.Models.PRFile
  alias Ace.GitHub.Models.OptimizationSuggestion
  alias Phoenix.PubSub
  
  @pubsub Ace.PubSub
  @topic "github:webhooks"
  
  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "GitHub Pull Requests")
     |> assign(:loading, false)
     |> assign(:pull_requests, [])
     |> assign(:selected_pr, nil)
     |> assign(:suggestions, [])
     |> assign(:active_tab, :github)}
  end
  
  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    case get_pull_request(id) do
      {:ok, pr} ->
        {:noreply,
         socket
         |> assign(:selected_pr, pr)
         |> assign(:live_action, :show)
         |> assign(:page_title, "PR ##{pr.number} - #{pr.title}")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:selected_pr, nil)
         |> assign(:live_action, :show)
         |> assign(:page_title, "Pull Request Not Found")}
    end
  end
  
  @impl true
  def handle_params(_params, _uri, socket) do
    # Load pull requests on initial page load
    pull_requests = list_pull_requests()

    {:noreply,
     socket
     |> assign(:pull_requests, pull_requests)
     |> assign(:live_action, :pull_requests)
     |> assign(:page_title, "GitHub Pull Requests")}
  end
  
  @impl true
  def handle_event("optimize_pr", %{"id" => id}, socket) do
    # Call the optimize endpoint to start optimization process
    case HTTPoison.post(
      "#{AceWeb.Endpoint.url()}/api/github/pull_requests/#{id}/optimize",
      Jason.encode!(%{}),
      [{"Content-Type", "application/json"}]
    ) do
      {:ok, %{status_code: status}} when status in 200..299 ->
        # Successfully started optimization
        socket = 
          if socket.assigns.live_action == :pull_requests do
            assign(socket, :pull_requests, list_pull_requests())
          else
            case get_pull_request(id) do
              {:ok, updated_pr} -> assign(socket, :selected_pr, updated_pr)
              {:error, _} -> socket
            end
          end

        {:noreply, put_flash(socket, :info, "Optimization started for pull request")}

      {:ok, _response} ->
        {:noreply, put_flash(socket, :error, "Failed to start optimization")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Network error when starting optimization")}
    end
  end
  
  @impl true
  def handle_event("refresh_prs", _params, socket) do
    {:noreply,
     socket
     |> assign(:loading, true)
     |> assign(:pull_requests, list_pull_requests())
     |> assign(:loading, false)}
  end
  
  @impl true
  def handle_event("view_suggestions", %{"id" => file_id}, socket) do
    # Fetch suggestions for the selected file
    suggestions = list_suggestions_by_file(file_id)

    {:noreply,
     socket
     |> assign(:suggestions, suggestions)}
  end
  
  @impl true
  def handle_info({:pr_received, pr}, socket) do
    # Add new PR to the list if not already there
    updated_prs = 
      if Enum.any?(socket.assigns.pull_requests, fn existing_pr -> existing_pr.id == pr.id end) do
        Enum.map(socket.assigns.pull_requests, fn existing_pr ->
          if existing_pr.id == pr.id, do: pr, else: existing_pr
        end)
      else
        [pr | socket.assigns.pull_requests]
      end
    
    {:noreply, assign(socket, pull_requests: updated_prs)}
  end
  
  @impl true
  def handle_info({:pr_optimized, pr_id}, socket) do
    # Update PR status in list
    updated_prs = Enum.map(socket.assigns.pull_requests, fn pr ->
      if pr.id == pr_id do
        %{pr | status: "optimized"}
      else
        pr
      end
    end)
    
    # If this is the selected PR, refresh it
    socket = 
      if socket.assigns.selected_pr && socket.assigns.selected_pr.id == pr_id do
        case Ace.Repo.get(PullRequest, pr_id) do
          nil -> socket
          updated_pr -> assign(socket, selected_pr: updated_pr)
        end
      else
        socket
      end
    
    {:noreply, assign(socket, pull_requests: updated_prs)}
  end
  
  @impl true
  def handle_info(_message, socket) do
    {:noreply, socket}
  end
  
  def list_pull_requests do
    Ace.GitHub.Models.PullRequest.list_all()
  end
  
  def get_pull_request(id) do
    case Ace.GitHub.Models.PullRequest.get_with_files_and_suggestions(id) do
      nil -> {:error, :not_found}
      pr -> {:ok, pr}
    end
  end
  
  defp update_pull_request_status(id, status) do
    Ace.GitHub.Models.PullRequest.update_status(id, status)
  end
  
  def list_suggestions_by_file(file_id) do
    Ace.GitHub.Models.OptimizationSuggestion.list_by_file(file_id)
  end
  
  # Helper functions for templates
  
  @doc """
  Returns a CSS class for styling status badges based on status value.
  
  ## Parameters
    - status: The status string
    
  ## Returns
    - String with CSS classes
  """
  def status_badge_class(status) do
    base_classes = "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
    
    status_specific_classes = case status do
      "pending" -> "bg-yellow-100 text-yellow-800"
      "processing" -> "bg-blue-100 text-blue-800"
      "approved" -> "bg-green-100 text-green-800"
      "applied" -> "bg-green-100 text-green-800"
      "error" -> "bg-red-100 text-red-800"
      "rejected" -> "bg-red-100 text-red-800"
      _ -> "bg-gray-100 text-gray-800"
    end
    
    "#{base_classes} #{status_specific_classes}"
  end
  
  @doc """
  Returns a CSS class for styling severity badges.
  
  ## Parameters
    - severity: The severity string
    
  ## Returns
    - String with CSS classes
  """
  def severity_badge_class(severity) do
    base_classes = "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
    
    severity_specific_classes = case severity do
      "high" -> "bg-red-100 text-red-800"
      "medium" -> "bg-yellow-100 text-yellow-800"
      "low" -> "bg-blue-100 text-blue-800"
      _ -> "bg-gray-100 text-gray-800"
    end
    
    "#{base_classes} #{severity_specific_classes}"
  end
  
  @doc """
  Formats a datetime for display.
  
  ## Parameters
    - datetime: The datetime to format
    
  ## Returns
    - String representation of the datetime
  """
  def format_datetime(nil), do: "N/A"
  def format_datetime(datetime) do
    # Format as a relative time if recent, otherwise as a date
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)
    
    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)} minutes ago"
      diff < 86400 -> "#{div(diff, 3600)} hours ago"
      diff < 604800 -> "#{div(diff, 86400)} days ago"
      true -> Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
    end
  end
  
  @doc """
  Returns an appropriate icon for a programming language.
  
  ## Parameters
    - language: The programming language
    
  ## Returns
    - HTML string with the icon
  """
  def language_icon(language) do
    icon = case language do
      "elixir" -> "hero-code-bracket-square"
      "javascript" -> "hero-code-bracket"
      "typescript" -> "hero-code-bracket"
      "ruby" -> "hero-code-bracket"
      "python" -> "hero-code-bracket"
      "go" -> "hero-code-bracket"
      "rust" -> "hero-code-bracket"
      _ -> "hero-document-text"
    end
    
    Phoenix.HTML.raw(~s(<span class="text-gray-500"><.icon name="#{icon}" class="w-5 h-5" /></span>))
  end
  
  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <%= if @live_action == :pull_requests do %>
        <h1 class="text-3xl font-semibold text-gray-800 mb-6">GitHub Pull Requests</h1>
        
        <div class="mb-6 flex justify-between items-center">
          <p class="text-gray-600">Manage and optimize GitHub pull requests</p>
          <button phx-click="refresh_prs" class="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded">
            <.icon name="hero-arrow-path" class="w-4 h-4 inline mr-1" />
            Refresh
          </button>
        </div>
        
        <%= if @loading do %>
          <div class="animate-pulse flex space-x-4 mb-4">
            <div class="flex-1 space-y-4 py-1">
              <div class="h-4 bg-gray-200 rounded w-3/4"></div>
              <div class="space-y-2">
                <div class="h-4 bg-gray-200 rounded"></div>
                <div class="h-4 bg-gray-200 rounded w-5/6"></div>
              </div>
            </div>
          </div>
        <% else %>
          <%= if Enum.empty?(@pull_requests) do %>
            <div class="bg-white shadow-md rounded-lg p-6 text-center">
              <div class="text-gray-500 mb-4">
                <.icon name="hero-document-text" class="w-12 h-12 mx-auto" />
              </div>
              <h3 class="text-lg font-medium text-gray-900">No pull requests yet</h3>
              <p class="mt-1 text-sm text-gray-500">Pull requests will appear here when received from GitHub webhooks.</p>
            </div>
          <% else %>
            <div class="bg-white shadow-md rounded-lg overflow-hidden">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">PR</th>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Repository</th>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <%= for pr <- @pull_requests do %>
                    <tr>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex items-center">
                          <div class="ml-4">
                            <div class="text-sm font-medium text-gray-900">
                              <a href={pr.html_url} target="_blank" class="hover:underline">
                                #<%= pr.number %> <%= pr.title %>
                              </a>
                            </div>
                            <div class="text-sm text-gray-500">
                              By <%= pr.user || "unknown" %>
                            </div>
                          </div>
                        </div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm text-gray-900"><%= pr.repo_name %></div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <span class={status_badge_class(pr.status)}>
                          <%= pr.status %>
                        </span>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div class="flex space-x-2">
                          <a href={~p"/github/pull_requests/#{pr.id}"} class="text-indigo-600 hover:text-indigo-900">
                            View
                          </a>
                          <%= if pr.status in ["pending", "error"] do %>
                            <button phx-click="optimize_pr" phx-value-id={pr.id} class="text-green-600 hover:text-green-900">
                              Optimize
                            </button>
                          <% end %>
                        </div>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        <% end %>
      <% else %>
        <%= if @selected_pr do %>
          <div class="mb-4">
            <a href={~p"/github/pull_requests"} class="text-blue-500 hover:underline flex items-center">
              <.icon name="hero-arrow-left" class="w-4 h-4 mr-1" />
              Back to all pull requests
            </a>
          </div>
          
          <div class="bg-white shadow-md rounded-lg p-6 mb-6">
            <div class="flex justify-between items-start">
              <div>
                <h1 class="text-2xl font-bold text-gray-900">
                  <a href={@selected_pr.html_url} target="_blank" class="hover:underline">
                    <%= @selected_pr.repo_name %> #<%= @selected_pr.number %>
                  </a>
                </h1>
                <h2 class="text-xl font-semibold text-gray-700 mt-1"><%= @selected_pr.title %></h2>
                <div class="mt-2 flex items-center">
                  <span class="text-gray-600 text-sm mr-4">By <%= @selected_pr.user || "unknown" %></span>
                  <span class={status_badge_class(@selected_pr.status)}>
                    <%= @selected_pr.status %>
                  </span>
                </div>
              </div>
              
              <%= if @selected_pr.status in ["pending", "error"] do %>
                <button phx-click="optimize_pr" phx-value-id={@selected_pr.id} class="bg-green-500 hover:bg-green-600 text-white px-4 py-2 rounded">
                  <.icon name="hero-sparkles" class="w-4 h-4 inline mr-1" />
                  Optimize
                </button>
              <% end %>
            </div>
          </div>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
            <div class="bg-white shadow-md rounded-lg p-6">
              <h3 class="text-lg font-medium text-gray-900 mb-4">Files (<%= length(@selected_pr.files) %>)</h3>
              
              <%= if Enum.empty?(@selected_pr.files) do %>
                <div class="text-gray-500 text-center py-4">
                  No files analyzed yet.
                </div>
              <% else %>
                <div class="space-y-3">
                  <%= for file <- @selected_pr.files do %>
                    <div class="border rounded-lg p-3 hover:bg-gray-50">
                      <button phx-click="view_suggestions" phx-value-id={file.id} class="w-full text-left">
                        <div class="flex items-center">
                          <div class="mr-2">
                            <%= language_icon(file.language) %>
                          </div>
                          <div class="flex-1">
                            <div class="text-sm font-medium text-gray-900 truncate">
                              <%= file.filename %>
                            </div>
                            <div class="text-xs text-gray-500">
                              +<%= file.additions || 0 %> -<%= file.deletions || 0 %> (<%= file.language || "unknown" %>)
                            </div>
                          </div>
                        </div>
                      </button>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
            
            <div class="bg-white shadow-md rounded-lg p-6">
              <h3 class="text-lg font-medium text-gray-900 mb-4">Optimization Suggestions</h3>
              
              <%= if Enum.empty?(@suggestions) do %>
                <div class="text-gray-500 text-center py-4">
                  Select a file to view suggestions.
                </div>
              <% else %>
                <div class="space-y-4">
                  <%= for suggestion <- @suggestions do %>
                    <div class="border rounded-lg p-4">
                      <div class="flex justify-between">
                        <span class={severity_badge_class(suggestion.severity)}>
                          <%= suggestion.severity %>
                        </span>
                        <span class={status_badge_class(suggestion.status)}>
                          <%= suggestion.status %>
                        </span>
                      </div>
                      <h4 class="text-md font-medium text-gray-900 mt-2"><%= suggestion.opportunity_type %></h4>
                      <p class="text-sm text-gray-600 mt-1"><%= suggestion.description %></p>
                      
                      <div class="mt-3">
                        <div class="text-xs font-medium text-gray-500 mb-1">Original Code:</div>
                        <pre class="bg-gray-50 p-2 rounded text-xs overflow-auto max-h-32"><code><%= suggestion.original_code %></code></pre>
                      </div>
                      
                      <div class="mt-3">
                        <div class="text-xs font-medium text-gray-500 mb-1">Optimized Code:</div>
                        <pre class="bg-gray-50 p-2 rounded text-xs overflow-auto max-h-32"><code><%= suggestion.optimized_code %></code></pre>
                      </div>
                      
                      <%= if suggestion.explanation do %>
                        <div class="mt-3">
                          <div class="text-xs font-medium text-gray-500 mb-1">Explanation:</div>
                          <p class="text-xs text-gray-600"><%= suggestion.explanation %></p>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        <% else %>
          <div class="bg-white shadow-md rounded-lg p-6 text-center">
            <div class="text-gray-500 mb-4">
              <.icon name="hero-exclamation-circle" class="w-12 h-12 mx-auto" />
            </div>
            <h3 class="text-lg font-medium text-gray-900">Pull request not found</h3>
            <p class="mt-1 text-sm text-gray-500">The requested pull request could not be found.</p>
            <div class="mt-4">
              <a href={~p"/github/pull_requests"} class="text-blue-500 hover:underline">
                Back to all pull requests
              </a>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  # Add a function for creating an optimization PR
  @spec create_optimization_pr(Phoenix.LiveView.Socket.t(), map()) :: {:noreply, Phoenix.LiveView.Socket.t()}
  def create_optimization_pr(socket, %{"id" => id}) do
    # Call the API to create an optimization PR
    case HTTPoison.post(
      "#{AceWeb.Endpoint.url()}/api/github/pull_requests/#{id}/create_optimization_pr",
      "",
      [{"Content-Type", "application/json"}]
    ) do
      {:ok, %{status_code: 201, body: body}} ->
        response = Jason.decode!(body)
        
        # Show success message
        socket = 
          socket
          |> put_flash(:info, "Optimization PR created successfully. PR ##{response["pr_number"]}")
          |> assign(:pr_creation_url, response["pr_url"])
        
        {:noreply, socket}
        
      {:ok, %{status_code: status_code, body: body}} ->
        # Handle error
        error = Jason.decode!(body)
        
        socket = put_flash(socket, :error, "Failed to create optimization PR: #{error["details"] || error["error"]}")
        {:noreply, socket}
        
      {:error, %HTTPoison.Error{reason: reason}} ->
        # Handle connection error
        socket = put_flash(socket, :error, "Error connecting to API: #{inspect(reason)}")
        {:noreply, socket}
    end
  end

  # Add handler for the optimize button
  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) :: {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("create_optimization_pr", %{"id" => id}, socket) do
    create_optimization_pr(socket, %{"id" => id})
  end
end 