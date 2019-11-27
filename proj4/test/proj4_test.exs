defmodule Proj4Test do
  use ExUnit.Case
  doctest Proj4.TwitterEngine

  test "greets the world" do
    assert Proj4.TwitterEngine.hello() == :world
  end
end
