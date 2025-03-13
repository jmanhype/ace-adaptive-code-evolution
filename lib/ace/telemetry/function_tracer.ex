defmodule Ace.Telemetry.FunctionTracer do
  @moduledoc """
  Provides function tracing macros for telemetry.
  """

  @doc """
  Defines a function with telemetry tracing.
  
  This macro wraps a function definition with telemetry events that track:
  - When the function starts
  - When the function completes successfully
  - When the function fails with an error
  
  The events include timing information and relevant metadata.
  
  ## Example
  
  ```
  defmodule MyModule do
    import Ace.Telemetry.FunctionTracer
    
    deftrace my_function(arg1, arg2) do
      # Function implementation
      arg1 + arg2
    end
  end
  ```
  """
  defmacro deftrace(head, body) do
    {name, args} = Macro.decompose_call(head)
    
    quote do
      def unquote(head) do
        operation = unquote(name)
        component = __MODULE__ |> Module.split() |> Enum.at(1) |> String.downcase()
        id = generate_operation_id()
        metadata = %{
          id: id, 
          function: operation,
          module: __MODULE__,
          args: unquote(args) |> Enum.map(&sanitize_arg/1)
        }
        
        :telemetry.execute(
          [:ace, String.to_atom(component), :start],
          %{system_time: System.system_time()},
          metadata
        )
        
        try do
          result = unquote(body[:do])
          
          :telemetry.execute(
            [:ace, String.to_atom(component), :stop],
            %{system_time: System.system_time()},
            Map.put(metadata, :result, :success)
          )
          
          result
        rescue
          error ->
            :telemetry.execute(
              [:ace, String.to_atom(component), :error],
              %{system_time: System.system_time()},
              Map.merge(metadata, %{
                result: :error,
                error: Exception.message(error),
                error_type: Map.get(error, :__struct__),
                stacktrace: __STACKTRACE__
              })
            )
            
            reraise error, __STACKTRACE__
        end
      end
    end
  end
  
  @doc false
  def generate_operation_id do
    Base.encode16(:crypto.strong_rand_bytes(8), case: :lower)
  end
  
  @doc false
  def sanitize_arg(arg) when is_binary(arg) and byte_size(arg) > 50 do
    "#{binary_part(arg, 0, 47)}..."
  end
  def sanitize_arg(arg) when is_list(arg) and length(arg) > 10 do
    Enum.take(arg, 10) ++ ["..."]
  end
  def sanitize_arg(arg) when is_map(arg) and map_size(arg) > 10 do
    arg
    |> Enum.take(10)
    |> Map.new()
    |> Map.put(:truncated, "...")
  end
  def sanitize_arg(arg), do: arg
end