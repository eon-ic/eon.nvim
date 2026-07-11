local M = {}
local PluginManager = require("eon.plugins.manager"):new()
local utils = require("eon.utils")
local function preload_pack_dir(dir)
	local files = vim.api.nvim_get_runtime_file("lua/" .. dir .. "/**/*.lua", true)
	for _, file in ipairs(files) do
		local name = string.match(file, "([^/]+)%.lua$")
		if name ~= "init" then
			--- @type PluginConfig|string
			local p = require("plugins." .. name)
			if p ~= nil and (type(p) == "table" or type(p) == "string") then
				if p[1] ~= nil and type(p[1]) == "table" then
					---@diagnostic disable-next-line: param-type-mismatch
					PluginManager:parser_packs(p)
				elseif p[1] ~= nil or type(p) == "string" or type(p) == "table" then
					PluginManager:add(p)
				end
			end
		end
	end
end
local function scan_dir(path)
	local files = {}
	local handle = vim.uv.fs_scandir(path)
	if not handle then
		return files
	end

	while true do
		local name, type = vim.uv.fs_scandir_next(handle)
		if not name then
			break
		end

		local full = path .. "/" .. name
		if type == "directory" then
			-- 递归子目录
			for _, f in ipairs(scan_dir(full)) do
				table.insert(files, f)
			end
		else
			table.insert(files, full)
		end
	end

	return files
end
local function load_dev_plugin(dirs)
	local packs = {}
	for _, dir in ipairs(dirs) do
		local files = scan_dir(dir)
		for _, file_path in ipairs(files) do
			if file_path:match(".*/plugin/*.lua") then
				local lines = vim.fn.readfile(file_path)
				load(table.concat(lines, "\n"))()
			else
				local name = utils.path_to_module(file_path)
				local lines = vim.fn.readfile(file_path)
				local pack_fn = load(table.concat(lines, "\n"))
				package.loaded[name] = {}
				packs[name] = pack_fn
			end
		end
	end
	for name, pack_fn in pairs(packs) do
		local pack = pack_fn()
		package.loaded[name] = pack
	end
	for name, _ in pairs(packs) do
		local pack = package.loaded[name]
		if pack.setup ~= nil then
			pack.setup()
		end
	end
end
function M.setup(opts)
	PluginManager:parser_packs(opts.packs)
	preload_pack_dir(opts.packs.dir)
	load_dev_plugin(opts.packs.dev_dirs)
	PluginManager:load_all()
	-- PluginManager.check_update()
end

return M
