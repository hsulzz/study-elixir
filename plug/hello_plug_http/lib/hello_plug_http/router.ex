defmodule HelloPlugHttp.Router do
  use Plug.Router

  plug Plug.Logger
  plug :match
  plug :dispatch

  get "/" do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello World!")
  end

  forward "/users", to: HelloPlugHttp.UsersRouter

  match _ do
    send_resp(conn, 404, "oops")
  end
end
