defmodule Test do
  use Supervisor

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(scheme: :http, plug: Test.Api, options: [port: 8080])
    ]

    opts = [strategy: :one_for_one, name: Test.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def init(opts) do
    opts
  end
end
