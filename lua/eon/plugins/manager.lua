local Utils = require("eon.utils")
local M = {
    --- @type table<string, Plugin>
    plugins = {}
}

function M.add(pack)
    local Plugin = require("eon.plugins.plugin")
    local src = pack[1] or pack
    if string.match(src, "https?://(.*)") == nil then
			src = "https://github.com/" .. src;
	end
    local name = pack.name or Utils.get_plugin_name(src)
    -- print("Adding plugin: " .. name)
	vim.pack.add({ { src = src, name = name, version = pack.version } })
    M.plugins[name] =  Plugin:new(name, src, pack)
end

function M.has(name)
	return M.plugins[name] ~= nil
end

function M.del(name)
	vim.pack.del({ name }, { force = true })
end

function M.load_all()
    for _,p in pairs(M.plugins) do
        p:load()
    end
end
function M.check_update()
	for _, p in pairs(M.plugins) do
		p:update()
	end
end
function M.reload(name)
    local plugin = M.plugins[name]
    if plugin then
        plugin:reload()
    else
        print("Plugin " .. name .. " not found.")
    end
end
return M