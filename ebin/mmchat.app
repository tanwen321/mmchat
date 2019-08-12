%% Feel free to use, reuse and abuse the code in this file.

{application, mmchat, [
	{description, "Cowboy mmchat web server."},
	{vsn, "1.008"},
	{modules, ['mmchat_app','mmchat_data','mmchat_handler','mmchat_lib','mmchat_server','mmchat_sup','mmchat_web']},
	{registered, [mmchat_sup]},
	{applications, [
		kernel,
		stdlib,
		cowboy
	]},
	{mod, {mmchat_app, []}},
	{env, []}
]}.
