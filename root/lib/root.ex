defmodule Root do
  defmacro __using__(_ \\ []) do
    Module.put_attribute(__CALLER__.module, :scope, [])
    Module.put_attribute(__CALLER__.module, :active_pipelines, [])
    Module.put_attribute(__CALLER__.module, :pipelines, [])
    quote do
      import Root
      import Plug.Conn

      def init(opts), do: opts
      def call(%Plug.Conn{path_info: path_info, method: method} = conn, opts) do
        __dispatch__(conn, method, path_info)
      end
    end
  end

  defmacro plug(plug, opts \\ []) do
    {plug, opts, true}
  end

  defmacro pipe_through(name, opts \\ []) when is_atom(name), do: __pipe_through__(__CALLER__, name, opts)
  defp __pipe_through__(env, name, _) do
    active_pipelines = Module.get_attribute(env.module, :active_pipelines)
    pipelines = Module.get_attribute(env.module, :pipelines)

    if !Keyword.has_key?(pipelines, name), do: raise "Pipeline #{to_string(name)} is not/has not yet been defined."
    Module.put_attribute(env.module, :active_pipelines, [name] ++ active_pipelines)
  end

  defmacro pipeline(name, do: {:__block__, _, block}) when is_atom(name), do: __pipeline__(__CALLER__, name, block)
  defmacro pipeline(name, do: block) when is_atom(name), do: __pipeline__(__CALLER__, name, [block])
  defp __pipeline__(env, name, block) do
    pipelines = Module.get_attribute(env.module, :pipelines)
    plugs = Enum.map(expand_ast(block, env), &validate_plug(&1))  

    Module.put_attribute(env.module, :pipelines, [{name, Enum.reverse(plugs)}] ++ pipelines)
  end

  defp validate_plug({plug, _, _} = node) when is_atom(plug) do
    case Atom.to_string(plug) do
      "Elixir." <> module ->
        if !function_exported?(plug, :init, 1), do: throw "Plug #{module} must export init/1"
        if !function_exported?(plug, :call, 2), do: throw "Plug #{module} must export call/2"
        node
      _ -> node
    end
  end
  defp validate_plug(a), do: throw "Only plugs allowed inside a pipeline, got: #{Macro.to_string(a)}"

  defmacro scope(do: block), do: __scope__(__CALLER__, "", block)
  defmacro scope(path, do: block) when is_binary(path), do: __scope__(__CALLER__, path, block)
  defp __scope__(env, path, block) do
    parent_scope = Module.get_attribute(env.module, :scope)
    parent_scope_active_pipelines = Module.get_attribute(env.module, :active_pipelines)
    child_scope = [path] ++ parent_scope

    Module.put_attribute(env.module, :scope, child_scope)
    
    code = try do
      expand_ast(block, env)
    catch
      error -> throw error
    end

    Module.put_attribute(env.module, :scope, parent_scope)
    Module.put_attribute(env.module, :active_pipelines, parent_scope_active_pipelines)

    code
  end

  defp expand_ast(ast, env) do
    Macro.prewalk(ast, &Macro.expand(&1, env))
  end

  defmacro get(path, block), do: __match__(__CALLER__, "GET", path, block)
  defmacro get(path, module, function), do: __match__(__CALLER__, "GET", path, module, function)
  
  defmacro post(path, block), do: __match__(__CALLER__, "POST", path, block)
  defmacro post(path, module, function), do: __match__(__CALLER__, "POST", path, module, function)

  defmacro put(path, block), do: __match__(__CALLER__, "PUT", path, block)
  defmacro put(path, module, function), do: __match__(__CALLER__, "PUT", path, module, function)

  defmacro patch(path, block), do: __match__(__CALLER__, "PATCH", path, block)
  defmacro patch(path, module, function), do: __match__(__CALLER__, "PATCH", path, module, function)

  defmacro delete(path, block), do: __match__(__CALLER__, "DELETE", path, block)
  defmacro delete(path, module, function), do: __match__(__CALLER__, "DELETE", path, module, function)

  defmacro options(path, block), do: __match__(__CALLER__, "OPTIONS", path, block)
  defmacro options(path, module, function), do: __match__(__CALLER__, "OPTIONS", path, module, function)

  defmacro match(method, path, block), do: __match__(__CALLER__, method, path, block)
  defmacro match(method, path, module, function), do: __match__(__CALLER__, method, path, module, function)

  defp __match__(env, method, path, module, function) when is_binary(method) and is_binary(path) and is_atom(function) do
    {func, [], args} = quote do
      unquote(module).unquote(function)(unquote(Macro.var(:conn, nil)), unquote(Macro.var(:path_params, __MODULE__)))
    end
    __match__(env, method, path, [{:do, {func, [line: env.line], args}}])
  end
  defp __match__(env, method, path, do: block) when is_binary(method) and is_binary(path) do
    full_path = get_scoped_path(env) <> path
    
    pattern = gen_path_pattern(full_path)
    params = gen_path_params(full_path)

    active_pipelines = Module.get_attribute(env.module, :active_pipelines)
    pipelines = Module.get_attribute(env.module, :pipelines)

    plugs = active_pipelines
    |> Enum.flat_map(&Keyword.fetch!(pipelines, &1))
    
    {conn, ast} = Plug.Builder.compile(env, plugs, [])

    quote do
      def __dispatch__(unquote(conn), unquote(method), unquote(pattern)) do
        case unquote(ast) do
          %Plug.Conn{halted: false} = unquote(Macro.var(:conn, nil)) ->
            unquote(Macro.var(:path_params, __MODULE__)) = unquote(params)
            case unquote(block) do
              %Plug.Conn{} = conn -> conn
              a -> raise "Route at line #{unquote(env.line)} returned #{a}. Routes must return a %Plug.Conn{} struct"
            end
          a -> a
        end
      end
    end
  end

  defp get_scoped_path(env) do
    Module.get_attribute(env.module, :scope)
    |> Enum.reverse()
    |> Enum.join()
  end

  defp gen_path_pattern("/" <> path), do: gen_path_pattern(path)
  defp gen_path_pattern(path) do
    path_parts = String.split(path, "/")

    path_parts
    |> Enum.reduce([], fn
      (":*" <> part, acc) -> acc ++ {:unquote, [], [str_to_var(part)]}
      (":" <> part, acc) -> acc ++ [{:unquote, [], [str_to_var(part)]}]
      (part, acc) -> acc ++ [part]
    end)
    |> Macro.escape(unquote: true)
  end

  defp gen_path_params("/" <> path), do: gen_path_params(path)
  defp gen_path_params(path) do
    path_parts = String.split(path, "/")

    path_parts
    |> Enum.reduce(%{}, fn
      (":*" <> part, var_map) -> Map.merge(var_map, %{part => {:unquote, [], [str_to_var(part)]}})
      (":" <> part, var_map) -> Map.merge(var_map, %{part => {:unquote, [], [str_to_var(part)]}})
      (_, var_map) -> var_map 
    end)
    |> Macro.escape(unquote: true)
  end

  defp str_to_var(str, context \\ nil) do
    Macro.var(String.to_atom(str), context)
  end
end
