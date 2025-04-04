-- Please see the LICENSE.txt file included with this distribution for
-- attribution and copyright information.

--luacheck: globals onLockChanged update onMenuSelection

function onInit()
	local nodeRecord = getDatabaseNode();
	DB.addHandler(nodeRecord.getPath("locked"), "onUpdate", onLockChanged);

	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	update(bReadOnly);
end

function onLockChanged(nodeLocked)
	local bLocked = nodeLocked.getValue() ~= 0;
	update(bLocked);
end

function update(bReadOnly)
	if bReadOnly == nil then bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode()) end
	for _,control in ipairs(getControls()) do
		control.setReadOnly(bReadOnly);
		--if control.update then control.update() end
	end
	--prepared.setReadOnly(bReadOnly);
	--usesperiod.setReadOnly(bReadOnly);
	actions.update(bReadOnly, true);

	if bReadOnly then
		prepared.setFrame(nil);
		resetMenuItems();
	else
		prepared.setFrame("fielddark", 7, 5, 7, 5);

		if self.parentcontrol then
			self.windowlist = self.parentcontrol;
		end
		PowerManagerCore.registerDefaultPowerMenu(self);
		if self.parentcontrol then
			self.windowlist = nil;
		end
	end
end

function onMenuSelection(...)
	PowerManagerCore.onDefaultPowerMenuSelection(self, ...)
end