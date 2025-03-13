defmodule AceTest do
  use ExUnit.Case
  doctest Ace

  test "greets the world" do
    assert Ace.hello() == :world
  end
end
