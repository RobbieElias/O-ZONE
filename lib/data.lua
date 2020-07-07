-- Simple library to save/get/update data from saved json file

local data = {}
local loadsave = require("lib.loadsave")

function data:init()
	local storage = {
		consent = nil,
	    gamesPlayed = 0,
	    highScore = 0,
	    highestLevel = 1,
	    lastLevelPlayed = -1,
	}

	data.storage = storage
end

function data:save()
	loadsave.saveTable(data.storage, "storage.json")
	print("data saved")
end

function data:update(option, val)
	data.storage[option] = val
end

function data:get(option)
	if data.storage[option] ~= nil then
		return data.storage[option]
	else
		print("no field " .. option)
		return nil
	end
end

function data:load()
	local storage = loadsave.loadTable("storage.json")
	if storage ~= nil then
		data.storage = storage
		print("data loaded")
	else
		data:init()
		data:save()
	end
end

function data:wipe()
	data:init()
	data:save()
	print("data wiped")
end

return data

