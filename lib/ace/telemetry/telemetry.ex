defmodule Ace.Telemetry do
  @moduledoc """
  Telemetry system for ACE.
  """
  require Logger

  @doc """
  Sets up telemetry event handlers.
  Should be called during application startup.
  """
  def setup do
    events = [
      [:ace, :analysis, :start],
      [:ace, :analysis, :stop],
      [:ace, :analysis, :error],
      [:ace, :optimization, :start],
      [:ace, :optimization, :stop],
      [:ace, :optimization, :error],
      [:ace, :evaluation, :start],
      [:ace, :evaluation, :stop],
      [:ace, :evaluation, :error],
      [:ace, :ai, :analyze_code, :start],
      [:ace, :ai, :analyze_code, :stop],
      [:ace, :ai, :analyze_code, :error],
      [:ace, :ai, :generate_optimization, :start],
      [:ace, :ai, :generate_optimization, :stop],
      [:ace, :ai, :generate_optimization, :error],
      [:ace, :ai, :evaluate_optimization, :start],
      [:ace, :ai, :evaluate_optimization, :stop],
      [:ace, :ai, :evaluate_optimization, :error]
    ]

    :telemetry.attach_many(
      "ace-telemetry-handler",
      events,
      &Ace.Telemetry.handle_event/4,
      nil
    )
  end

  @doc """
  Handles telemetry events.
  """
  def handle_event([:ace, component, :start], measurements, metadata, _config) do
    Logger.debug("#{component} started", measurements: measurements, metadata: metadata)

    # Store start time for duration calculation
    Process.put({:ace_telemetry, component, metadata[:id]}, :os.system_time(:millisecond))
  end

  def handle_event([:ace, component, :stop], measurements, metadata, _config) do
    start_time = Process.get({:ace_telemetry, component, metadata[:id]})
    duration = if start_time, do: :os.system_time(:millisecond) - start_time, else: nil

    Logger.info("#{component} completed", 
      measurements: Map.put(measurements, :duration_ms, duration),
      metadata: metadata
    )

    # Store metrics
    store_metric("#{component}_duration", duration, Map.put(metadata, :success, true))
  end

  def handle_event([:ace, component, :error], measurements, metadata, _config) do
    start_time = Process.get({:ace_telemetry, component, metadata[:id]})
    duration = if start_time, do: :os.system_time(:millisecond) - start_time, else: nil

    Logger.error("#{component} failed", 
      measurements: Map.put(measurements, :duration_ms, duration),
      metadata: metadata,
      error: metadata[:error]
    )

    # Store error metrics
    store_metric("#{component}_error", 1, Map.merge(metadata, %{
      error: metadata[:error] || "unknown",
      duration_ms: duration
    }))
  end

  def handle_event([:ace, :ai, operation, :start], measurements, metadata, _config) do
    Logger.debug("AI operation #{operation} started", measurements: measurements, metadata: metadata)

    # Store start time for duration calculation
    Process.put({:ace_telemetry, "ai_#{operation}", metadata[:id]}, :os.system_time(:millisecond))
  end

  def handle_event([:ace, :ai, operation, :stop], measurements, metadata, _config) do
    key = "ai_#{operation}"
    start_time = Process.get({:ace_telemetry, key, metadata[:id]})
    duration = if start_time, do: :os.system_time(:millisecond) - start_time, else: nil

    Logger.info("AI operation #{operation} completed", 
      measurements: Map.put(measurements, :duration_ms, duration),
      metadata: metadata
    )

    # Store metrics
    store_metric("#{key}_duration", duration, Map.put(metadata, :success, true))

    # Store AI specific metrics if available
    if model = metadata[:model] do
      store_metric("ai_model_usage", 1, %{
        operation: operation,
        model: model,
        duration_ms: duration
      })
    end
  end

  def handle_event([:ace, :ai, operation, :error], measurements, metadata, _config) do
    key = "ai_#{operation}"
    start_time = Process.get({:ace_telemetry, key, metadata[:id]})
    duration = if start_time, do: :os.system_time(:millisecond) - start_time, else: nil

    Logger.error("AI operation #{operation} failed", 
      measurements: Map.put(measurements, :duration_ms, duration),
      metadata: metadata,
      error: metadata[:error]
    )

    # Store error metrics
    store_metric("#{key}_error", 1, Map.merge(metadata, %{
      error: metadata[:error] || "unknown",
      duration_ms: duration
    }))

    # Store AI failure metrics if model available
    if model = metadata[:model] do
      store_metric("ai_model_error", 1, %{
        operation: operation,
        model: model,
        error: metadata[:error] || "unknown"
      })
    end
  end

  # Store metric in the configured backend
  defp store_metric(name, value, metadata) do
    # Store in memory for now, but could be extended to store in a proper metrics backend
    Ace.Telemetry.Metrics.record(name, value, metadata)

    # Emit telemetry event for potential external consumers
    :telemetry.execute(
      [:ace, :metric, String.to_atom(name)],
      %{value: value},
      metadata
    )
  end
end