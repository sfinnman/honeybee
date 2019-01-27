defmodule Test.Api.Errors do
  def not_found(conn, _opts) do
    Plug.Conn.resp(conn, 404, "")
  end
end
