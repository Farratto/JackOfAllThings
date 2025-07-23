-- Please see the LICENSE.txt file included with this distribution for
-- attribution and copyright information.

--luacheck: globals getItemSourceType addEquippedSpellPC beginRecharging onTimeChanged rechargeItemPowers
--luacheck: globals getRechargeAmount calculateDailyRecharge handleItemRecharge shouldRollRecharge
--luacheck: globals onRechargeRoll distributeCharges handleItemChargesUsed destroyDischargedItem
--luacheck: globals beginRollDischargedItem handleRollDischargedItem onDischargeRoll rechargeDischargedItem
--luacheck: globals updateDischargeCount showCarriedOrEquipped shouldShowItemPowers getItemGroupName
--luacheck: globals beginCreatingItemGroup handleItemGroupCreation countCharges getActorResourceItem
--luacheck: globals isChargeResource getCurrentChargeResource getAvailableChargeResource rollRecharge
--luacheck: globals getItemResourceChargeSetters addChargeResourceChangedHandler EquippedEffectsManager
--luacheck: globals removeChargeResourceChangedHandler
--luacheck: globals FULL_RECHARGE_DAY_THRESHOLD RECHARGE_NONE RECHARGE_NORMAL RECHARGE_FULL ResourceManager
--luacheck: globals DAWN_TIME_OF_DAY NOON_TIME_OF_DAY DUSK_TIME_OF_DAY MIDNIGHT_TIME_OF_DAY

OOB_MSGTYPE_RECHARGE_ITEM = "rechargeitem";
OOB_MSGTYPE_CREATE_ITEM_GROUP = "createitemgroup";
OOB_MSGTYPE_ROLL_DISCHARGED_ITEM = "rolldischargeditem";

RECHARGE_NONE = 0;
RECHARGE_NORMAL = 1;
RECHARGE_FULL = 2;

DAWN_TIME_OF_DAY = 0.25;
NOON_TIME_OF_DAY = 0.5;
DUSK_TIME_OF_DAY = 0.75;
MIDNIGHT_TIME_OF_DAY = 0;

-- Only a few items could potentially be missing charges after 5 days, and even for those it would be extremely unlikely.
FULL_RECHARGE_DAY_THRESHOLD = 5;

local getItemSourceTypeOriginal;
local addEquippedSpellPCOriginal;

local nodeItemBeingEquiped; --luacheck: ignore 231
local nPreviousDateInMinutes;

-- Initialization
function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_CREATE_ITEM_GROUP, handleItemGroupCreation);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_RECHARGE_ITEM, handleItemRecharge);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_ROLL_DISCHARGED_ITEM, handleRollDischargedItem);

	ActionsManager.registerResultHandler("rechargeitem", onRechargeRoll);
	ActionsManager.registerResultHandler("dischargeitem", onDischargeRoll);

	if Session.IsHost then
		getItemSourceTypeOriginal = ItemManager.getItemSourceType;
		ItemManager.getItemSourceType = getItemSourceType;

		if TimeManager then
			nPreviousDateInMinutes = TimeManager.getCurrentDateinMinutes();
			TimeManager.addTimeChangeFunction(onTimeChanged);
		end

		--if not OptionsManager.isOption("IPAE", "off") then
			if EquippedEffectsManager then
				addEquippedSpellPCOriginal = EquippedEffectsManager.addEquippedSpellPC;
				EquippedEffectsManager.addEquippedSpellPC = addEquippedSpellPC;
			end
		--end
	end

	if ResourceManager then
		ResourceManager.addSpecialResource("Item Charges",
		{
			fIsMatch = isChargeResource,
			fGetValue = getCurrentChargeResource,
			fGetLimit = getAvailableChargeResource,
			fGetValueSetters = getItemResourceChargeSetters,
			fAddHandlers = addChargeResourceChangedHandler,
			fRemoveHandlers = removeChargeResourceChangedHandler
		});
	end
end

-- Overrides
function getItemSourceType(vNode)
	local sResult = getItemSourceTypeOriginal(vNode);
	if (sResult or "") == "" then
		local sNodePath = nil;
		if type(vNode) == "databasenode" then
			sNodePath = vNode.getPath();
		elseif type(vNode) == "string" then
			sNodePath = vNode;
		end

		if sNodePath then
			if StringManager.startsWith(sNodePath, "combattracker") then
				return "charsheet";
			end
			for _,vMapping in ipairs(LibraryData.getMappings("npc")) do
				if StringManager.startsWith(sNodePath, vMapping) then
					return "charsheet";
				end
			end
		end
	end
	return sResult;
