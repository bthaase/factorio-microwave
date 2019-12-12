data:extend({
    {
        type = "recipe",
        name = "microwave-tower",
        enabled = false,
        energy_required = 12,
        ingredients = { {"processing-unit", 10}, {"battery", 5}, {"big-electric-pole", 1} },
        result = "microwave-tower",
        -- categories = {"armor"},
    },	
    {
        type = "recipe",
        name = "microwave-receiver-small",
        enabled = false,
        energy_required = 2,
        ingredients = { {"plastic-bar", 2}, {"processing-unit", 2}, {"battery-equipment", 1} },
		result="microwave-receiver-small",
        -- categories = {"armor"},
    },
    {
        type = "recipe",
        name = "microwave-receiver-large",
        enabled = false,
        energy_required = 3,
        ingredients = { {"microwave-receiver-small", 2}, {"processing-unit", 2}, {"battery-mk2-equipment", 1} },
		result="microwave-receiver-large",
        -- categories = {"armor"},
    }
})