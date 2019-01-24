defmodule RootTest do
  use ExUnit.Case
  doctest Root

  test "greets the world" do
    assert Root.hello() == :world
  end
end
