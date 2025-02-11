-- Please see the LICENSE.txt file included with this distribution for
-- attribution and copyright information.

-- luacheck: globals registerOptions openTargetWindow closeAllTargetWindows handleTargetWindowOpen
-- luacheck: globals handleCloseTargetWindow getControllingClient sendOpenTargetWindow openTargetWindow
-- luacheck: globals closeTargetWindow sendCloseTargetWindow checkOpenTargetWindow getRootCommander
-- luacheck: globals fonDoubleClick onDoubleClickJOAT handlePictureRequest createPictureItemSelective
-- luacheck: globals hasExtension

OOB_MSGTYPE_TRGTWNDW = "targetwindow";
OOB_MSGTYPE_CLOSETRGTWNDW = "closetargetwindow";
OOB_MSGTYPE_REQUEST_PIC = 'request_picture';

fonDoubleClick = '';
local tExtensions = {};

function onInit()
	registerOptions();

	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_TRGTWNDW, handleTargetWindowOpen);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_CLOSETRGTWNDW, handleCloseTargetWindow);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_REQUEST_PIC, handlePictureRequest);

	fonDoubleClick = Token.onDoubleClick;
	Token.onDoubleClick = onDoubleClickJOAT;

	if Session.IsHost then
		CombatManager.setCustomTurnStart(checkOpenTargetWindow);
		CombatManager.setCustomTurnEnd(closeAllTargetWindows);
	end
end

