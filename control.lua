require("stdlib/table")
require("stdlib/string")
local Position = require("stdlib/area/position")

local passive_tower_draw = 20000		-- 20 KW passive draw.

local chargable_types = { "character", "car", "tank", "spider-vehicle", "artillery-wagon", "cargo-wagon", "fluid-wagon", "locomotive" }
local receiverNames = { "microwave-receiver-small", "microwave-receiver-large", "microwave-vehicle-receiver-small", "microwave-vehicle-receiver-large" }

function update_settings()
	global.showDebug = settings.global["mw-show-debug"].value
	global.mwChargeRadius = settings.global["mw-charge-radius"].value
	global.mwChargeInterval = settings.global["mw-charge-interval"].value
	global.mwSearchInterval = settings.global["mw-search-interval"].value
	
	if ( global.showDebug ) then game.print("[Microwave] Runtime Settings Changed.") end	
end

-- Divide by this to handle scaling for various tick cycles. 1.0 at 60 ticks, 4.0 at 15 ticks, etc. 
function tick_scale()
	return (60 / global.mwChargeInterval)
end

function count_towers()
	local c = 0
	for _,tower in pairs(global.microwaves) do c = c + 1 end
	return c
end

function find_tower_from_entity(entity)
	local r = nil
	for id,tower in pairs(global.microwaves) do
		if ( tower.entity == entity ) then r=tower end
	end
	return r
end

function register_tower(entity)
	-- stored is used to buffer the energy in a link when it's being rebuilt. (If we.. implement that)
	table.insert(global.microwaves, { entity=entity, link=nil, target=nil, beam=nil, stored=0 })	
	debug_log("Registered tower - " .. count_towers() .. " in list.")
end

function unregister_tower(entity)
	local tower = find_tower_from_entity(entity)
	if ( tower ) then 
		if ( tower.beam ) then tower.beam.destroy() end
		if ( tower.link ) then tower.link.destroy() end		
		tower.entity = nil

		global.microwaves = table.filter(global.microwaves, function(e) return e.entity end)
	
		debug_log("Unregistered tower - " .. count_towers() .. " remain after cleanup.")
	end
end

function on_init()
	global.microwaves = global.microwaves or {}
	update_settings()
end

function on_configuration_changed()
	-- TODO: We can check our global version for migrations, etc.
	debug_log("Configuration changed.")
	
	update_settings()
end

local function update_microwave_beam(tower)
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
			source={ x=tower.entity.position.x + 0.2, y=tower.entity.position.y - 2.3 },
			target=tower.target
		}
	end
end

function is_target_charging(target)
	local is_charging = false
	table.each(global.microwaves, function(tower)
		if ( tower.target and tower.target == target ) then is_charging = true end
	end)
	return is_charging
end

-- Returns how much we actually consumed.
function send_power_to_equipment(eq, available)
	local spent = 0
	
	if ( available <= 0 ) then return 0 end
	if ( not eq or not eq.valid ) then return 0 end
	
	local eq_max_in = (eq.max_energy - eq.energy)
	if ( eq.prototype and eq.prototype.energy_source ) then eq_max_in = eq.prototype.energy_source.input_flow_limit end
	-- eq_max_in = eq_max_in / 60			-- Scale work for tick cycle
	eq_max_in = eq_max_in / tick_scale()	-- Scale work for tick cycle

	local wants = eq.max_energy - eq.energy	
	spent = math.min(eq_max_in, wants, available)
	if ( spent < 0 ) then spent = 0 end
	
	eq.energy = eq.energy + spent
	return spent
end 

function is_receiver_name(name)
	local hasMatch = false
	table.each(receiverNames, function(receiver)
		if ( name == receiver ) then hasMatch = true end
	end)
	return hasMatch
end

-- Returns how much we actually consumed. Microwave Receivers are the priority.
function send_power_to_grid(target, amount)
	local avail = amount
	
	if ( not target or not target.valid or not target.grid ) then return 0 end
	
	local equip = table.filter(target.grid.equipment, function(e) return e.valid end)	
	
	-- Search and charge receivers first.
	table.each(equip, function(eq)
		if ( is_receiver_name(eq.name) ) then avail = avail - send_power_to_equipment(eq, avail) end
	end)
	
	if ( avail < 0 ) then return (amount-avail) end
	
	-- Search and charge whatever is left.
	table.each(equip, function(eq)
		if ( eq.type == "battery-equipment" ) then
			if ( not is_receiver_name(eq.name) ) then avail = avail - send_power_to_equipment(eq, avail) end
		end
	end)
	
	return (amount - avail)
end

-- Time rates determined here are based around a 1-second duration. IE: A small recetenna
-- produces 500KW, and will return this regardless of tick interval configuration.
function inspect_grid(target) 
	-- local result = { work=0, throughput=0, max_receive=0, max_charge=0, energy=0, max_energy=0, energy_wanted=0 }
	local result = { throughput=0, max_receive=0, max_charge=0, energy=0, max_energy=0, energy_wanted=0 }
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
			if ( is_receiver_name(eq.name) ) then
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
	
	-- Set throughput to the lowest of our energy transfer caps.
	result.throughput = math.min(result.max_receive, result.max_charge)
	
	return result
end

function debug_log(message, tower) 
	if not ( global.showDebug ) then return false end
	
	local suffix = ""
	if tower and tower.entity then
		suffix = "@" .. tower.entity.position.x .. "," .. tower.entity.position.y
	elseif tower and tower.position then
		suffix = "@" .. tower.position.x .. "," .. tower.position.y		
	end
	
	game.print("[microwave" .. suffix .. "] " .. message)
	return true
