defmodule Ruut.Route.Validator do
  defmodule ArgumentError do
    use Ruut.Error
  end
  defmodule PathError do
    use Ruut.Error
  end
  defmodule UndefinedMethodError do
    use Ruut.Error
  end
  defmodule NotPlugError do
    use Ruut.Error
  end

  @valid_methods ["CONNECT", "HEAD", "GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
  defguard is_http_method(value) when value in @valid_methods

  def validate_route(%{type: :module} = route) do
    cond do
      not is_http_method(route.http_method) ->
        argument_error(inspect(route.http_method) <> " is not supported. Supported methods are: " <> inspect(@valid_methods), route)
      not is_binary(route.path) ->
        argument_error("Route paths must be strings, got: " <> inspect(route.path), route)
      not is_atom(route.method) ->
        argument_error("Methods must be atoms, got: " <> inspect(route.method), route)
      not is_list(route.opts) ->
        argument_error("Expected options to be a keyword list, got: " <> inspect(route.opts), route)
    end
  end

  def validate_route_path(route) do
    true
  end

  def validate_route_method() do
    true
  end

  def argument_error(message, route) do
    raise ArgumentError, message: message, line: route.line, env: route.env
  end

end
