defmodule Honeybee.Validator do
  # @spec validate_pipeline!(Macro.Env.t(), Honeybee.Pipeline.t()) :: any
  # def validate_pipeline!(env, %Honeybee.Pipeline{plugs: plugs, name: name, line: line}) do
  #   cond do
  #     !is_atom(name) -> raise "LOL"
  #   end

  #   Enum.each(plugs, &validate_plug!(env, &1))
  #   :ok
  # end

  # def validate_plug!(env, %Honeybee.Plug{plug: plug, line: line, opts: opts}) do
  #   plug = Macro.expand(plug, env)

  #   cond do
  #     !is_atom(plug) -> raise "LOL"
  #   end

  #   :ok
  # end

  # def is_valid_plug?(plug) do
  #   case Atom.to_string(plug) do
  #     ":Elixir." <> _ -> is_valid_module_plug?(plug)
  #   end
  # end
end