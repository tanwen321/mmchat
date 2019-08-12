mmchat
=================
a web chat server on cowboy.

%基于cowboy的web聊天工具

%web界面仿照QQ
%支持群组和单独聊天
%server不保留任何聊天内容（所以不支持离线聊天）
%好友上线自动动态创建会话，下线会话会隐藏
%支持图片和表情～～

%使用步骤
1、安装erlang（推荐linux版本,otp 16+）
2、下载git代码并编译
3、启动应用添加账号密码（目前只能后台数据库添加），启动命令如下
To try this example, you need GNU `make` and `git` in your PATH.

To build the example, run the following command:

``` bash
$ make
```

To start the release in the foreground:

``` bash
erl -pa /xxx/xxx/mmchat/ebin/ -pa /xxx/xxx/mmchat/deps/*/ebin
1> application:ensure_all_started(mmchat).
{ok,[ranch,crypto,cowlib,cowboy,mmchat]}
2> 
```

Then point your browser at [http://serverip:9999](http://localhost:9999).
