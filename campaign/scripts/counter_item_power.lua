-- Please see the LICENSE.txt file included with this distribution for
-- attribution and copyright information.

--super = CoreRPG/campaign/scripts/buttongroup_counter_power_5E.lua

--luacheck: globals getCastValue adjustCounter onChargesChanged calculateTotal calculateUsed getTotalCharges canCast
--luacheck: globals getChargesUsed onClickRelease onWheel onValueChanged maxslotperrow spacing update updateSlots
--luacheck: globals stateicons getPreparedValue setPreparedValue setCastValue

local nodePower;
local nodeItem;
local nTotal;
local nUsed;
local bWheel = false;

--local adjustCounterOriginal;
local getCastValueOriginal;

local sSheetMode = "";
local bSpontaneous = false;
local nAvailable = 0;
local nDefaultSpacing = 10;
local nSpacing = nDefaultSpacing;
local nMaxSlotRow = 10;
local nTotalCast = 0;
local _sDisabledColor = "B0FFFFFF";
local _sFullColor = "FFFFFFFF";
local slots = {};

function onInit()
	--from super
	if maxslotperrow then
		nMaxSlotRow = tonumber(maxslotperrow[1]) or 10;
	end
	if spacing then
		nSpacing = tonumber(spacing[1]) or nDefaultSpacing;
	end

	setAnchoredHeight(nSpacing*2);
	setAnchoredWidth(nSpacing);
	--end from super

	--adjustCounterOriginal = super.adjustCounter;
	--super.adjustCounter = adjustCounter;
	getCastValueOriginal = super.getCastValue;
	super.getCastValue = getCastValue;

	nodePower = window.getDatabaseNode();
	nodeItem = DB.getChild(nodePower, "...");

	onChargesChanged();
	DB.addHandler(nodeItem.getPath("count"), "onUpdate", onChargesChanged);
	DB.addHandler(nodeItem.getPath("prepared"), "onUpdate", onChargesChanged);
	DB.addHandler(nodePower.getPath("charges"), "onUpdate", onChargesChanged);
	DB.addHandler(nodeItem.getPath("powers.*.cast"), "onUpdate", onChargesChanged);
	DB.addHandler(nodeItem.getPath("powers.*.chargeperiod"), "onUpdate", onChargesChanged);
end

function onClose()
	DB.removeHandler(nodeItem.getPath("count"), "onUpdate", onChargesChanged);
	DB.removeHandler(nodeItem.getPath("prepared"), "onUpdate", onChargesChanged);
	DB.removeHandler(nodePower.getPath("charges"), "onUpdate", onChargesChanged);
	DB.removeHandler(nodeItem.getPath("powers.*.cast"), "onUpdate", onChargesChanged);
	DB.removeHandler(nodeItem.getPath("powers.*.chargeperiod"), "onUpdate", onChargesChanged);

	if super and super.onClose then
		super.onClose()
	end
end

function getCastValue()
	if type(window) == "windowinstance" then
		return getCastValueOriginal();
	end
	return 0;
end

function onWheel(notches)
	bWheel = true;
	local result = super.onWheel(notches);
	bWheel = false;
	return result;
end

function adjustCounter(val_adj)
	if not bWheel and DB.getValue(nodePower, "chargeperiod", "") == "" then
		if val_adj == 1 then
			val_adj = DB.getValue(nodePower, "charges", 1);
		elseif val_adj == -1 then
			val_adj = val_adj * DB.getValue(nodePower, "charges", 1);
		end
	end

	--from super
	if sSheetMode == "preparation" then
		if bSpontaneous then
			return true;
		end

		local val = self.getPreparedValue() + val_adj;

		if val > nAvailable then
			self.setPreparedValue(nAvailable);
		elseif val < 0 then
			self.setPreparedValue(0);
		else
			self.setPreparedValue(val);
		end
	else
		local val = self.getCastValue() + val_adj;
		local nTempTotal = nTotalCast + val_adj;

		if bSpontaneous then
			if nTempTotal > nAvailable then
				if val - (nTempTotal - nAvailable) > 0 then
					self.setCastValue(val - (nTempTotal - nAvailable));
				else
					self.setCastValue(0);
				end
			elseif val < 0 then
				self.setCastValue(0);
			else
				self.setCastValue(val);
			end
		else
			local nPrepared = self.getPreparedValue();

			if val > nPrepared then
				self.setCastValue(nPrepared);
			elseif val < 0 then
				self.setCastValue(0);
			else
				self.setCastValue(val);
			end
		end
	end

	if self.onValueChanged then
		self.onValueChanged();
	end
	--end from super
end

function onChargesChanged()
	calculateTotal();
	calculateUsed();

	local nodePower = getDatabaseNode();
	DB.setValue(nodePower, "prepared", "number", nTotal);
	--if super and super.update then
	--	super.update("standard", true, nTotal, nUsed, nTotal);
		update("standard", true, nTotal, nUsed, nTotal);
	--end
end

function onValueChanged()
	ItemPowerManager.handleItemChargesUsed(nodeItem);
end

function calculateTotal()
	local nCharges = DB.getValue(nodePower, "charges", 0);
	if nCharges > 0 then
		if DB.getValue(nodePower, "chargeperiod", "") == "" then
			nTotal = DB.getValue(nodeItem, "prepared", 0) * DB.getValue(nodeItem, "count", 1);
		else
			nTotal = nCharges;
		end
	else
		nTotal = 0;
	end
