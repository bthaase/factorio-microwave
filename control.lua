require("stdlib/table")
require("stdlib/string")
local Position = require("stdlib/area/position")
-- local Entity = require("stdlib/entity/entity")
-- local util = require("util")

local receiverNames = { "microwave-receiver-small", "microwave-receiver-large", "microwave-vehicle-receiver-small", "microwave-vehicle-receiver-large" }

function updateSettings()
	global.showDebug = settings.global["mw-show-debug"].value
	global.mwChargeRadius = settings.global["mw-charge-radius"].value
	global.mwChargeInterval = settings.global["mw-charge-interval"].value
	global.mwSearchInterval = settings.global["mw-search-interval"].value
	
	if ( global.showDebug ) then game.print("[Microwave] Runtime Settings Changed.") end	
end

function countTowers()
	local c = 0
	for _,tower in pairs(global.microwaves) do c = c + 1 end
	return c
end

function findTowerFromEntity(entity)
	local r = nil
	for id,tower in pairs(global.microwaves) do
		if ( tower.entity == entity ) then r=tower end
	end
	return r
end

function registerTower(entity)
	-- stored is used to buffer the energy in a link when it's being rebuilt. (If we.. implement that)
	table.insert(global.microwaves, {entity=entity, link=nil, target=nil, beam=nil, stored=0})	
	if ( global.showDebug ) then game.print("[Microwave] Registered Tower - " .. countTowers() .. " in list.") end
end

function unregisterTower(entity)
	local tower = findTowerFromEntity(entity)
	if ( tower ) then 
		if ( tower.beam ) then tower.beam.destroy() end
		if ( tower.link ) then tower.link.destroy() end		
		tower.entity = nil

		global.microwaves = table.filter(global.microwaves, function(e) return e.entity end)
	
		if ( global.showDebug ) then game.print("[Microwave] Unregistered Tower - " .. countTowers() .. " remain after cleanup.") end
	end
end

function on_init()
	global.microwaves = global.microwaves or {}
	updateSettings()
end

function on_configuration_changed()
	-- TODO: We can check our global version for migrations, etc.
	if ( global.showDebug ) then game.print("[Microwave] Configuration Changed.") end
	
	updateSettings()
end

local function updateMicrowaveBeam(tower)
	-- Destroy existing beams
	if ( tower and tower.beam ) then
		if ( tower.beam.valid ) then tower.beam.destroy() end
		tower.beam = nil
	end
	
	-- Create a new one
	if ( tower and tower.entity and tower.entity.valid and tower.target and tower.target.valid ) then
		tower.beam = tower.entity.surface.create_entity{
			name="microwave-beam",
			position=tower.entity.position,
			-- source=tower.entity,
			source={ x=tower.entity.position.x, y=tower.entity.position.y - 2 },
			target=tower.target
		}
	end
end

function isTargetCharging(target)
	local isCharging = false
	table.each(global.microwaves, function(tower)
		if ( tower.target and tower.target == target ) then isCharging = true end
	end)
	return isCharging
end

-- Returns how much we actually consumed.
function sendPowerToEquipment(eq, amount)
	local spent = 0
	
	if ( amount <= 0 ) then return 0 end
	if ( not eq or not eq.valid ) then return 0 end
	
	local eq_max_in = (eq.max_energy - eq.energy)
	if ( eq.prototype and eq.prototype.energy_source ) then eq_max_in = eq.prototype.energy_source.input_flow_limit end
	eq_max_in = eq_max_in / 60	-- Scale work for tick cycle

	local wants = eq.max_energy - eq.energy
	spent = (eq_max_in < amount) and eq_max_in or amount
	spent = (wants < spent) and wants or spent
	
	eq.energy = eq.energy + spent	
	return spent
end 

function isReceiverName(name)
	local hasMatch = false
	table.each(receiverNames, function(receiver)
		if ( name == receiver ) then hasMatch = true end
	end)
	return hasMatch
end

-- Returns how much we actually consumed. Microwave Receivers are the priority.
function sendPowerToGrid(target, amount)
	local avail = amount
	
	if ( not target or not target.valid or not target.grid ) then return 0 end
	
	local equip = table.filter(target.grid.equipment, function(e) return e.valid end)	
	
	-- Search and charge receivers first.
	table.each(equip, function(eq)
		if ( isReceiverName(eq.name) ) then avail = avail - sendPowerToEquipment(eq, avail) end
	end)
	
	if ( avail < 0 ) then return (amount-avail) end
	
	-- Search and charge whatever is left.
	table.each(equip, function(eq)
		if ( eq.type == "battery-equipment" ) then
			if ( not isReceiverName(eq.name) ) then avail = avail - sendPowerToEquipment(eq, avail) end
		end
	end)
	
	return (amount - avail)
end

