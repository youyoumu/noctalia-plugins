local fs = require("@lune/fs")
local serde = require("@lune/serde")
local frktest = require("@frktest/frktest")
local test = frktest.test
local check = frktest.assert.check
local parser = require("./parser")

local dirname = debug.info(1, "s"):match("(.*/)")
local fixture = fs.readFile(dirname .. "../../fixtures/wpctl_status_1.txt")
local dumpFixture = serde.decode("json", fs.readFile(dirname .. "../../fixtures/pw-dump_1.json"))

return function()
	test.suite("parser", function()
		test.case("parses active sink from wpctl status", function()
			local result = parser.getActiveSinkFromWpctl(fixture)
			check.equal(result, "Starship/Matisse HD Audio Controller Digital Stereo (IEC958)")
		end)

		test.case("returns nil on empty wpctl status", function()
			local result = parser.getActiveSinkFromWpctl("")
			check.falsy(result)
		end)

		test.case("returns nil on no sinks section", function()
			local result = parser.getActiveSinkFromWpctl("Audio\n ├─ Sources:\n │  *   1. foo [vol: 0.50]")
			check.falsy(result)
		end)

		test.case("returns nil on no active sink", function()
			local result =
				parser.getActiveSinkFromWpctl("Audio\n ├─ Sinks:\n │      1. Some Device [vol: 1.00]\n ├─ Sources:")
			check.falsy(result)
		end)

		test.case("parses all sinks from wpctl status", function()
			local result = parser.getSinks(fixture)
			check.equal(#result, 1)
			check.equal(result[1].id, 35)
			check.equal(result[1].name, "Starship/Matisse HD Audio Controller Digital Stereo (IEC958)")
			check.equal(result[1].active, true)
		end)

		test.case("returns empty table on empty wpctl status", function()
			local result = parser.getSinks("")
			check.equal(#result, 0)
		end)

		test.case("parses multiple sinks", function()
			local multiSink = "Audio\n ├─ Sinks:\n │    *1. Device A [vol: 0.80]\n │      2. Device B [vol: 1.00]\n ├─ Sources:"
			local result = parser.getSinks(multiSink)
			check.equal(#result, 2)
			check.equal(result[1].id, 1)
			check.equal(result[1].name, "Device A")
			check.equal(result[1].active, true)
			check.equal(result[2].id, 2)
			check.equal(result[2].name, "Device B")
			check.equal(result[2].active, false)
		end)

		test.case("parses active sink from pw-dump", function()
			local result = parser.getActiveSinkFromPwDump(dumpFixture)
			check.equal(result, "Starship/Matisse HD Audio Controller Digital Stereo (IEC958)")
		end)

		test.case("returns nil on empty pw-dump", function()
			local result = parser.getActiveSinkFromPwDump({})
			check.falsy(result)
		end)

		test.case("returns nil on no default metadata", function()
			local result = parser.getActiveSinkFromPwDump({
				{ type = "PipeWire:Interface:Metadata", props = { ["metadata.name"] = "settings" }, metadata = {} },
			})
			check.falsy(result)
		end)

		test.case("returns nil on no matching node", function()
			local result = parser.getActiveSinkFromPwDump({
				{
					type = "PipeWire:Interface:Metadata",
					props = { ["metadata.name"] = "default" },
					metadata = { { key = "default.audio.sink", value = { name = "nonexistent" } } },
				},
			})
			check.falsy(result)
		end)
	end)
end
