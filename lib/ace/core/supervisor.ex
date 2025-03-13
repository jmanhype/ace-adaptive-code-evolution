defmodule Ace.Core.Supervisor do
  @moduledoc """
  Supervisor for core ACE components.
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      # Core components would be supervised here
      # No real children needed for our minimal setup
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end