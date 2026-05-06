local M = {}
function M.setup(opts) 
	local packages = opts.packs
	require("eon.packages").setup({
		packs = packages
	})
end

return M
