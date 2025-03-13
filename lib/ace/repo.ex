defmodule Ace.Repo do
  @moduledoc """
  Ecto repository for Ace.
  
  Handles persistence for all database operations in the system.
  """
  use Ecto.Repo,
    otp_app: :ace,
    adapter: Ecto.Adapters.Postgres
end