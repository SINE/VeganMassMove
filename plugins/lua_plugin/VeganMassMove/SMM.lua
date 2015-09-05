--
--	Author: 							SINE		(	github.com/SINE	)	
--	Credits: 
--											FH3095	(	github.com/FH3095	)	 for creating the base of this wonderful script and providing a fix for TS version 3.0.17
--											Dave												 for doing his first fix for the ChannelPassword problem (LUA cant read the TS Password Storage)
--


local channelMover = FH3095_getChannelMover()
local password = ""

channelMover.const.menuIDs = {
	MOVE_ALL_FROM_CHANNEL_TO_MY_CHANNEL = 1,
	MOVE_ALL_FROM_MY_CHANNEL_TO_CHANNEL = 2,
	MOVE_ALL_TEST = 3,
}
channelMover.var.menuItemID = 0

local lastactionTime = 0
local lastactionHandlerID = 0
local lastErrorTime = 0
local lastErrorHandled = 1
local ErrorInProcess = 0
local lastactiondata = {}

local function ResetLastActionData()
	local self = channelMover
	self:debugMsg("channelMover ResetLastActionData")
	astactionTime = 0
	lastactionHandlerID = 0
	lastErrorTime = 0
	lastErrorHandled = 1
	ErrorInProcess = 0
	lastactiondata = {}
end

function channelMover:printMsg(msg)
	ts3.printMessage(ts3.getCurrentServerConnectionHandlerID(), self.const.MODULE_NAME .. ": " .. msg, 1)
end