end

function addEquippedSpellPC(nodeActor, nodeCarriedItem, nodeSpell, sName)
	if OptionsManager.isOption('IPAE', 'off') then
		return addEquippedSpellPCOriginal(nodeActor, nodeCarriedItem, nodeSpell, sName);
	end

	-- Add the new power if the item has not already been configured.
	if DB.getChildCount(nodeCarriedItem, "powers") == 0 then
		nodeItemBeingEquiped = nodeCarriedItem; -- Track that the item is being processed

		-- Grab charge info
		DB.setValue(nodeCarriedItem, "prepared", "number", DB.getValue(nodeSpell, "prepared", 0));
		DB.setValue(nodeCarriedItem, "rechargeperiod", "string", DB.getValue(nodeSpell, "rechargeperiod", ""));
		DB.setValue(nodeCarriedItem, "rechargetime", "string", DB.getValue(nodeSpell, "rechargetime", ""));
		DB.setValue(nodeCarriedItem, "rechargedice", "dice", DB.getValue(nodeSpell, "rechargedice", {}));
		DB.setValue(nodeCarriedItem, "rechargebonus", "number", DB.getValue(nodeSpell, "rechargebonus", 0));

		-- Check to see if it should be grouped.
		local sSource = DB.getValue(nodeSpell, "source", "");
		if (sSource == "Potion") or (sSource == "Scroll") or (sSource == "Wand") then
			DB.setValue(nodeCarriedItem, "displaygroup", "string", sSource .. "s");
		end

		-- Add the power
		PowerManager.addPower("power", nodeSpell, nodeCarriedItem); --original
--		CharPowerManager.addPowerDB(nodeCarriedItem, "power", nodeSpell); --new
		nodeItemBeingEquiped = nil; -- No longer tracking
	end
end

-- Recharging
function beginRecharging(nodeActor, bLong)
	local sPeriod = "short";
	if PowerManagerKw and PowerManagerKw.isExtended() then
		sPeriod = "extended";
	elseif bLong then
		sPeriod = "long";
	end

	for _,nodeItem in pairs(DB.getChildren(nodeActor.getPath("inventorylist"))) do
		rechargeItemPowers(nodeItem, sPeriod);
	end
end

function onTimeChanged()
	local nNewDateInMinutes = TimeManager.getCurrentDateinMinutes();

	if not nNewDateInMinutes or not nPreviousDateInMinutes or nNewDateInMinutes <= nPreviousDateInMinutes then
		nPreviousDateInMinutes = nNewDateInMinutes;
		return;
	end
	local nElapsedDays = TimeManager.convertMinutestoDays(nNewDateInMinutes - nPreviousDateInMinutes);
	local _,nCurrentTimeOfDay = math.modf(TimeManager.convertMinutestoDays(nNewDateInMinutes));

	for _,nodeCombatant in pairs(CombatManager.getCombatantNodes()) do
		local sClass, sRecord = DB.getValue(nodeCombatant, "link", "", "");
		if sClass == "charsheet" and sRecord ~= "" then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				nodeCombatant = nodePC;
			end
		end
		for _,nodeItem in pairs(DB.getChildren(nodeCombatant.getPath("inventorylist"))) do
			rechargeItemPowers(nodeItem, "daily", nCurrentTimeOfDay, nElapsedDays);
		end
	end

	nPreviousDateInMinutes = nNewDateInMinutes;
end

function rechargeItemPowers(nodeItem, sPeriod, nCurrentTimeOfDay, nElapsedDays)
	local nRechargeAmount, nRechargeCount = getRechargeAmount(nodeItem, sPeriod, nCurrentTimeOfDay, nElapsedDays);
	local messageOOB = {
		type=OOB_MSGTYPE_RECHARGE_ITEM,
		sItem=nodeItem.getPath(),
		sPeriod=sPeriod,
		sRechargeAmount=tostring(nRechargeAmount),
		sRechargeCount=tostring(nRechargeCount)
	};

	if Session.IsHost then
		local sOwner = DB.getOwner(nodeItem);
		if sOwner ~= "" then
			for _,vUser in ipairs(User.getActiveUsers()) do
				if vUser == sOwner then
					Comm.deliverOOBMessage(messageOOB, sOwner);
					return;
				end
			end
		end
		handleItemRecharge(messageOOB);
	end
