local M = {}
local pack = require("eon.packages")
local commands = {
	{
		name = "EonReload",
		command = function(opts)
			for _, name in pairs(opts.fargs) do
				pack.packreload(name)
			end
		end,
		opts = {
			nargs = "+",
		},
	},
	{
		name = "EonDel",
		command = function(opts)
			for _, name in pairs(opts.fargs) do
				if pack.has_pack(name) then
					pack.packdel(name)
				end
			end
		end,
		opts = {
			nargs = "+",
		},
	},
}

function M.setup()
	for _, cmd in ipairs(commands) do
		local opts = vim.tbl_extend("force", cmd.opts or {}, { force = true })
		vim.api.nvim_create_user_command(cmd.name, cmd.command, opts)
	end
end

return M
