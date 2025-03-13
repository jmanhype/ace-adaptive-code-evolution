defmodule Ace.Core.ProjectTest do
  use Ace.DataCase

  alias Ace.Core.Project

  describe "project schema" do
    @valid_attrs %{
      name: "Test Project",
      base_path: "/tmp/test_project",
      description: "A test project for multi-file analysis",
      settings: %{"language_preference" => "elixir"}
    }
    @invalid_attrs %{name: nil, base_path: nil}

    setup do
      # Create the directory to pass validation
      File.mkdir_p!("/tmp/test_project")
      :ok
    end

    test "changeset with valid attributes" do
      changeset = Project.changeset(%Project{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Project.changeset(%Project{}, @invalid_attrs)
      refute changeset.valid?
    end

    test "changeset requires name" do
      attrs = Map.delete(@valid_attrs, :name)
      changeset = Project.changeset(%Project{}, attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "changeset requires base_path" do
      attrs = Map.delete(@valid_attrs, :base_path)
      changeset = Project.changeset(%Project{}, attrs)
      assert %{base_path: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "path utilities" do
    setup do
      project = %Project{
        name: "Test Project",
        base_path: "/base/path"
      }
      %{project: project}
    end

    test "relative_path converts full path to relative", %{project: project} do
      assert Project.relative_path(project, "/base/path/file.ex") == "file.ex"
      assert Project.relative_path(project, "/base/path/dir/file.ex") == "dir/file.ex"
    end

    test "relative_path returns original if not under base_path", %{project: project} do
      assert Project.relative_path(project, "/other/path/file.ex") == "/other/path/file.ex"
    end

    test "absolute_path converts relative path to absolute", %{project: project} do
      assert Project.absolute_path(project, "file.ex") == "/base/path/file.ex"
      assert Project.absolute_path(project, "dir/file.ex") == "/base/path/dir/file.ex"
    end
  end
end