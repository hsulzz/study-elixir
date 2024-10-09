defmodule HelloPlugHttpTest do
  use ExUnit.Case, async: true
  use Plug.Test

  doctest HelloPlugHttp

  @opts HelloPlugHttp.Router.init([])

  test "return helloworld" do
    conn=conn("GET", "/")

    conn = HelloPlugHttp.Router.call(conn, @opts)
    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "Hello World!"
  end
end
