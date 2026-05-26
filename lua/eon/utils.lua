local M = {}
function M.get_plugin_name(url)
	return string.match(url, "([^/]+)$"):gsub("%.git$", "")
end

function M.path_to_module(filepath)
	local modpath = filepath:match(".*/lua/(.*)%.lua$")

	-- init.lua → 去掉末尾的 /init
	modpath = modpath:gsub("/init$", "")

	-- / 替换为 .
	modpath = modpath:gsub("/", ".")

	return modpath
end

return M
