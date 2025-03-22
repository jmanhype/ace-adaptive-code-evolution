defmodule AceWeb.DashboardLive do
  @moduledoc """
  LiveView dashboard for the ACE system.
  
  Provides a real-time interface for monitoring and interacting with
  the Adaptive Code Evolution system. Features include:
  
  - Overview of system metrics and recent activities
  - File analysis interface
  - Opportunity management and optimization
  - Evaluation results visualization
  - File relationship visualization
  - Real-time updates through PubSub
  """
  use AceWeb, :live_view
  
  alias Ace.Core.AnalysisRelationship
  import Ecto.Query, only: [from: 2, order_by: 2, limit: 2]
  
  @topic "ace:dashboard"
  @page_size 10
  
  # Rely on automatic template rendering
  
  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to PubSub topics for real-time updates
      Phoenix.PubSub.subscribe(Ace.PubSub, "ace:analyses")
      Phoenix.PubSub.subscribe(Ace.PubSub, "ace:opportunities")
      Phoenix.PubSub.subscribe(Ace.PubSub, "ace:optimizations")
      Phoenix.PubSub.subscribe(Ace.PubSub, "ace:evaluation_results")
      Phoenix.PubSub.subscribe(Ace.PubSub, "evolution:proposals")
      Phoenix.PubSub.subscribe(Ace.PubSub, "evolution:updates")
      # Subscribe to proposals for real-time updates
      Phoenix.PubSub.subscribe(Ace.PubSub, "proposals")
      Process.send_after(self(), :refresh_evolutions, 1000)
    end

    # Load real data from the database using direct Repo queries
    analyses = Ace.Repo.all(from a in Ace.Core.Analysis, order_by: [desc: a.inserted_at], limit: 20)
    {:ok, opportunities} = Ace.Analysis.Service.list_opportunities(%{})
    optimizations = Ace.Repo.all(from o in Ace.Core.Optimization, order_by: [desc: o.inserted_at], limit: 20)

    # Initialize socket with default values
    socket = 
      socket
      |> assign(:page_title, "ACE Dashboard")
      |> assign(:active_tab, get_active_tab(socket.assigns.live_action))
      |> assign(:analyses, analyses)
      |> assign(:opportunities, opportunities)
      |> assign(:optimizations, optimizations)
      |> assign(:evaluations, [])
      |> assign(:analyzing, false)
      |> assign(:recent_activities, load_recent_activities())
      |> assign(:projects, load_projects())
      |> assign(:metrics, load_system_metrics())
      |> assign(:file_path, "")
      |> assign(:language, "elixir")
      |> assign(:focus_areas, ["performance", "maintainability"])
      |> assign(:severity_threshold, "medium")
      |> assign(:content, "")
      |> assign(:selected_opportunity_id, nil)
      |> assign(:selected_optimization_id, nil)
      |> assign(:selected_project_id, nil)
      |> assign(:chart_data, generate_chart_data())
      |> assign(:upload_errors, [])
      |> assign(:loading, false)
      |> assign(:multi_file_mode, false)
      |> assign(:file_list, [])
      # Optimization strategy options
      |> assign(:strategy, "auto")
      |> assign(:use_ast, true)
      |> assign(:modern_js, true)
      |> assign(:use_type_hints, false)
      # Relationship visualization options
      |> assign(:relationship_type_filters, nil) # nil means all types
      |> assign(:api_status, %{has_api_key: true, provider: "mock", providers: []})
      
    # Load section-specific data based on the live action
    socket = case socket.assigns.live_action do
      :evolution_proposals -> 
        # Explicitly load the proposals for the proposals page
        pending_proposals = Ace.Core.EvolutionProposal.list_pending()
        socket
        |> assign(:pending_proposals, pending_proposals)
        |> assign(:proposal_count, length(pending_proposals))
        
      :evolution ->
        # Load evolution data for the evolution page
        assign_evolution_data(socket)
        
      _ -> 
        socket
    end

    {:ok, socket}
  end
  
  # Check the availability of AI API providers
  defp check_api_availability do
    api_keys = %{
      "groq" => System.get_env("GROQ_API_KEY"),
      "openai" => System.get_env("OPENAI_API_KEY"),
      "anthropic" => System.get_env("ANTHROPIC_API_KEY")
    }
    
    has_api_key = Enum.any?(api_keys, fn {_provider, key} -> 
      not is_nil(key) and key != ""
    end)
    
    active_provider = cond do
      not is_nil(api_keys["groq"]) and api_keys["groq"] != "" -> "groq"
      not is_nil(api_keys["openai"]) and api_keys["openai"] != "" -> "openai"
      not is_nil(api_keys["anthropic"]) and api_keys["anthropic"] != "" -> "anthropic"
      true -> "mock"
    end
    
    %{
      has_api_key: has_api_key,
      provider: active_provider,
      providers: Map.keys(api_keys) |> Enum.filter(fn provider -> 
        not is_nil(api_keys[provider]) and api_keys[provider] != ""
      end)
    }
  end
  
  @impl true
  def handle_params(params, uri, socket) do
    # Set the active tab based on live_action
    active_tab = case socket.assigns.live_action do
      :evolution -> :evolution
      :evolution_proposals -> :evolution_proposals
      :index -> :overview
      _ -> :overview
    end
    
    socket = assign(socket, :active_tab, active_tab)
    
    # Handle specific page param loading
    socket = case active_tab do
      :evolution_proposals ->
        status_filter = params["status"] || "all"
        socket
        |> assign(:status_filter, status_filter)
        |> assign_filtered_proposals(status_filter, params)
      
      _ ->
        socket
    end
    
    {:noreply, socket}
  end

  # Helper function to load opportunities
  defp load_opportunities_data(socket) do
    IO.puts("Loading opportunities data")
    case Ace.Analysis.Service.list_opportunities(%{}) do
      {:ok, opportunities} ->
        IO.puts("Loaded #{length(opportunities)} opportunities")
        
        socket
        |> assign(:opportunities, opportunities)
      
      {:error, reason} ->
        IO.puts("Error loading opportunities: #{inspect(reason)}")
        
        socket
        |> assign(:opportunities, [])
    end
  end

  # Helper functions for handle_params
  defp start_analysis(socket) do
    # Directly use Analysis Service instead of HTTP request which may fail
    demo_file_path = "demo_code/test_module.ex"
    
    # Create the file if it doesn't exist for demo purposes
    ensure_demo_file_exists(demo_file_path)
    
    case Ace.Analysis.Service.analyze_file(demo_file_path, [
      language: "elixir",
      focus_areas: ["performance", "maintainability"],
      severity_threshold: "medium"
    ]) do
      {:ok, analysis} ->
        # Broadcast to PubSub
        Phoenix.PubSub.broadcast(Ace.PubSub, "ace:analyses", {:analysis_created, analysis})
        
        socket
        |> assign(:analyzing, true)
        |> put_flash(:info, "Analysis started for #{demo_file_path}")
        
      {:error, reason} ->
        socket
        |> put_flash(:error, "Analysis failed: #{reason}")
    end
  end

  defp refresh_evolution_data(socket) do
    assign_evolution_data(socket)
  end
  
  defp refresh_proposals(socket) do
    assign_proposal_data(socket)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:active_tab, :overview)
  end

  defp apply_action(socket, live_action, _params) when live_action in [:projects, :files, :optimizations, :evaluations] do
    socket
    |> assign(:active_tab, live_action)
  end
  
  defp apply_action(socket, :opportunities, _params) do
    case Ace.Analysis.Service.list_opportunities(%{}) do
      {:ok, opportunities} ->
        socket
        |> assign(:active_tab, :opportunities)
        |> assign(:opportunities, opportunities)
      
      {:error, _reason} ->
        socket
        |> assign(:active_tab, :opportunities)
        |> assign(:opportunities, [])
    end
  end
  
  defp apply_action(socket, :evolution, _params) do
    socket
    |> assign(:active_tab, :evolution)
    |> assign_evolution_data()
  end
  
  defp apply_action(socket, :evolution_proposals, _params) do
    # Add debug logging
    IO.puts("Loading evolution proposals page")
    pending_proposals = Ace.Core.EvolutionProposal.list_pending()
    IO.puts("Found #{length(pending_proposals)} pending proposals")
    
    socket
    |> assign(:active_tab, :evolution_proposals)
    |> assign(:pending_proposals, pending_proposals)
    |> assign(:proposal_count, length(pending_proposals))
  end
  
  # Group all handle_event functions together
  @impl true
  def handle_event("analyze", _params, socket) do
    # Directly use Analysis Service instead of HTTP request which may fail
    demo_file_path = "demo_code/test_module.ex"
    
    # Create the file if it doesn't exist for demo purposes
    ensure_demo_file_exists(demo_file_path)
    
    case Ace.Analysis.Service.analyze_file(demo_file_path, [
      language: "elixir",
      focus_areas: ["performance", "maintainability"],
      severity_threshold: "medium"
    ]) do
      {:ok, analysis} ->
        # Broadcast to PubSub
        Phoenix.PubSub.broadcast(Ace.PubSub, "ace:analyses", {:analysis_created, analysis})
        
        {:noreply, 
          socket
          |> assign(:analyzing, true)
          |> assign(:recent_activities, load_recent_activities())
          |> assign(:metrics, load_system_metrics())
          |> put_flash(:info, "Analysis started for #{demo_file_path}")
        }
        
      {:error, reason} ->
        {:noreply,
          socket
          |> put_flash(:error, "Analysis failed: #{reason}")
        }
    end
  end
  
  @impl true
  def handle_event("trigger_evolution", _params, socket) do
    # Generate a test module for evolution
    test_module_name = "Elixir.Test.Module#{:rand.uniform(10)}"
    source_code = """
    defmodule #{test_module_name} do
      def test_function(list) do
        Enum.reduce(list, 0, fn num, acc -> 
          acc + num 
        end)
      end
    end
    """
    
    # Trigger evolution for this module
    case Ace.Evolution.Service.evolve(
      test_module_name, 
      source_code, 
      "test_source",
      [notify: true]
    ) do
      {:ok, proposal} ->
        {:noreply, 
          socket
          |> put_flash(:info, "Created evolution proposal for #{test_module_name}")
          |> assign_proposal_data()
        }
        
      {:error, reason} ->
        {:noreply,
          socket
          |> put_flash(:error, "Failed to create evolution proposal: #{inspect(reason)}")
        }
    end
  end
  
  # Create demo file if it doesn't exist
  defp ensure_demo_file_exists(file_path) do
    demo_dir = Path.dirname(file_path)
    
    # Create directory if it doesn't exist
    unless File.exists?(demo_dir) do
      File.mkdir_p!(demo_dir)
    end
    
    # Create file if it doesn't exist
    unless File.exists?(file_path) do
      content = """
      defmodule Demo.TestModule do
        def inefficient_sum(list) do
          Enum.reduce(list, 0, fn num, acc -> 
            Process.sleep(1)  # Artificial inefficiency
            acc + num 
          end)
        end
        
        def find_duplicates(list) do
          Enum.filter(list, fn item ->
            Enum.count(list, fn x -> x == item end) > 1
          end)
          |> Enum.uniq()
        end
      end
      """
      File.write!(file_path, content)
    end
  end
  
  @impl true
  def handle_event("select-project-for-relationships", %{"value" => ""}, socket) do
    socket = 
      socket
      |> assign(:selected_project_id, nil)
      |> assign(:relationship_graph_data, build_relationship_graph_data())
      |> assign(:selected_file_id, nil)
      |> assign(:selected_file, nil)
      |> assign(:selected_file_relationships, %{incoming: [], outgoing: []})
      |> assign(:selected_file_stats, %{incoming_count: 0, outgoing_count: 0})
      |> assign(:selected_file_opportunities, [])
      
    {:noreply, socket}
  end
  
  @impl true
  def handle_event("select-project-for-relationships", %{"value" => project_id}, socket) do
    {project_id, _} = Integer.parse(project_id)
    
    socket = 
      socket
      |> assign(:selected_project_id, project_id)
      |> assign(:relationship_graph_data, build_relationship_graph_data(project_id))
      |> assign(:selected_file_id, nil)
      |> assign(:selected_file, nil)
      |> assign(:selected_file_relationships, %{incoming: [], outgoing: []})
      |> assign(:selected_file_stats, %{incoming_count: 0, outgoing_count: 0})
      |> assign(:selected_file_opportunities, [])
      
    {:noreply, socket}
  end
  
  @impl true
  def handle_event("toggle-relationship-type-filter", %{"type" => type}, socket) do
    current_filters = socket.assigns.relationship_type_filters || AnalysisRelationship.relationship_types()
    
    new_filters = 
      if Enum.member?(current_filters, type) do
        List.delete(current_filters, type)
      else
        [type | current_filters]
      end
    
    # If all types are selected, set to nil for "all"
    new_filters = 
      if length(new_filters) == length(AnalysisRelationship.relationship_types()) do
        nil
      else
        new_filters
      end
    
    socket = 
      socket
      |> assign(:relationship_type_filters, new_filters)
      |> assign(:relationship_graph_data, build_relationship_graph_data(socket.assigns.selected_project_id, new_filters))
      
    {:noreply, socket}
  end
  
  @impl true
  def handle_event("select-file-node", %{"id" => file_id}, socket) do
    {file_id, _} = Integer.parse(file_id)
    
    case Ace.Repo.get(Ace.Core.Analysis, file_id) do
      nil -> 
        {:noreply, socket}
        
      file ->
        # Get relationships for this file
        relationships = load_file_relationships(file_id)
        
        # Get cross-file opportunities for this file
        opportunities = load_cross_file_opportunities(file_id)
        
        # Count stats
        stats = %{
          incoming_count: length(relationships.incoming),
          outgoing_count: length(relationships.outgoing)
        }
        
        {:noreply, 
          socket
          |> assign(:selected_file_id, file_id)
          |> assign(:selected_file, file)
          |> assign(:selected_file_relationships, relationships)
          |> assign(:selected_file_stats, stats)
          |> assign(:selected_file_opportunities, opportunities)}
    end
  end
  
  @impl true
  def handle_event("select-relationship-file", %{"id" => file_id}, socket) do
    handle_event("select-file-node", %{"id" => file_id}, socket)
  end

  @impl true
  def handle_event("refresh_evolution_data", _params, socket) do
    {:noreply, assign_evolution_data(socket)}
  end
  
  @impl true
  def handle_event("refresh_proposals", _params, socket) do
    {:noreply, assign_filtered_proposals(socket, socket.assigns.status_filter, %{})}
  end
  
  @impl true
  def handle_event("view_proposal", %{"id" => id}, socket) do
    # This will be handled by JS hook to toggle visibility
    {:noreply, 
      socket 
      |> push_event("toggle-proposal-diff", %{id: id})}
  end
  
  @impl true
  def handle_event("reject_proposal_modal", %{"id" => id}, socket) do
    # This will be handled by JS hook to show modal
    {:noreply, 
      socket 
      |> push_event("show-rejection-modal", %{id: id})}
  end
  
  @impl true
  def handle_event("approve_proposal_modal", %{"id" => id}, socket) do
    # Show the approval modal
    {:noreply, 
      socket 
      |> push_event("show-approval-modal", %{id: id})}
  end
  
  @impl true
  def handle_event("apply_proposal_modal", %{"id" => id}, socket) do
    # Show the apply modal
    {:noreply, 
      socket 
      |> push_event("show-apply-modal", %{id: id})}
  end
  
  @impl true
  def handle_event("approve_proposal", %{"id" => id, "comments" => comments}, socket) do
    reviewer_id = "admin" # In a real app, this would come from auth context
    comments = if comments == "", do: "Approved via dashboard", else: comments
    
    case handle_proposal_approval(id, reviewer_id, comments) do
      {:ok, _proposal} ->
        {:noreply, 
          socket
          |> put_flash(:info, "Proposal approved successfully")
          |> assign_filtered_proposals(socket.assigns.status_filter, %{})}
        
      {:error, reason} ->
        {:noreply, 
          socket
          |> put_flash(:error, "Failed to approve proposal: #{inspect(reason)}")}
    end
  end
  
  @impl true
  def handle_event("reject_proposal", %{"id" => id, "reason" => reason}, socket) do
    reviewer_id = "admin" # In a real app, this would come from auth context
    
    case handle_proposal_rejection(id, reviewer_id, reason) do
      {:ok, _proposal} ->
        {:noreply, 
          socket
          |> put_flash(:info, "Proposal rejected successfully")
          |> assign_filtered_proposals(socket.assigns.status_filter, %{})}
        
      {:error, reason} ->
        {:noreply, 
          socket
          |> put_flash(:error, "Failed to reject proposal: #{inspect(reason)}")}
    end
  end
  
  @impl true
  def handle_event("apply_proposal", %{"id" => id}, socket) do
    case handle_proposal_application(id) do
      {:ok, version} ->
        {:noreply, 
          socket
          |> put_flash(:info, "Proposal applied successfully as version #{version}")
          |> assign_filtered_proposals(socket.assigns.status_filter, %{})
          |> assign_evolution_data()}
        
      {:error, reason} ->
        {:noreply, 
          socket
          |> put_flash(:error, "Failed to apply proposal: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("filter_proposals", %{"status" => status}, socket) do
    socket = assign(socket, :status_filter, status)
    {:noreply, push_patch(socket, to: Routes.dashboard_path(socket, :evolution_proposals, status: status))}
  end

  # Group all handle_info functions together
  @impl true
  def handle_info(:analysis_complete, socket) do
    # Load fresh data after analysis completes
    analyses = Ace.Repo.all(from a in Ace.Core.Analysis, order_by: [desc: a.inserted_at], limit: 20)
    {:ok, opportunities} = Ace.Analysis.Service.list_opportunities(%{})
    optimizations = Ace.Repo.all(from o in Ace.Core.Optimization, order_by: [desc: o.inserted_at], limit: 20)
    
    socket =
      socket
      |> assign(:analyzing, false)
      |> assign(:analyses, analyses)
      |> assign(:opportunities, opportunities)
      |> assign(:optimizations, optimizations)
      |> assign(:recent_activities, load_recent_activities())
      |> assign(:metrics, load_system_metrics())
    
    {:noreply, socket}
  end
  
  @impl true
  def handle_info({:analysis_created, _analysis}, socket) do
    # Get updated lists of all entities
    analyses = Ace.Repo.all(from a in Ace.Core.Analysis, order_by: [desc: a.inserted_at], limit: 20)
    
    {:noreply, 
      socket
      |> assign(:analyses, analyses)
      |> assign(:recent_activities, load_recent_activities())
    }
  end
  
  @impl true
  def handle_info({:opportunity_created, _opportunity}, socket) do
    # Get updated list of opportunities
    {:ok, opportunities} = Ace.Analysis.Service.list_opportunities(%{})
    
    {:noreply, 
      socket
      |> assign(:opportunities, opportunities)
      |> assign(:recent_activities, load_recent_activities())
    }
  end
  
  @impl true
  def handle_info({:optimization_created, _optimization}, socket) do
    # Get updated list of optimizations
    optimizations = Ace.Repo.all(from o in Ace.Core.Optimization, order_by: [desc: o.inserted_at], limit: 20)
    
    {:noreply, 
      socket
      |> assign(:optimizations, optimizations)
      |> assign(:recent_activities, load_recent_activities())
    }
  end
  
  @impl true
  def handle_info({:evaluation_completed, {:ok, evaluation}}, socket) do
    # Update assigns
    updated_socket = 
      socket
      |> assign(:loading, false)
      |> assign(:evaluations, [evaluation | socket.assigns.evaluations] |> Enum.take(@page_size))
      |> assign(:metrics, load_system_metrics())
      |> assign(:chart_data, generate_chart_data())
      |> put_flash(:info, "Evaluation completed successfully")
    
    # Notify charts to update with new data
    updated_socket = if socket.assigns.active_tab == :overview do
      # Format chart data for JavaScript
      performance_data = %{
        dates: Enum.map(updated_socket.assigns.chart_data.performance, fn p -> p.date end),
        improvements: Enum.map(updated_socket.assigns.chart_data.performance, fn p -> p.improvement end)
      }
      
      # Send updates to charts
      push_event(updated_socket, "chart-data-updated", %{chart: "performance-chart", data: performance_data})
    else
      updated_socket
    end
    
    {:noreply, updated_socket}
  end
  
  @impl true
  def handle_info({:evaluation_completed, {:error, reason}}, socket) do
    {:noreply, 
      socket
      |> assign(:loading, false)
      |> put_flash(:error, "Evaluation failed: #{reason}")}
  end
  
  @impl true
  def handle_info({:optimization_applied, {:ok, optimization}}, socket) do
    socket = 
      socket
      |> assign(:loading, false)
      |> assign(:optimizations, 
        Enum.map(socket.assigns.optimizations, fn opt ->
          if opt.id == optimization.id, do: optimization, else: opt
        end)
      )
      |> assign(:metrics, load_system_metrics())
      |> put_flash(:info, "Optimization applied successfully")
    
    {:noreply, socket}
  end
  
  @impl true
  def handle_info({:optimization_applied, {:error, reason}}, socket) do
    {:noreply, 
      socket
      |> assign(:loading, false)
      |> put_flash(:error, "Failed to apply optimization: #{reason}")}
  end
  
  @impl true
  def handle_info({:pipeline_completed, {:ok, results}}, socket) do
    socket = 
      socket
      |> assign(:loading, false)
      |> assign(:analyses, 
        (if results.analysis, do: [results.analysis | socket.assigns.analyses], else: socket.assigns.analyses) 
        |> Enum.take(@page_size)
      )
      |> assign(:opportunities, 
        (results.opportunities ++ socket.assigns.opportunities) 
        |> Enum.take(@page_size * 2)
      )
      |> assign(:optimizations,
        (results.optimizations ++ socket.assigns.optimizations)
        |> Enum.take(@page_size)
      )
      |> assign(:evaluations,
        (results.evaluations ++ socket.assigns.evaluations)
        |> Enum.take(@page_size)
      )
      |> assign(:metrics, load_system_metrics())
      |> assign(:chart_data, generate_chart_data())
      |> put_flash(:info, "Pipeline completed successfully")
    
    {:noreply, socket}
  end
  
  @impl true
  def handle_info({:pipeline_completed, {:error, reason}}, socket) do
    {:noreply, 
      socket
      |> assign(:loading, false)
      |> put_flash(:error, "Pipeline failed: #{reason}")}
  end
  
  @impl true
  def handle_info({:api_error, %{provider: provider, reason: reason}}, socket) do
    error_message = case provider do
      "groq" -> 
        "Groq API error: #{format_api_error(reason)}. Check your API key and try again."
      "openai" -> 
        "OpenAI API error: #{format_api_error(reason)}. Check your API key and try again."
      "anthropic" -> 
        "Anthropic API error: #{format_api_error(reason)}. Check your API key and try again."
      _ -> 
        "API error: #{format_api_error(reason)}"
    end
    
    {:noreply, 
      socket
      |> assign(:loading, false)
      |> put_flash(:error, error_message)}
  end
  
  @impl true
  def handle_info({:project_created, {:ok, result}}, socket) do
    socket = 
      socket
      |> assign(:loading, false)
      |> assign(:projects, [result.project | socket.assigns.projects] |> Enum.take(@page_size))
      |> assign(:analyses, (result.analyses ++ socket.assigns.analyses) |> Enum.take(@page_size))
      |> assign(:opportunities, 
        (result.cross_file_opportunities ++ socket.assigns.opportunities) 
        |> Enum.take(@page_size * 2))
      |> assign(:metrics, load_system_metrics())
      |> assign(:file_list, [])
      |> assign(:selected_project_id, result.project.id)
      |> assign(:show_project_modal, false)
      |> put_flash(:info, "Project created and analyzed successfully")
    
    {:noreply, socket}
  end
  
  @impl true
  def handle_info({:project_created, {:error, reason}}, socket) do
    {:noreply, 
      socket
      |> assign(:loading, false)
      |> assign(:show_project_modal, false)
      |> put_flash(:error, "Project creation failed: #{reason}")}
  end

  @impl true
  def handle_info({:new_proposal, proposal}, socket) do
    # Update proposal count
    new_count = socket.assigns.proposal_count + 1
    
    # If we're on the proposals page, also update the list
    socket = 
      if socket.assigns.active_tab == :evolution_proposals do
        assign(socket, :pending_proposals, [proposal | socket.assigns.pending_proposals])
      else
        socket
      end
    
    {:noreply, assign(socket, :proposal_count, new_count)}
  end
  
  @impl true
  def handle_info({:proposal_status_changed, proposal}, socket) do
    # If we're on the proposals page, update the list
    socket = 
      if socket.assigns.active_tab == :evolution_proposals do
        # Remove from pending list if not pending anymore
        updated_proposals = 
          if proposal.status != "pending_review" do
            Enum.reject(socket.assigns.pending_proposals, fn p -> p.id == proposal.id end) 
          else
            Enum.map(socket.assigns.pending_proposals, fn p ->
              if p.id == proposal.id, do: proposal, else: p
            end)
          end
          
        assign(socket, :pending_proposals, updated_proposals)
      else
        socket
      end
    
    # Update count if status changed from/to pending
    socket = if socket.assigns.active_tab == :evolution do
      assign(socket, :proposal_count, Ace.Core.EvolutionProposal.count_pending())
    else
      socket
    end
    
    {:noreply, socket}
  end
  
  @impl true
  def handle_info({:proposal_applied, _proposal_id}, socket) do
    # Re-load evolution data if we're on the evolution page
    socket = 
      if socket.assigns.active_tab == :evolution do
        assign_evolution_data(socket)
      else
        socket
      end
      
    {:noreply, socket}
  end

  @impl true
  def handle_info({:proposal_updated, _proposal}, socket) do
    # Refresh the proposals when we receive a pubsub notification about a proposal update
    Logger.info("Received proposal update notification, refreshing proposals")
    {:noreply, assign_filtered_proposals(socket, socket.assigns.status_filter, %{})}
  end
  
  @impl true
  def handle_info({:proposal_applied, _id, _version}, socket) do
    # Refresh both proposals and evolution data when a proposal is applied
    Logger.info("Received proposal applied notification, refreshing data")
    socket = 
      socket
      |> assign_filtered_proposals(socket.assigns.status_filter, %{})
      |> assign_evolution_data()
    
    {:noreply, socket}
  end

  # Format API error messages for display
  defp format_api_error(error) do
    cond do
      is_binary(error) -> 
        error
      is_map(error) && Map.has_key?(error, :message) -> 
        error.message
      is_map(error) && Map.has_key?(error, "message") -> 
        error["message"]
      is_tuple(error) && tuple_size(error) == 2 -> 
        "#{elem(error, 0)}: #{elem(error, 1)}"
      true -> 
        inspect(error)
    end
  end
  
  # Load projects from the database
  defp load_projects do
    Ace.Repo.all(
      from project in Ace.Core.Project,
        order_by: [desc: project.inserted_at],
        limit: @page_size,
        preload: [:analyses]
    )
  end
  
  # Load system metrics
  defp load_system_metrics do
    %{
      analyses_count: Ace.Repo.aggregate(Ace.Core.Analysis, :count, :id),
      opportunities_count: Ace.Repo.aggregate(Ace.Core.Opportunity, :count, :id),
      optimizations_count: Ace.Repo.aggregate(Ace.Core.Optimization, :count, :id),
      evaluations_count: Ace.Repo.aggregate(Ace.Core.Evaluation, :count, :id),
      projects_count: Ace.Repo.aggregate(Ace.Core.Project, :count, :id),
      successful_evaluations_count: Ace.Repo.aggregate(Ace.Core.Evaluation, :count, :id, [
        where: [success: true]
      ]),
      applied_optimizations_count: Ace.Repo.aggregate(Ace.Core.Optimization, :count, :id, [
        where: [status: "applied"]
      ]),
      languages_breakdown: Ace.Repo.all(
        from a in Ace.Core.Analysis,
          group_by: a.language,
          select: {a.language, count(a.id)}
      ),
      opportunity_types: Ace.Repo.all(
        from o in Ace.Core.Opportunity,
          group_by: o.type,
          select: {o.type, count(o.id)}
      ),
      cross_file_opportunities_count: Ace.Repo.aggregate(Ace.Core.Opportunity, :count, :id, [
        where: [scope: "cross_file"]
      ])
    }
  end
  
  # Generate chart data for visualizations
  defp generate_chart_data do
    # Get performance improvements over time
    performance_data = Ace.Repo.all(
      from evaluation in Ace.Core.Evaluation,
        order_by: evaluation.inserted_at,
        select: %{
          date: fragment("date_trunc('day', ?)", evaluation.inserted_at),
          improvement: fragment("(metrics->>'overall_improvement')::float"),
          success: evaluation.success
        },
        where: fragment("metrics->>'overall_improvement' IS NOT NULL")
    )
    
    # Get language distribution
    language_data = Ace.Repo.all(
      from analysis in Ace.Core.Analysis,
        group_by: analysis.language,
        select: %{language: analysis.language, count: count()}
    )
    
    # Get opportunity type distribution
    type_data = Ace.Repo.all(
      from opportunity in Ace.Core.Opportunity,
        group_by: opportunity.type,
        select: %{type: opportunity.type, count: count()}
    )
    
    # Get severity distribution
    severity_data = Ace.Repo.all(
      from opportunity in Ace.Core.Opportunity,
        group_by: opportunity.severity,
        select: %{severity: opportunity.severity, count: count()}
    )
    
    %{
      performance: performance_data,
      languages: language_data,
      types: type_data,
      severities: severity_data
    }
  end
  
  # Format datetime for display
  def format_datetime(datetime) do
    case datetime do
      %DateTime{} -> Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p")
      %NaiveDateTime{} -> Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p")
      _ -> "Unknown date"
    end
  end
  
  # Helper function to determine status class for UI
  def status_class(status) do
    case status do
      "Complete" -> "text-green-600 font-medium"
      "Applied" -> "text-green-600 font-medium"
      "Pending" -> "text-yellow-600 font-medium"
      "Failed" -> "text-red-600 font-medium"
      _ -> "text-gray-500"
    end
  end
  
  # Format evaluation report with proper styling
  def format_report(report) when is_binary(report) do
    report
    |> String.replace(~r/^# (.+)$/m, "<h3>\\1</h3>")
    |> String.replace(~r/^## (.+)$/m, "<h4>\\1</h4>")
    |> String.replace(~r/^- (.+)$/m, "<li>\\1</li>")
    |> String.replace(~r/<li>(.+)\n(?!<li>)/, "<li>\\1</li>\n")
    |> String.replace(~r/✅/m, "<span class=\"success-icon\">✅</span>")
    |> String.replace(~r/❌/m, "<span class=\"error-icon\">❌</span>")
    |> String.replace(~r/\n\n/, "<br><br>")
  end
  def format_report(_), do: ""
  
  # Check if an evaluation exists for an optimization
  def has_evaluation?(optimization_id, evaluations) do
    Enum.any?(evaluations, fn e -> e.optimization_id == optimization_id end)
  end
  
  # Get an evaluation for an optimization
  def get_evaluation(optimization_id, evaluations) do
    Enum.find(evaluations, fn e -> e.optimization_id == optimization_id end)
  end
  
  # Format percentage for display
  def format_percentage(value) when is_number(value) do
    sign = if value >= 0, do: "+", else: ""
    "#{sign}#{Float.round(value, 2)}%"
  end
  def format_percentage(_), do: "N/A"
  
  # Status formatting helpers for proposals
  def status_badge_class(status) do
    case status do
      "pending_review" -> "bg-yellow-100 text-yellow-800"
      "approved" -> "bg-green-100 text-green-800"
      "rejected" -> "bg-red-100 text-red-800"
      "applied" -> "bg-indigo-100 text-indigo-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end
  
  def humanize_status(status) do
    case status do
      "pending_review" -> "Pending Review"
      "approved" -> "Approved"
      "rejected" -> "Rejected"
      "applied" -> "Applied"
      _ -> "Unknown"
    end
  end
  
  # Format complexity change
  def format_complexity_change(%{score: score}) when is_number(score) do
    cond do
      score < -10 -> "Significantly improved (#{format_percentage(score)})"
      score < 0 -> "Slightly improved (#{format_percentage(score)})"
      score == 0 -> "Unchanged"
      score < 10 -> "Slightly increased (#{format_percentage(score)})"
      true -> "Significantly increased (#{format_percentage(score)})"
    end
  end
  def format_complexity_change(%{percentage: percentage}) when is_number(percentage) do
    format_percentage(percentage)
  end
  def format_complexity_change(_), do: "Unknown"
  
  # Evolution and feedback functions
  
  # Loads all evolution data for the evolution dashboard.
  defp assign_evolution_data(socket) do
    # Load feedback data
    feedback_count = Ace.Repo.aggregate(Ace.Core.Feedback, :count, :id)
    
    # Load NPS distribution
    nps_distribution = try do
      Ace.Core.Feedback.nps_distribution()
    rescue
      # Handle any errors by returning a default structure
      _ -> %{
        detractors: %{count: 0, percentage: 0.0},
        passive: %{count: 0, percentage: 0.0},
        promoters: %{count: 0, percentage: 0.0},
        nps_score: 0.0,
        total: 0
      }
    end
    
    nps_score = case nps_distribution do
      %{nps_score: score} -> score
      _ -> 0.0
    end
    
    # Load recent feedback
    recent_feedback = Ace.Core.Feedback.list(limit: 10)
    
    # Load evolution history
    evolution_history = Ace.Repo.all(
      from h in Ace.Core.EvolutionHistory,
        order_by: [desc: h.date],
        limit: 10
    )
    
    # Count pending proposals
    proposal_count = Ace.Core.EvolutionProposal.count_pending()
    
    socket
    |> assign(:feedback_count, feedback_count)
    |> assign(:nps_score, nps_score)
    |> assign(:nps_distribution, nps_distribution)
    |> assign(:recent_feedback, recent_feedback)
    |> assign(:evolution_history, evolution_history)
    |> assign(:proposal_count, proposal_count)
  end
  
  defp assign_filtered_proposals(socket, status_filter, _params) do
    # Get counts by status for the filter tabs
    status_counts = Ace.Core.EvolutionProposal.count_by_status()
    total_count = status_counts |> Map.values() |> Enum.sum()
    
    # Load proposals based on the selected filter
    proposals = case status_filter do
      "all" -> 
        Ace.Core.EvolutionProposal.list_all()
      status when status in ["pending_review", "approved", "rejected", "applied"] -> 
        Ace.Core.EvolutionProposal.list_by_status(status)
      _ -> 
        Ace.Core.EvolutionProposal.list_all()
    end
    
    # Log for debugging
    IO.puts("Loading #{length(proposals)} proposals with filter: #{status_filter}")
    
    socket
    |> assign(:proposals, proposals)
    |> assign(:pending_proposals, Enum.filter(proposals, fn p -> p.status == "pending_review" end))
    |> assign(:approved_proposals, Enum.filter(proposals, fn p -> p.status == "approved" end))
    |> assign(:proposal_count, status_counts["pending_review"] || 0)
    |> assign(:status_counts, status_counts)
    |> assign(:total_proposal_count, total_count)
  end
  
  defp assign_proposal_data(socket) do
    # Use new filtered loading
    assign_filtered_proposals(socket, socket.assigns.status_filter || "all", %{})
  end
  
  # Handles approving a proposal.
  def handle_proposal_approval(id, reviewer_id, comments) do
    Logger.info("Approving proposal #{id} by #{reviewer_id} with comments: #{comments}")
    
    case Ace.Core.EvolutionProposal.approve(id, reviewer_id, comments) do
      {:ok, proposal} = result ->
        Logger.info("Proposal #{id} approved successfully")
        Phoenix.PubSub.broadcast(Ace.PubSub, "proposals", {:proposal_updated, proposal})
        result
        
      error ->
        Logger.error("Failed to approve proposal #{id}: #{inspect(error)}")
        error
    end
  end
  
  # Handles rejecting a proposal.
  def handle_proposal_rejection(id, reviewer_id, reason) do
    Logger.info("Rejecting proposal #{id} by #{reviewer_id} with reason: #{reason}")
    
    case Ace.Core.EvolutionProposal.reject(id, reviewer_id, reason) do
      {:ok, proposal} = result ->
        Logger.info("Proposal #{id} rejected successfully")
        Phoenix.PubSub.broadcast(Ace.PubSub, "proposals", {:proposal_updated, proposal})
        result
        
      error ->
        Logger.error("Failed to reject proposal #{id}: #{inspect(error)}")
        error
    end
  end
  
  # Handles applying an approved proposal.
  def handle_proposal_application(id) do
    Logger.info("Applying proposal #{id}")
    
    case Ace.Evolution.Service.apply_proposal(id) do
      {:ok, version} = result ->
        Logger.info("Proposal #{id} applied successfully as version #{version}")
        Phoenix.PubSub.broadcast(Ace.PubSub, "proposals", {:proposal_applied, id, version})
        result
        
      error ->
        Logger.error("Failed to apply proposal #{id}: #{inspect(error)}")
        error
    end
  end
  
  # Get all supported relationship types
  def get_relationship_types do
    AnalysisRelationship.relationship_types()
  end
  
  # Format relationship details
  def format_relationship_details(details) when is_map(details) do
    details
    |> Enum.map(fn {key, value} -> "#{key}: #{value}" end)
    |> Enum.join(", ")
  end
  def format_relationship_details(_), do: ""
  
  # Load relationships for a specific file
  defp load_file_relationships(file_id) do
    import Ecto.Query
    
    # Get outgoing relationships (this file -> other files)
    outgoing_query = 
      from r in AnalysisRelationship,
        where: r.source_analysis_id == ^file_id,
        join: t in Ace.Core.Analysis, on: r.target_analysis_id == t.id,
        select: %{
          id: r.id,
          relationship_type: r.relationship_type,
          details: r.details,
          source_analysis_id: r.source_analysis_id,
          target_analysis_id: r.target_analysis_id,
          target_file_path: t.file_path
        }
    
    # Get incoming relationships (other files -> this file)
    incoming_query = 
      from r in AnalysisRelationship,
        where: r.target_analysis_id == ^file_id,
        join: s in Ace.Core.Analysis, on: r.source_analysis_id == s.id,
        select: %{
          id: r.id,
          relationship_type: r.relationship_type,
          details: r.details,
          source_analysis_id: r.source_analysis_id,
          target_analysis_id: r.target_analysis_id,
          source_file_path: s.file_path
        }
    
    %{
      outgoing: Ace.Repo.all(outgoing_query),
      incoming: Ace.Repo.all(incoming_query)
    }
  end
  
  # Load cross-file opportunities for a specific file
  defp load_cross_file_opportunities(file_id) do
    import Ecto.Query
    
    # Find the analysis
    case Ace.Repo.get(Ace.Core.Analysis, file_id) do
      nil -> []
      _analysis ->
        # Get opportunities that are related to this file
        query = 
          from o in Ace.Core.Opportunity,
            where: o.analysis_id == ^file_id,
            where: o.scope == "cross_file",
            order_by: [desc: o.severity, desc: o.inserted_at]
            
        Ace.Repo.all(query)
    end
  end
  
  # Build relationship graph data
  defp build_relationship_graph_data(project_id \\ nil, type_filters \\ nil) do
    import Ecto.Query
    
    # Get analyses based on project
    analyses_query = 
      case project_id do
        nil -> 
          from a in Ace.Core.Analysis,
            select: %{id: a.id, file_path: a.file_path, language: a.language}
          
        id -> 
          from a in Ace.Core.Analysis,
            where: a.project_id == ^id,
            select: %{id: a.id, file_path: a.file_path, language: a.language}
      end
    
    analyses = Ace.Repo.all(analyses_query)
    
    # Get relationships based on filters
    relationships_query = 
      case {project_id, type_filters} do
        {nil, nil} -> 
          from r in AnalysisRelationship,
            select: %{
              id: r.id,
              source_id: r.source_analysis_id,
              target_id: r.target_analysis_id,
              type: r.relationship_type
            }
          
        {id, nil} -> 
          from r in AnalysisRelationship,
            join: s in Ace.Core.Analysis, on: r.source_analysis_id == s.id,
            join: t in Ace.Core.Analysis, on: r.target_analysis_id == t.id,
            where: s.project_id == ^id and t.project_id == ^id,
            select: %{
              id: r.id,
              source_id: r.source_analysis_id,
              target_id: r.target_analysis_id,
              type: r.relationship_type
            }
          
        {nil, types} -> 
          from r in AnalysisRelationship,
            where: r.relationship_type in ^types,
            select: %{
              id: r.id,
              source_id: r.source_analysis_id,
              target_id: r.target_analysis_id,
              type: r.relationship_type
            }
            
        {id, types} -> 
          from r in AnalysisRelationship,
            join: s in Ace.Core.Analysis, on: r.source_analysis_id == s.id,
            join: t in Ace.Core.Analysis, on: r.target_analysis_id == t.id,
            where: s.project_id == ^id and t.project_id == ^id,
            where: r.relationship_type in ^types,
            select: %{
              id: r.id,
              source_id: r.source_analysis_id,
              target_id: r.target_analysis_id,
              type: r.relationship_type
            }
      end
      
    relationships = Ace.Repo.all(relationships_query)
    
    # Format for the graph visualization
    %{
      nodes: Enum.map(analyses, fn a -> 
        %{
          id: a.id,
          label: Path.basename(a.file_path),
          group: a.language,
          title: a.file_path
        }
      end),
      edges: Enum.map(relationships, fn r -> 
        %{
          id: r.id,
          from: r.source_id,
          to: r.target_id,
          label: r.type,
          arrows: "to"
        }
      end)
    }
  end
  
  # Mock data for demonstration
  defp mock_activities do
    load_recent_activities()
  rescue
    # Fallback to hardcoded mock data if database access fails
    _ -> [
      {"Analysis", "user_controller.ex", "Complete", "2 hours ago"},
      {"Optimization", "Performance issue in sort algorithm", "Complete", "3 hours ago"},
      {"Evaluation", "O(n²) to O(n log n) conversion", "Complete", "3 hours ago"},
      {"Applied", "Sort algorithm improvement", "Complete", "3 hours ago"},
      {"Analysis", "auth_service.ex", "Complete", "1 day ago"},
      {"Optimization", "Memory usage in caching layer", "Failed", "1 day ago"},
      {"Analysis", "dashboard_live.ex", "Complete", "2 days ago"},
      {"Optimization", "Query optimization", "Complete", "2 days ago"},
      {"Evaluation", "Database query restructuring", "Complete", "2 days ago"},
      {"Applied", "Query optimization", "Complete", "2 days ago"}
    ]
  end
  
  defp mock_analyses do
    [
      %{id: "1", file_path: "lib/project/user.ex", language: "elixir", focus_areas: ["performance", "maintainability"]},
      %{id: "2", file_path: "lib/project/auth.ex", language: "elixir", focus_areas: ["security", "reliability"]}
    ]
  end
  
  defp mock_opportunities do
    [
      %{id: "1", analysis_id: "1", type: "performance", severity: "high", location: "sort_users/1", 
        description: "O(n²) sorting algorithm can be replaced with more efficient implementation"},
      %{id: "2", analysis_id: "1", type: "maintainability", severity: "medium", location: "process_data/2",
        description: "Complex function with multiple responsibilities can be refactored"},
      %{id: "3", analysis_id: "2", type: "security", severity: "high", location: "validate_token/1",
        description: "Potential timing attack vulnerability in token comparison"}
    ]
  end

  @impl true
  def render(assigns) do
    # Ensure all required assigns are available
    assigns = assigns
      |> ensure_assign(:nps_distribution, %{
        detractors: %{count: 0, percentage: 0.0},
        passive: %{count: 0, percentage: 0.0},
        promoters: %{count: 0, percentage: 0.0},
        nps_score: 0.0,
        total: 0
      })
      |> ensure_assign(:recent_feedback, [])
      |> ensure_assign(:evolution_history, [])
      |> ensure_assign(:feedback_count, 0)
      |> ensure_assign(:nps_score, 0.0)
      |> ensure_assign(:proposal_count, 0)
      |> ensure_assign(:pending_proposals, [])
    
    # Render different templates based on the live action
    case assigns.live_action do
      :evolution -> ~H"""
      <div class="py-6">
        <.header>
          Evolution Dashboard
          <:subtitle>User feedback analysis and code evolution</:subtitle>
          <:actions>
            <a href="/evolution?refresh=1" class="bg-indigo-600 hover:bg-indigo-700 px-4 py-2 text-white rounded inline-block mr-2">
              Refresh Data
            </a>
            <a href="/evolution/generate" class="bg-green-600 hover:bg-green-700 px-4 py-2 text-white rounded inline-block">
              Generate Proposal
            </a>
          </:actions>
        </.header>

        <div class="mt-6 grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
          <.card>
            <div class="flex items-center">
              <div class="flex-shrink-0 rounded-md bg-blue-500 p-3">
                <svg class="h-6 w-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
                </svg>
              </div>
              <div class="ml-5 w-0 flex-1">
                <dl>
                  <dt class="truncate text-sm font-medium text-gray-500">Feedback Collected</dt>
                  <dd>
                    <div class="text-lg font-medium text-gray-900"><%= @feedback_count || 0 %></div>
                  </dd>
                </dl>
              </div>
            </div>
          </.card>

          <.card>
            <div class="flex items-center">
              <div class="flex-shrink-0 rounded-md bg-green-500 p-3">
                <svg class="h-6 w-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5"></path>
                </svg>
              </div>
              <div class="ml-5 w-0 flex-1">
                <dl>
                  <dt class="truncate text-sm font-medium text-gray-500">NPS Score</dt>
                  <dd>
                    <div class="text-lg font-medium text-gray-900"><%= @nps_score || "-" %></div>
                  </dd>
                </dl>
              </div>
            </div>
          </.card>

          <.card>
            <div class="flex items-center">
              <div class="flex-shrink-0 rounded-md bg-purple-500 p-3">
                <svg class="h-6 w-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path>
                </svg>
              </div>
              <div class="ml-5 w-0 flex-1">
                <dl>
                  <dt class="truncate text-sm font-medium text-gray-500">Pending Proposals</dt>
                  <dd>
                    <div class="text-lg font-medium text-gray-900"><%= @proposal_count || 0 %></div>
                  </dd>
                </dl>
              </div>
            </div>
          </.card>
        </div>

        <!-- NPS Visualization -->
        <div class="mt-8">
          <h2 class="text-lg font-medium text-gray-900">NPS Distribution</h2>
          <div class="mt-3 bg-white shadow overflow-hidden rounded-lg">
            <div class="p-5">
              <!-- NPS Chart - Simple Bar Visualization -->
              <div class="grid grid-cols-10 h-6 rounded-full overflow-hidden">
                <%= if @nps_distribution do %>
                  <div class="bg-red-500" style={"width: #{@nps_distribution.detractors.percentage}%"}></div>
                  <div class="bg-yellow-400" style={"width: #{@nps_distribution.passive.percentage}%"}></div>
                  <div class="bg-green-500" style={"width: #{@nps_distribution.promoters.percentage}%"}></div>
                <% else %>
                  <div class="bg-gray-200 col-span-10"></div>
                <% end %>
              </div>
              
              <!-- Legend -->
              <div class="flex justify-between mt-2 text-sm">
                <div class="flex items-center">
                  <div class="h-3 w-3 bg-red-500 mr-1 rounded-sm"></div>
                  <span>Detractors (<%= (@nps_distribution && @nps_distribution.detractors.percentage) || 0 %>%)</span>
                </div>
                <div class="flex items-center">
                  <div class="h-3 w-3 bg-yellow-400 mr-1 rounded-sm"></div>
                  <span>Passives (<%= (@nps_distribution && @nps_distribution.passive.percentage) || 0 %>%)</span>
                </div>
                <div class="flex items-center">
                  <div class="h-3 w-3 bg-green-500 mr-1 rounded-sm"></div>
                  <span>Promoters (<%= (@nps_distribution && @nps_distribution.promoters.percentage) || 0 %>%)</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Recent Feedback -->
        <div class="mt-8">
          <div class="flex justify-between items-center">
            <h2 class="text-lg font-medium text-gray-900">Recent Feedback</h2>
            <a href="/evolution/proposals" target="_self" rel="nofollow" class="text-blue-600 hover:text-blue-800">
              View Pending Proposals →
            </a>
          </div>
          
          <%= if @recent_feedback && length(@recent_feedback) > 0 do %>
            <div class="mt-3 bg-white shadow overflow-hidden sm:rounded-md">
              <ul role="list" class="divide-y divide-gray-200">
                <%= for feedback <- @recent_feedback do %>
                  <li>
                    <div class="px-4 py-4 sm:px-6">
                      <div class="flex items-center justify-between">
                        <div class="flex items-center">
                          <%= case feedback.score do %>
                            <% score when score >= 9 -> %>
                              <div class="h-8 w-8 rounded-full bg-green-100 flex items-center justify-center mr-3">
                                <span class="text-green-600 font-bold"><%= feedback.score %></span>
                              </div>
                            <% score when score >= 7 -> %>
                              <div class="h-8 w-8 rounded-full bg-yellow-100 flex items-center justify-center mr-3">
                                <span class="text-yellow-600 font-bold"><%= feedback.score %></span>
                              </div>
                            <% _ -> %>
                              <div class="h-8 w-8 rounded-full bg-red-100 flex items-center justify-center mr-3">
                                <span class="text-red-600 font-bold"><%= feedback.score %></span>
                              </div>
                          <% end %>
                          <p class="text-sm font-medium text-gray-900 truncate">
                            <%= feedback.comment %>
                          </p>
                        </div>
                        <div class="ml-2 flex-shrink-0 flex">
                          <p class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800">
                            <%= feedback.source %>
                          </p>
                        </div>
                      </div>
                      <div class="mt-2 sm:flex sm:justify-between">
                        <div class="sm:flex">
                          <p class="flex items-center text-sm text-gray-500">
                            <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
                            </svg>
                            <%= feedback.user_id || "Anonymous" %>
                          </p>
                        </div>
                        <div class="mt-2 flex items-center text-sm text-gray-500 sm:mt-0">
                          <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
                          </svg>
                          <p>
                            <%= Calendar.strftime(feedback.inserted_at, "%B %d, %Y") %>
                          </p>
                        </div>
                      </div>
                    </div>
                  </li>
                <% end %>
              </ul>
            </div>
          <% else %>
            <div class="mt-3 bg-white shadow overflow-hidden sm:rounded-md p-6 text-center text-gray-500">
              No feedback collected yet.
            </div>
          <% end %>
        </div>

        <!-- Evolution History -->
        <div class="mt-8">
          <h2 class="text-lg font-medium text-gray-900">Evolution History</h2>
          
          <%= if @evolution_history && length(@evolution_history) > 0 do %>
            <div class="mt-3 bg-white shadow overflow-hidden sm:rounded-md">
              <ul role="list" class="divide-y divide-gray-200">
                <%= for entry <- @evolution_history do %>
                  <li>
                    <div class="px-4 py-4 sm:px-6">
                      <div class="flex items-center justify-between">
                        <div class="text-sm font-medium text-indigo-600 truncate">
                          <%= entry.dsl_name %>
                        </div>
                        <div class="ml-2 flex-shrink-0 flex">
                          <%= if entry.was_successful do %>
                            <p class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                              Successful
                            </p>
                          <% else %>
                            <p class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800">
                              Unsuccessful
                            </p>
                          <% end %>
                        </div>
                      </div>
                      <div class="mt-2 sm:flex sm:justify-between">
                        <div class="sm:flex">
                          <p class="flex items-center text-sm text-gray-500">
                            <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
                            </svg>
                            <%= entry.date |> Calendar.strftime("%B %d, %Y at %I:%M %p") %>
                          </p>
                        </div>
                      </div>
                    </div>
                  </li>
                <% end %>
              </ul>
            </div>
          <% else %>
            <div class="mt-3 bg-white shadow overflow-hidden sm:rounded-md p-6 text-center text-gray-500">
              No evolution history yet.
            </div>
          <% end %>
        </div>
      </div>
      """
      
      :opportunities -> ~H"""
      <div class="py-6">
        <.header>
          Improvement Opportunities
          <:subtitle>Detected opportunities for code improvements</:subtitle>
          <:actions>
            <a href="/?analyze=1" class="bg-indigo-600 hover:bg-indigo-700 px-4 py-2 text-white rounded inline-block">
              Analyze New Code
            </a>
          </:actions>
        </.header>

        <div class="mt-6">
          <div class="mt-3 bg-white shadow sm:rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <ul role="list" class="divide-y divide-gray-200">
                <%= if @opportunities && length(@opportunities) > 0 do %>
                  <%= for opportunity <- @opportunities do %>
                    <li class="flex py-4">
                      <div class="ml-3 w-full">
                        <div class="flex justify-between">
                          <p class="text-sm font-medium text-gray-900">
                            <%= opportunity.description %>
                          </p>
                          <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{severity_color(opportunity.severity)}"}>
                            <%= opportunity.severity %>
                          </span>
                        </div>
                        <p class="text-sm text-gray-500">Location: <%= opportunity.location %></p>
                        <p class="text-sm text-gray-500">Type: <%= opportunity.type %></p>
                        <p class="mt-1 text-sm text-gray-700"><%= opportunity.rationale %></p>
                        <p class="mt-1 text-sm text-indigo-600">Suggestion: <%= opportunity.suggested_change %></p>
                      </div>
                    </li>
                  <% end %>
                <% else %>
                  <li class="py-4 text-center text-gray-500">
                    No opportunities found. Try analyzing some code first.
                  </li>
                <% end %>
              </ul>
            </div>
          </div>
        </div>
      </div>
      """
      
      :evolution_proposals -> ~H"""
      <div id="proposal-manager" class="py-6" phx-hook="ProposalManager">
        <.header>
          Evolution Proposals
          <:subtitle>Review and manage code change proposals</:subtitle>
          <:actions>
            <a href="/evolution" target="_self" rel="nofollow" class="mr-2 text-sm text-blue-600 hover:text-blue-800">
              ← Back to Evolution Dashboard
            </a>
            <a href="/evolution/proposals?refresh=1" class="bg-indigo-600 hover:bg-indigo-700 px-4 py-2 text-white rounded inline-block mr-2">
              Refresh Proposals
            </a>
            <a href="/evolution/generate" class="bg-green-600 hover:bg-green-700 px-4 py-2 text-white rounded inline-block">
              Generate Proposal
            </a>
          </:actions>
        </.header>

        <div class="mt-8">
          <h2 class="text-lg font-medium text-gray-900">Pending Proposals</h2>
          
          <%= if @pending_proposals && length(@pending_proposals) > 0 do %>
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
                  <%= for proposal <- @pending_proposals do %>
                    <tr id={"proposal-#{proposal.id}"}>
                      <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-6">
                        <%= proposal.dsl_name %>
                      </td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                        <%= format_datetime(proposal.inserted_at) %>
                      </td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                        <span class={"inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium #{status_badge_class(proposal.status)}"}>
                          <%= humanize_status(proposal.status) %>
                        </span>
                      </td>
                      <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                        <div class="flex space-x-2">
                          <button phx-click="view_proposal" phx-value-id={proposal.id} class="text-indigo-600 hover:text-indigo-900">
                            View
                          </button>
                          <button phx-click="approve_proposal_modal" phx-value-id={proposal.id} class="text-green-600 hover:text-green-900">
                            Approve
                          </button>
                          <button phx-click="reject_proposal_modal" phx-value-id={proposal.id} class="text-red-600 hover:text-red-900">
                            Reject
                          </button>
                        </div>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% else %>
            <div class="mt-3 bg-white shadow overflow-hidden sm:rounded-md p-6 text-center text-gray-500">
              No pending proposals.
            </div>
          <% end %>
        </div>
      </div>
      """
      _ -> ~H"""
      <div class="py-6">
        <.header>
          ACE Dashboard
          <:subtitle>AI-powered code optimization and analysis</:subtitle>
          <:actions>
            <%= if @api_status.provider == "mock" do %>
              <div class="mr-4 flex items-center text-amber-600">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
                <span>Running in mock mode</span>
              </div>
            <% else %>
              <div class="mr-4 flex items-center text-green-600">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span>Using <%= String.capitalize(@api_status.provider) %> AI</span>
              </div>
            <% end %>
            <a href="/?analyze=1" class={"bg-indigo-600 hover:bg-indigo-700 px-4 py-2 text-white rounded inline-block #{if @analyzing, do: "opacity-50 cursor-not-allowed"}"}>
              <%= if @analyzing, do: "Analyzing...", else: "Start Analysis" %>
            </a>
          </:actions>
        </.header>

        <%= case @active_tab do %>
          <% :overview -> %>
            <div class="mt-6 grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
              <.card>
                <div class="flex items-center">
                  <div class="flex-shrink-0 rounded-md bg-blue-500 p-3">
                    <svg class="h-6 w-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
                    </svg>
                  </div>
                  <div class="ml-5 w-0 flex-1">
                    <dl>
                      <dt class="truncate text-sm font-medium text-gray-500">Analyses</dt>
                      <dd>
                        <div class="text-lg font-medium text-gray-900"><%= length(@analyses) %></div>
                      </dd>
                    </dl>
                  </div>
                </div>
              </.card>

              <.card>
                <div class="flex items-center">
                  <div class="flex-shrink-0 rounded-md bg-green-500 p-3">
                    <svg class="h-6 w-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
                    </svg>
                  </div>
                  <div class="ml-5 w-0 flex-1">
                    <dl>
                      <dt class="truncate text-sm font-medium text-gray-500">Opportunities</dt>
                      <dd>
                        <div class="text-lg font-medium text-gray-900"><%= length(@opportunities) %></div>
                      </dd>
                    </dl>
                  </div>
                </div>
              </.card>

              <.card>
                <div class="flex items-center">
                  <div class="flex-shrink-0 rounded-md bg-purple-500 p-3">
                    <svg class="h-6 w-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path>
                    </svg>
                  </div>
                  <div class="ml-5 w-0 flex-1">
                    <dl>
                      <dt class="truncate text-sm font-medium text-gray-500">Optimizations</dt>
                      <dd>
                        <div class="text-lg font-medium text-gray-900"><%= length(@optimizations) %></div>
                      </dd>
                    </dl>
                  </div>
                </div>
              </.card>
            </div>

            <!-- Additional dashboard content -->
            <div class="mt-6">
              <h2 class="text-lg font-medium text-gray-900">Recent Activities</h2>
              <div class="mt-3 overflow-hidden shadow ring-1 ring-black ring-opacity-5 sm:rounded-md">
                <table class="min-w-full divide-y divide-gray-300">
                  <thead class="bg-gray-50">
                    <tr>
                      <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6">Action</th>
                      <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Target</th>
                      <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Status</th>
                      <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Time</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-200 bg-white">
                    <%= for {action, target, status, time} <- @recent_activities do %>
                      <tr>
                        <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-6"><%= action %></td>
                        <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500"><%= target %></td>
                        <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                          <span class={status_class(status)}><%= status %></span>
                        </td>
                        <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500"><%= time %></td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>

          <% :files -> %>
            <div class="mt-6">
              <h2 class="text-lg font-medium text-gray-900">File Analysis</h2>
              <div class="mt-3 bg-white shadow sm:rounded-lg">
                <div class="px-4 py-5 sm:p-6">
                  <h3 class="text-base font-semibold leading-6 text-gray-900">File List</h3>
                  <div class="mt-4">
                    <ul role="list" class="divide-y divide-gray-200">
                      <%= for analysis <- @analyses do %>
                        <li class="flex py-4">
                          <div class="ml-3">
                            <p class="text-sm font-medium text-gray-900"><%= analysis.file_path %></p>
                            <p class="text-sm text-gray-500">Language: <%= analysis.language %></p>
                          </div>
                        </li>
                      <% end %>
                    </ul>
                  </div>
                </div>
              </div>
            </div>

          <% :opportunities -> %>
            <div class="mt-6">
              <h2 class="text-lg font-medium text-gray-900">Improvement Opportunities</h2>
              <div class="mt-3 bg-white shadow sm:rounded-lg">
                <div class="px-4 py-5 sm:p-6">
                  <ul role="list" class="divide-y divide-gray-200">
                    <%= if @opportunities && length(@opportunities) > 0 do %>
                      <%= for opportunity <- @opportunities do %>
                        <li class="flex py-4">
                          <div class="ml-3 w-full">
                            <div class="flex justify-between">
                              <p class="text-sm font-medium text-gray-900">
                                <%= opportunity.description %>
                              </p>
                              <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{severity_color(opportunity.severity)}"}>
                                <%= opportunity.severity %>
                              </span>
                            </div>
                            <p class="text-sm text-gray-500">Location: <%= opportunity.location %></p>
                            <p class="text-sm text-gray-500">Type: <%= opportunity.type %></p>
                            <p class="mt-1 text-sm text-gray-700"><%= opportunity.rationale %></p>
                            <p class="mt-1 text-sm text-indigo-600">Suggestion: <%= opportunity.suggested_change %></p>
                          </div>
                        </li>
                      <% end %>
                    <% else %>
                      <li class="py-4 text-center text-gray-500">
                        No opportunities found. Try analyzing some code first.
                      </li>
                    <% end %>
                  </ul>
                </div>
              </div>
            </div>

          <% :optimizations -> %>
            <div class="mt-6">
              <h2 class="text-lg font-medium text-gray-900">Optimizations</h2>
              <div class="mt-3 bg-white shadow sm:rounded-lg">
                <div class="px-4 py-5 sm:p-6">
                  <ul role="list" class="divide-y divide-gray-200">
                    <%= for optimization <- @optimizations do %>
                      <li class="flex py-4">
                        <div class="ml-3">
                          <p class="text-sm font-medium text-gray-900"><%= optimization.title || "Optimization" %></p>
                          <p class="text-sm text-gray-500"><%= optimization.description %></p>
                        </div>
                      </li>
                    <% end %>
                  </ul>
                </div>
              </div>
            </div>

          <% _ -> %>
            <div class="mt-6">
              <div class="rounded-md bg-blue-50 p-4">
                <div class="flex">
                  <div class="flex-shrink-0">
                    <svg class="h-5 w-5 text-blue-400" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
                    </svg>
                  </div>
                  <div class="ml-3 flex-1 md:flex md:justify-between">
                    <p class="text-sm text-blue-700">This is a demo interface. Content will be displayed here based on the selected view.</p>
                  </div>
                </div>
              </div>
            </div>
        <% end %>
      </div>
      """
    end
  end

  # Handle query parameters for regular link actions
  defp handle_query_params(socket, params) do
    socket = cond do
      # Handle analyze parameter for the Start Analysis button
      Map.has_key?(params, "analyze") ->
        handle_analyze_action(socket)
        
      # Handle refresh parameter for the Refresh Data button on evolution page
      Map.has_key?(params, "refresh") && socket.assigns.active_tab == :evolution ->
        assign_evolution_data(socket)
        
      # Handle refresh parameter for the Refresh Proposals button
      Map.has_key?(params, "refresh") && socket.assigns.active_tab == :evolution_proposals ->
        assign_proposal_data(socket)
        
      true ->
        socket
    end
    
    socket
  end
  
  # Handle the analyze action from the query parameter
  defp handle_analyze_action(socket) do
    # Create demo file if it doesn't exist
    demo_file_path = "demo_code/test_module.ex"
    ensure_demo_file_exists(demo_file_path)
    
    # Start analysis
    case Ace.Analysis.Service.analyze_file(demo_file_path, [
      language: "elixir",
      focus_areas: ["performance", "maintainability"],
      severity_threshold: "medium"
    ]) do
      {:ok, analysis} ->
        # Broadcast to PubSub
        Phoenix.PubSub.broadcast(Ace.PubSub, "ace:analyses", {:analysis_created, analysis})
        
        socket
        |> assign(:analyzing, true)
        |> put_flash(:info, "Analysis started for #{demo_file_path}")
        
      {:error, reason} ->
        socket
        |> put_flash(:error, "Analysis failed: #{reason}")
    end
  end

  # Get severity color class
  def severity_color(severity) do
    case severity do
      "high" -> "bg-red-100 text-red-800"
      "medium" -> "bg-yellow-100 text-yellow-800"
      "low" -> "bg-green-100 text-green-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  # Load real recent activities from the database
  defp load_recent_activities do
    # Get recent analyses
    analyses = Ace.Repo.all(
      from a in Ace.Core.Analysis,
        order_by: [desc: a.inserted_at],
        limit: 10,
        select: {a.file_path, a.completed_at, a.inserted_at}
    )
    
    # Get recent optimizations
    optimizations = Ace.Repo.all(
      from o in Ace.Core.Optimization,
        join: op in Ace.Core.Opportunity, on: o.opportunity_id == op.id,
        order_by: [desc: o.inserted_at],
        limit: 5,
        select: {op.description, o.status, o.inserted_at}
    )
    
    # Get recent evaluations
    evaluations = Ace.Repo.all(
      from e in Ace.Core.Evaluation,
        join: o in Ace.Core.Optimization, on: e.optimization_id == o.id,
        join: op in Ace.Core.Opportunity, on: o.opportunity_id == op.id,
        order_by: [desc: e.inserted_at],
        limit: 5,
        select: {op.description, e.success, e.inserted_at}
    )
    
    # Combine and format the activities
    analyses_activities = Enum.map(analyses, fn {file_path, completed_at, inserted_at} ->
      status = if completed_at, do: "Complete", else: "Pending"
      time_ago = time_ago(completed_at || inserted_at)
      {"Analysis", file_path, status, time_ago}
    end)
    
    optimization_activities = Enum.map(optimizations, fn {description, status, inserted_at} ->
      formatted_status = if status == "applied", do: "Complete", else: status
      {"Optimization", description, formatted_status, time_ago(inserted_at)}
    end)
    
    evaluation_activities = Enum.map(evaluations, fn {description, success, inserted_at} ->
      status = if success, do: "Complete", else: "Failed"
      {"Evaluation", description, status, time_ago(inserted_at)}
    end)
    
    # Combine all activities, sort by recency, and take the top 10
    (analyses_activities ++ optimization_activities ++ evaluation_activities)
    |> Enum.sort_by(fn {_, _, _, time} -> parse_time_ago(time) end)
    |> Enum.take(10)
  end
  
  # Helper to parse time_ago strings for sorting (lower values are more recent)
  defp parse_time_ago(time_string) do
    cond do
      String.contains?(time_string, "just now") -> 0
      String.contains?(time_string, "minute") -> 
        {num, _} = time_string |> String.replace(" minutes ago", "") |> String.replace(" minute ago", "") |> Integer.parse()
        num
      String.contains?(time_string, "hour") -> 
        {num, _} = time_string |> String.replace(" hours ago", "") |> String.replace(" hour ago", "") |> Integer.parse()
        num * 60
      String.contains?(time_string, "day") -> 
        {num, _} = time_string |> String.replace(" days ago", "") |> String.replace(" day ago", "") |> Integer.parse()
        num * 24 * 60
      String.contains?(time_string, "week") -> 
        {num, _} = time_string |> String.replace(" weeks ago", "") |> String.replace(" week ago", "") |> Integer.parse()
        num * 7 * 24 * 60
      String.contains?(time_string, "month") -> 
        {num, _} = time_string |> String.replace(" months ago", "") |> String.replace(" month ago", "") |> Integer.parse()
        num * 30 * 24 * 60
      true -> 999999 # Very old
    end
  end
  
  # Helper to format time difference as a human-readable string
  defp time_ago(datetime) do
    now = DateTime.utc_now()
    
    # Convert NaiveDateTime to DateTime if needed
    datetime_utc = case datetime do
      %DateTime{} -> datetime
      %NaiveDateTime{} -> 
        {:ok, dt} = DateTime.from_naive(datetime, "Etc/UTC")
        dt
      _ -> datetime  # Handle other cases, though this might not work properly
    end
    
    diff = DateTime.diff(now, datetime_utc, :second)
    
    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)} #{if div(diff, 60) == 1, do: "minute", else: "minutes"} ago"
      diff < 86400 -> "#{div(diff, 3600)} #{if div(diff, 3600) == 1, do: "hour", else: "hours"} ago"
      diff < 604800 -> "#{div(diff, 86400)} #{if div(diff, 86400) == 1, do: "day", else: "days"} ago"
      diff < 2592000 -> "#{div(diff, 604800)} #{if div(diff, 604800) == 1, do: "week", else: "weeks"} ago"
      true -> "#{div(diff, 2592000)} #{if div(diff, 2592000) == 1, do: "month", else: "months"} ago"
    end
  end

  # Helper to ensure assigns have default values for required keys
  defp ensure_assign(assigns, key, default) do
    if !Map.has_key?(assigns, key) do
      Map.put(assigns, key, default)
    else
      assigns
    end
  end

  # Determine the active tab based on the live action
  defp get_active_tab(live_action) do
    case live_action do
      :index -> :overview
      :projects -> :projects
      :files -> :files
      :opportunities -> :opportunities
      :optimizations -> :optimizations
      :evaluations -> :evaluations
      :evolution -> :evolution
      :evolution_proposals -> :evolution_proposals
      _ -> :overview
    end
  end
end