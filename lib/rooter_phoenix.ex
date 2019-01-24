# defmodule Rooter.Phoenix do
#   use Phoenix.Router

#   get "", Rooter.Phoenix, :asd

#   def asd(conn, _) do
#     conn
#   end

#   def test() do
#     time_before = Time.utc_now()
#     Enum.each [1..2999], fn _ ->
#       call(%Plug.Conn{path_info: ["asd"]}, [])
#     end
#     time_after = Time.utc_now()
#     Time.diff(time_after, time_before, :microseconds)
#   end

# end
