mmchat
=================
a web chat server on cowboy.

基于cowboy的web聊天工具

web界面仿照QQ

支持群组和单独聊天

server不保留任何聊天内容（所以不支持离线消息）

好友上线自动动态创建会话，下线会话会隐藏

支持图片和表情～～

使用步骤

1、安装erlang（推荐linux版本,otp 16+）

2、下载git代码并编译

3、启动应用添加账号密码（目前只能后台数据库添加），启动命令如下

To try this example, you need GNU `make` and `git` in your PATH.

To build the example, run the following command:

``` bash
$ ./rebar get-deps
$ ./rebar compile
```

To start the release in the foreground:

``` bash
erl -pa ebin/ -pa deps/*/ebin
1> application:ensure_all_started(mmchat).
{ok,[ranch,crypto,cowlib,cowboy,mmchat]}
2> 
```

常用的功能如下

``` bash
##增加群组1
3> mmchat_data:add_group("钓鱼的人").
{ugroup,2,
        [38035,40060,30340,20154],
        "./img/tx007.jpg",
        [38035,40060,30340,20154],
        {1623,289423,482383}}
 ##增加群组2
4> mmchat_data:add_group("修车群").  
{ugroup,3,
        [20462,36710,32676],
        "./img/tx005.jpg",
        [20462,36710,32676],
        {1623,289436,233943}}
##增加用户1
5> mmchat_data:add_user("maomao", "test123").
ok
##增加用户2
6> mmchat_data:add_user("zhangsan", "test123").
ok
##添加用户到群众
7> mmchat_data:adduser_to_group("maomao", "钓鱼的人").
{atomic,ok}
8> mmchat_data:adduser_to_group("zhangsan", "钓鱼的人").
{atomic,ok}
9> mmchat_data:adduser_to_group("zhangsan", "修车群").  
{atomic,ok}
10> mmchat_data:adduser_to_group("maomao", "修车群").  
##增加用户互为好友
11> mmchat_data:add_friends("maomao", "zhangsan").
{atomic,ok}

```

Then point your browser at [http://serverip:9999](http://localhost:9999).