local function inTable(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return key end
    end
    return -1
end


function channelMover:debugMsg(msg)
	if self.const.DEBUG ~= 0 then
		if self.const.DEBUG_MSG_IN_CHAT ~= 0 then
			self:printMsg(msg)
		end
		print(self.const.MODULE_NAME .. ": " .. msg)
	end
end


function channelMover:getMyClientID(serverConnectionHandlerID)
	local myClientID, error = ts3.getClientID(serverConnectionHandlerID)
	if error ~= ts3errors.ERROR_ok then
		self:printMsg("Error getting own client ID: " .. error)
		return 0
	end
	if myClientID == 0 then
		self:printMsg("Not connected")
		return 0
	end
	
	return myClientID
end


function channelMover:getMyChannelID(serverConnectionHandlerID, myClientID)
	local myChannelID, error = ts3.getChannelOfClient(serverConnectionHandlerID, myClientID)
	if error ~= ts3errors.ERROR_ok then
		self:printMsg("Error getting own channel: " .. error)
		return 0
	end

	return myChannelID
end



function channelMover:getClientListOfChannel(serverConnectionHandlerID, targetChannelID)
	local function reverseTable(tbl)
		local ret = {}
		for i,v in ipairs(tbl) do
			ret[v] = i
		end
		return ret
	end

	local channelClients, error = ts3.getChannelClientList(serverConnectionHandlerID, targetChannelID)
	if error == ts3errors.ERROR_not_connected then
		self:printMsg("Not connected")
		return false
	elseif error ~= ts3errors.ERROR_ok then
		self:printMsg("Error getting client list of target channel: " .. error)
		return false
	end
	return reverseTable(channelClients)
end

function channelMover:moveUsers(serverConnectionHandlerID,targetChannelID,getClientsFunction)
		
		local myClientID = self:getMyClientID(serverConnectionHandlerID)
		lastactionTime = os.clock()
		lastactionHandlerID = serverConnectionHandlerID
		
		local channelClients = channelMover:getClientListOfChannel(serverConnectionHandlerID, targetChannelID)

		local clients, error = getClientsFunction(serverConnectionHandlerID)
		if error == ts3errors.ERROR_not_connected then
			self:printMsg("Not connected")
			return
		elseif error ~= ts3errors.ERROR_ok then
			self:printMsg("Error getting client list: " .. error)
			return
		end
		
		local counter = 0
		for i=1, #clients do
			if nil == channelClients[clients[i]] then
				--error = ts3.requestClientMove(serverConnectionHandlerID, clients[i], targetChannelID, password)
				test = ts3.requestClientMove(serverConnectionHandlerID, clients[i], targetChannelID, password)
				if test == ts3errors.ERROR_ok then
					counter = counter + 1
				else
					local clientName, error = ts3.getClientVariableAsString(serverConnectionHandlerID, clients[i], ts3defs.ClientProperties.CLIENT_NICKNAME)
					if error ~= ts3errors.ERROR_ok then
						self:printMsg("Error moving client with id " .. clients[i] .. ", additionally an error occurred while trying to receive this clients nickname: " .. error)
					else
						self:printMsg("Error moving \"" .. clientName .. "\": " .. error)
					end
				end
			end
		end
		--self:printMsg("Moved " .. counter .. " clients.")
		
		-- Zuruecksetzen des Passwortes
		--password = ""
		--self:printMsg("Password cleared.")
end

-- Funktion ueberpruef den angegebenen Channel auf Passwortschutz
function channelMover:checkPassword(serverConnectionHandlerID, SelectedChannelID)
	return ts3.getChannelVariableAsInt(serverConnectionHandlerID, SelectedChannelID, ts3defs.ChannelProperties.CHANNEL_FLAG_PASSWORD)
end

-- Eingabeaufforderung zur Passworteingabe
function channelMover:getChannelPassword(serverConnectionHandlerID)
	local myClientID = self:getMyClientID(serverConnectionHandlerID)
	ts3.requestSendPrivateTextMsg(serverConnectionHandlerID, "Bitte Channel-Passwort eingeben: ", myClientID)
end


function channelMover:onChannelMenuItemEvent(serverConnectionHandlerID, menuType, menuItemID, selectedItemID)
	self:debugMsg("ChannelMenuItemEvent: " .. serverConnectionHandlerID .. " , " .. menuType .. " , " .. menuItemID .. " , " .. selectedItemID)

	local myClientID = self:getMyClientID(serverConnectionHandlerID)
	local myChannelID = self:getMyChannelID(serverConnectionHandlerID,myClientID)
	
	if myChannelID == selectedItemID then
		self:printMsg("Kann nicht vom gleichen Channel in sich selbst verschieben.")
		return
	end
		
		
		---- VOM ZIEL CHANNEL IN DEN EIGENEN
	if menuItemID == self.const.menuIDs.MOVE_ALL_FROM_CHANNEL_TO_MY_CHANNEL then
		local function getClientsFunc(_)
			return ts3.getChannelClientList(serverConnectionHandlerID, selectedItemID)
		end
			lastactiondata = {
				serverConnectionHandlerID,
				myChannelID,
				getClientsFunc
			}
			self:moveUsers(serverConnectionHandlerID,myChannelID,getClientsFunc)
	end
	
	---- VOM EIGENEN CHANNEL IN DEN ZIELCHANNEL
	if menuItemID == self.const.menuIDs.MOVE_ALL_FROM_MY_CHANNEL_TO_CHANNEL then
		local function getClientsFunc(_)
			return ts3.getChannelClientList(serverConnectionHandlerID, myChannelID)
		end
		
			lastactiondata = {
				serverConnectionHandlerID,
				selectedItemID,
				getClientsFunc
			}

			self:moveUsers(serverConnectionHandlerID,selectedItemID,getClientsFunc)
	end
end






----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                                                                                                                     EVENTS
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function channelMover.onTextMessageEvent(serverConnectionHandlerID, targetMode, toID, fromID, fromName, fromUniqueIdentifier, message, ffIgnored)
	local self = channelMover
	self:debugMsg("TextMsgEvent: " .. serverConnectionHandlerID .. " , " .. targetMode .. " , " .. toID .. " , " .. fromID .. " , " .. fromName .. " , " .. fromUniqueIdentifier .. " , " .. message .. " , " .. ffIgnored)
	
	-- Passwort aus privatem Tab einlesen
	if toID == fromID then 
		if(  (serverConnectionHandlerID == lastactionHandlerID) and (lastErrorHandled == 0) ) then
			if message ~= "Bitte Channel-Passwort eingeben: " then
				lastactionTime = 0
				lastErrorHandled = 1
				ErrorInProcess = 0
				lastErrorTime = 0

				password = message
				
				self:debugMsg(	"password required > request enter password" )
				self:moveUsers(lastactiondata[1],lastactiondata[2],lastactiondata[3])
			end
		end
	end
end


-- Callback functions (not allowed to use channelMover:onMenuItemEvent)
function channelMover.onMenuItemEvent(serverConnectionHandlerID, menuType, menuItemID, selectedItemID)

	local self = channelMover
	self:debugMsg("MenuItemEvent: " .. serverConnectionHandlerID .. " , " .. menuType .. " , " .. menuItemID .. " , " .. selectedItemID)

	if menuType == ts3defs.PluginMenuType.PLUGIN_MENU_TYPE_CHANNEL then
		self:onChannelMenuItemEvent(serverConnectionHandlerID, menuType, menuItemID, selectedItemID)
	elseif menuType == ts3defs.PluginMenuType.PLUGIN_MENU_TYPE_GLOBAL then
		self:onGlobalMenuItemEvent(serverConnectionHandlerID, menuType, menuItemID)
	end
	
end


function channelMover.onCreateMenus(moduleMenuItemID)
	local self = channelMover
	self:debugMsg("Register Menu with moduleID " .. moduleMenuItemID)
	self.var.menuItemID = moduleMenuItemID

	return {
		{ts3defs.PluginMenuType.PLUGIN_MENU_TYPE_CHANNEL, self.const.menuIDs.MOVE_ALL_FROM_CHANNEL_TO_MY_CHANNEL, "Clients zu mir verschieben", self.const.MODULE_FOLDER .. "/move_here_by_SINE.png",},
		{ts3defs.PluginMenuType.PLUGIN_MENU_TYPE_CHANNEL, self.const.menuIDs.MOVE_ALL_FROM_MY_CHANNEL_TO_CHANNEL, "Clients dort hin verschieben", self.const.MODULE_FOLDER .. "/move_there_by_SINE.png",},
	}
end


function channelMover.onServerErrorEvent(serverConnectionHandlerID, errorMessage, errorCode, extraMessage)
	local self = channelMover
	self:debugMsg("onservererrorevent" .. serverConnectionHandlerID .. "," .. errorMessage .. "," .. errorCode .. "," .. extraMessage)
	local timenow = os.clock()
	
	if ( ((timenow-lastactionTime) <= 0.75) and (lastactionHandlerID == serverConnectionHandlerID) and ((ErrorInProcess == 0) or (os.clock()-ErrorInProcess >= 1.0)) ) then 
		if( errorCode == ts3errors.ERROR_channel_invalid_password ) then
			self:debugMsg(	"invalid password > request enter password" )
			ErrorInProcess = os.clock()
			
			lastErrorTime = os.clock()
			lastErrorHandled = 0
			self:getChannelPassword(serverConnectionHandlerID)
		else
			self:debugMsg(	"onservererrorevent > errorcode other" )
		end
	else 
		self:debugMsg(	"onservererrorevent > filter parameters not fitting" )
		
		self:debugMsg(	tostring(timenow)	)
		self:debugMsg(	tostring(lastactionTime)	)
		--self:debugMsg(	tostring((timenow-lastactionTime) <= 0.1)	)
		self:debugMsg(	tostring(lastactionHandlerID == serverConnectionHandlerID)	)
		self:debugMsg(	tostring(ErrorInProcess == 0)	)
	end	
end


function onServerPermissionErrorEvent(serverConnectionHandlerID, errorMessage, errorCode, failedPermissionID)
	local self = channelMover
	self:debugMsg( "onServerPermissionErrorEvent: ".. serverConnectionHandlerID .. "," ..errorMessage .. "," ..errorCode .. "," ..failedPermissionID)
end


function onChannelMoveEvent(serverConnectionHandlerID, channelID, newParentChannelID, invokerID, invokerName, invokerUniqueIdentifier)
	local self = channelMover
	self:debugMsg( "onChannelMoveEvent: " .. serverConnectionHandlerID .. "," .. channelID .. "," .. newParentChannelID .. "," .. invokerID .. "," .. invokerName .. "," .. invokerUniqueIdentifier)
end


function onClientMoveEvent(serverConnectionHandlerID, clientID, oldChannelID, newChannelID, visibility, moveMessage)
	local self = channelMover
	local myClientID = self:getMyClientID(serverConnectionHandlerID)
	
	if ( clientID == myClientID ) then
		self:debugMsg( "onClientMoveEvent: ".. serverConnectionHandlerID .. "," .. clientID .. "," .. oldChannelID .. "," .. newChannelID .. "," .. visibility .. "," .. moveMessage)
		if (	serverConnectionHandlerID == lastactionHandlerID	) then
			ResetLastActionData()
		end
	end
end


function onClientMoveMovedEvent(serverConnectionHandlerID, clientID, oldChannelID, newChannelID, visibility, moverID, moverName, moverUniqueIdentifier, moveMessage)
	local self = channelMover
	local myClientID = self:getMyClientID(serverConnectionHandlerID)
	
	if ( clientID == myClientID ) then
		self:debugMsg( "onClientMoveEvent: ".. serverConnectionHandlerID .. "," ..clientID .. "," ..oldChannelID .. "," ..newChannelID .. "," ..visibility .. "," ..moverID .. "," ..moverName .. "," ..moverUniqueIdentifier .. "," ..moveMessage)
		if (	serverConnectionHandlerID == lastactionHandlerID	) then
			ResetLastActionData()
		end
	end
end