end

function calculateUsed()
	if DB.getValue(nodePower, "chargeperiod", "") == "" then
		nUsed = ItemPowerManager.countCharges(nodeItem);
	else
		nUsed = DB.getValue(nodePower, "cast", 0);
	end
end

function getTotalCharges()
	if not nTotal then
		calculateTotal();
	end
	return nTotal;
end

function getChargesUsed()
	if not nUsed then
		calculateUsed();
	end
	return nUsed;
end

--from super
function onClickRelease(_, x, y)
	if isReadOnly() then
		return;
	end

	local nPrepared = self.getPreparedValue();
	local bPrepMode = (sSheetMode == "preparation");
	local nMax = nPrepared;
	if bSpontaneous or bPrepMode then
		nMax = nAvailable;
	end

	local nClickH = math.floor(x / nSpacing) + 1;
	local nClickV;
	if nMax > nMaxSlotRow then
		nClickV	= math.floor(y / nSpacing);
	else
		nClickV = 0;
	end
	local nClick = (nClickV * nMaxSlotRow) + nClickH;

	if bPrepMode then
		local nCurrent = self.getPreparedValue();

		if nClick > nCurrent then
			self.adjustCounter(1);
		else
			self.adjustCounter(-1);
		end
	else
		local nCurrent = self.getCastValue();

		if bSpontaneous then
			if nClick > nTotalCast then
				self.adjustCounter(1);
			elseif nCurrent > 0 then
				self.adjustCounter(-1);
			end
		else
			if nClick > nCurrent then
				self.adjustCounter(1);
			else
				self.adjustCounter(-1);
			end
		end

		if self and self.getCastValue() > nCurrent then
			PowerManagerCore.usePower(window.getDatabaseNode());
		end
	end

	return true;
end
function update(sNewSheetMode, bNewSpontaneous, nNewAvailable, nNewTotalCast)
	sSheetMode = sNewSheetMode;
	bSpontaneous = bNewSpontaneous;
	nAvailable = nNewAvailable;
	nTotalCast = nNewTotalCast;

	self.updateSlots();
end
function updateSlots()
	-- Construct based on values
	local nPrepared = self.getPreparedValue();
	local nCast = self.getCastValue();
	local bPrepMode = (sSheetMode == "preparation");

	local nMax = nPrepared;
	if bSpontaneous or bPrepMode then
		nMax = nAvailable;
	end

	if #slots ~= nMax then
		-- Clear
		for _,v in ipairs(slots) do
			v.destroy();
		end
		slots = {};

		-- Build the slots, based on the all the spell cast statistics
		for i = 1, nMax do
			local sIcon, sColor;
			if bSpontaneous then
				if i > nTotalCast then
					sIcon = stateicons[1].off[1];
				else
					sIcon = stateicons[1].on[1];
				end

				if i <= nTotalCast - nCast or bPrepMode then
					sColor = _sDisabledColor;
				else
					sColor = _sFullColor;
				end
			else
				if i > nCast then
					sIcon = stateicons[1].off[1];
				else
					sIcon = stateicons[1].on[1];
				end

				if i > nPrepared then
					sColor = _sDisabledColor;
				else
					sColor = _sFullColor;
				end
			end

			local nW = (i - 1) % nMaxSlotRow;
			local nH = math.floor((i - 1) / nMaxSlotRow);

			local nX = (nSpacing * nW) + math.floor(nSpacing / 2);
			local nY;
			if nMax > nMaxSlotRow then
				nY = (nSpacing * nH) + math.floor(nSpacing / 2);
			else
				nY = (nSpacing * nH) + nSpacing;
			end

			slots[i] = addBitmapWidget({ icon = sIcon, color = sColor, position="topleft", x = nX, y = nY });
		end

		-- Determine final width of control based on slots
		if nMax > nMaxSlotRow then
			setAnchoredWidth(nMaxSlotRow * nSpacing);
			setAnchoredHeight((math.floor((nMax - 1) / nMaxSlotRow) + 1) * nSpacing);
		else
			setAnchoredWidth(nMax * nSpacing);
			setAnchoredHeight(nSpacing * 2);
		end
	else
		for i = 1, nMax do
			if bSpontaneous then
				if i > nTotalCast then
					slots[i].setBitmap(stateicons[1].off[1]);
				else
					slots[i].setBitmap(stateicons[1].on[1]);
				end

				if i <= nTotalCast - nCast or bPrepMode then
					slots[i].setColor(_sDisabledColor);
				else
					slots[i].setColor(_sFullColor);
				end
			else
				if i > nCast then
					slots[i].setBitmap(stateicons[1].off[1]);
				else
					slots[i].setBitmap(stateicons[1].on[1]);
				end

				if i > nPrepared then
					slots[i].setColor(_sDisabledColor);
				else
					slots[i].setColor(_sFullColor);
				end
			end
		end
	end
end
function canCast()
	if bSpontaneous then
		return (nTotalCast < nAvailable);
	else
		return (self.getCastValue() < self.getPreparedValue());
	end
end
function getPreparedValue()
	return DB.getValue(window.getDatabaseNode(), "prepared", 0);
end
function setPreparedValue(nNewValue)
	return DB.setValue(window.getDatabaseNode(), "prepared", "number", nNewValue);
end
function setCastValue(nNewValue)
	return DB.setValue(window.getDatabaseNode(), "cast", "number", nNewValue);
end
--end from super