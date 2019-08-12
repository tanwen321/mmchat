-record(muser, {mid,    %%用户id
    mname,              %%用户名
    uimage,             %%用户头像链接
    passwd,             %%密码
    group=[1],          %%组，是个列表
    friend=[],          %%好友列表
    mword=[],           %%个性签名
    createtime}).       %%创建时间

-record(ugroup, {gid,    %%组id
    gname,               %%组名称
    gimage,              %%组照片
    gword,               %%组签名
    gcretime}).          %%组创建时间


-record(muinfo, {mid,    %%用户id
    mpid,                %%用户登录后socket pid
    mip,                 %%用户登录后ip
    matime,              %%最后活跃时间
    mcook                %%用户登录后cook
    }).              

-record(mgroup, {gname, %%小组名称  
    gulist}).           %%小组在线用户socket pid列表

-record(user_seq, {name, seq}).  %%自增索引表

-record(user_data, {imid, ifname, utime}).            %%图片缓存

-define(SERVERNAME, twmmchat).
-define(DEFAULTPORT, 9090).
-define(TCP_OPTIONS, [binary,{nodelay,true},{packet, 4},{reuseaddr, true}, {active, true}]).
-define(ERRORFILE, "./img/error.png").
-define(MAXFLEN, 512).
-define(MAXTIME, 3600000).
-define(CACHETIME, 3600000).