defmodule Ruut.Scope do
  alias Ruut.Scope
  alias Ruut.Resolver
  alias Macro.Env

  @attr_scope :__ruut_scope__

  defstruct path: "/", pipe_through: []

  def init(%Env{module: module}) do
    Module.put_attribute(module, @attr_scope, [%Scope{}])
  end

  def build(%Env{} = env, path, block) do
    push(env, %Scope{path: path})
    Resolver.resolve(env, block)
    pop(env)
  end

  @spec pipe_through(Macro.Env.t(), [any()]) :: :ok
  def pipe_through(%Env{} = env, name) do
    scope = pop(env)
    push(env, %Scope{scope | pipe_through: name ++ scope.pipe_through})
  end

  @spec in_scope?(Macro.Env.t()) :: boolean()
  def in_scope?(env), do: length(get(env)) > 1

  def get(%Env{module: module}) do
    Module.get_attribute(module, @attr_scope)
  end

  def push(%Env{module: module} = env, scope) do
    Module.put_attribute(module, @attr_scope, [scope | get(env)])
  end

  def pop(%Env{module: module} = env) do
    [top | scope] = get(env)
    Module.put_attribute(module, @attr_scope, scope)
    top
  end

end