function inspectGrid(target) 
	local result = { work=0, max_receive=0, max_charge=0, energy=0, max_energy=0, energy_wanted=0, energy_p=0 }
	local eq_max_in = 0
	
	if ( not target or not target.valid or not target.grid ) then return result end
	
	-- Iterate equipment
	local equip = table.filter(target.grid.equipment, function(e) return e.valid end)
	table.each(equip, function(eq)	
		-- We only charge batteries (our receivers count as batteries)
		if ( eq.type == "battery-equipment" ) then
			-- Determine max input rate for this piece of equipment
			eq_max_in = (eq.max_energy - eq.energy)
			if ( eq.prototype and eq.prototype.energy_source ) then 
				eq_max_in = eq.prototype.energy_source.input_flow_limit * 60	-- Convert joule/tick back into joule/second
			end		
		
			-- If this a Receiver? We use these to determine our max wireless receive rate.
			if ( isReceiverName(eq.name) ) then
				result.max_receive = result.max_receive + eq_max_in
			end	
			
			-- Either way, factor in the power they need.
			result.energy = result.energy + eq.energy
			result.max_energy = result.max_energy + eq.max_energy
			result.max_charge = result.max_charge + eq_max_in
		end
	end)

	-- Determine our percentage of charge and other stats.
	result.energy_wanted = (result.max_energy - result.energy)
	result.energy_p = math.floor((result.energy / result.max_energy) * 100)
	
	-- Set work to the lowest of our energy transfer caps.
	result.work = (result.max_receive < result.max_charge) and result.max_receive or result.max_charge
	result.work = (result.energy_wanted < result.work) and result.energy_wanted or result.work
	
	return result
end

function microwaveChargeEntity(tower)
	if ( not tower or not tower.target or not tower.target.valid or not tower.target.grid ) then
		return true	-- Return true will detach us from the entity.
	end

	-- Check our range to entity. We might also end up using this to scale power efficency.
	local range = Position.distance(tower.entity.position, tower.target.position)
	if ( range > global.mwChargeRadius ) then return true end
	
	-- Determine the work we want to do, and scale to tick cycle.
	local status = inspectGrid(tower.target)	
	
	local work = ( tower.link.energy < status.work ) and tower.link.energy or status.work
	work = math.floor((work * global.mwChargeInterval) / 60)
	-- TODO: We can optionally use the range now to scale our work, to adjust effiency. 
	-- TODO: If we do so, we need to handle the consumption from the tower a little differently.

	-- No work is required/available, detach this target.
	if ( work <= 0 ) then return true end

	-- Send power to the Equipment Grid, and update the drain rate to reflect that.
	local sent = sendPowerToGrid(tower.target, work)
	tower.link.power_usage = ( global.expDrain ) and ( sent / global.mwChargeInterval ) or 0	
	
	if ( sent <= 0 ) then return true end -- Failed to send any power for some reason. Detach.
	
	-- DEBUGGING: Report status
	-- local lp = math.floor((tower.link.energy / tower.link.electric_buffer_size) * 100)
	-- game.print("[Link: " .. lp .. "%][Target: " .. status.energy_p .. "%, Sent: " .. math.floor(sent) .. " of " .. math.floor(work) .. "][" .. status.max_charge .. ", " .. status.max_receive .. "]")
	if ( global.showDebug ) then game.print("[Microwave] Sent " .. math.floor(sent) .. " units to a " .. tower.target.type) end

	-- Check our results, if we're full up we want to detach.
	status = inspectGrid(tower.target)
	return ( status.energy >= status.max_energy or status.work <= 0 )
end

-- TODO: We may need to figure out a better solution for search types. Maybe data-final-fixes can scan for all prototypes that include an equipment grid and store a list in global?
function microwaveSearchTarget(tower)
	local search = tower.entity.surface.find_entities_filtered{position=tower.entity.position, radius=global.mwChargeRadius, force=tower.entity.force, type={"character", "car", "tank", "spider-vehicle"}}
	
	search = table.filter(search, function(e) return (e.valid) end)
	search = table.filter(search, function(e) return (isTargetCharging(e) == false) end)
	
	local best = { target = nil, score = 0 }
	local status = nil
	
	table.each(search, function(e)
		status = inspectGrid(e)				
		if ( (status.max_receive > 0) and (status.energy_wanted > best.score) ) then
			best.target = e
			best.score = status.energy_wanted
		end
	end)
	
	-- if ( best.target ) then game.print(tower.entity.position.x .. "," .. tower.entity.position.y .. " :: Picked " .. best.target.name .. " who " .. (isTargetCharging(best.target) and " IS " or " IS NOT ") .. " charging.") end
	
	tower.target = best.target
	return (tower.target or false)
end

---------------------------------------------------- SCRIPT EVENTS ----------------------------------------------------

script.on_init(function() on_init() end)
-- on_load
script.on_configuration_changed(function() on_configuration_changed() end)

