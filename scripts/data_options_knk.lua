-- Please see the LICENSE.txt file included with this distribution for
-- attribution and copyright information.

function onInit()
	registerOptions();
end

function registerOptions()
	-- Remove item from inventory when destoyed
	OptionsManager.registerOption2("IDLU", true, "option_header_knk", "option_label_IDLU", "option_entry_cycler",
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("SCIP", true, "option_header_knk", "option_label_SCIP", "option_entry_cycler",
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	OptionsManager.registerOption2("IPAE", true, "option_header_knk", "option_label_IPAE", "option_entry_cycler",
		{ labels = "option_label_disable", values = "off", baselabel = "option_label_enable", baseval = "on", default = "on" });
	-- ASED option to be used at a later date.
	-- OptionsManager.registerOption2("ASED", true, "option_header_knk", "option_label_ASED", "option_entry_cycler",
	-- 	{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
end