local fs = require("@lune/fs")

-- exclude these directories from test scanning
local EXCLUDE_DIRS = { ".git", ".github", ".lune", ".tools", ".vscode", ".luau_modules" }

-- get root directory from this script's location
local dirname = debug.info(1, "s"):match("(.*/)")
local root = dirname .. ".."

-- recursively find all *.test.luau files
local function findTests(dir: string): { string }
	local tests = {}
	for _, entry in fs.readDir(dir) do
		local path = dir .. "/" .. entry
		if fs.isDir(path) then
			local excluded = false
			for _, exclude in EXCLUDE_DIRS do
				if entry == exclude then
					excluded = true
					break
				end
			end
			if not excluded then
				for _, f in findTests(path) do
					table.insert(tests, f)
				end
			end
		elseif entry:match("%.test%.luau$") then
			table.insert(tests, path)
		end
	end
	return tests
end

-- scan and require all test files
for _, path in findTests(root) do
	-- convert absolute path to relative path from this script
	local rel = path:sub(#dirname):gsub("%.luau$", "")
	require("." .. rel)()
end

-- initialize a reporter (there is currently only one... this one, but you can make your own!)
local console_reporter = require("@frktest/reporters/console_reporter")
console_reporter.init()

-- run the tests
local frktest = require("@frktest/frktest")
frktest.run()
