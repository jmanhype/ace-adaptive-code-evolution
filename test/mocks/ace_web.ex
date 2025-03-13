defmodule AceWeb do
  @moduledoc """
  Mock for AceWeb for testing.
  """
  defmacro __using__(which) when is_atom(which) do
    quote do
      # Empty mock
    end
  end
end