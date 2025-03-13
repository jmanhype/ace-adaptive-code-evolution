defmodule AceWeb.AceChannel do
  @moduledoc """
  Channel for ACE-related real-time updates.
  """
  use Phoenix.Channel

  @impl true
  def join("ace:" <> _topic, _message, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_in("ping", %{"count" => count}, socket) do
    {:reply, {:ok, %{count: count}}, socket}
  end

  @impl true
  def handle_in(_event, _payload, socket) do
    {:noreply, socket}
  end
end