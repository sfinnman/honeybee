# defmodule Test.Plug do

#   def init(opts), do: opts

#   def call(conn, _opts), do: conn

#   def test(conn, _opts) do
#     conn
#   end

# end

# defmodule Test do
#   use Ruut

#   pipeline :auth do
#     plug :method
#     plug :noob
#   end

#   pipe_through :auth

#   scope "/noob" do
#     get :asd, Test.Plug, :test
#   end

#   def method(conn, _opts) do
#     conn
#   end

#   def noob(conn, _opts) do
#     IO.inspect "CALLED"
#     conn
#   end

# end
