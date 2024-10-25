--
-- Please see the license.txt file included with this distribution for
-- attribution and copyright information.
--

-- luacheck: globals checkForKNK overrideSaveWindowState

local handleDropReorderOriginal;
local origlSaveWindowState

-- Initialization
function onInit()
	handleDropReorderOriginal = WindowManager.handleDropReorder;
	WindowManager.handleDropReorder = handleDropReorder;
	if Session.IsHost then
		origlSaveWindowState = WindowSaveManager.saveWindowState
		WindowSaveManager.saveWindowState = overrideSaveWindowState
		checkForKNK()
	end
end

function overrideSaveWindowState()
	local wWarning = Interface.findWindow('please_disable', '');
	if wWarning then
		wWarning.close();
	end
	origlSaveWindowState()
	WindowSaveManager.saveWindowState = origlSaveWindowState
end

function onClose()
	local wWarning = Interface.findWindow('please_disable', '');
	if wWarning then
		wWarning.close();
	end
	WindowSaveManager.saveWindowState = origlSaveWindowState
end

function checkForKNK()
	local tExtensions = Extension.getExtensions()
	for _,sExtension in ipairs(tExtensions) do
		if sExtension == 'KitNKaboodle' then
			Interface.openWindow('please_disable', '');
			return true
		end
	end
	local wWarning = Interface.findWindow('please_disable', '');
	if wWarning then
		wWarning.close();
	end
	return false
end

function handleHoverReorder(winTarget, bOnControl)
	if not winTarget or not winTarget.windowlist then
		return;
	end

	local draginfo = Input.getDragData();
	local bIsReorder = bOnControl and (draginfo ~= nil) and (draginfo.getType() == "reorder");
	local dropWidget = winTarget.windowlist.dropWidget;
	if dropWidget then
		dropWidget.setVisible(bIsReorder);
	end

	if not bIsReorder then
		return;
	end

	if not dropWidget then
		dropWidget = winTarget.windowlist.addBitmapWidget("tool_right_30");
		winTarget.windowlist.dropWidget = dropWidget;
	end

	local widgetWidth, widgetHeight = dropWidget.getSize(); -- luacheck: ignore 211

	local nodeDrag = draginfo.getDatabaseNode();
	local bDifferentParent = nodeDrag.getParent() ~= winTarget.windowlist.getDatabaseNode();
	local nOrder = DB.getValue(nodeDrag, "order", 0);
	local nHeight = 0;
	for nIndex, winChild in ipairs(winTarget.windowlist.getWindows()) do
		local _,windowHeight = winChild.getSize();
		if winChild == winTarget then
			if (nIndex > nOrder) or (bDifferentParent) then
				nHeight = nHeight + windowHeight;
			end
			break;
		end
		nHeight = nHeight + windowHeight;
	end

	dropWidget.setPosition("topleft", 20 + widgetWidth/2, nHeight);
end

function handleDropReorder(w, draginfo)
	if w and w.windowlist then
		if draginfo.isType("reorder") then
			local nodeTarget = w.getDatabaseNode();
			local nodeDrag = draginfo.getDatabaseNode();
			local nodeTargetParent = DB.getParent(nodeTarget);
			if nodeTargetParent ~= DB.getParent(nodeDrag) then
				local nodeNewAction = DB.createChild(nodeTargetParent);
				DB.copyNode(nodeDrag, nodeNewAction);
				draginfo.setDatabaseNode(nodeNewAction);
				if Input.isShiftPressed() then
					DB.deleteNode(nodeDrag);
				end
			elseif Input.isControlPressed() then
				local nodeNewAction = DB.createChild(nodeTargetParent);
				DB.copyNode(nodeDrag, nodeNewAction);
				draginfo.setDatabaseNode(nodeNewAction);
			end
		end
	end

	return handleDropReorderOriginal(w, draginfo);
end