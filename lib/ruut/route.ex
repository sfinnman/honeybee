defmodule Ruut.Route do
  alias Ruut.Route
  alias Macro.Env

  @attr_route :__ruut_routes__
  defstruct env: nil,
            type: nil,
            scope: nil,
            verb: nil,
            path: nil,
            module: nil,
            method: nil,
            opts: nil

  def init(%Env{module: module}) do
    Module.register_attribute(module, @attr_route, accumulate: true)
  end

  def build(%Env{} = env, type, scope, verb, path, module, method, opts) do
    route = %Route{
      env: env,
      type: type,
      scope: scope,
      verb: verb,
      path: path,
      module: module,
      method: method,
      opts: opts
    }

    Module.put_attribute(env.module, @attr_route, route)
  end

  def get(%Env{module: module}) do
    Module.get_attribute(module, @attr_route)
  end
end
