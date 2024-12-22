-- Please see the LICENSE.txt file included with this distribution for
-- attribution and copyright information.

--luacheck: globals onMenuSelection addEntry update

function onInit()
	if not isReadOnly() then
		registerMenuItem(Interface.getString("list_menu_createitem"), "insert", 5);
	end
end

function onMenuSelection(selection)
	if selection == 5 then
		addEntry(true);
	end
end

function update()
	local bEditMode = (window.powerlist_iedit.getValue() == 1);
	for _,win in pairs(getWindows()) do
		win.idelete.setVisibility(bEditMode);
	end
end

function addEntry(bFocus)
	local win = createWindow();
	if bFocus and win then
		win.header.subwindow.focus();
	end
	return win;
end