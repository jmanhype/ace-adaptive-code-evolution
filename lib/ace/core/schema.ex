defmodule Ace.Schema do
  @moduledoc """
  Base schema module that all ACE schemas should use.
  Provides common functionality and fields.
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      import Ecto.Query
      
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end
end