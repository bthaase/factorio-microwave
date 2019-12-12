----------------------------------------------------------------------------------------------------------------
-- Vehicle-based Microwave Items
----------------------------------------------------------------------------------------------------------------
data:extend({
    {   -- Microwave-Vehicle-Receiver-Small
        type = "item",
        name = "microwave-vehicle-receiver-small",
        icon = "__camedo-microwave__/graphics/icons/microwave1.png",
        icon_size = 32,
        placed_as_equipment_result = "microwave-vehicle-receiver-small",
        subgroup = "equipment",
        order = "a[energy-source]-a[solar-panel]-b",
        stack_size = 100,
    },
    {   -- Microwave-Vehicle-Receiver-Large
        type = "item",
        name = "microwave-vehicle-receiver-large",
        icon = "__camedo-microwave__/graphics/icons/microwave2.png",
        icon_size = 32,
        placed_as_equipment_result = "microwave-vehicle-receiver-large",
        subgroup = "equipment",
        order = "a[energy-source]-a[solar-panel]-c",
        stack_size = 50,
    }	
})

