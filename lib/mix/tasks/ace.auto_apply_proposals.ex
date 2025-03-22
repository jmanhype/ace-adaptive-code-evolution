defmodule Mix.Tasks.Ace.AutoApplyProposals do
  @moduledoc """
  Mix task to automatically apply pending evolution proposals.

  This task checks for pending proposals and auto-applies them if autonomous_deploy is enabled.
  """
  use Mix.Task
  
  @shortdoc "Auto-applies pending evolution proposals"
  
  @doc """
  Run the task to auto-apply pending proposals.
  """
  def run(_) do
    # Ensure the application is started
    Mix.Task.run("app.start")
    
    alias Ace.Core.EvolutionProposal
    alias Ace.Evolution.Service
    
    # Get configuration
    autonomous_deploy = Application.get_env(:ace, :autonomous_deploy, false)
    Mix.shell().info("Autonomous deploy enabled: #{autonomous_deploy}")
    
    # Get pending proposals
    pending_proposals = EvolutionProposal.list_pending()
    Mix.shell().info("Pending proposals count: #{length(pending_proposals)}")
    
    if autonomous_deploy do
      for proposal <- pending_proposals do
        Mix.shell().info("Auto-applying proposal #{proposal.id}...")
        case Service.auto_apply_proposal(proposal.id) do
          {:ok, %{version: version, proposal_id: proposal_id}} ->
            Mix.shell().info("Successfully applied proposal #{proposal_id} as version #{version}")
          {:ok, proposal_id, version} ->
            Mix.shell().info("Successfully applied proposal #{proposal_id} as version #{version}")
          {:error, reason} ->
            Mix.shell().info("Failed to apply proposal #{proposal.id}: #{inspect(reason)}")
        end
      end
    else
      Mix.shell().info("Autonomous deploy is disabled. Set autonomous_deploy to true in config to auto-apply proposals.")
    end
  end
end 