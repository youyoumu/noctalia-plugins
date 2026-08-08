--!nonstrict

local Launcher = require("./src/launcher.luau")()

onQuery = Launcher.onQuery
onActivate = Launcher.onActivate
