---------------------------------------------------------------------------------------------------------------------
-- Require our config which will determine if we're using vehicles, and provides equipmentCategories containing 
-- the recognized non-player equipment grids.
require("config")

---------------------------------------------------------------------------------------------------------------------
-- Adjust Microwave Tower to inherit any big electric pole mod changes.
local towerBase = data.raw["electric-pole"]["big-electric-pole"]
local towerNew = data.raw["electric-pole"]["microwave-tower"]

towerNew.max_health = math.floor(towerBase.max_health * 1.1) 		-- Slightly more durable.
towerNew.resistances = towerBase.resistances						-- Match the resistances.
towerNew.maximum_wire_distance = towerBase.maximum_wire_distance	-- Match the wire distance.
towerNew.supply_area_distance = towerBase.supply_area_distance		-- Match the supply area.

-- Update default equipment categories
data.raw["battery-equipment"]["microwave-receiver-small"].categories = { "armor" }
data.raw["battery-equipment"]["microwave-receiver-large"].categories = { "armor" }

if ( hasVehicles ) then
	data.raw["battery-equipment"]["microwave-vehicle-receiver-small"].categories = equipmentCategories
	data.raw["battery-equipment"]["microwave-vehicle-receiver-large"].categories = equipmentCategories
	
	-- check for vehicle-equipment subgroup (Bob's Vehicle Equipment) and move our gear into that grouping.
	if ( data.raw["item-subgroup"]["vehicle-equipment"] ) then
		data.raw["item"]["microwave-vehicle-receiver-small"].subgroup = "vehicle-equipment"
		data.raw["item"]["microwave-vehicle-receiver-large"].subgroup = "vehicle-equipment"
		data.raw["item"]["microwave-vehicle-receiver-small"].order = "v[vehicle-equipment]-m[microwave]-1"
		data.raw["item"]["microwave-vehicle-receiver-large"].order = "v[vehicle-equipment]-m[microwave]-2"
	end
else 
	
end
