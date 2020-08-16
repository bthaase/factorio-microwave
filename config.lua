----------------------------------------------------------------------------
-- Attempt vehicle presence detection

hasVehicles = false				-- Are we enabling vehicle components?
equipmentCategories = {}		-- Detected non-player equipment categories... hopefully.

-- Search and detect specific equipment categories.
local searchCategories = {"aircraft", "car", "tank", "train", "vehicle", "locomotive", "electric-hovercraft-equipment", "cargo-wagon", "armoured-cargo-wagon", "armoured-locomotive", "armoured-train", "armoured-vehicle", "spider-vehicle"}
for _,cat in pairs(searchCategories) do
	if ( data.raw["equipment-category"][cat] ) then 
		hasVehicles = true
		table.insert(equipmentCategories, cat) 
	end
end
