--
--	Author: 							SINE		(	github.com/SINE	)	
--	Credits: 
--											FH3095	(	github.com/FH3095	)	 for creating the base of this wonderful script and providing a fix for TS version 3.0.17
--											Dave												 	 for doing his first fix for the ChannelPassword problem (LUA cant read the TS Password Storage)
--


require("ts3init")
require("ts3defs")
require("ts3errors")

local function protectTable(tbl)
	local function metaTableConstProtect(_,key,value)
		if nil ~= tbl[key] then
			print(tostring(key) .. " is a read-only variable! (Tried to change to \'" .. tostring(value) .. "\'.)")
			return
		end
		rawset(tbl,key,value)
	end

	return setmetatable ({}, -- You need to use a empty table, otherwise __newindex would only be called for first entry
		{
			__index = tbl, -- read access -> original table
			__newindex = metaTableConstProtect,
	})
end

local channelMover = {
	const = {
		MODULE_NAME = "VeganMassMove",
		MODULE_FOLDER = "VeganMassMove",
		DEBUG = 0,
		DEBUG_MSG_IN_CHAT = 0,
	},
	var = {},
}

channelMover.const = protectTable(channelMover.const)

function FH3095_getChannelMover()
	return channelMover
end

require(channelMover.const.MODULE_FOLDER .. "/SMM")



local registeredEvents = {
	createMenus = channelMover.onCreateMenus,
	onMenuItemEvent = channelMover.onMenuItemEvent,
	onTextMessageEvent = channelMover.onTextMessageEvent,
	onServerErrorEvent = channelMover.onServerErrorEvent,
	onServerPermissionErrorEvent = channelMover.onServerPermissionErrorEvent,
	onChannelMoveEvent = channelMover.onChannelMoveEvent,
	onClientMoveEvent = channelMover.onClientMoveEvent,
	onClientMoveMovedEvent = channelMover.onClientMoveMovedEvent,
}

ts3RegisterModule(channelMover.const.MODULE_NAME, registeredEvents)
