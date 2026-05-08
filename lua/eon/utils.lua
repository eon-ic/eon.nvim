local M = {}
function M.match_name(url)
	return string.match(url, "([^/]+)$"):gsub("%.git$", "")
end
return M