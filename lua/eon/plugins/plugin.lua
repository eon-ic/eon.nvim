local uv = vim.loop
local Utils = require("eon.utils")
--- @class Plugin
--- @field name string
--- @field url string
--- @field opts table?
--- @field config function?
--- @field build function?
--- @field dependencies table?
local Plugin = {
    name = "",
    url = "",
    opts = nil,
    config = nil,
    build = nil,
    dependencies = nil
}

function Plugin:new(name, url, pack)
    --- @type Plugin
    local instance = {
        name = name,
        url = url,
        opts = pack.opts,
        config = pack.config,
        build = pack.build,
        dependencies = pack.dependencies,
    }
    setmetatable(instance, { __index = Plugin })
    return instance
end

function Plugin:load()
    if self.dependencies then
        local PluginsManager = require("eon.plugins.manager")
        for _, dep in ipairs(self.dependencies) do
            local name = Utils.get_plugin_name(dep);
            if not PluginsManager.has(name) then
                PluginsManager.add(dep)
            end
            PluginsManager.plugins[name]:load()
        end
    end
    vim.cmd("packadd " .. self.name)
    local module_name = self.name:gsub("%.nvim$", "")
    local is_load = pcall(require, module_name)
    if is_load then
        local pack = package.loaded[module_name]
        if pack.setup ~= nil then
            if self.opts ~= nil then
                pack.setup(self.opts)
            else
                pack.setup()
            end
        end
        if self.build ~= nil then
            self.build()
        end
        if self.config ~= nil then
            self.config(self, self.opts)
        end
    end
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
