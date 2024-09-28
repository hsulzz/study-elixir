# Plug

 - Plug是使用函数编写网络应用的一套规范
 - Erlang VM中的不同web服务器的连接适配器


## Plug种类

有函数plug 和 模块plug 两种类型

### 函数plug

接受一个connection和一套options作为参数，返回一个connection的函数 被称为函数plug，他必须满足以下类型签名：

```elixir
(Plug.Conn.t, Plug.opts) :: Plug.Conn.t
```

函数plug的例子：

```elixir
def json_header_plug(conn, _opts) do
  Plug.Conn.put_resp_content_type(conn, "application/json")
end
```



### 模块plug

模块plug是函数plug的扩展。他是一个模块，必须暴露以下方法：

-  `c:call/2` 与函数plug拥有相同的类型签名 
   -  `call(Plug.Conn.t(), Plug.opts) :: Plug.Conn.t()`
  
-  `c:init/1` 接受一套options作为参数，并进行初始化，**`init/1`的返回值会被当作`call/2`的第二个参数**。
  

`c:init/1 `可能在编译期间被调用，因此它的返回值不能包含与运行时环境相关的内容，比如进程标识符（PIDs）、端口或其他在程序运行时才会存在的值

模块plug的例子：

```elixir
defmodule JsonHeaderPlug do
  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    Plug.Conn.put_resp_content_type(conn, "application/json")
  end
end
```

## Plug pipeline

`Plug.Builder`模块提供一构建plug pipeline的方法。




## 相关方法

### `run/2`

在运行时执行一系列的plug。

这里给出的plug可以是一个元组，代表模块plug及其选项，或者是一个简单的函数，该函数接收一个连接并返回一个连接。

如果任何plug中止，连接将不会调用剩余的plug。如果给定的连接已经中止，则也不会调用任何plug。

`Plug.Builder` 被设计用于编译时，`run` 函数作为运行时执行的简单替代方案。


```elixir
Plug.run(conn, [{Plug.Head, []}, &IO.inspect/1])
```

### `forward/4`

将请求转发到另一个plug，同时将连接设置为请求的路径。

转发连接的 `path_info` 只会包括传递给 `forward` 函数的请求路径尾部段。`conn.script_name` 属性保留正确的基础路径，例如用于 URL 生成。

```elixir   
 defmodule Router do
        @behaviour Plug

        def init(opts), do: opts

        def call(conn, opts) do
          case conn do
            # Match subdomain
            %{host: "admin." <> _} ->
              AdminRouter.call(conn, opts)

            # Match path on localhost
            %{host: "localhost", path_info: ["admin" | rest]} ->
              Plug.forward(conn, rest, AdminRouter, opts)

            _ ->
              MainRouter.call(conn, opts)
          end
        end
      end
```

