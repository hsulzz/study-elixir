# 路由

一个用于定义与 Plug 一起工作的路由算法的领域特定语言（DSL）。

它提供了一组宏来生成路由。例如：

```elixir
defmodule AppRouter do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/hello" do
    send_resp(conn, 200, "world")
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
```

每个路由接收一个 `conn` 变量，该变量包含 `Plug.Conn` 结构，并且根据 Plug 规范需要返回一个连接。建议定义一个通配符 `match`，如上面的示例所示，否则路由将以函数子句错误失败。

路由器本身就是一个 plug，这意味着它可以被调用为：

```elixir
AppRouter.call(conn, AppRouter.init([]))
```

每个 `Plug.Router` 都有一个通过 `Plug.Builder` 定义的 plug 管道，默认情况下需要两个 plugs：`:match` 和 `:dispatch`。`:match` 负责查找匹配的路由，然后转发到 `:dispatch`。这意味着用户可以轻松地钩入路由机制，并在匹配之前、调度之前或两者之后添加行为。有关更多信息，请参见 `Plug.Builder` 模块。

## 路由

```elixir
get "/hello" do
  send_resp(conn, 200, "world")
end
```

在上面的示例中，只有在 `GET` 请求且路由为 "/hello" 时，请求才会匹配。支持的 HTTP 方法有 `get`、`post`、`put`、`patch`、`delete` 和 `options`。

路由还可以指定参数，这些参数在函数体中将可用：

```elixir
get "/hello/:name" do
  send_resp(conn, 200, "hello #{name}")
end
```

这意味着名称可以在守卫中使用：

```elixir
get "/hello/:name" when name in ~w(foo bar) do
  send_resp(conn, 200, "hello #{name}")
end
```

`:name` 参数在函数体中也可以作为 `conn.params["name"]` 和 `conn.path_params["name"]` 使用。

标识符总是以 `:` 开头，必须后跟字母、数字和下划线，就像任何 Elixir 变量一样。标识符可以以其他单词为前缀或后缀。例如，您可以包含一个以点分隔的文件扩展名作为后缀：

```elixir
get "/hello/:name.json" do
  send_resp(conn, 200, "hello #{name}")
end
```

上面的代码将匹配 `/hello/foo.json`，但不匹配 `/hello/foo`。可以使用其他分隔符，例如 `-`、`@` 来表示后缀。

路由允许通配符匹配，这将匹配路由的其余部分。通配符匹配使用 `*` 字符后跟变量名。通常您会用下划线前缀变量名称以将其丢弃：

```elixir
get "/hello/*_rest" do
  send_resp(conn, 200, "matches all routes starting with /hello")
end
```

但是您也可以将通配符分配给任何变量。内容将始终是一个列表：

```elixir
get "/hello/*glob" do
  send_resp(conn, 200, "route after /hello: #{inspect glob}")
end
```

与 `:identifiers` 相反，通配符不允许前缀或后缀匹配。

最后，还支持通用 `match` 函数：

```elixir
match "/hello" do
  send_resp(conn, 200, "world")
end
```

`match` 将匹配任何路由，而不考虑 HTTP 方法。有关路由编译的工作原理和支持选项的列表，请查看 `match/3`。

## 参数解析

处理请求数据可以通过 [`Plug.Parsers`](https://hexdocs.pm/plug/Plug.Parsers.html#content) plug 完成。它支持解析 URL 编码、表单数据和 JSON 数据，并提供其他解析器可以采用的行为。

以下是如何在 `Plug.Router` 路由中使用 `Plug.Parsers` 来解析 POST 请求的 JSON 编码主体的示例：

```elixir
defmodule AppRouter do
  use Plug.Router

  plug :match

  plug Plug.Parsers,
       parsers: [:json],
       pass:  ["application/json"],
       json_decoder: Jason

  plug :dispatch

  post "/hello" do
    IO.inspect conn.body_params # 打印 JSON POST 主体
    send_resp(conn, 200, "成功！")
  end
end
```

重要的是 `Plug.Parsers` 必须放在管道中的 `:dispatch` plug 之前，否则在调度时，匹配的子句路由将不会在其 `Plug.Conn` 参数中接收解析的主体。

`Plug.Parsers` 还可以插入在 `:match` 和 `:dispatch` 之间（如上面的示例所示）：这意味着 `Plug.Parsers` 只有在存在匹配路由时才会运行。这对于在解析主体之前执行操作（例如身份验证）很有用，应该只在匹配路由之后解析主体。

## 错误处理

如果请求中发生错误，路由器默认会崩溃，而不会向客户端返回任何响应。可以通过使用两个不同的模块来配置这种行为：

* `Plug.ErrorHandler` - 允许开发人员通过 `handle_errors/2` 函数自定义发送给客户端的页面；

* `Plug.Debugger` - 自动显示关于故障的调试和请求信息。推荐仅在开发环境中使用此模块。

以下是如何在应用程序中使用这两个模块的示例：

```elixir
defmodule AppRouter do
  use Plug.Router

  if Mix.env == :dev do
    use Plug.Debugger
  end

  use Plug.ErrorHandler

  plug :match
  plug :dispatch

  get "/hello" do
    send_resp(conn, 200, "world")
  end

  defp handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, "出现错误")
  end
end
```

## 在路由和 plugs 之间传递数据

还可以将数据分配给 `Plug.Conn`，以便在 `:match` plug 之后调用的任何 plug 都可以使用。如果希望匹配的路由自定义后续 plug 的行为，这非常有用。

您可以使用 `:assigns`（包含用户数据）或 `:private`（包含库/框架数据）。例如：

```elixir
get "/hello", assigns: %{an_option: :a_value} do
  send_resp(conn, 200, "world")
end
```

在上面的示例中，`conn.assigns[:an_option]` 将可用于所有在 `:match` 之后调用的 plugs。这些 plugs 可以从 `conn.assigns`（或 `conn.private`）中读取，以根据匹配的路由配置其行为。

## `use` 选项

提供给 `use Plug.Router` 的所有选项被转发到 `Plug.Builder`。有关更多信息，请参见 `Plug.Builder` 模块。

## 监测

路由器会发出以下监测事件：

* `[:plug, :router_dispatch, :start]` - 在调度到匹配路由之前进行调度
  * 测量：`%{system_time: System.system_time}`
  * 元数据：`%{telemetry_span_context: term(), conn: Plug.Conn.t, route: binary, router: module}`

* `[:plug, :router_dispatch, :exception]` - 在调度路由时发生异常后进行调度
  * 测量：`%{duration: native_time}`
  * 元数据：`%{telemetry_span_context: term(), conn: Plug.Conn.t, route: binary, router: module, kind: :throw | :error | :exit, reason: term(), stacktrace: list()}`

* `[:plug, :router_dispatch, :stop]` - 在成功调度匹配路由后进行调度
  * 测量：`%{duration: native_time}`
  * 元数据：`%{telemetry_span_context: term(), conn: Plug.Conn.t, route: binary, router: module}`   