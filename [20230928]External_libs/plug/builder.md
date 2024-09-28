# Plug Builder

Plug Builder为创建plug提供了便利，可以使用该模块构建Plug pipelines。

`plug/2`宏在一个pipeline中定义多个plugs，plug依次从上往下执行，下面例子中
`Plug.Logger`模块的plug在`:hello`函数的plug之前被调用，因此函数plug将在模块plug生成的连接上被调用。

`Plug.Builder`导入了`Plug.Conn`模块，所以可以直接使用`send_resp/3`等函数。

```elixir
defmodule MyApp do
  use Plug.Builder

  plug Plug.Logger
  plug :hello, upper: true

  # 一个来自其他模块的函数也可以被使用，需要先将其导入到当前模块中。
  import AnotherModule, only: [interesting_plug: 2]
  plug :interesting_plug

  def hello (conn, opts) do
    body = if opts[:upper], do: "WORLD", else: "world"
    send_resp(conn, 200, body)
  end
end
```


## 选项

使用时，`Plug.Builder` 接受以下选项：

* `:init_mode` - 初始化插件选项的环境，可以是 `:compile` 或 `:runtime`。默认值是 `:compile`。

* `:log_on_halt` - 接受在请求被终止时的日志级别。

* `:copy_opts_to_assign` - 一个表示分配的 `原子`。如果提供，将把传递给 Plug 初始化的选项复制到给定的连接分配中。

## 插件行为

`Plug.Builder` 通过实现 `Plug` 行为定义 `init/1` 和 `call/2` 函数。

通过实现 Plug API，`Plug.Builder` 保证该模块是一个插件，可以交给一个 web 服务器或作为另一个管道的一部分使用。

## 条件插件

有时你可能希望在管道中有条件地调用一个插件。例如，你可能希望仅在某些路由下调用 `Plug.Parsers`。这可以通过将模块插件包装在一个函数插件中来完成。你可以这样写：

```elixir
plug :conditional_parser

defp conditional_parser(%Plug.Conn{path_info: ["noparser" | _]} = conn, _opts) do
  conn
end

@parser Plug.Parsers.init(parsers: [:urlencoded, :multipart], pass: ["text/*"])
defp conditional_parser(conn, _opts) do
  Plug.Parsers.call(conn, @parser)
end
```

上述代码将在所有路由上调用 `Plug.Parsers`，除了 `/noparser` 下的路由。

## 重写默认的 Plug API 函数

`Plug.Builder` 定义的 `init/1` 和 `call/2` 函数都可以被手动重写。例如，`Plug.Builder` 提供的 `init/1` 函数返回它作为参数接收的选项，不过其行为可以被自定义：

```elixir
defmodule PlugWithCustomOptions do
  use Plug.Builder
  plug Plug.Logger

  def init(opts) do
    opts
  end
end
```

`Plug.Builder` 提供的 `call/2` 函数在内部用于执行使用 `plug` 宏列出的所有插件，因此重写 `call/2` 函数通常意味着需要使用 `super` 来继续调用插件链：

```elixir
defmodule PlugWithCustomCall do
  use Plug.Builder
  plug Plug.Logger
  plug Plug.Head

  def call(conn, opts) do
    conn
    |> super(opts) # 调用 Plug.Logger 和 Plug.Head
    |> assign(:called_all_plugs, true)
  end
end
```

## 停止一个插件管道

`Plug.Conn.halt/1` 用于停止一个插件管道。`Plug.Builder` 阻止下游插件被调用并返回当前连接。在下面的例子中，`Plug.Logger` 插件永远不会被调用：

```elixir
defmodule PlugUsingHalt do
  use Plug.Builder

  plug :stopper
  plug Plug.Logger

  def stopper(conn, _opts) do
    halt(conn)
  end
end
```