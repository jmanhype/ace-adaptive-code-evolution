defmodule AceWeb.RawBodyPlug do
  @moduledoc """
  Plug to capture the raw request body before it's parsed.
  This is needed for validating GitHub webhook signatures.
  """
  
  @behaviour Plug
  import Plug.Conn
  
  def init(opts), do: opts
  
  def call(conn, _opts) do
    {:ok, body, conn} = read_body(conn)
    assign(conn, :raw_body, body)
  end
end 