end

function getRechargeAmount(nodeItem, sPeriod, nCurrentTimeOfDay, nElapsedDays)
	local sItemPeriod = DB.getValue(nodeItem, "rechargeperiod", "");
	if sPeriod == sItemPeriod then
		if sPeriod == "daily" then
			return calculateDailyRecharge(nodeItem, nCurrentTimeOfDay, nElapsedDays);
		end
		return RECHARGE_NORMAL;
	elseif sPeriod == "extended" then
		return RECHARGE_FULL;
	elseif (sPeriod == "long") and (sItemPeriod == "short") then
		return RECHARGE_NORMAL;
	end
	return RECHARGE_NONE;
end

function calculateDailyRecharge(nodeItem, nCurrentTimeOfDay, nElapsedDays)
	if nElapsedDays >= FULL_RECHARGE_DAY_THRESHOLD then
		return RECHARGE_FULL;
	end

	local sRechargeTime = DB.getValue(nodeItem, "rechargetime", "");
	local nRechargeTimeOfDay = DAWN_TIME_OF_DAY;
	if sRechargeTime == "noon" then
		nRechargeTimeOfDay = NOON_TIME_OF_DAY;
	elseif sRechargeTime == "dusk" then
		nRechargeTimeOfDay = DUSK_TIME_OF_DAY;
	elseif sRechargeTime == "midnight" then
		nRechargeTimeOfDay = MIDNIGHT_TIME_OF_DAY;
	end

	local nTolerance = 1e-10; -- Less than a thousandth of a seccond by Earth measure
	local nCount, nElapsedRemainder = math.modf(nElapsedDays); -- Recharge at least once for each full day that has past
	nElapsedRemainder = nElapsedRemainder - nTolerance; -- Account for the previous time being the recharge time.
	if math.abs(nCurrentTimeOfDay - nRechargeTimeOfDay) < nTolerance then
		-- Advancing 1 minute to the recharge time should trigger a single recharge.
		-- Advancing 1 day and 1 minute to the recharge time should trigger two recharges
		-- Advancing exactly 1 day to the recharge time should trigger a single recharge.
		if (nElapsedRemainder > 0) then
			nCount = nCount + 1;
		end
	else
		if nRechargeTimeOfDay > nCurrentTimeOfDay then
			-- Handle wrapping around midnight into a new day.
			nCurrentTimeOfDay = nCurrentTimeOfDay + 1;
		end
		if nRechargeTimeOfDay > (nCurrentTimeOfDay - nElapsedRemainder) then
			-- Increment the number of recharges if the previous time was before the recharge time and the current time is after.
			nCount = nCount + 1;
		end
	end

	if nCount > 0 then
		return RECHARGE_NORMAL, nCount;
	else
		return RECHARGE_NONE;
	end
end

function handleItemRecharge(msgOOB)
	local nodeItem = DB.findNode(msgOOB.sItem);
	if nodeItem then
		if shouldRollRecharge(nodeItem) then
			rollRecharge(nodeItem, msgOOB.sRechargeAmount, msgOOB.sRechargeCount);
		end

		-- Handle item powers that aren't dependent on charges.
		for _,nodePower in pairs(DB.getChildren(nodeItem, "powers")) do
			local sPowerPeriod = DB.getValue(nodePower, "chargeperiod", "");
			local bRecharge = (sPowerPeriod == "short" and StringManager.contains({"short", "long", "extended"}, msgOOB.sPeriod)) or
				(sPowerPeriod == "long" and StringManager.contains({"long", "extended"}, msgOOB.sPeriod)) or
				(sPowerPeriod == "extended" and msgOOB.sPeriod == "extended") or
				(sPowerPeriod == "intrigue" and msgOOB.sPeriod == "intrigue");
			if bRecharge then
				DB.setValue(nodePower, "cast", "number", 0);
			end
		end
	end
end

function shouldRollRecharge(nodeItem)
	local nPrepared = DB.getValue(nodeItem, "prepared", 0);
	local nCount = DB.getValue(nodeItem, "count", 0);
	local bIdentified = DB.getValue(nodeItem, "isidentified", 1) == 1;
	if bIdentified and (nCount > 0) and (nPrepared > 0) then
		local sMode = DB.getValue(nodeItem, "rechargemode", "");
		local nCharges = countCharges(nodeItem);
		if sMode == "" then
			return nCharges > 0;
		elseif sMode == "lose" then
			return nCharges < (nPrepared * nCount);
		else
			return true;
		end
	end

	return false;
