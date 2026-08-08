--!nonstrict
-- Bar widget that displays the current audio output device name.
-- Reads shared state from the service; cycles outputs on click.
--

local signals = require("../../.luau_modules/alien-signals/alien-signals.luau")

local createSignal = signals.signal
local createEffect = signals.effect
local createMemo = signals.computed

local NAME_MAP = {
	["Starship/Matisse HD Audio Controller Digital Stereo (IEC958)"] = "Samsung Soundbar",
	["SteelSeries Arctis 5 Game"] = "SteelSeries Arctis 5",
}

return function()
	local name, setName = createSignal(noctalia.state.get("active_sink") or "")
	local glyph, setGlyph = createSignal(noctalia.getConfig("glyph"))
	local sinks, setSinks = createSignal(noctalia.state.get("sinks") or {})
	local otherName = createMemo(function()
		local other = NAME_MAP[name()]
		return if other then other else name()
	end)

	barWidget.setTooltip(noctalia.tr("title"))

	createEffect(function()
		barWidget.setGlyph(glyph())
	end)

	createEffect(function()
		local name = otherName()
		barWidget.setText(name ~= "" and name or noctalia.tr("no_device"))
	end)

	noctalia.state.watch("active_sink", function(value)
		setName(value or "")
	end)

	noctalia.state.watch("sinks", function(value)
		setSinks(value or {})
	end)

	local function onClick()
		local current = sinks()
		if #current == 0 then
			return
		end
		local activeIdx = 1
		for i, sink in current do
			if sink.active then
				activeIdx = i
				break
			end
		end
		local nextIdx = (activeIdx % #current) + 1
		local nextSink = current[nextIdx]
		noctalia.runAsync(`wpctl set-default {nextSink.id}`, function(result)
			if result.exitCode == 0 then
				noctalia.state.set("refresh", nil)
			end
		end)
	end

	local function onConfigChanged()
		setGlyph(noctalia.getConfig("glyph"))
	end

	return {
		onClick = onClick,
		onConfigChanged = onConfigChanged,
	}
end
