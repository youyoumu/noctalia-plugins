local M = {}

export type Sink = {
	id: number,
	name: string,
	active: boolean,
}

M.getSinks = function(statusOutput: string): { Sink }
	local sinks: { Sink } = {}
	local inSinks = false
	for line in statusOutput:gmatch("[^\n]+") do
		if line:match("Sinks:") then
			inSinks = true
		end
		if inSinks then
			if line:match("Sources:") or line:match("Filters:") or line:match("Streams:") then
				break
			end
			local id, desc = line:match("(%d+)%..-%s*(.-)%s*%[vol:")
			if id and desc then
				table.insert(sinks, {
					id = tonumber(id) :: number,
					name = desc,
					active = line:match("%*") ~= nil,
				})
			end
		end
	end
	return sinks
end

M.getActiveSinkFromWpctl = function(statusOutput: string): string?
	local sinks = M.getSinks(statusOutput)
	for _, sink in sinks do
		if sink.active then
			return sink.name
		end
	end
	return nil
end

M.getActiveSinkFromPwDump = function(dump: { any }): string?
	-- Find default sink name from metadata
	local defaultSinkName: string? = nil
	for _, obj in dump do
		if obj.type == "PipeWire:Interface:Metadata" and obj.props["metadata.name"] == "default" then
			for _, entry in obj.metadata do
				if entry.key == "default.audio.sink" then
					defaultSinkName = entry.value.name
					break
				end
			end
		end
	end
	if not defaultSinkName then
		return nil
	end

	-- Find node with matching name and return its description
	for _, obj in dump do
		if obj.type == "PipeWire:Interface:Node" and obj.info.props["node.name"] == defaultSinkName then
			return obj.info.props["node.description"]
		end
	end
	return nil
end

return M
