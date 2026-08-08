--!nonstrict

local Service = require("./src/service.luau")()

update = Service.update
onConfigChanged = Service.onConfigChanged
