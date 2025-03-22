#!/usr/bin/env elixir

# This script checks for pending proposals and auto-applies them if autonomous_deploy is enabled
Mix.install([])

# Start the application
Application.put_env(:phoenix, :serve_endpoints, false, persistent: true)
Application.ensure_all_started(:ace)

alias Ace.Core.EvolutionProposal
alias Ace.Evolution.Service

# Get configuration
autonomous_deploy = Application.get_env(:ace, :autonomous_deploy, false)
IO.puts("Autonomous deploy enabled: #{autonomous_deploy}")

# Get pending proposals
pending_proposals = EvolutionProposal.list_pending()
IO.puts("Pending proposals count: #{length(pending_proposals)}")

if autonomous_deploy do
  for proposal <- pending_proposals do
    IO.puts("Auto-applying proposal #{proposal.id}...")
    case Service.auto_apply_proposal(proposal.id) do
      {:ok, proposal_id, version} ->
        IO.puts("Successfully applied proposal #{proposal_id} as version #{version}")
      {:error, reason} ->
        IO.puts("Failed to apply proposal #{proposal.id}: #{inspect(reason)}")
    end
  end
else
  IO.puts("Autonomous deploy is disabled. Set autonomous_deploy to true in config to auto-apply proposals.")
end

# Gracefully shutdown the application
Application.stop(:ace)
System.halt(0) 