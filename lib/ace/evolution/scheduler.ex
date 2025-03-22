defmodule Ace.Evolution.Scheduler do
  @moduledoc """
  Manages scheduled evolution checks and autonomous optimization.
  """
  use GenServer
  require Logger
  alias Ace.Evolution.Service
  alias Ace.Core.EvolutionProposal
  
  @default_interval 86_400_000  # 24 hours in milliseconds
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def schedule_evolution_check(modules_config) do
    GenServer.cast(__MODULE__, {:schedule_check, modules_config})
  end
  
  def schedule_evolution_check(modules_config, delay) when is_integer(delay) do
    GenServer.cast(__MODULE__, {:schedule_check, modules_config, delay})
  end
  
  def cancel_scheduled_check() do
    GenServer.cast(__MODULE__, :cancel_check)
  end
  
  def process_pending_proposals() do
    GenServer.cast(__MODULE__, :process_pending_proposals)
  end
  
  # Server Callbacks
  
  def init(opts) do
    # Check if self-evolution is enabled
    evolution_enabled = Application.get_env(:ace, :self_evolution_enabled, false)
    
    # Get configured modules for auto-evolution
    modules_config = Application.get_env(:ace, :evolution_modules, [])
    
    # Get check interval
    check_interval = Application.get_env(:ace, :evolution_check_interval, @default_interval)
    
    state = %{
      timer_ref: nil,
      modules_config: modules_config,
      check_interval: check_interval,
      evolution_enabled: evolution_enabled
    }
    
    # Start automatic checking if enabled and modules are configured
    if evolution_enabled && Enum.any?(modules_config) do
      # Process any pending proposals right away
      process_pending_proposals_impl()
      
      {:ok, schedule_check(state)}
    else
      {:ok, state}
    end
  end
  
  def handle_cast({:schedule_check, modules_config}, state) do
    # Cancel any existing timer
    if state.timer_ref, do: Process.cancel_timer(state.timer_ref)
    
    # Schedule check with new modules config
    new_state = %{state | modules_config: modules_config}
    |> schedule_check()
    
    {:noreply, new_state}
  end
  
  def handle_cast({:schedule_check, modules_config, delay}, state) do
    # Cancel any existing timer
    if state.timer_ref, do: Process.cancel_timer(state.timer_ref)
    
    # Schedule immediate check
    timer_ref = Process.send_after(self(), :check_evolution, delay)
    
    new_state = %{state | modules_config: modules_config, timer_ref: timer_ref}
    
    {:noreply, new_state}
  end
  
  def handle_cast(:cancel_check, state) do
    # Cancel any existing timer
    if state.timer_ref, do: Process.cancel_timer(state.timer_ref)
    
    {:noreply, %{state | timer_ref: nil}}
  end
  
  def handle_cast(:process_pending_proposals, state) do
    # Process any pending proposals
    process_pending_proposals_impl()
    
    {:noreply, state}
  end
  
  def handle_info(:check_evolution, state) do
    # Only proceed if evolution is enabled
    new_state = if state.evolution_enabled do
      try do
        # Check and evolve modules based on feedback
        Logger.info("Running scheduled evolution check for #{length(state.modules_config)} modules")
        
        case Service.auto_evolve(state.modules_config) do
          {:ok, results} ->
            log_evolution_results(results)
            # Process any pending proposals
            process_pending_proposals_impl()
          {:error, reason} ->
            Logger.error("Failed to run auto-evolution: #{inspect(reason)}")
        end
      rescue
        e ->
          Logger.error("Error during scheduled evolution check: #{Exception.message(e)}")
          Logger.error(Exception.format_stacktrace())
      end
      
      # Schedule next check regardless of success/failure
      schedule_check(state)
    else
      # Evolution is disabled, don't reschedule
      %{state | timer_ref: nil}
    end
    
    {:noreply, new_state}
  end
  
  # Private helpers
  
  defp schedule_check(state) do
    Logger.debug("Scheduling next evolution check in #{div(state.check_interval, 60_000)} minutes")
    timer_ref = Process.send_after(self(), :check_evolution, state.check_interval)
    %{state | timer_ref: timer_ref}
  end
  
  defp log_evolution_results(results) do
    # Count successes and fails
    counts = Enum.reduce(results, %{evolved: 0, skipped: 0, failed: 0}, fn
      {:ok, %{proposal_id: _}}, acc -> %{acc | evolved: acc.evolved + 1}
      {:ok, %{status: :skipped}}, acc -> %{acc | skipped: acc.skipped + 1}
      {:error, _}, acc -> %{acc | failed: acc.failed + 1}
    end)
    
    # Log summary
    Logger.info("Evolution check completed: " <>
      "#{counts.evolved} modules evolved, " <>
      "#{counts.skipped} modules skipped, " <>
      "#{counts.failed} modules failed")
    
    # Log details for evolved modules
    Enum.each(results, fn
      {:ok, %{module: module, proposal_id: proposal_id}} ->
        Logger.info("Created evolution proposal #{proposal_id} for #{module}")
      {:error, %{module: module, reason: reason}} -> 
        Logger.warning("Failed to evolve #{module}: #{inspect(reason)}")
      _ -> 
        :ok
    end)
  end
  
  defp process_pending_proposals_impl() do
    # Check if autonomous deployment is enabled
    autonomous_deploy = Application.get_env(:ace, :autonomous_deploy, false)
    
    if autonomous_deploy do
      # Get all pending proposals
      pending_proposals = EvolutionProposal.list_pending()
      
      Logger.info("Auto-processing #{length(pending_proposals)} pending proposals")
      
      # Auto-approve and auto-apply each pending proposal
      Enum.each(pending_proposals, fn proposal ->
        try do
          # Auto-approve and apply the proposal
          case Service.auto_apply_proposal(proposal.id) do
            {:ok, result} ->
              Logger.info("Auto-applied proposal #{proposal.id} for #{proposal.dsl_name}, version: #{result.version}")
            {:error, reason} ->
              Logger.error("Failed to auto-apply proposal #{proposal.id}: #{inspect(reason)}")
          end
        rescue
          e ->
            Logger.error("Error processing proposal #{proposal.id}: #{Exception.message(e)}")
        end
      end)
    else
      Logger.debug("Autonomous deployment is disabled, skipping proposal processing")
    end
  end
end