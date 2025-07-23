-- Please see the LICENSE.txt file included with this distribution for
-- attribution and copyright information.

--luacheck: globals update onGroupChanged powergroup displaygroup

function onInit()
	powergroup.onValueChanged = onGroupChanged;
end

function update(bLocked)
	displaygroup.setReadOnly(bLocked);
	powergroup.setReadOnly(bLocked);

	if bLocked then
		displaygroup.setFrame(nil);
		powergroup.setFrame(nil);
	else
		displaygroup.setFrame("fielddark", 7, 5, 7, 5);
		powergroup.setFrame("fielddark", 7, 5, 7, 5);
	end
end

function onGroupChanged(sGroup) --luacheck: ignore 212
	local nodeItem = getDatabaseNode();
	local sGroup = powergroup.getValue()
	for _,nodePower in pairs(DB.getChildren(nodeItem, "powers")) do
		DB.setValue(nodePower, "group", "string", sGroup);
	end
end