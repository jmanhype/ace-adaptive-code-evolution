defmodule Ace.Core.VersionControl do
  @moduledoc """
  Handles versioning and storage of generated code implementations.
  """
  require Logger
  
  @versions_dir "lib/ace/generated/versions"
  
  @doc """
  Saves a new version of a module's implementation.
  
  ## Parameters
    
    - `module_name`: Name of the module as an atom
    - `code`: The new implementation code
  
  ## Returns
  
    - `{:ok, version}`: The version string for the saved code
    - `{:error, reason}`: If saving the version fails
  """
  def save_new_version(module_name, code) when is_atom(module_name) do
    # Ensure versions directory exists
    File.mkdir_p!(@versions_dir)
    
    # Generate version string
    version = generate_version()
    
    # Format module name for filename
    module_string = Atom.to_string(module_name)
    
    # Build filename
    filename = Path.join(@versions_dir, "#{module_string}_#{version}.ex")
    
    # Save the file
    case File.write(filename, code) do
      :ok -> 
        Logger.info("Saved new version #{version} for #{module_string}")
        {:ok, version}
      {:error, reason} -> 
        Logger.error("Failed to save new version for #{module_string}: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  @doc """
  Gets the content of a specific version.
  
  ## Parameters
    
    - `module_name`: Name of the module as an atom
    - `version`: The version string
  
  ## Returns
  
    - `{:ok, code}`: The code for the requested version
    - `{:error, :not_found}`: If the version doesn't exist
    - `{:error, reason}`: If reading the version fails
  """
  def get_version(module_name, version) when is_atom(module_name) do
    module_string = Atom.to_string(module_name)
    filename = Path.join(@versions_dir, "#{module_string}_#{version}.ex")
    
    case File.read(filename) do
      {:ok, content} -> {:ok, content}
      {:error, :enoent} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Lists all versions for a given module.
  
  ## Parameters
    
    - `module_name`: Name of the module as an atom
  
  ## Returns
  
    - `{:ok, versions}`: List of version strings, sorted by creation time
    - `{:error, reason}`: If reading the versions fails
  """
  def list_versions(module_name) when is_atom(module_name) do
    module_string = Atom.to_string(module_name)
    pattern = Path.join(@versions_dir, "#{module_string}_*.ex")
    
    case File.ls(@versions_dir) do
      {:ok, files} ->
        # Filter files for this module and extract versions
        versions = files
        |> Enum.filter(fn file -> 
          String.starts_with?(file, "#{module_string}_") && String.ends_with?(file, ".ex")
        end)
        |> Enum.map(fn file ->
          # Extract version from filename
          file
          |> String.replace("#{module_string}_", "")
          |> String.replace(".ex", "")
        end)
        |> Enum.sort_by(fn version ->
          # Parse timestamp from version
          case Integer.parse(version) do
            {timestamp, _} -> timestamp
            :error -> 0
          end
        end, :desc)
        
        {:ok, versions}
        
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Applies a specific version as the active implementation.
  
  ## Parameters
    
    - `module_name`: Name of the module as an atom
    - `version`: The version string to apply
    - `file_path`: Optional file path to write to, defaults to module path
  
  ## Returns
  
    - `:ok`: If the version was applied successfully
    - `{:error, :not_found}`: If the version doesn't exist
    - `{:error, reason}`: If applying the version fails
  """
  def apply_version(module_name, version, file_path \\ nil) when is_atom(module_name) do
    # Get the version content
    with {:ok, code} <- get_version(module_name, version) do
      # Determine destination file path
      target_path = if file_path do
        file_path
      else
        module_to_path(module_name)
      end
      
      # Ensure the parent directory exists
      target_dir = Path.dirname(target_path)
      File.mkdir_p!(target_dir)
      
      # Backup existing file if it exists
      if File.exists?(target_path) do
        backup_path = "#{target_path}.bak.#{System.system_time(:second)}"
        File.copy(target_path, backup_path)
      end
      
      # Write the new version
      case File.write(target_path, code) do
        :ok -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  end
  
  # Private helpers
  
  defp generate_version do
    # Use current Unix timestamp as version
    Integer.to_string(System.system_time(:second))
  end
  
  defp module_to_path(module) when is_atom(module) do
    # Convert module name to path
    # e.g., MyApp.User -> lib/my_app/user.ex
    module
    |> Atom.to_string()
    |> String.replace("Elixir.", "")
    |> String.split(".")
    |> Enum.map(&Macro.underscore/1)
    |> (fn parts ->
      # Ensure lib directory exists
      first = List.first(parts)
      rest = Enum.slice(parts, 1..-1)
      ["lib", first | rest]
    end).()
    |> Path.join()
    |> Kernel.<>(".ex")
  end
end