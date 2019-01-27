defmodule Test.Api.HelloWorldHandler do
  def get(conn, _opts) do
    Plug.Conn.resp(conn, 200, "{ \"ok\": true }")
  end
end
