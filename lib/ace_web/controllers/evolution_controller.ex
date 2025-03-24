defmodule AceWeb.EvolutionController do
  use AceWeb, :controller
  
  @doc """
  Generates a test evolution proposal and redirects to the proposals page.
  """
  def generate_proposal(conn, _params) do
    # Generate a test module for evolution
    test_module_name = "Elixir.Test.Module#{:rand.uniform(100)}"
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
      {:ok, _proposal} ->
        conn
        |> put_flash(:info, "Created evolution proposal for #{test_module_name}")
        |> redirect(to: "/evolution/proposals")
        
      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to create evolution proposal: #{inspect(reason)}")
        |> redirect(to: "/evolution/proposals")
    end
  end
end 