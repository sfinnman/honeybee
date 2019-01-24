defmodule Ruut.Compiler do
  alias Ruut.Route
  alias Ruut.Scope
  alias Ruut.Pipeline
  alias Macro.Env

  def compile(%Env{} = env) do
    routes = Route.get(env)
    pipelines = Pipelines.get(env)
  end

end
