--!nonstrict
-- Launcher provider for the run plugin.
-- Loads scripts from the JSON file configured in plugin settings,
-- fuzzy-matches on query, and runs the selected script via noctalia.runAsync.

local scripts = require("./scripts.luau")

return function()
	local function buildRows(query)
		local rows = {}
		local trimmed = noctalia.string.trim(query)

		for _, script in scripts.scripts do
			if trimmed == "" or noctalia.fuzzyScore(trimmed, script.title) then
				table.insert(rows, {
					id = script.id,
					title = script.title,
					subtitle = script.subtitle,
					glyph = script.glyph,
					category = script.category,
				})
			end
		end

		if #rows == 0 then
			rows[1] = {
				id = "",
				title = noctalia.tr("no_match"),
				subtitle = trimmed,
				glyph = "mood-empty",
			}
		end

		return rows
	end

	local function onQuery(query)
		launcher.setResults(query, buildRows(query))
	end

	local function onActivate(id)
		if id == "" then
			return
		end

		for _, script in scripts.scripts do
			if script.id == id then
				noctalia.runAsync(script.command)
				return
			end
		end
	end

	return {
		onQuery = onQuery,
		onActivate = onActivate,
	}
end
