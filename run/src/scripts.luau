--!nonstrict
-- Loads the run plugin's scripts from the JSON file configured in the plugin
-- settings (noctalia.getConfig("scripts_path")). Edit that file to add, remove,
-- or modify scripts.

local M = {}

local path = noctalia.getConfig("scripts_path") or "scripts.json"

local contents, readErr = noctalia.readFile(path)
if contents then
	local decoded, decodeErr = noctalia.json.decode(contents)
	if type(decoded) == "table" then
		M.scripts = decoded
	else
		noctalia.log(`run: failed to parse {path}: {decodeErr}`)
		M.scripts = {}
	end
else
	noctalia.log(`run: failed to read {path}: {readErr}`)
	M.scripts = {}
end

return M
