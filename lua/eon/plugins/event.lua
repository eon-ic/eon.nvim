---@class EventManager
---@field events table<vim.api.keyset.events,function[]>
local EventManager = {
	events = {},
}
function EventManager:new()
	local instant = {
		events = {},
	}
	setmetatable(instant, { __index = EventManager })
	return instant
end
---@param name vim.api.keyset.events|vim.api.keyset.events[]
function EventManager:emit(name)
	local names = {}
	if type(name) == "string" then
		table.insert(names, name)
	elseif type(name) == "table" then
		names = name
	end
	for _, name in pairs(names) do
		local fns = self.events[name]
		if fns ~= nil then
			for _, f in pairs(fns) do
				f()
			end
		end
	end
end

---@param name vim.api.keyset.events|vim.api.keyset.events[]
---@param fn function
function EventManager:addlistener(name, fn)
	local fns = self.events[name] or {}
	table.insert(fns, fn)
	self.events[name] = fns
end

return EventManager
