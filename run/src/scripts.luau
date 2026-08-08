--!nonstrict
-- Hardcoded script definitions for the run plugin.
-- Edit this table to add, remove, or modify scripts.

local M = {}

M.scripts = {
	{
		id = "screenshot-region",
		title = "Screenshot Region",
		subtitle = "Capture a selected region",
		glyph = "crop",
		category = "Screenshot",
		command = "bash ~/dotfiles/script/screenshot.sh region",
	},
	{
		id = "screenshot-window",
		title = "Screenshot Window",
		subtitle = "Capture a specific window",
		glyph = "app-window",
		category = "Screenshot",
		command = "bash ~/dotfiles/script/screenshot.sh window",
	},
	{
		id = "screenshot-screen",
		title = "Screenshot Screen",
		subtitle = "Capture the current monitor",
		glyph = "device-desktop",
		category = "Screenshot",
		command = "bash ~/dotfiles/script/screenshot.sh monitor",
	},
	{
		id = "screenshot-region-delay",
		title = "Screenshot Region (Delay)",
		subtitle = "3 second delay, then select region",
		glyph = "clock",
		category = "Screenshot",
		command = "bash ~/dotfiles/script/screenshot.sh region-delay",
	},
	{
		id = "screenshot-region-delay-annotate",
		title = "Screenshot Region (Annotate)",
		subtitle = "Select region, annotate in Satty",
		glyph = "pencil",
		category = "Screenshot",
		command = "bash ~/dotfiles/script/screenshot.sh region-delay-annotate",
	},
}

return M
