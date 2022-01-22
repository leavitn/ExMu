defmodule RmudTest do
  use ExUnit.Case
  doctest Rmud

  test "greets the world" do
    assert Rmud.hello() == :world
  end
end
