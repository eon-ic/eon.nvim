local uv = vim.loop
--- @class Plugin
--- @field name string
--- @field url string
--- @field opts table?
--- @field config function?
local Plugin = {
    name = "",
    url = "",
    opts = nil,
    config = nil
}

function Plugin:new(name, url, opts, config)
    local instance = {
        name = name,
        url = url,
        opts = opts,
        config = config
    }
    setmetatable(instance, { __index = Plugin })
    return instance
end

function Plugin:load()
    -- print("Loading plugin: " .. self.name)
    vim.cmd("packadd " .. self.name)
    local module_name = self.name:gsub("%.nvim$", "")
    -- if package.preload[module_name] ~= nil then
    local is_load = pcall(require,module_name)
    -- print("Running setup for plugin: " .. self.name)
    if is_load then
        local pack = package.loaded[module_name]
        if pack.setup ~= nil then
            if self.opts ~= nil then
                pack.setup(self.opts)
            else
                pack.setup()
            end
        end
        if self.config ~= nil then
            -- print("Running config for plugin: " .. self.name)
            self.config()
        end
    end
    -- end
end

function Plugin:unload()
    for n, _ in pairs(package.loaded) do
        if string.match(n, self.name .. "%.?") then
            -- print("Unloading module: " .. n)
            package.loaded[n] = nil
        end
    end
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

function Plugin:reload()
    self:unload()
    self:load()
end

function Plugin:get_pack()
    return vim.pack.get({ self.name })[1]
end

return Plugin
