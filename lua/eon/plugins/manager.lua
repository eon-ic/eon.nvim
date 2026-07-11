local Utils = require("eon.utils")
local Plugin = require("eon.plugins.plugin")
local EventManager = require("eon.plugins.event")
--- @class PluginConfig
--- @field enable boolean
--- @field lazy boolean
--- @field dev boolean
--- @field name string?
--- @field version string?
--- @field import string?
--- @field opts table?
--- @field ft table<string>?
--- @field event vim.api.keyset.events|vim.api.keyset.events[]?
--- @field cmd table<string>?
--- @field keys table<string>?
--- @field dependencies table<PluginConfig|string>?
--- @field priority (1|2|3)?
--- @field init function?
--- @field config function<Plugin,table> | boolean
--- @field build function?
local default_plugin_config = {
	name = nil,
	lazy = true,
	enable = true,
	import = nil,
	opts = nil,
	dev = false,
	version = nil,
	dependencies = nil,
	ft = nil,
	event = nil,
	cmd = nil,
	keys = nil,
	priority = nil,
	init = nil,
	config = true,
	build = nil,
}
local PluginManager = {
	--- @type table<string, Plugin>
	plugins = {},
	--- @type EventManager
	event = nil,
}
function PluginManager:new()
	local instance = {
		plugins = {},
		event = EventManager:new(),
	}
	setmetatable(instance, { __index = PluginManager })
	return instance
end

--- @param packs table<string | table>
function PluginManager:parser_packs(packs)
	for _, p in ipairs(packs) do
		self.add(p)
	end
end
--- @return Plugin[]
function PluginManager:parser_dependencies(packs)
	local plugins = {}
	for _, p in ipairs(packs) do
		local plugin = self:add(p)
		if plugin ~= nil then
			table.insert(plugins, plugin)
		end
	end
	return plugins
end
--- @param pack PluginConfig | string?
--- @return Plugin?
function PluginManager:add(pack)
	if pack == nil then
		return
	end
	local src = nil
	if type(pack) == "string" then
		src = pack
	else
		src = pack[1] or pack.name
	end
	if pack.dev then
	else
		if src ~= nil then
			if string.match(src, "https?://(.*)") == nil then
				src = "https://github.com/" .. src
			end
			local name = pack.name or Utils.get_plugin_name(src)
			-- print("Adding plugin: " .. name)
			vim.pack.add({ { src = src, name = name, version = pack.version } })
			if type(pack) == "string" then
				pack = nil
			end
			local config = vim.tbl_extend("force", pack or {}, { name = name })
			config = vim.tbl_extend("force", default_plugin_config, config)
			local plugin = Plugin:new(name, src, config)
			if config.dependencies then
				plugin.dependencies = self:parser_dependencies(config.dependencies)
			end
			self.plugins[name] = plugin
			return plugin
		end
	end
end

function PluginManager:has(name)
	return self.plugins[name] ~= nil
end

function PluginManager:del(name)
	vim.pack.del({ name }, { force = true })
end

function PluginManager:load_all()
	--- @type table<vim.api.keyset.events,boolean>
	local event_names = {}
	for _, p in pairs(self.plugins) do
		local enames = p.config.event
		if enames ~= nil then
			---@type vim.api.keyset.events[]
			local names = {}
			if type(enames) == "string" then
				table.insert(names, enames)
			elseif type(enames) == "table" then
				names = enames
			end
			for _, name in pairs(names) do
				self.event:addlistener(name, function()
					p:load()
				end)
				event_names[name] = true
			end
		elseif p.config.lazy == true then
			vim.schedule(function()
				p:load()
			end)
		else
			p:load()
		end
	end
	for name, _ in pairs(event_names) do
		vim.api.nvim_create_autocmd(name, {
			callback = function()
				self.event:emit(name)
			end,
		})
	end
end

function PluginManager:check_update()
	for _, p in pairs(self.plugins) do
		p:update()
	end
end

function PluginManager:reload(name)
	local plugin = self.plugins[name]
	if plugin then
		plugin:reload()
	else
		print("Plugin " .. name .. " not found.")
	end
end

return PluginManager
