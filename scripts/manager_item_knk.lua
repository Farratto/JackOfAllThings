-- Please see the LICENSE.txt file included with this distribution for
-- attribution and copyright information.

--luacheck: globals nodeBelongsToItem onCarriedChanged

function onInit()
	ItemManager.setInventoryPaths("charsheet",
	{
		"inventorylist",
		"cohorts.*.inventorylist",
	});
	ItemManager.setInventoryPaths("combattracker.list",
	{
		"inventorylist",
		"cohorts.*.inventorylist",
	});
	ItemManager.setInventoryPaths("npc",
	{
		"inventorylist",
		"cohorts.*.inventorylist",
	});
	ItemManager.setInventoryPaths("reference.npcdata",
	{
		"inventorylist",
		"cohorts.*.inventorylist",
	});
	local tData = {
		tCurrencyPaths = ItemManager.getDefaultCurrencyPaths()
				  };
	ItemManager.setActorTypeInfo("npc", tData);

	--[[if Session.IsHost then
		DB.addHandler("charsheet.*.inventorylist.*.carried", "onUpdate", onCarriedChanged);
	end]]
end

function nodeBelongsToItem(nodePower)
	if not nodePower then
		return false;
	end

	local sPath = nodePower.getPath();
	return (LibraryData.getRecordTypeFromRecordPath(sPath) == "item") or (sPath:match("inventorylist") ~= nil);
end

--[[function onCarriedChanged(nodeChanged)
	--local nCarried = DB.getValue(nodeChanged, '.', 0); --1 = carried, 2 = equipped, 0 = not carried
	local nodeItem = DB.getParent(nodeChanged);
	if not ItemPowerManager.shouldShowItemPowers(nodeItem) then return end
	local nodeItemPowers = DB.getChild(nodeItem, 'powers');
	if not nodeItemPowers then return end

	local nItemCharges = DB.getValue(nodeItem, 'prepared', 0);
	if nItemCharges == 0 then return end
	for _,node in pairs(DB.getChildren(nodeItemPowers, '.')) do
		local nSpellUses = DB.getValue(node, 'prepared', 0);
		if nSpellUses == 0 then DB.setValue(node, 'prepared', 'number', nItemCharges) end
	end
end]]