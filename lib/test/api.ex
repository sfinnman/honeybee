defmodule Test.Api do
  use Plug.Builder

  plug(Plug.Logger)
  plug(Plug.MethodOverride)
  plug(Plug.Head)

  plug(Test.Api.Router)
end
