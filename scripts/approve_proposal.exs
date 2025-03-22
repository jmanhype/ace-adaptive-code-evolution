alias Ace.Core.EvolutionProposal
alias Ace.Core.VersionControl

# List all pending proposals
proposals = EvolutionProposal.list_pending()

if length(proposals) == 0 do
  IO.puts("No pending proposals to approve.")
  System.halt(0)
end

# Display all pending proposals
IO.puts("Pending proposals:")
proposals
|> Enum.with_index(1)
|> Enum.each(fn {proposal, index} ->
  IO.puts("\n#{index}. Proposal ID: #{proposal.id}")
  IO.puts("   Module: #{proposal.dsl_name}")
  IO.puts("   Created: #{proposal.inserted_at}")
  IO.puts("\n   Code:")
  IO.puts("   ```")
  IO.puts("   #{String.replace(proposal.proposed_code, "\n", "\n   ")}")
  IO.puts("   ```")
end)

# Ask for which proposal to approve
proposal_index = case System.argv() do
  [index_str] -> 
    case Integer.parse(index_str) do
      {index, _} when index > 0 and index <= length(proposals) -> index
      _ -> 1  # Default to first proposal
    end
  _ -> 1  # Default to first proposal
end

# Get the selected proposal
proposal = Enum.at(proposals, proposal_index - 1)

IO.puts("\nApproving proposal #{proposal_index}: #{proposal.id}")

# Approve the proposal
reviewer_id = "cli-user"
comments = "Approved via CLI"

case EvolutionProposal.approve(proposal.id, reviewer_id, comments) do
  {:ok, approved_proposal} ->
    IO.puts("✅ Proposal approved successfully!")
    
    # Ask if we should apply the proposal
    IO.puts("\nDo you want to apply this proposal? (y/N)")
    apply_response = case System.argv() do
      [_, "y"] -> "y"
      [_, "Y"] -> "y"
      _ -> "n"  # Default to no
    end
    
    if apply_response == "y" do
      case EvolutionProposal.apply_proposal(approved_proposal.id) do
        {:ok, version} ->
          IO.puts("✅ Proposal applied successfully! Version: #{version}")
          
          # Show where the version is stored
          module_atom = String.to_existing_atom(approved_proposal.dsl_name)
          version_path = "lib/ace/generated/versions/#{approved_proposal.dsl_name}_#{version}.ex"
          IO.puts("\nApplied version stored at:")
          IO.puts(version_path)
          
          # Display the content of the version file if it exists
          if File.exists?(version_path) do
            IO.puts("\nGenerated code:")
            IO.puts(File.read!(version_path))
          end
          
        {:error, reason} ->
          IO.puts("❌ Failed to apply proposal: #{inspect(reason)}")
      end
    else
      IO.puts("Proposal approved but not applied.")
    end
    
  {:error, reason} ->
    IO.puts("❌ Failed to approve proposal: #{inspect(reason)}")
end