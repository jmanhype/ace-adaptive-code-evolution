defmodule Ace.PubSub do
  @moduledoc """
  PubSub module for ACE to handle real-time updates and notifications.
  
  This is a simple implementation for testing purposes.
  """
  
  @doc """
  Returns the node name for PubSub.
  """
  def node_name do
    Node.self()
  end
  
  @doc """
  Broadcasts a message to subscribers.
  """
  def broadcast(topic, message) do
    Phoenix.PubSub.broadcast(Ace.PubSub, topic, message)
  end
  
  @doc """
  Broadcasts a message to subscribers on all nodes.
  """
  def broadcast_from(from_pid, topic, message) do
    Phoenix.PubSub.broadcast_from(Ace.PubSub, from_pid, topic, message)
  end
  
  @doc """
  Subscribes the caller to the given topic.
  """
  def subscribe(topic) do
    Phoenix.PubSub.subscribe(Ace.PubSub, topic)
  end
  
  @doc """
  Unsubscribes the caller from the given topic.
  """
  def unsubscribe(topic) do
    Phoenix.PubSub.unsubscribe(Ace.PubSub, topic)
  end
end