Websocket example
=================

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
