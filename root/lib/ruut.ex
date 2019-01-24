defmodule Ruut do
  alias Ruut.Scope
  alias Ruut.Route
  alias Ruut.Pipeline

  defmacro __using__(_ \\ []) do
    env = __CALLER__
    Scope.init(env)
    Route.init(env)
    Pipeline.init(env)

    quote do
      import Ruut
      @before_compile Ruut

      def init(opts), do: opts
      def call(conn, opts), do: __dispatch__(conn)
    end
  end

  defmacro scope(path \\ "", do: block) do
    Scope.build(__CALLER__, path, block)
  end

  defmacro head(path, module, method, opts \\ []) do
    __match__(__CALLER__, "HEAD", path, module, method, opts)
  end
  defmacro get(path, module, method, opts \\ []) do
    __match__(__CALLER__, "GET", path, module, method, opts)
  end
  defmacro post(path, module, method, opts \\ []) do
    __match__(__CALLER__, "POST", path, module, method, opts)
  end
  defmacro put(path, module, method, opts \\ []) do
    __match__(__CALLER__, "PUT", path, module, method, opts)
  end
  defmacro patch(path, module, method, opts \\ []) do
    __match__(__CALLER__, "PATCH", path, module, method, opts)
  end
  defmacro connect(path, module, method, opts \\ []) do
    __match__(__CALLER__, "CONNECT", path, module, method, opts)
  end
  defmacro options(path, module, method, opts \\ []) do
    __match__(__CALLER__, "OPTIONS", path, module, method, opts)
  end
  defmacro delete(path, module, method, opts \\ []) do
    __match__(__CALLER__, "DELETE", path, module, method, opts)
  end
  defmacro match(verb, path, module, method, opts \\ []) do
    __match__(__CALLER__, verb, path, module, method, opts)
  end

  defp __match__(env, verb, path, module, method, opts) do
    scope = Scope.get(env)
    Route.build(env, :match, scope, verb, path, module, method, opts)
  end

  defmacro forward(path, module, opts) do
    scope = Scope.get(__CALLER__)
    Route.build(__CALLER__, :forward, scope, nil, path, module, nil, opts)
  end

  defmacro pipeline(name, do: block) do
    Pipeline.build(__CALLER__, name, block)
  end
  defmacro plug(plug, opts \\ []) do
    {plug, opts, true}
  end
  defmacro pipe_through(name) do
    Scope.pipe_through(__CALLER__, name)
  end

  defmacro __before_compile__(env) do
    pipelines = Pipeline.get(env)

    Pipeline.Validator.validate_pipelines(pipelines)

    routes = Route.get(env)

    Pipeline.Compiler.compile(pipelines)

    Pipeline.Validator.validate!(pipelines)
    # Ruut.Compiler.compile(env)
  end

  defp compile(env, route) do

    ensure_exports!(env, {resolve(env, module), :init, 1}, line)
    ensure_exports!(env, {resolve(env, module), :call, 2}, line)

    {conn, ast} = compile_pipeline(env, active_pipelines)
    path_pattern = compile_path_pattern(path)
    path_params = compile_path_params(path)

    quote do
      def __dispatch__(%Plug.Conn{path_info: unquote(path_pattern)} = unquote(conn)) do

      end
    end
  end

  defp compile(env, route) do
    route = route |> Map.new() |> Map.merge(%{env: env})

  end

  defp build_route(env, route) do
    route
    |> Map.new()
    |> Map.merge(%{env: env})
  end

  defp compile(env, {:module, line, http_method, path, module, method, opts, active_pipelines}) do
    ensure_exports!(env, {resolve(env, module), method, 2}, line)

    {conn, ast} = compile_pipeline(env, active_pipelines)
    path_pattern = compile_path_pattern(path)
    path_params = compile_path_params(path)

    quote do
      def __dispatch__(%Plug.Conn{method: unquote(http_method), path_info: unquote(path_pattern)} = unquote(conn)) do
        unquote(conn) = %Plug.Conn{unquote(conn) | path_params: unquote(path_params)}
        unquote(module).unquote(method)(unquote(ast), unquote(opts))
      end
    end
  end

  defp compile_pipeline(env, active_pipelines) do
    pipelines = Scope.var_get!(env, :pipelines)
    plug_pipeline = Enum.flat_map(active_pipelines, &resolve_pipeline(env, &1, pipelines))
    Plug.Builder.compile(env, plug_pipeline, [])
  end

  defp resolve_pipeline(env, {line, key} = _active_pipelines, pipelines) do
    ensure_in!(env, {:pipeline, key}, {:pipelines, Keyword.keys(pipelines)}, line)
    {_, plugs} = Keyword.fetch!(pipelines, key)
    Enum.map(plugs, &resolve_plug(env, &1))
  end

  defp resolve_plug(env, {line, {plug, _, _} = plug_struct} = _plug) do
    atom = resolve(env, plug)
    case Atom.to_string(atom) do
      "Elixir." <> _ ->
        ensure_exports!(env, {atom, :init, 1}, line)
        ensure_exports!(env, {atom, :call, 2}, line)
      _ ->
        ensure_defines!(env, {atom, 2}, line)
    end
    resolve(env, plug_struct)
  end

  defp compile_path_pattern(path) do
    path_parts(path)
    |> Enum.reduce([], fn
      (":*" <> part, acc) -> acc ++ {:unquote, [], [str_to_var(part)]}
      (":" <> part, acc) -> acc ++ [{:unquote, [], [str_to_var(part)]}]
      (part, acc) -> acc ++ [part]
    end)
    |> Macro.escape(unquote: true)
  end

  defp compile_path_params(path) do
    path_parts(path)
    |> Enum.reduce(%{}, fn
      (":*" <> part, var_map) -> Map.merge(var_map, %{part => {:unquote, [], [str_to_var(part)]}})
      (":" <> part, var_map) -> Map.merge(var_map, %{part => {:unquote, [], [str_to_var(part)]}})
      (_, var_map) -> var_map
    end)
    |> Macro.escape(unquote: true)
  end

  defp path_parts(path) do
    path
    |> Enum.map(&String.trim(&1, "/"))
    |> Enum.reverse()
    |> Enum.join("/")
    |> String.split("/")
  end

  defp str_to_var(str, context \\ Ruut) do
    Macro.var(String.to_atom(str), context)
  end

  defp resolve(env, statements) do
    Macro.prewalk(statements, &Macro.expand(&1, env))
  end

  defp ensure_exports!(env, {module, method, arity}, line) do
    if !function_exported?(module, method, arity),
      do: Ruut.Errors.compile_error(env, "#{inspect(module)} must export #{method}/#{arity}.", line)
  end

  defp ensure_defines!(env, {method, arity}, line) do
    if !Module.defines?(env.module, {method, arity}),
      do: Ruut.Errors.compile_error(env, "#{inspect(env.module)} must define #{method}/#{arity}.", line)
  end

  defp ensure_in!(env, {key_name, key}, {list_name, list}, line) do
    if !(key in list),
      do: Ruut.Errors.compile_error(env, "#{key_name} not found in #{list_name}", line)
  end
end
