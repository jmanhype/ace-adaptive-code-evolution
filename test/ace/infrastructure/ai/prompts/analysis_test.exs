defmodule Ace.Infrastructure.AI.Prompts.AnalysisTest do
  use ExUnit.Case, async: true

  alias Ace.Infrastructure.AI.Prompts.Analysis

  test "system_prompt returns a valid system prompt" do
    prompt = Analysis.system_prompt()
    assert is_binary(prompt)
    assert String.contains?(prompt, "You are an expert code analyzer")
    assert String.contains?(prompt, "Performance issues")
    assert String.contains?(prompt, "Maintainability issues")
  end
  
  test "system_prompt_multi_file returns a valid multi-file system prompt" do
    prompt = Analysis.system_prompt_multi_file()
    assert is_binary(prompt)
    assert String.contains?(prompt, "cross-file optimization opportunities")
    assert String.contains?(prompt, "Duplicated logic")
    assert String.contains?(prompt, "Inconsistent patterns")
    assert String.contains?(prompt, "Cross-file dependencies")
  end

  test "build/4 returns a valid prompt for single file analysis" do
    code = "defmodule Test do\n  def test() do\n    :ok\n  end\nend"
    language = "elixir"
    focus_areas = ["performance", "maintainability"]
    
    prompt = Analysis.build(code, language, focus_areas)
    
    assert is_binary(prompt)
    assert String.contains?(prompt, code)
    assert String.contains?(prompt, language)
    assert String.contains?(prompt, "performance")
    assert String.contains?(prompt, "maintainability")
  end
  
  test "build includes severity threshold when provided" do
    code = "function test() { return true; }"
    language = "javascript"
    focus_areas = ["security"]
    options = [severity_threshold: "high"]
    
    prompt = Analysis.build(code, language, focus_areas, options)
    
    assert String.contains?(prompt, "high")
    assert String.contains?(prompt, "severity")
  end
  
  test "build_multi_file/4 returns a valid prompt for multi-file analysis" do
    file_context = [
      %{
        file_path: "/path/to/file1.ex",
        file_name: "file1.ex",
        language: "elixir",
        content: "defmodule File1 do\n  def test() do\n    :ok\n  end\nend"
      },
      %{
        file_path: "/path/to/file2.ex",
        file_name: "file2.ex",
        language: "elixir",
        content: "defmodule File2 do\n  def test() do\n    :ok\n  end\nend"
      }
    ]
    primary_language = "elixir"
    focus_areas = ["performance"]
    
    prompt = Analysis.build_multi_file(file_context, primary_language, focus_areas)
    
    assert is_binary(prompt)
    assert String.contains?(prompt, "file1.ex")
    assert String.contains?(prompt, "file2.ex")
    assert String.contains?(prompt, primary_language)
    assert String.contains?(prompt, "performance")
    assert String.contains?(prompt, "cross-file optimization opportunities")
    assert String.contains?(prompt, "Duplicated code across files")
  end
  
  test "build_multi_file includes multiple files with proper formatting" do
    file_context = [
      %{
        file_path: "/path/to/source.js",
        file_name: "source.js", 
        language: "javascript",
        content: "import { helper } from './utils';\nexport function main() { return helper(); }"
      },
      %{
        file_path: "/path/to/utils.js",
        file_name: "utils.js",
        language: "javascript",
        content: "export function helper() { return 'test'; }"
      }
    ]
    
    prompt = Analysis.build_multi_file(file_context, "javascript", ["maintainability"])
    
    # Check that both files are included and properly separated
    assert String.contains?(prompt, "FILE: source.js")
    assert String.contains?(prompt, "FILE: utils.js")
    assert String.contains?(prompt, "Next File")
    
    # Check that the content of both files is included
    assert String.contains?(prompt, "import { helper } from './utils';")
    assert String.contains?(prompt, "export function helper()")
    
    # Check that each file has its proper language tag
    assert String.contains?(prompt, "```javascript")
  end
  
  test "build_multi_file includes severity threshold when provided" do
    file_context = [
      %{
        file_path: "/path/to/file1.py",
        file_name: "file1.py", 
        language: "python",
        content: "def test():\n    return True"
      }
    ]
    options = [severity_threshold: "high"]
    
    prompt = Analysis.build_multi_file(file_context, "python", ["security"], options)
    
    assert String.contains?(prompt, "high")
    assert String.contains?(prompt, "severity")
  end
end