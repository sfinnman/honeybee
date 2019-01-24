defmodule Test.Macro do
  defmodule Error do
    use Ruut.Error
  end

  defmacro __using__(opts \\ []) do
    quote do
      import Test.Macro

      @before_compile Test.Macro
    end
  end

  defmacro test() do
    Module.put_attribute(__CALLER__.module, :env, __CALLER__)
  end

  defmacro test2() do
    Module.put_attribute(__CALLER__.module, :map, %{test: "test"})
  end

  defmacro __before_compile__(env) do
    case Module.get_attribute(env.module, :env) do
      nil -> quote do end
      env -> raise Error, message: Module.get_attribute(env.module, :map).test, env: env
    end

    quote do end
  end
end
