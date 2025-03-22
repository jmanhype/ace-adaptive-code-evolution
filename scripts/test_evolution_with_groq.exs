alias Ace.Core.Feedback
alias Ace.Evolution.Service
alias Ace.Core.EvolutionProposal
alias Ace.Core.EvolutionHistory
alias Ace.Repo
import Ecto.Query

# Check if Groq is configured correctly
groq_key = System.get_env("GROQ_API_KEY")
IO.puts("Using Groq API: #{groq_key != nil}")

feedback_source = "demo_feature"
module_name = "Demo"

# Get NPS information
nps = Feedback.nps_distribution(source: feedback_source)
avg_score = Feedback.average_score(source: feedback_source)
IO.puts("Average NPS score: #{avg_score} | NPS score: #{nps.nps_score}")

# Check if module should evolve
{_, should_evolve} = Service.should_evolve?(module_name, feedback_source)
IO.puts("Should evolve? #{should_evolve}")

# Create demo source code
source_code = """
defmodule Demo do
  def inefficient_sum(list) do
    Enum.reduce(list, 0, fn num, acc -> acc + num end)
  end
end
"""

# Try to evolve with Groq
IO.puts("\nTrying to evolve the module using Groq...")
case Service.evolve(module_name, source_code, feedback_source, notify: false) do
  {:ok, proposal} -> 
    IO.puts("🎉 Evolution successful! New proposal created with ID: #{proposal.id}")
    IO.puts("\nOptimized code:")
    IO.puts("==============")
    IO.puts(proposal.proposed_code)
    IO.puts("==============")
  {:error, reason} -> 
    IO.puts("❌ Evolution failed: #{inspect(reason)}")
end

# List all pending proposals
proposals = EvolutionProposal.list_pending()
IO.puts("\nTotal pending proposals: #{length(proposals)}")