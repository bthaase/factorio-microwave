----------------------------------------------------------------------------------------------------------------
-- Microwave Vehicle Equipment (Categories are overridden in data-final-fixes)
----------------------------------------------------------------------------------------------------------------
data:extend({
    {
        type = "battery-equipment",
        name = "microwave-vehicle-receiver-small",
        sprite = { 
			filename = "__camedo-microwave__/graphics/entity/receivers/microwave1.png", 
			width = 64,
			height = 64, 
			priority = "medium", 
		},
        shape = { width = 2, height = 2, type = "full",},
        energy_source = { 
			type = "electric", 
			buffer_capacity = "500kJ", 
			input_flow_limit="500kW", 
			output_flow_limit="50kW", 
			usage_priority = "tertiary" 
		},
        categories = {"armor"},
    },	
    {
        type = "battery-equipment",
        name = "microwave-vehicle-receiver-large",
        sprite = { 
			filename = "__camedo-microwave__/graphics/entity/receivers/microwave2.png", 
			width = 96, 
			height = 96, 
			priority = "medium", 
		},
        shape = { width = 3, height = 3, type = "full",},
        energy_source = { 
			type = "electric", 
			buffer_capacity = "1MJ", 
			input_flow_limit="1MW", 
			output_flow_limit="100kW", 
			usage_priority = "tertiary" 
		},
        categories = {"armor"},
    }
})