script.on_event(defines.events.on_tick, function (e)	  
	global.microwaves = global.microwaves or {}

	-- Tower Interval: Charge Existing Targets (Runs every tick right now)
	if ( e.tick % global.mwChargeInterval == 0 ) then
		local towers = table.filter(global.microwaves, function(e) return (e.entity and e.entity.valid) end)
		table.each(towers, function(tower)
			-- Ensure we have an electric energy interface
			if ( (not tower.link) or (not tower.link.valid) ) then
				tower.link = tower.entity.surface.create_entity{
					name = "microwave-tower-interface", 
					position = tower.entity.position, 
					force = tower.entity.force
				}
				-- tower.link.minable = false
				-- tower.link.destructable = false
			else 
				tower.link.power_usage = 0	-- Reset our drain now, we've consumed our last cycles cost.
			end
		
			-- If we have a valid target, attempt to charge it.
			tower.target = ( tower.target and tower.target.valid ) and tower.target or nil
			if ( tower.target ) then
				local isDone = microwaveChargeEntity(tower)
				if ( isDone ) then tower.target = nil end
			end
			
			-- Manage our Microwave Beam
			updateMicrowaveBeam(tower)
		end)
	end
	
	-- Tower Interval: Search for Charge Targets
	if ( e.tick % global.mwSearchInterval == 0 ) then
		local towers = table.filter(global.microwaves, function(e) return (e.entity and e.entity.valid and not e.target) end)
		table.each(towers, function(tower)
			microwaveSearchTarget(tower)
		end)
	end	
end)

-- Some cute attempts at detecting our 'extended' versions to maintain our microwave tower behaviour.
function is_tower_entity(entity)
	local isTower = false
	
	if ( entity.name == "microwave-tower" ) then return true end			-- Detect by exact entity
	if ( entity.type ~= "electric-pole" ) then return false end				-- If it's not a power pole, it's not a microwave tower.
	
	-- String match against name
	if ( string.match(entity.name, "microwave%-tower") ~= nil ) then return true end

	-- Detect by corpse
	if ( entity.prototype and entity.prototype.corpses ) then
		for _,corpse in pairs(entity.prototype.corpses) do
			if ( corpse.name == "microwave-tower-remnants" ) then isTower = true end
		end
		if ( isTower ) then return true end
	end
	
	return false
end

function on_built_entity(event)
	local entity = event.created_entity or event.entity	
	if ( is_tower_entity(entity) ) then registerTower(entity) end
end

function on_removed_entity(event)
	local entity = event.entity		
	if ( is_tower_entity(entity) ) then unregisterTower(entity) end
end

-- TODO: Reinit on Research Completed? Or atleast reset targets so they recalc throughput? Probably not necessary... 

-- Scan all tower targets and clear them if their forces no longer match.
function reset_targets()
	local towers = table.filter(global.microwaves, function(e) return (e.entity and e.entity.valid) end)
	table.each(towers, function(tower)
		if ( tower.entity and tower.entity.valid and tower.target and tower.target.valid ) then
			if ( tower.target.force == tower.entity.force and tower.entity.surface.index == tower.target.surface.index ) then
				--
			else 
				tower.target = nil
			end
		end
	end)	
end

-- defines.events.on_research_finished
-- defines.events.on_player_joined_game
-- defines.events.on_player_left_game
-- defines.events.on_player_died

-- defines.events.on_player_removed_equipment
-- defines.events.on_player_placed_equipment
-- defines.events.on_player_armor_inventory_changed


script.on_event(defines.events.on_player_changed_force, function(e) reset_targets() end)
script.on_event(defines.events.on_player_changed_surface, function(e) reset_targets() end)

script.on_event(defines.events.on_built_entity, function(e) on_built_entity(e) end)
script.on_event(defines.events.on_robot_built_entity, function(e) on_built_entity(e) end)
script.on_event(defines.events.script_raised_built, function(e) on_built_entity(e) end)
script.on_event(defines.events.script_raised_revive, function(e) on_built_entity(e) end)

script.on_event(defines.events.on_entity_died, function(e) on_removed_entity(e) end)
script.on_event(defines.events.on_player_mined_entity, function(e) on_removed_entity(e) end)
script.on_event(defines.events.on_robot_mined_entity, function(e) on_removed_entity(e) end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(e) updateSettings() end)


---------------------------------------------------- MISC EXAMPLES ----------------------------------------------------
-- Create Fire at a Player's Position
-- player.surface.create_entity{name="fire-flame", position=player.position, force="neutral"} 

-- Remove/Place an item in an equipment grid.
-- armor.grid.take{position=pos}
-- armor.grid.put{name="microwave-receiver-small", position=pos}


 -- Entity.set_data(player.character, { vehicle = vehicle, start_pos = player.character.position, player_idx = event.player_index })
 -- local data = Entity.get_data(player.character)
 -- if data then game.print(data.start_pos) end
 -- Entity.set_data(player.character, nil)
