----------------------------------------------------------------------------------------------------------------
-- Microwave Items
----------------------------------------------------------------------------------------------------------------
data:extend({
	{	-- Microwave-Tower
		type = "item",
		name = "microwave-tower",
		icon = "__camedo-microwave__/graphics/icons/tower.png",
		icon_size = 32,
		subgroup = "energy-pipe-distribution",
		order = "a[energy]-c[big-electric-pole]-a",
		place_result = "microwave-tower",
		stack_size = 50
	},	
    {   -- Microwave-Receiver-Small
        type = "item",
        name = "microwave-receiver-small",
        icon = "__camedo-microwave__/graphics/icons/microwave1.png",
        icon_size = 32,
        placed_as_equipment_result = "microwave-receiver-small",
        subgroup = "equipment",
        order = "a[energy-source]-a[solar-panel]-b",
        stack_size = 100,
    },
    {   -- Microwave-Receiver-Large
        type = "item",
        name = "microwave-receiver-large",
        icon = "__camedo-microwave__/graphics/icons/microwave2.png",
        icon_size = 32,
        placed_as_equipment_result = "microwave-receiver-large",
        subgroup = "equipment",
        order = "a[energy-source]-a[solar-panel]-c",
        stack_size = 50,
    }
})