function registerOptions()
	-- Remove item from inventory when destoyed
	OptionsManager.registerOption2("IDLU", true, "option_header_knk", "option_label_IDLU", "option_entry_cycler",
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("SCIP", true, "option_header_knk", "option_label_SCIP", "option_entry_cycler",
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("IPAE", true, "option_header_knk", "option_label_IPAE", "option_entry_cycler",
		{ labels = "option_label_disable", values = "off", baselabel = "option_label_enable", baseval = "on", default = "on" });
	-- ASED option to be used at a later date.
	-- OptionsManager.registerOption2("ASED", true, "option_header_knk", "option_label_ASED", "option_entry_cycler",
	-- 	{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOptionData({	sKey = 'AOTW', bLocal = true, sGroupRes = 'option_header_knk' });
	OptionsManager.registerOptionData({	sKey = 'ACTW', bLocal = true, sGroupRes = 'option_header_knk' });
	OptionsManager.registerOptionData({	sKey = 'AUTO_SHARE_PICS', sGroupRes = 'option_header_knk', tCustom = {
		default = "on" }
	});
end

function hasExtension(sExtName)
	if not tExtensions[1] then tExtensions = Extension.getExtensions() end
	if not sExtName then return end
	for _,sExtension in ipairs(tExtensions) do
		if sExtension == sExtName then
			return true;
		end
	end
	return false;
end

function checkOpenTargetWindow(nodeCT)
	local sOwner = getControllingClient(nodeCT);

	if sOwner then
		sendOpenTargetWindow(nodeCT)
	else
		openTargetWindow(nodeCT);
	end
end

function closeAllTargetWindows(nodeCT)
	closeTargetWindow(nodeCT);
	local sOwner = getControllingClient(nodeCT);
	if sOwner then
		sendCloseTargetWindow(sOwner, nodeCT);
	end
end

function handleTargetWindowOpen(msgOOB)
	if OptionsManager.isOption('AOTW', 'off') then
		return;
	end
	local nodeCT = msgOOB.sCTNodeID;
	if nodeCT then
		openTargetWindow(nodeCT);
	else
		Debug.console("DataOptionsKNK.handleTargetWindowOpen - not nodeCT");
	end
end

function handleCloseTargetWindow(msgOOB)
	if OptionsManager.isOption('ACTW', 'off') then
		return;
	end
	local nodeCT = msgOOB.sCTNodeID;
	if nodeCT then
		closeTargetWindow(nodeCT);
	else
		Debug.console("DataOptionsKNK.handleCloseTargetWindow - not nodeCT");
	end
end

---For a given cohort actor, determine the root character node that owns it
function getRootCommander(rActor)
	if not rActor then
		Debug.console("DataOptionsKNK.getRootCommander - rActor doesn't exist");
		return;
	end
	local sRecord = ActorManager.getCreatureNodeName(rActor);
	local sRecordSansModule = StringManager.split(sRecord, "@")[1];
	local aRecordPathSansModule = StringManager.split(sRecordSansModule, ".");
	if aRecordPathSansModule[1] and aRecordPathSansModule[2] then
		return aRecordPathSansModule[1] .. "." .. aRecordPathSansModule[2];
	end
	return nil;
end

--Returns nil for inactive identities and those owned by the GM
function getControllingClient(nodeCT)
	if not nodeCT then
		Debug.console("DataOptionsKNK.getControllingClient - nodeCT doesn't exist");
		return;
	end
	local sPCNode = nil;
	local rActor = ActorManager.resolveActor(nodeCT);
	local sNPCowner;
	if ActorManager.isPC(rActor) then
		sPCNode = ActorManager.getCreatureNodeName(rActor);
	else
		sNPCowner = DB.getValue(nodeCT, "NPCowner", "");
		if sNPCowner == "" then
			if Pets and Pets.isCohort(rActor) then
				sPCNode = getRootCommander(rActor);
			else
				if FriendZone and FriendZone.isCohort(rActor) then
					sPCNode = getRootCommander(rActor);
				end
			end
		end
	end

	if sPCNode or sNPCowner then
		for _, value in pairs(User.getAllActiveIdentities()) do
			if sPCNode then
				if "charsheet." .. value == sPCNode then
					return User.getIdentityOwner(value);
				end
			end
			if sNPCowner then
				local sIDOwner = User.getIdentityOwner(value)
				if sIDOwner == sNPCowner then
					return sIDOwner;
				end
			end
		end
	end
	return nil;
end

function sendOpenTargetWindow(nodeCT)
	if not nodeCT then
		nodeCT = CombatManager.getActiveCT();
	end
	local sOwner = getControllingClient(nodeCT);

	if sOwner then
		local msgOOB = {};
		msgOOB.type = OOB_MSGTYPE_TRGTWNDW;
		msgOOB.sCTNodeID = DB.getPath(nodeCT);
		Comm.deliverOOBMessage(msgOOB, sOwner);
	else
		ChatManager.SystemMessage(Interface.getString("msg_NotConnected"));
	end
end

function openTargetWindow(nodeCT)
	if OptionsManager.isOption('AOTW', 'off') then
		return;
	end
	if not nodeCT then
		nodeCT = CombatManager.getActiveCT();
	end
	--local wTargets = Interface.findWindow('window_targets', nodeCT);
	local wTargets = Interface.openWindow('window_targets', nodeCT);
	if wTargets then
		wTargets.bringToFront();
	--else
	--	Interface.openWindow('window_targets', nodeCT);
	end
end

function closeTargetWindow(nodeCT)
	if OptionsManager.isOption('ACTW', 'off') then
		return;
	end
	if not nodeCT then
		Debug.console("DataOptionsKNK.closeTargetWindow - not nodeCT");
		return;
	end
	local wTargets = Interface.findWindow('window_targets', nodeCT);
	if wTargets then wTargets.close() end
end

function sendCloseTargetWindow(sOwner, nodeCT)
	if not nodeCT then
		Debug.console("DataOptionsKNK.sendCloseTargetWindow - not nodeCT");
		return;
	end
	if not sOwner then sOwner = getControllingClient(nodeCT) end
	if sOwner then
		local msgOOB = {};
		msgOOB.type = OOB_MSGTYPE_CLOSETRGTWNDW;
		msgOOB.sCTNodeID = DB.getPath(nodeCT);
		Comm.deliverOOBMessage(msgOOB, sOwner);
	else
		ChatManager.SystemMessage(Interface.getString("msg_NotConnected"));
	end
end

function onDoubleClickJOAT(token, image) --luacheck: ignore 212
	if not Session.IsHost and OptionsManager.isOption('AUTO_SHARE_PICS', 'on') then
		local nodeCT = CombatManager.getCTFromToken(token);
		if nodeCT and CombatManager.getFactionFromCT(nodeCT) ~= "friend" then
			local sAsset = DB.getValue(nodeCT, 'picture')
			if sAsset and sAsset ~= '' then
				local sName;
				local nIsId = DB.getValue(nodeCT, 'isidentified');
				if not nIsId or nIsId == 1 then
					sName = DB.getValue(nodeCT, 'name');
				else
					sName = DB.getValue(nodeCT, 'nonid_name');
				end
				if not sName or sName == '' then sName = 'Unidentified' end
				local msgOOB = {};
				msgOOB.sAsset = sAsset;
				msgOOB.sName = sName;
				msgOOB.sOwner = Session.UserName;
				msgOOB.type = OOB_MSGTYPE_REQUEST_PIC;
				Comm.deliverOOBMessage(msgOOB);
			end
		end
	end
end
function handlePictureRequest(msgOOB)
	createPictureItemSelective(msgOOB.sAsset, msgOOB.sName, msgOOB.sOwner);
end
function createPictureItemSelective(sAsset, sName, sOwner)
	if (sAsset or "") == "" then
		return false;
	end
	if (sName or "") == "" then
		sName = UtilityManager.getAssetBaseFileName(sAsset);
	end

	local nodePicture = nil;
	local sNameFind = StringManager.trim(sName);
	local tMappings = RecordDataManager.getDataPaths("picture");
	for _,sMapping in ipairs(tMappings) do
		for _,v in ipairs(DB.getChildrenGlobal(sMapping)) do
			if (StringManager.trim(DB.getValue(v, "name", "")) == sNameFind) and (DB.getValue(v, "picture", "") == sAsset) then
				nodePicture = v;
				break;
			end
		end
		if nodePicture then
			break;
		end
	end
	if not nodePicture then
		nodePicture = DB.createChild("picture");
		DB.setValue(nodePicture, "name", "string", sName);
		DB.setValue(nodePicture, "picture", "token", sAsset);
	end

	if sOwner then
		local msgOOB = {};
		msgOOB.type = PictureManager.OOB_MSGTYPE_PICTURE_SHARE;
		msgOOB.sRecordNode = DB.getPath(nodePicture);
		Comm.deliverOOBMessage(msgOOB, sOwner);
	end

	return true;
end
