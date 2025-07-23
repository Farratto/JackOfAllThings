-- Please see the LICENSE.txt file included with this distribution for
-- attribution and copyright information.

--luacheck: globals isRecord onCurrencyUpdate hideItemPowers

--local _tDefaultCurrencyPaths = { "coins" };
local bPC;

function onInit()
	if string.sub(DB.getPath(getDatabaseNode()), 1, 9) == 'charsheet' then
		bPC = true;
	else
		bPC = false;
	end

	if super and super.onInit then super.onInit() end

	if not bPC and isRecord then
		onCurrencyUpdate();
		OptionsManager.registerCallback("CURR", onCurrencyUpdate);
		CurrencyManager.registerCallback(onCurrencyUpdate);
	end

	if bPC then
		hideItemPowers();
	end
end

function onClose()
	if super and super.onClose then super.onClose() end

	if not bPC and isRecord then
		OptionsManager.unregisterCallback("CURR", onCurrencyUpdate);
		CurrencyManager.unregisterCallback(onCurrencyUpdate);
	end
end

function isRecord()
	--local sPath = getDatabaseNode.getPath();
	return StringManager.startsWith("npc") or StringManager.startsWith("reference");
end

function onCurrencyUpdate()
	CharEncumbranceManager.updateEncumbrance(getDatabaseNode());
end

function hideItemPowers()
	powerstitle.setVisible(false);
	powerstitle.setEnabled(false);
	powers.setVisible(false);
	powers.setEnabled(false);
end