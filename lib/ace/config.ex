defmodule Ace.Config do
  @moduledoc """
  Configuration management for ACE system.
  
  Handles loading and accessing configuration from multiple sources with precedence:
  1. Environment variables (highest priority)
  2. Project-specific YAML configuration files (.ace.yaml)
  3. Global configuration files (~/.ace/config.yaml, /etc/ace/config.yaml)
  4. Default values (lowest priority)
  
  This layered approach allows for flexible configuration in different environments
  while maintaining separation of concerns between global, project, and runtime settings.
  """
  
  @config_file ".ace.yaml"
  @global_config_paths [
    "~/.ace/config.yaml",
    "/etc/ace/config.yaml"
  ]
  
  @doc """
  Gets a configuration value from the merged configuration.
  
  ## Parameters
  
    - `key`: A string, atom, or list representing the path to the config value
      (e.g., "ai_provider", :ai_provider, or ["ai_provider"])
    - `default`: The default value to return if the key is not found
  
  ## Examples
  
      iex> Ace.Config.get("ai_provider")
      "groq"
      
      iex> Ace.Config.get("api_keys.groq")
      "api-key-value"
      
      iex> Ace.Config.get(["database", "url"], "postgres://localhost/ace")
      "postgres://localhost/ace"
  """
  def get(key, default \\ nil) do
    merged_config()
    |> get_in(split_key(key))
    |> case do
      nil -> default
      value -> value
    end
  end
  
  @doc """
  Gets all configuration as a map.
  """
  def get_all do
    merged_config()
  end
  
  @doc """
  Loads configuration for a specific path.
  
  Will look for a .ace.yaml file in the given directory and all its parent directories,
  then merge them with global configuration and environment variables.
  
  ## Parameters
  
    - `path`: The path to start searching from
  
  ## Returns
  
    - The merged configuration map
  """
  def load_for_path(path) do
    find_config_in_path(path)
    |> Enum.reduce(%{}, fn config_path, acc ->
      load_yaml_file(config_path)
      |> deep_merge(acc)
    end)
    |> deep_merge(global_config())
    |> deep_merge(env_config())
  end
  
  @doc """
  Reloads the configuration from all sources.
  
  This is useful when configuration files have changed or when
  environment variables have been updated.
  """
  def reload do
    # Clear any cached config
    Application.put_env(:ace, :config_cache, nil)
    # Return the newly loaded config
    merged_config()
  end
  
  # Get the merged configuration from all sources, with precedence:
  # env vars > project config > global config > defaults
  defp merged_config do
    # Check if we have a cached config
    case Application.get_env(:ace, :config_cache) do
      nil ->
        # Build the config hierarchy
        config = 
          default_config()
          |> deep_merge(global_config())
          |> deep_merge(project_config())
          |> deep_merge(env_config())
        
        # Cache the result
        Application.put_env(:ace, :config_cache, config)
        config
      
      cached -> cached
    end
  end
  
  # Get default configuration - baseline settings
  defp default_config do
    %{
      "ai_provider" => "groq",
      "ai_model" => "llama3-70b-8192",
      "default_focus_areas" => ["performance", "maintainability"],
      "default_severity_threshold" => "medium",
      "default_strategy" => "auto",
      "auto_apply" => false,
      "default_format" => "text",
      "database" => %{
        "pool_size" => 10,
        "ssl" => false
      },
      "server" => %{
        "port" => 4000,
        "host" => "localhost"
      },
      "telemetry" => %{
        "enabled" => true,
        "metrics_interval" => 15000
      }
    }
  end
  
  # Get configuration from environment variables
  defp env_config do
    # Map of environment variables to config keys
    env_mappings = [
      {"ACE_AI_PROVIDER", ["ai_provider"]},
      {"ACE_AI_MODEL", ["ai_model"]},
      {"ACE_DEFAULT_FOCUS_AREAS", ["default_focus_areas"]},
      {"ACE_DEFAULT_SEVERITY_THRESHOLD", ["default_severity_threshold"]},
      {"ACE_DEFAULT_STRATEGY", ["default_strategy"]},
      {"ACE_AUTO_APPLY", ["auto_apply"]},
      {"ACE_DEFAULT_FORMAT", ["default_format"]},
      {"ACE_SERVER_PORT", ["server", "port"]},
      {"ACE_SERVER_HOST", ["server", "host"]},
      {"ACE_DATABASE_URL", ["database", "url"]},
      {"ACE_DATABASE_POOL_SIZE", ["database", "pool_size"]},
      {"ACE_DATABASE_SSL", ["database", "ssl"]},
      {"ACE_TELEMETRY_ENABLED", ["telemetry", "enabled"]},
      {"ACE_TELEMETRY_METRICS_INTERVAL", ["telemetry", "metrics_interval"]},
      # API keys for various providers
      {"GROQ_API_KEY", ["api_keys", "groq"]},
      {"OPENAI_API_KEY", ["api_keys", "openai"]},
      {"ANTHROPIC_API_KEY", ["api_keys", "anthropic"]},
      {"COHERE_API_KEY", ["api_keys", "cohere"]}
    ]
    
    # Build config from environment variables
    Enum.reduce(env_mappings, %{}, fn {env_var, config_path}, acc ->
      case System.get_env(env_var) do
        nil -> acc
        value -> put_in_nested(acc, config_path, parse_env_value(value))
      end
    end)
  end
  
  # Parse environment variable values with appropriate type conversion
  defp parse_env_value(value) do
    cond do
      # Boolean values
      value == "true" -> true
      value == "false" -> false
      # Integer values
      Regex.match?(~r/^\d+$/, value) -> String.to_integer(value)
      # Float values
      Regex.match?(~r/^\d+\.\d+$/, value) -> String.to_float(value)
      # Array values (comma-separated)
      String.contains?(value, ",") -> String.split(value, ",") |> Enum.map(&String.trim/1)
      # Default: string value
      true -> value
    end
  end
  
  # Get configuration from global config files
  defp global_config do
    @global_config_paths
    |> Enum.map(&Path.expand/1)
    |> Enum.filter(&File.exists?/1)
    |> Enum.reduce(%{}, fn path, acc ->
      deep_merge(load_yaml_file(path), acc)
    end)
  end
  
  # Get configuration from project config file
  defp project_config do
    case find_config_in_path(File.cwd!()) do
      [] -> %{}
      paths ->
        paths
        |> Enum.reduce(%{}, fn path, acc ->
          deep_merge(load_yaml_file(path), acc)
        end)
    end
  end
  
  # Find .ace.yaml files in a path and its parents
  defp find_config_in_path(path) do
    find_config_in_path(path, [])
  end
  
  defp find_config_in_path(path, acc) do
    config_path = Path.join(path, @config_file)
    new_acc = if File.exists?(config_path), do: [config_path | acc], else: acc
    
    parent = Path.dirname(path)
    if parent == path do
      # We've reached the root directory
      Enum.reverse(new_acc)
    else
      find_config_in_path(parent, new_acc)
    end
  end
  
  # Load a YAML file and parse it
  defp load_yaml_file(path) do
    with {:ok, content} <- File.read(path) do
      case Application.ensure_all_started(:yaml_elixir) do
        {:ok, _} ->
          try do
            {:ok, yaml} = apply(YamlElixir, :read_from_string, [content])
            yaml || %{}
          rescue
            _ -> %{}
          end
        _ ->
          # YamlElixir not available, return empty map
          %{}
      end
    else
      _ -> %{}
    end
  end
  
  # Merge two maps deeply, with right values taking precedence
  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _k, left_val, right_val ->
      if is_map(left_val) and is_map(right_val) do
        deep_merge(left_val, right_val)
      else
        right_val
      end
    end)
  end
  
  # Handle the case where one side isn't a map
  defp deep_merge(_left, right), do: right
  
  # Split a dot-separated key string into a list
  defp split_key(key) when is_binary(key), do: String.split(key, ".")
  defp split_key(key) when is_atom(key), do: split_key(Atom.to_string(key))
  defp split_key(key) when is_list(key), do: key
  
  # Put a value in a nested map, creating intermediate maps as needed
  defp put_in_nested(map, [key], value) when is_map(map), do: Map.put(map, key, value)
  defp put_in_nested(map, [key | rest], value) when is_map(map) do
    Map.put(map, key, put_in_nested(Map.get(map, key, %{}), rest, value))
  end
  defp put_in_nested(_non_map, keys, value), do: put_in_nested(%{}, keys, value)
end