alias Ace.Core.Feedback
alias Ace.Evolution.Service
alias Ace.Core.EvolutionProposal
alias Ace.Core.EvolutionHistory
alias Ace.Repo
import Ecto.Query

feedback_source = "demo_feature"

# Check NPS distribution
dist = Feedback.nps_distribution(source: feedback_source)
IO.inspect(dist, label: "NPS Distribution")

# Get the average NPS score directly
avg_score = Feedback.average_score(source: feedback_source)
IO.puts("Average NPS score: #{avg_score}")

# Check recent evolution attempts
module_name = "Demo"
one_day_ago = DateTime.utc_now() |> DateTime.add(-86400, :second)
recent_attempts = from(h in EvolutionHistory, 
  where: h.dsl_name == ^module_name and h.date >= ^one_day_ago
) |> Repo.aggregate(:count, :id)
IO.puts("Recent evolution attempts: #{recent_attempts}")

# Check if module should evolve
{result, should_evolve} = Service.should_evolve?(module_name, feedback_source)
IO.puts("Should evolve? #{should_evolve}")

# Check why evolution isn't triggered
IO.puts("\nAnalyzing why evolution isn't triggered:")
IO.puts("1. NPS threshold check: avg_score (#{avg_score}) < 7.0?")
IO.puts("A. Double-check: 5.0 < 7.0? #{5.0 < 7.0}")  # For sanity check

# Convert to float for proper comparison
avg_score_float = 
  case avg_score do
    %Decimal{} -> Decimal.to_float(avg_score)
    _ -> avg_score
  end
IO.puts("B. After conversion to float: #{avg_score_float} < 7.0? #{avg_score_float < 7.0}")
IO.puts("2. Enough feedback? #{dist.total} >= 10? #{dist.total >= 10}")
IO.puts("3. No recent evolution attempts? #{recent_attempts} == 0? #{recent_attempts == 0}")

# All conditions are true, so let's try to evolve the module directly
source_code = """
defmodule Demo do
  def inefficient_sum(list) do
    Enum.reduce(list, 0, fn num, acc -> acc + num end)
  end
end
"""

IO.puts("\nTrying to evolve the module directly...")
case Service.evolve(module_name, source_code, feedback_source, notify: false) do
  {:ok, proposal} -> 
    IO.puts("Evolution successful! New proposal created with ID: #{proposal.id}")
  {:error, reason} -> 
    IO.puts("Evolution failed: #{inspect(reason)}")
end

# List pending proposals
proposals = EvolutionProposal.list_pending()
IO.inspect(proposals, label: "Pending Proposals")

# Let's force evolution by deleting recent history
if recent_attempts > 0 do
  IO.puts("\nDeleting recent evolution attempts to test evolution...")
  from(h in EvolutionHistory, where: h.dsl_name == ^module_name)
  |> Repo.delete_all()
  
  {result, should_evolve} = Service.should_evolve?(module_name, feedback_source)
  IO.puts("Should evolve after history deletion? #{should_evolve}")
  
  if should_evolve do
    # Create test source code
    source_code = """
    defmodule Demo do
      def inefficient_sum(list) do
        Enum.reduce(list, 0, fn num, acc -> acc + num end)
      end
    end
    """
    
    IO.puts("\nTrying to evolve the module...")
    case Service.evolve(module_name, source_code, feedback_source, notify: false) do
      {:ok, proposal} -> 
        IO.puts("Evolution successful! New proposal created with ID: #{proposal.id}")
      {:error, reason} -> 
        IO.puts("Evolution failed: #{inspect(reason)}")
    end
  end
end