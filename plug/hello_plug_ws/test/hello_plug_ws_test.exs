defmodule HelloPlugWsTest do
  use ExUnit.Case
  doctest HelloPlugWs

  test "greets the world" do
    assert HelloPlugWs.hello() == :world
  end
end
