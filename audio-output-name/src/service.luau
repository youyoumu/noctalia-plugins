--!nonstrict
-- Background service: polls wpctl status and publishes sink state
-- so all widget instances share a single wpctl call.
--

local parser = require("./lib/parser.luau")
local signals = require("../../.luau_modules/alien-signals/alien-signals.luau")

local createSignal = signals.signal
local createEffect = signals.effect

return function()
	local sinks, setSinks = createSignal({})
	local activeSink, setActiveSink = createSignal("")

	noctalia.setUpdateInterval(3000)

	createEffect(function()
		noctalia.state.set("sinks", sinks())
	end)

	createEffect(function()
		noctalia.state.set("active_sink", activeSink())
	end)

	local function update()
		noctalia.runAsync("wpctl status", function(result)
			if result.exitCode ~= 0 or result.stdout == "" then
				setSinks({})
				setActiveSink("")
				return
			end
			local allSinks = parser.getSinks(result.stdout)
			setSinks(allSinks)
			for _, sink in allSinks do
				if sink.active then
					setActiveSink(sink.name)
					return
				end
			end
			setActiveSink("")
		end)
	end

	noctalia.state.watch("refresh", function()
		update()
	end)

	return {
		update = update,
	}
end
