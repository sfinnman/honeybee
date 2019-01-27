defmodule Test.Api.Router do
  use Honeybee

  get("/hello", Test.Api.HelloWorldHandler, :get)
  get("/bye", Test.Api.GoodbyeWorldHandler, :get)

  match(_, ":*a", Test.Api.Errors, :not_found)
end