end

function rollRecharge(nodeItem, sRechargeAmount, sRechargeCount)
	local aDice = {};
	local nMod = 0;
	local nRechargeAmount = tonumber(sRechargeAmount);
	local bRoll = false;
	if nRechargeAmount == RECHARGE_NORMAL then
		bRoll = true;
		aDice = DB.getValue(nodeItem, "rechargedice", {});
		nMod = DB.getValue(nodeItem, "rechargebonus");
	elseif nRechargeAmount == RECHARGE_FULL then
		bRoll = true;
		nMod = DB.getValue(nodeItem, "prepared");
	end

	if bRoll then
		local sDescription = DB.getValue(nodeItem, "name", "Unnamed Item") .. " [RECHARGE]";
		local rechargeRoll = {sType="rechargeitem", sDesc=sDescription, aDice=aDice, nMod=nMod, sItem=nodeItem.getPath()};
		local nCount = DB.getValue(nodeItem, "count", 0);
		if DB.getValue(nodeItem, "rechargesingle") == 1 then
			nCount = math.min(nCount, 1);
		end
		for index=1,nCount do --luacheck:ignore 213
			for count=1,(tonumber(sRechargeCount) or 1) do --luacheck:ignore 213
				ActionsManager.roll(nodeItem.getChild("..."), nil, rechargeRoll, false);
			end
		end
	end
end

