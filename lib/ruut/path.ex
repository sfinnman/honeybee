defmodule Ruut.Path do
  defmodule InvalidPathError do
    use Ruut.Error
  end

  # def contains_glob_pattern?(path) do
  #   String.contains?(path, ":*")
  # end

  # def contains_path_param?(path) do
  #   String.contains?(path, ":")
  # end

  # def validate(path) do
  #   cond do
  #     !String.starts_with?(path, "/") ->
  #       {:error, "Routes must start with a /"}
  #     String.ends_with?(path, "/") ->
  #       {:error, "Routes can not end with a /"}
  #     String.contains?(path, "//") ->
  #       {:error, "Routes can not contain //"}
  #     String.match?(path, ~r/:\*.*?\//) ->
  #       {:error, "Routes can not match after globbing"}
  #     String.match?(path, ~r/\/[^/]*:[^/]*:\//) ->
  #       {:error, "Routes can not contain two named matches"}
  #     String.match?(path, ~r/[\s?=&@;"<>#%{}|\\\^~[\]]/)
  #   end
  #   {:ok, nil}
  # end

  def compile_pattern(path) do
    path
    |> String.split("/")
    |> Enum.map(&String.split(&1, ":"))
    |> Enum.reduce([], fn
      (["", "*" <> glob], acc) -> acc ++ var(glob)
      ([static, "*" <> glob], acc) -> acc ++ [static <> var("_" <> glob)] ++ var(glob)
      (["", dynamic], acc) -> acc ++ [var(dynamic)]
      ([static, dynamic], acc) -> acc ++ [static <> var(dynamic)]
      ([static], acc) -> acc ++ [static]
    end)
    |> Macro.escape(unquote: true)
  end

  def compile_params(path) do
    path
    |> String.split("/")
    |> Enum.map(&String.split(&1, ":"))
    |> Enum.reduce(%{}, fn
      (["", "*" <> glob], var_map) -> Map.merge(var_map, %{glob => var(glob)})
      ([_, "*" <> glob], var_map) -> Map.merge(var_map, %{glob => [var("_" <> glob) | var(glob)]})
      ([_, dynamic], var_map) -> Map.merge(var_map, %{dynamic => var(dynamic)})
      (_, var_map) -> var_map
    end)
    |> Macro.escape(unquote: true)
  end

  defp var(str, context \\ __MODULE__) do
    {:unquote, [], [Macro.var(String.to_atom(str), context)]}
  end
end