end


-- This will run at an adjustable interval. (By default, 15 ticks or 4 times per second)
-- Math must be adjusted on the fly to account for this.
-- Returning TRUE will detach us from the entity.
function microwave_charge_entity(tower)
	if ( not tower or not tower.target or not tower.target.valid or not tower.target.grid ) then return true end
	
	-- Check our range to entity. We might also end up using this to scale power efficency.
	local range = Position.distance(tower.entity.position, tower.target.position)
	if ( range > global.mwChargeRadius ) then return true end
	
	-- Determine the work we want to do, and scale to tick cycle.
	local status = inspect_grid(tower.target)		
	
	-- Scaled throughput should result in 500000/4=125000, per small dish.
	-- Use min to also cap our workload below energy WANTED, and available power in 'da towa.
	local work = math.floor(math.min(status.throughput / tick_scale(), status.energy_wanted, tower.link.energy))

	-- No work is required/available, detach this target.
	if ( work <= 0 ) then return true end

	-- Send power to the Equipment Grid, and update the drain rate to reflect that.
	-- We scale the sent value back UP to what it would be over a 60-tick interval, from whatever we're at now.
	local sent = math.floor(send_power_to_grid(tower.target, work))
	tower.link.power_usage = (passive_tower_draw + (sent * tick_scale())) / 60
	
	if ( sent <= 0 ) then return true end -- Failed to send any power for some reason. Detach.
	
	debug_log("Sent " .. sent .. " of " .. work .. " to " .. tower.target.type, tower)

	-- Recheck the grid, detach when full.
	status = inspect_grid(tower.target)
	return ( status.energy >= status.max_energy - 1 )
end

-- TODO: We may need to figure out a better solution for search types. Maybe data-final-fixes can scan for all prototypes that include an equipment grid and store a list in global?
function microwave_search_target(tower)
	local search = tower.entity.surface.find_entities_filtered{position=tower.entity.position, radius=global.mwChargeRadius, force=tower.entity.force, type=chargable_types}
	
	search = table.filter(search, function(e) return (e.valid) end)
	search = table.filter(search, function(e) return (is_target_charging(e) == false) end)
	
	local best = { target = nil, score = 0 }
	local status = nil
	
	table.each(search, function(e)
		status = inspect_grid(e)				
		if ( (status.max_receive > 0) and (status.energy_wanted > best.score) ) then
			best.target = e
			best.score = status.energy_wanted
		end
	end)
	
	-- if ( best.target ) then game.print(tower.entity.position.x .. "," .. tower.entity.position.y .. " :: Picked " .. best.target.name .. " who " .. (is_target_charging(best.target) and " IS " or " IS NOT ") .. " charging.") end
	
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
			else 
				tower.link.power_usage = passive_tower_draw / 60
			end
		
			-- If we have a valid target, attempt to charge it.
			tower.target = ( tower.target and tower.target.valid ) and tower.target or nil
			if ( tower.target ) then
				local is_fully_charged = microwave_charge_entity(tower)
				if ( is_fully_charged ) then tower.target = nil end
			end
			
			-- Manage our Microwave Beam
			update_microwave_beam(tower)
		end)
	end
	
	-- Tower Interval: Search for charge targets
	if ( e.tick % global.mwSearchInterval == 0 ) then
		local towers = table.filter(global.microwaves, function(e) return (e.entity and e.entity.valid and not e.target) end)
		table.each(towers, function(tower)
			microwave_search_target(tower)
		end)
	end	
end)

-- Some cute attempts at detecting our 'extended' versions to maintain our microwave tower behaviour.
function is_tower_entity(entity)
	local is_tower = false
	
	if ( entity.name == "microwave-tower" ) then return true end			-- Detect by exact entity
	if ( entity.type ~= "electric-pole" ) then return false end				-- If it's not a power pole, it's not a microwave tower.
	
	-- String match against name
	if ( string.match(entity.name, "microwave%-tower") ~= nil ) then return true end

	-- Detect by corpse
	if ( entity.prototype and entity.prototype.corpses ) then
		for _,corpse in pairs(entity.prototype.corpses) do
			if ( corpse.name == "microwave-tower-remnants" ) then is_tower = true end
		end
		if ( is_tower ) then return true end
	end
	
	return false
end

function on_built_entity(event)
	local entity = event.created_entity or event.entity	or event.destination
	if ( is_tower_entity(entity) ) then register_tower(entity) end
end

function on_removed_entity(event)
	local entity = event.entity		
	if ( is_tower_entity(entity) ) then unregister_tower(entity) end
end

-- Scan all tower targets and clear them if their forces or surface no longer match.
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


script.on_event(defines.events.on_player_changed_force, function(e) reset_targets() end)
script.on_event(defines.events.on_player_changed_surface, function(e) reset_targets() end)

script.on_event(defines.events.on_built_entity, function(e) on_built_entity(e) end)
script.on_event(defines.events.on_entity_cloned, function(e) on_built_entity(e) end)
script.on_event(defines.events.on_robot_built_entity, function(e) on_built_entity(e) end)
script.on_event(defines.events.script_raised_built, function(e) on_built_entity(e) end)
script.on_event(defines.events.script_raised_revive, function(e) on_built_entity(e) end)

script.on_event(defines.events.on_entity_died, function(e) on_removed_entity(e) end)
script.on_event(defines.events.on_player_mined_entity, function(e) on_removed_entity(e) end)
script.on_event(defines.events.on_robot_mined_entity, function(e) on_removed_entity(e) end)
script.on_event(defines.events.script_raised_destroy, function(e) on_removed_entity(e) end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(e) update_settings() end)