function onRechargeRoll(rSource, _, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local nodeItem = DB.findNode(rRoll.sItem);
	if nodeItem then
		local nResult = ActionsManager.total(rRoll);
		local nPrepared = DB.getValue(nodeItem, "prepared", 1);
		local sMode = DB.getValue(nodeItem, "rechargemode", "");
		if sMode == "" then
			nResult = math.max(0, nResult);
		elseif sMode == "lose" then
			nResult = math.min(0, -nResult);
		end

		distributeCharges(nodeItem, nResult)
		updateDischargeCount(nodeItem, nPrepared);
	end

	-- Deliver roll message
	Comm.deliverChatMessage(rMessage);
end

function distributeCharges(nodeItem, nChargesToAdd)
	local nMax = DB.getValue(nodeItem, "prepared", 0) * DB.getValue(nodeItem, "count", 0);
	for _,nodePower in pairs(DB.getChildren(nodeItem, "powers")) do
		if nChargesToAdd == 0 then
			break;
		end
		if DB.getValue(nodePower, "chargeperiod", "") == "" then
			local nCast = DB.getValue(nodePower, "cast", 0);
			if nCast > nChargesToAdd then
				nCast = nCast - nChargesToAdd;
				if nCast > nMax then
					nChargesToAdd = nMax - nCast;
					nCast = nMax;
				else
					nChargesToAdd = 0;
				end
				DB.setValue(nodePower, "cast", "number", nCast);
			elseif nCast > 0 then
				nChargesToAdd = nChargesToAdd - nCast;
				DB.setValue(nodePower, "cast", "number", 0);
			end
		end
	end

	handleItemChargesUsed(nodeItem)
end

-- Discharging
function handleItemChargesUsed(nodeItem)
	local nChargeCount = DB.getValue(nodeItem, "prepared", 1);
	local nChargesUsed = countCharges(nodeItem);
	local nCurrentDischargeCount = DB.getValue(nodeItem, "discharged", 0);
	local nDischargeCount = math.floor(nChargesUsed / nChargeCount);
	local bDeleted = false;
	if nDischargeCount > nCurrentDischargeCount then
		local sOnDischarge = DB.getValue(nodeItem, "dischargeaction", "");
		if sOnDischarge == "destroy" then
			ChatManager.Message(DB.getValue(nodeItem, "name", "Unnamed Item") .. " - Item destroyed on discharge.",
				true,
				ActorManager.resolveActor(nodeItem));
			bDeleted = destroyDischargedItem(nodeItem, nChargeCount);
		elseif sOnDischarge == "roll" then
			beginRollDischargedItem(nodeItem);
		end
	end

	if not bDeleted then
		updateDischargeCount(nodeItem, nChargeCount);
	end
end

function destroyDischargedItem(nodeItem, nChargeCount)
	distributeCharges(nodeItem, nChargeCount);
	local nCount = DB.getValue(nodeItem, "count", 1) - 1;
	local bDeleted = false;
	if nCount == 0 and OptionsManager.getOption("IDLU") == "on" then
		nodeItem.delete();
		bDeleted = true
	else
		DB.setValue(nodeItem, "count", "number", nCount);
	end
	return bDeleted;
end

function beginRollDischargedItem(nodeItem)
	local messageOOB = {type=OOB_MSGTYPE_ROLL_DISCHARGED_ITEM, sItem=nodeItem.getPath()};

	if Session.IsHost then
		local sOwner = DB.getOwner(nodeItem);
		if sOwner ~= "" then
			for _,vUser in ipairs(User.getActiveUsers()) do
				if vUser == sOwner then
					Comm.deliverOOBMessage(messageOOB, sOwner);
					return;
				end
			end
		end
	end
	handleRollDischargedItem(messageOOB);
end

function handleRollDischargedItem(messageOOB)
	local nodeItem = DB.findNode(messageOOB.sItem);
	if nodeItem then
		local aDice = DB.getValue(nodeItem, "dischargedice", {});
		local nMod = 0;
		local sDescription = DB.getValue(nodeItem, "name", "Unnamed Item") .. " [DISCHARGE]";
		local dischargeRoll = {sType="dischargeitem", sDesc=sDescription, aDice=aDice, nMod=nMod, sItem=nodeItem.getPath()};
		ActionsManager.roll(nodeItem.getChild("..."), nil, dischargeRoll, false);
	end
end

function onDischargeRoll(rSource, _, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local nodeItem = DB.findNode(rRoll.sItem);
	if nodeItem then
		local nDestroyOn = DB.getValue(nodeItem, "destroyon", 0);
		local nRechargeOn = DB.getValue(nodeItem, "rechargeon", 0);
		local nResult = ActionsManager.total(rRoll);
		if nResult <= nDestroyOn then
			destroyDischargedItem(nodeItem, DB.getValue(nodeItem, "prepared"));
			rMessage.text = rMessage.text .. " Item destroyed on discharge."
		elseif (nResult >= nRechargeOn) and (nRechargeOn > 0) then
			rechargeDischargedItem(nodeItem);
		else
			updateDischargeCount(nodeItem, DB.getValue(nodeItem, "prepared", 1));
		end
	end

	-- Deliver roll message
	Comm.deliverChatMessage(rMessage);
end

function rechargeDischargedItem(nodeItem)
	local aDice = DB.getValue(nodeItem, "dischargerechargedice", {});
	local nMod = DB.getValue(nodeItem, "dischargerechargebonus", 0);
	local sDescription = DB.getValue(nodeItem, "name", "Unnamed Item") .. " [RECHARGE]";
	local rechargeRoll = {sType="rechargeitem", sDesc=sDescription, aDice=aDice, nMod=nMod, sItem=nodeItem.getPath()};
	ActionsManager.roll(nodeItem.getChild("..."), nil, rechargeRoll, false);
end

function updateDischargeCount(nodeItem, nChargeCount)
	if type(nodeItem) == "databasenode" then
		DB.setValue(nodeItem, "discharged", "number", math.floor(countCharges(nodeItem) / nChargeCount));
	end
end

-- Utility functions
function showCarriedOrEquipped(nodeItem)
	if OptionsManager.isOption("SCIP", "on") then
		return DB.getValue(nodeItem, "carried", 0) > 0;
	else
		return DB.getValue(nodeItem, "carried", 0) == 2;
	end
end

function shouldShowItemPowers(nodeItem)
	if OptionsManager.isOption("IPAE", "off") then
		return false
	end
	return DB.getValue(nodeItem, "count", 0) > 0 and
		showCarriedOrEquipped(nodeItem) and
		DB.getValue(nodeItem, "isidentified", 1) == 1 and
		((DB.getValue(nodeItem, "attune", 0) == 1) or not CharAttunementManager.doesItemAllowAttunement(nodeItem)) and
		DB.getChildCount(nodeItem, "powers") ~= 0;
end

function getItemGroupName(nodeItem)
	local sGroup = DB.getValue(nodeItem, "displaygroup", "");
	if sGroup == "" then
		sGroup = DB.getValue(nodeItem, "name", "");
	end
	return sGroup;
end

function beginCreatingItemGroup(sCharPath, sGroup)
	local messageOOB = {type=OOB_MSGTYPE_CREATE_ITEM_GROUP, sChar=sCharPath, sGroup=sGroup};
	if not Session.IsHost then
		Comm.deliverOOBMessage(messageOOB);
	else
		handleItemGroupCreation(messageOOB)
	end
end

function handleItemGroupCreation(msgOOB)
	if not Session.IsHost then
		return;
	end

	local nodeChar = DB.findNode(msgOOB.sChar);
	if not nodeChar then
		return;
	end

	local nodeGroups = nodeChar.getChild("itemgroups");
	if nodeGroups then
		for _,nodeGroup in pairs(nodeGroups.getChildren()) do
			if DB.getValue(nodeGroup, "name", "") == msgOOB.sGroup then
				return;
			end
		end
	else
		nodeGroups = nodeChar.createChild("itemgroups");
	end

	local nodeGroup = nodeGroups.createChild();
	if nodeGroup then
		DB.setValue(nodeGroup, "name", "string", msgOOB.sGroup);
	end
end

function countCharges(nodeItem)
	local nCount = 0;
	for _,nodePower in pairs(DB.getChildren(nodeItem.getPath("powers"))) do
		if DB.getValue(nodePower, "chargeperiod", "") == "" then
			nCount = nCount + DB.getValue(nodePower, "cast", 0);
		end
	end
	return nCount;
end

-- A return value of nil indicates that the resource does not
-- refer to the charges of an item in the actor's possession.
function getActorResourceItem(rActor, sResource)
	local sTargetItem, bMatch = sResource:lower():match("(.*) ?(charges)");
	if (not sTargetItem) or (not bMatch) then
		return;
	end

	sTargetItem = StringManager.trim(sTargetItem);
	local nodeActor = ActorManager.getCreatureNode(rActor);
	for _,nodeItem in pairs(DB.getChildren(nodeActor, "inventorylist")) do
		if (DB.getValue(nodeItem, "count", 0) > 0)
		and (DB.getValue(nodeItem, "prepared", 0) > 0)
		and (DB.getValue(nodeItem, "isidentified", 0) == 1)
		and (DB.getValue(nodeItem, "name", ""):lower() == sTargetItem)
		and ((DB.getValue(nodeItem, "attune", 0) == 1) or not CharAttunementManager.doesItemAllowAttunement(nodeItem)) then
			return nodeItem;
		end
	end
end

function isChargeResource(rActor, sResource)
	return getActorResourceItem(rActor, sResource) ~= nil;
end

function getCurrentChargeResource(rActor, sResource)
	local nodeItem = getActorResourceItem(rActor, sResource);
	local nCharges = DB.getValue(nodeItem, "prepared", 0);
	local nUsed = countCharges(nodeItem);
	return nCharges - nUsed;
end

function getAvailableChargeResource(rActor, sResource)
	local nodeItem = getActorResourceItem(rActor, sResource);
	return DB.getValue(nodeItem, "prepared", 0);
end

function getItemResourceChargeSetters(rActor, sResource)
	local nodeItem = getActorResourceItem(rActor, sResource);
	return {function(nValue)
		distributeCharges(nodeItem, nValue);
		local nCharges = DB.getValue(nodeItem, "prepared", 0);
		local nUsed = countCharges(nodeItem);
		return nCharges - nUsed, 0;
	end};
end

function addChargeResourceChangedHandler(rActor, sResource, fCurrentHandler, fLimitHandler)
	local nodeItem = getActorResourceItem(rActor, sResource);
	if fCurrentHandler then
		DB.addHandler(DB.getPath(nodeItem, "powers.*.cast"), "onUpdate", fCurrentHandler);
	end
	if fLimitHandler then
		DB.addHandler(DB.getPath(nodeItem, "prepared"), "onUpdate", fCurrentHandler);
	end
end

function removeChargeResourceChangedHandler(rActor, sResource, fCurrentHandler, fLimitHandler)
	local nodeItem = getActorResourceItem(rActor, sResource);
	if fCurrentHandler then
		DB.removeHandler(DB.getPath(nodeItem, "powers.*.cast"), "onUpdate", fCurrentHandler);
	end
	if fLimitHandler then
		DB.removeHandler(DB.getPath(nodeItem, "prepared"), "onUpdate", fCurrentHandler);
	end
end