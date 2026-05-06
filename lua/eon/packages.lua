local M = {}
local uv = vim.loop
local function get_all_pack()
	local plugins = { all = {}, start = {}, opt = {} }
	local user = vim.fn.expand("$USER")
	local path = "/home/" .. user .. "/.local/share/nvim/site"
	local start_pattern = path .. "/pack/*/start/*"
	local start_plugins = vim.fn.glob(start_pattern, true, true)
	for _, p in ipairs(start_plugins) do
		local name = vim.fn.fnamemodify(p, ":t")
		plugins.all[name] = { path = p }
		table.insert(plugins.start, { name = name, path = p })
	end
	local opt_pattern = path .. "/pack/*/opt/*"
	local opt_plugins = vim.fn.glob(opt_pattern, true, true)
	for _, p in ipairs(opt_plugins) do
		local name = vim.fn.fnamemodify(p, ":t")
		plugins.all[name] = { path = p }
		table.insert(plugins.opt, { name = name, path = p })
	end
	return plugins
end

local all_packs = get_all_pack()

function packadd(src, name, version)
	vim.pack.add({ { src = src, name = name, version = version } })
end
function M.has_pack(name)
	return not (all_packs.all[name] == nil)
end
function M.packdel(name)
	vim.pack.del({ name }, { force = true })
end
function M.packreload(name)
	if has_pack(name) then
		for n, _ in pairs(package.loaded) do
			if string.match(n, name .. "%.?") then
				package.loaded[n] = nil
				if n == "eon" then
					goto continue
				else
					require(n)
				end
			end
			::continue::
		end
	end
end
local function check_update()
	for name, p in pairs(all_packs.all) do
		local handle
		handle = uv.spawn("/usr/bin/git", {
			args = { "fetch" },
			cwd = p.path, -- 插件目录
		}, function(code, _) -- 回调函数（在任务完成时触发）
			if code == 0 then
				vim.schedule(function()
					if name == "eon" then
						return
					end
					local rev = vim.pack.get({ name })[1].rev
					local fetch_rev = vim.fn.system("cd " .. p.path .. " && git rev-parse HEAD")
					if not rev == fetch_rev then
						vim.pack.update({ p.name }, { force = true })
					end
				end)
			else
				print("Git fetch 失败，退出码: " .. code)
			end
			handle:close()
		end)
	end
end

function M.setup(opts)
	check_update()
	for _, p in ipairs(opts.packs) do
		local url = p[1]
		local name = p.name
		local version = p.version or p.branch or "master"
		local has_pack = all_packs[name]
		if not has_pack then
			if string.match(url, "https?://(.*)") == nil then
				packadd("https://github.com/" .. url, name, version)
			else
				packadd(url, name, version)
			end
		end
		vim.cmd("packadd " .. p.name)
		if not (p.opts == nil) then
			require(p.name).setup(p.opts or {})
		end
		if not (p.config == nil) then
			p.config()
		end
	end
end

return M
