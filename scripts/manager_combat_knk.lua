-- Please see the LICENSE.txt file included with this distribution for
-- attribution and copyright information.

--luacheck: globals resetHealthKNK fresetHealth

fresetHealth = nil;

function onInit()
	fresetHealth = ActorCommonManager.resetHealth;
	ActorCommonManager.resetHealth = resetHealthKNK;
end

function resetHealthKNK(rActor, sRestType, ...)
	fresetHealth(rActor, sRestType, ...);

	local bLong;
	if sRestType == 'long' then bLong = true end
	local nodeCT = ActorManager.getCTNode(rActor);

	ItemPowerManager.beginRecharging(nodeCT, bLong);
end