defmodule Ace.Telemetry.Metrics do
  @moduledoc """
  In-memory metrics storage for ACE telemetry.
  """
  use GenServer

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Records a metric value with associated metadata.
  """
  def record(name, value, metadata) do
    GenServer.cast(__MODULE__, {:record, name, value, metadata, timestamp()})
  end

  @doc """
  Retrieves metric values for a specific metric name.
  """
  def get_metric(name, opts \\ []) do
    GenServer.call(__MODULE__, {:get_metric, name, opts})
  end

  @doc """
  Gets all available metrics.
  """
  def get_all_metrics do
    GenServer.call(__MODULE__, :get_all_metrics)
  end

  @doc """
  Gets a summary of all metrics.
  """
  def get_summary do
    GenServer.call(__MODULE__, :get_summary)
  end

  @doc """
  Clears all stored metrics.
  """
  def clear do
    GenServer.call(__MODULE__, :clear)
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    {:ok, %{metrics: %{}}}
  end

  @impl true
  def handle_cast({:record, name, value, metadata, timestamp}, state) do
    metrics = Map.update(
      state.metrics,
      name,
      [%{value: value, metadata: metadata, timestamp: timestamp}],
      fn existing -> [%{value: value, metadata: metadata, timestamp: timestamp} | existing] end
    )

    {:noreply, %{state | metrics: metrics}}
  end

  @impl true
  def handle_call({:get_metric, name, opts}, _from, state) do
    result = case Map.get(state.metrics, name) do
      nil -> []
      values ->
        values
        |> filter_by_time_range(opts[:since], opts[:until])
        |> filter_by_metadata(opts[:metadata])
    end

    {:reply, result, state}
  end

  @impl true
  def handle_call(:get_all_metrics, _from, state) do
    {:reply, state.metrics, state}
  end

  @impl true
  def handle_call(:get_summary, _from, state) do
    summary = Enum.map(state.metrics, fn {name, values} ->
      {name, summarize_values(values)}
    end)
    |> Map.new()

    {:reply, summary, state}
  end

  @impl true
  def handle_call(:clear, _from, _state) do
    {:reply, :ok, %{metrics: %{}}}
  end

  # Helper functions

  defp timestamp do
    DateTime.utc_now()
  end

  defp filter_by_time_range(values, nil, nil), do: values
  defp filter_by_time_range(values, since, nil) do
    Enum.filter(values, fn %{timestamp: ts} -> DateTime.compare(ts, since) in [:gt, :eq] end)
  end
  defp filter_by_time_range(values, nil, until) do
    Enum.filter(values, fn %{timestamp: ts} -> DateTime.compare(ts, until) in [:lt, :eq] end)
  end
  defp filter_by_time_range(values, since, until) do
    Enum.filter(values, fn %{timestamp: ts} -> 
      DateTime.compare(ts, since) in [:gt, :eq] && DateTime.compare(ts, until) in [:lt, :eq]
    end)
  end

  defp filter_by_metadata(values, nil), do: values
  defp filter_by_metadata(values, metadata) do
    Enum.filter(values, fn %{metadata: value_metadata} ->
      Enum.all?(metadata, fn {key, val} -> Map.get(value_metadata, key) == val end)
    end)
  end

  defp summarize_values(values) do
    numeric_values = Enum.filter(values, fn %{value: v} -> is_number(v) end)
    
    %{
      count: length(values),
      numeric_count: length(numeric_values),
      sum: Enum.reduce(numeric_values, 0, fn %{value: v}, acc -> acc + v end),
      avg: case numeric_values do
        [] -> nil
        nums -> Enum.reduce(nums, 0, fn %{value: v}, acc -> acc + v end) / length(nums)
      end,
      min: case numeric_values do
        [] -> nil
        nums -> Enum.min_by(nums, fn %{value: v} -> v end).value
      end,
      max: case numeric_values do
        [] -> nil
        nums -> Enum.max_by(nums, fn %{value: v} -> v end).value
      end,
      latest: case values do
        [] -> nil
        vals -> Enum.max_by(vals, fn %{timestamp: ts} -> ts end)
      end
    }
  end
end