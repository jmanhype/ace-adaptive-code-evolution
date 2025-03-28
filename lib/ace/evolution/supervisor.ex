defmodule Ace.Evolution.Supervisor do
  @moduledoc """
  Supervisor for evolution-related processes.
  """
  use Supervisor
  
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end
  
  @impl true
  def init(_args) do
    children = [
      # Scheduler for periodic evolution checks
      Ace.Evolution.Scheduler
    ]
    
    Supervisor.init(children, strategy: :one_for_one)
  end
end