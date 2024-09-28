Here is the translation of the provided text into simplified Chinese:

# Plug 连接

这个模块定义了一个结构体和主要函数，用于处理 HTTP 连接中的请求和响应。

注意，请求头会被规范化为小写，响应头的键也期望为小写。

## 请求字段

这些字段包含请求信息：

* `host` - 请求的主机，类型为二进制，例如："www.example.com"
* `method` - 请求方法，类型为二进制，例如："GET"
* `path_info` - 路径分割为多个部分，例如：`["hello", "world"]`
* `script_name` - URL 路径的初始部分，对应于应用程序路由，分割为多个部分，例如：`["sub","app"]`
* `request_path` - 请求的路径，例如：`/trailing/and//double//slashes/`
* `port` - 请求的端口，类型为整数，例如：`80`
* `remote_ip` - 客户端的 IP，例如：`{151, 236, 219, 228}`。该字段
  意在被理解例如 `X-Forwarded-For` 
  头或 HAProxy 的 PROXY 协议的插头覆盖。默认为对方的 IP。
* `req_headers` - 请求头，类型为列表，例如：`[{"content-type", "text/plain"}]`。
  注意所有头部都会被转为小写。
* `scheme` - 请求方案，类型为原子，例如：`:http`
* `query_string` - 请求查询字符串，类型为二进制，例如："foo=bar"

## 可获取字段

可获取字段在相应的前缀为 'fetch_' 的函数获取之前，不会填充请求信息，例如，`fetch_cookies/2` 函数获取 `cookies` 字段。

如果在获取之前访问这些字段，它们将返回 `Plug.Conn.Unfetched` 结构体。

* `cookies` - 请求的 cookies 和响应的 cookies。
* `body_params` - 请求体参数，通过 `Plug.Parsers` 解析器填充。
* `query_params` - 请求查询参数，通过 `fetch_query_params/2` 填充。
* `path_params` - 请求路径参数，通过路由器如 `Plug.Router` 填充。
* `params` - 请求参数，合并了 `:path_params`、`:body_params` 和 `:query_params` 的结果。
* `req_cookies` - 请求的 cookies（不包括响应的 cookies）。

## 会话和分配

HTTP 是无状态的。

这意味着服务器在每个请求周期开始时不知道客户端的任何信息，除了请求本身。其响应可能包括一个或多个 `"Set-Cookie"` 头，要求客户端在后续请求中通过 `"Cookie"` 头发送该值。

这是与客户端进行状态交互的基础，以便服务器可以记住客户端的名称、他们购物车的内容，等等。

在 `Plug` 中，“会话”是一个存储在请求之间保留数据的地方。通常这些数据存储在使用 `Plug.Session.COOKIE` 的 cookie 中。

最简单的方法是只在会话中存储用户的 ID，然后在请求周期中使用该 ID 查找其他信息（在数据库或其他地方）。

可以在会话 cookie 中存储更多信息，但要小心：这会使请求和响应变得更重，客户端可能会拒绝超出某个大小的 cookie。此外，会话 cookie 不会在用户的不同浏览器或设备之间共享。

如果会话存储在其他地方，例如使用 `Plug.Session.ETS`，则会话数据查找仍然需要一个键，例如用户的 ID。与会话数据不同，`assigns` 数据字段只在单个请求中有效。

一个典型的用例是身份验证插头通过 ID 查找用户，并通过将其存储在 `assigns` 中来保持用户凭据的状态。其他插头将通过 `assigns` 存储访问它。这一点非常重要，因为会话数据在下一个请求中会消失。

总结一下：`assigns` 用于存储在当前请求期间访问的数据，而会话用于存储在后续请求中访问的数据。

## 响应字段

这些字段包含响应信息：

* `resp_body` - 响应体默认是空字符串。响应发送后，该字段被设置为 nil，测试连接除外。响应的字符集默认是 "utf-8"。
* `resp_cookies` - 响应的 cookies 及其名称和选项。
* `resp_headers` - 响应头，类型为元组列表，`cache-control` 默认设置为 `"max-age=0, private, must-revalidate"`。
  注意：响应头应全部小写。
* `status` - 响应状态。

## 连接字段

* `assigns` - 作为映射共享的用户数据。
* `owner` - 拥有该连接的 Elixir 进程。
* `halted` - 管道是否被中止的布尔状态。
* `secret_key_base` - 用于验证和加密 cookies 的秘密密钥。
  这些功能需要手动字段设置。数据必须保存在连接中，且不得直接使用。始终使用 `Plug.Crypto.KeyGenerator.generate/3` 从中派生密钥。
* `state` - 连接状态。

连接状态用于跟踪连接生命周期。它开始为 `:unset`，通过 `resp/3` 更改为 `:set` 或 `:set_chunked`（仅用于 `send_chunked/2` 的 `before_send` 回调）或 `:file`（通过 `send_file/3` 调用时）。最终结果为 `:sent`、`:file`、`:chunked` 或 `:upgraded`，具体取决于响应模型。

## 私有字段

这些字段保留供库/框架使用。

* `adapter` - 作为元组保存适配器信息。
* `private` - 作为映射共享的库数据。

## 自定义状态代码

`Plug` 允许覆盖或添加状态代码，并允许添加 `Plug` 或其适配器未直接指定的新代码。`:plug` 应用程序的 Mix 配置可以添加或覆盖状态代码。

例如，以下配置覆盖默认的 404 原因短语（"未找到"），并添加一个新的 998 状态代码：

```elixir
config :plug, :statuses, %{
  404 => "actually this was found",
  998 => "not an_rfc status code"
}
```

依赖特定的配置变更不会自动重新编译。要使更改生效，重新编译 `Plug`。以下命令重新编译 `Plug`：

```elixir
mix deps.clean --build plug
```

每个状态代码原因短语都有相应的原子形式。在许多函数中，这些原子可以代替状态代码。例如，通过上述配置，以下代码将有效：

```elixir
put_status(conn, :not_found)                     # 404
put_status(conn, :actually_this_was_found)       # 404
put_status(conn, :not_an_rfc_status_code)        # 998
```

即使 404 状态代码的原因短语被覆盖，`:not_found` 原子仍然可以用于设置 404 状态。新原子 `:actually_this_was_found`，由原因短语 "实际上这是找到的" 转化而来，也可以用于设置 404 状态代码。

## 协议升级

`Plug.Conn.upgrade_adapter/3` 为协议升级提供基本支持，并促进连接升级到如 WebSocket 的协议。如其名所示，此功能依赖于适配器。协议升级功能需要 `Plug` 应用程序与基础适配器之间的明确协调。

`Plug` 相关的升级功能仅提供了 `Plug` 应用程序请求基础适配器进行协议升级的可能性。请参见 `upgrade_adapter/3` 文档。

