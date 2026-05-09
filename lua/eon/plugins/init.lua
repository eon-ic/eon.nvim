local M = {}
local PluginManager = require("eon.plugins.manager")


function M.setup(opts)
	for _, p in ipairs(opts.packs) do
		PluginManager.add(p)
	end
    local files = vim.api.nvim_get_runtime_file("lua/" .. opts.packs.dir .."/**/*.lua", true)
    for _, file in ipairs(files) do
        local name = string.match(file, "([^/]+)%.lua$")
        if name ~= "init" then
            local p = require("plugins." .. name)
            if p ~= nil and (type(p) == "table" or type(p) == "string") then
                if p[1] and type(p[1]) == "table" and type(p) == "table" then
                    for _, pack in ipairs(p) do
                        PluginManager.add(pack)
                    end
                else
                    PluginManager.add(p)
                end
            end
        end
    end
    PluginManager.load_all()
    PluginManager.check_update()
end

return M
