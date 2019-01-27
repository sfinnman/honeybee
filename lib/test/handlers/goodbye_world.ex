defmodule Test.Api.GoodbyeWorldHandler do
  def get(conn, _opts) do
    Plug.Conn.resp(conn, 200, "{ \"ok\": false }")
  end
end
