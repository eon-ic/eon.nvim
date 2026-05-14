local Utils = require("eon.utils")
local Plugin = require("eon.plugins.plugin")
--- @class PluginConfig
--- @field enable boolean
--- @field lazy boolean
--- @field name string?
--- @field opts table?
--- @field ft table<string>?
--- @field event table<string>?
--- @field cmd table<string>?
--- @field keys table<string>?
--- @field dependencies table<PluginConfig|string>?
--- @field priority (1|2|3)?
--- @field init function?
--- @field config function<Plugin,Opts>?
--- @field build function?
local default_plugin_config = {
	lazy = true,
	enable = true,
	name = nil,
	opts = nil,
	dependencies = nil,
	ft = nil,
	event = nil,
	cmd = nil,
	keys = nil,
	priority = nil,
	init = nil,
	config = nil,
	build = nil,
}
local M = {
	--- @type table<string, Plugin>
	plugins = {},
}
--- @param packs table<string | table>
function M.parser_packs(packs)
	for _, p in ipairs(packs) do
		M.add(p)
	end
end
function M.add(pack)
	local src = pack[1] or pack
	if string.match(src, "https?://(.*)") == nil then
		src = "https://github.com/" .. src
	end
	local name = pack.name or Utils.get_plugin_name(src)
	-- print("Adding plugin: " .. name)
	vim.pack.add({ { src = src, name = name, version = pack.version } })
	if type(pack) == "string" then
		pack = {}
	end
	local config = vim.tbl_extend("force", pack, { name = name })
	config = vim.tbl_extend("force", default_plugin_config, config)
	local plugin = Plugin:new(name, src, config)
	if config.dependencies then
		M.parser_packs(config.dependencies)
	end
	M.plugins[name] = plugin
end

function M.has(name)
	return M.plugins[name] ~= nil
end

function M.del(name)
	vim.pack.del({ name }, { force = true })
end

function M.load_all()
	--- @type table<string>
	local lazy_loads = {}
	for n, p in pairs(M.plugins) do
		if p.config.lazy == true then
			table.insert(lazy_loads, n)
		else
			p:load()
		end
	end
	vim.api.nvim_create_autocmd("VimEnter", {
		callback = function()
			for _, n in pairs(lazy_loads) do
				M.plugins[n]:load()
			end
		end,
	})
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
