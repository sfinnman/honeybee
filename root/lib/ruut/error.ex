defmodule Ruut.Error do
  defmacro __using__(_ \\ []) do
    quote do
      defexception [:message, :env, :file, :line]

      @impl true
      def exception(opts) do
        msg = Keyword.fetch!(opts, :message)
        env = Keyword.fetch!(opts, :env)

        line = env.line
        file = env.file
        %__MODULE__{message: msg, file: file, line: line, env: env}
      end

      @impl true
      def blame(err, stacktrace) do
        case err.env do
          nil -> {err, stacktrace}
          env -> {err, Macro.Env.stacktrace(env)}
        end
      end
    end
  end
end
