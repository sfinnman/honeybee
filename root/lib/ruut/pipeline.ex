defmodule Ruut.Pipeline do
  alias Ruut.Pipeline
  alias Ruut.Resolver
  alias Macro.Env

  @attr_pipelines :__ruut_scope__
  defstruct env: nil, name: nil, plugs: nil

  def init(%Env{module: module}) do
    Module.register_attribute(module, @attr_pipelines, accumulate: true)
  end

  def build(%Env{module: module} = env, name, block) do
    plugs = build_plugs(env, block)
    Module.put_attribute(module, @attr_pipelines, %Pipeline{env: env, name: name, plugs: plugs})
  end

  defp build_plugs(env, block) do
    Resolver.resolve(env, block)
  end

  def get(%Env{module: module}) do
    Module.get_attribute(module, @attr_pipelines)
  end
end
