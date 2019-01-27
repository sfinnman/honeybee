# Honeybee
Honeybee is a Router built on [Plug](https://hexdocs.pm/plug/readme.html "Plug Hexdocs").

Honeybee is built to be very lightweight and impressively fast.

In order to minimize bloat, and keep the project as unopinionated as possible Honeybee only provides a router, thus giving developers better control over what their stacks look like.

> Why use Honeybee, when Plug already has a Router module?

Honeybee provides quick routing, in a small package with comfortable features, that extend those of Plug.

## Example
```
defmodule MyApp.MyRouter do
  use Honeybee

  get "/examples/:id", MyApp.Example, :get_by_id

  match _, MyApp.MyRouter, :not_found

  def not_found(%Plug.Conn{path: path} = conn, _opts) do
    Plug.Conn.resp(conn, 404, "Not Found: #{path}")
  end
end
```

```
defmodule MyApp.Example do
  def get_by_id(%Plug.Conn{path_params: %{"id" => id}} = conn, _opts) do
    IO.puts("Got " <> id)
    Plug.Conn.resp(conn, 200, "{ \"ok\": true }")
  end
end
```

```bash
$ curl http://localhost:8080/examples/1
{ "ok": true }

$ curl http://localhost:8080/something/that/doesnt/exist
Not Found: /something/that/doesnt/exist
```

## Dependencies
Honeybee depends on [Plug](https://hexdocs.pm/plug/readme.html "Plug Hexdocs") and [Cowboy](https://github.com/ninenines/cowboy "Cowboy Github").

