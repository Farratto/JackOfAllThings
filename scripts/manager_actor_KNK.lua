-- Please see the LICENSE.txt file included with this distribution for
-- attribution and copyright information.

--luacheck: globals getActorRecordTypeFromPath

local getActorRecordTypeFromPathOriginal;

-- Initialization
function onInit()
	getActorRecordTypeFromPathOriginal = ActorManager.getActorRecordTypeFromPath;
	ActorManager.getActorRecordTypeFromPath = getActorRecordTypeFromPath;

	ActorManager.registerActorRecordType("item");
end

-- Internal use only
function getActorRecordTypeFromPath(sActorNodePath)
	if sActorNodePath:match("%.inventorylist%.") then
		return "item";
	else
		return getActorRecordTypeFromPathOriginal(sActorNodePath);
	end
end