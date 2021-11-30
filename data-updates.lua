---------------------------------------------------------------------------------------------------------------------
-- Detect the presence of vehicle grids and enable vehicle versions of equipment automatically (Hopefully)
-- Occurs inside the required config.lua
---------------------------------------------------------------------------------------------------------------------
require("config")

--[[
if ( hasVehicles ) then
	require("prototypes.items-vehicle")
	require("prototypes.equipment-vehicle")
	require("prototypes.recipes-vehicle")
	
	-- Adjust technology unlocks
	table.insert(data.raw["technology"]["microwave-charging1"].effects, { type = "unlock-recipe", recipe = "microwave-vehicle-receiver-small" })
	table.insert(data.raw["technology"]["microwave-charging2"].effects, { type = "unlock-recipe", recipe = "microwave-vehicle-receiver-large" })	
end
]]--