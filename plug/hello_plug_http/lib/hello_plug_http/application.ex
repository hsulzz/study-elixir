defmodule HelloPlugHttp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: HelloPlugHttp.Worker.start_link(arg)
      # {HelloPlugHttp.Worker, arg}
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: HelloPlugHttp.Router,
        options: [port: 4000]
      )
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HelloPlugHttp.Supervisor]
    Logger.info("Plug now running on localhost:4000")
    Supervisor.start_link(children, opts)
  end
end
