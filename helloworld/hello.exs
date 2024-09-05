defmodule Hello do
  def say(name) do
    IO.puts("Hello #{name} !")
  end
end

Hello.say("Elixir")
