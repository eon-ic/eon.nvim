local uv = vim.loop
--- @class Plugin
--- @field name string
--- @field url string
--- @field config PluginConfig?
--- @field dependencies Plugin[]
local Plugin = {
	name = "",
	url = "",
	config = nil,
	dependencies = {},
	_loaded = false,
}
--- @param pack PluginConfig
function Plugin:new(name, url, pack)
	--- @type Plugin
	local instance = {
		name = name,
		url = url,
		config = pack,
		dependencies = {},
		_loaded = false,
	}
	setmetatable(instance, { __index = Plugin })
	return instance
end

function Plugin:load()
	if self._loaded then
		return
	end
	if self.config.enable == false then
		return
	end
	for _, dep in pairs(self.dependencies) do
		dep:load()
	end
	if self.config.dev == false then
		local has_pack = pcall(vim.pack.get, { self.name })
		vim.cmd("packadd " .. self.name)
		if not has_pack then
			self:build()
		end
	end
	local module_name = self.config.import or self.name:gsub("%.nvim$", ""):gsub("^nvim%-", "")

	local is_load = pcall(require, module_name)
	if is_load then
		local pack = package.loaded[module_name]
		if pack.setup ~= nil then
			if self.config.config == true then
				if self.config.opts ~= nil then
					pack.setup(self.config.opts)
				else
					pack.setup()
				end
			else
				self.config.config(self, self.config.opts)
			end
		end
	end
	if self.config.init ~= nil then
		self.config.init(self.config.opts)
	end
	self._loaded = true
end

function Plugin:unload()
	local name = self.config.import or self.name:gsub("%.nvim$", ""):gsub("^nvim%-", "")
	package.loaded[name] = nil
	self._loaded = false
end

function Plugin:update()
	local pack = self:get_pack()
	--- @type uv.uv_prepare_t?
	local handle
	---@diagnostic disable-next-line: missing-fields
	handle = uv.spawn("/usr/bin/git", {
		args = { "fetch" },
		cwd = pack.path, -- 插件目录
	}, function(code, _) -- 回调函数（在任务完成时触发）
		if code == 0 then
			vim.schedule(function()
				local rev = pack.rev
				local fetch_rev = vim.fn.system("cd " .. pack.path .. " && git rev-parse HEAD")
				if not rev == fetch_rev then
					-- print("Plugin " .. self.name .. " has an update. Reloading...")
					vim.pack.update({ self.name }, { force = true })
					self:reload()
					self:build()
				end
			end)
		else
			print("Git fetch 失败，退出码: " .. code)
		end
		if handle then
			handle:close()
		end
	end)
end

function Plugin:build()
	if self.config.build ~= nil then
		self.config.build()
	end
end

function Plugin:reload()
	self:unload()
	self:load()
end

function Plugin:get_pack()
	return vim.pack.get({ self.name })[1]
end

return Plugin
