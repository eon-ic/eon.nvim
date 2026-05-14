local M = {}
local PluginManager = require("eon.plugins.manager")

function M.setup(opts)
	PluginManager.parser_packs(opts.packs)
	local files = vim.api.nvim_get_runtime_file("lua/" .. opts.packs.dir .. "/**/*.lua", true)
	for _, file in ipairs(files) do
		local name = string.match(file, "([^/]+)%.lua$")
		if name ~= "init" then
			local p = require("plugins." .. name)
			if p ~= nil and (type(p) == "table" or type(p) == "string") then
				if p[1] ~= nil and type(p[1]) == "table" then
					PluginManager.parser_packs(p)
				elseif p[1] ~= nil or type(p) == "string" or type(p) == "table" then
					PluginManager.add(p)
				end
			end
		end
	end
	PluginManager.load_all()
	PluginManager.check_update()
end

return M
