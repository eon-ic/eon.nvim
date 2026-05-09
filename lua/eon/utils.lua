local M = {}
function M.get_plugin_name(url)
	return string.match(url, "([^/]+)$"):gsub("%.git$", "")
end
return M