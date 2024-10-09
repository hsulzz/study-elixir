defmodule HelloPlug do
  @moduledoc """
  Documentation for `HelloPlug`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> HelloPlug.hello()
      :world

  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/json")
    |> send_resp(200, "Hello, World!")
end
