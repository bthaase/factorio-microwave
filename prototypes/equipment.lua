----------------------------------------------------------------------------------------------------------------
-- Microwave Equipment (Categories are overridden in data-final-fixes)
----------------------------------------------------------------------------------------------------------------
data:extend({
    {
        type = "battery-equipment",
        name = "microwave-receiver-small",
        sprite = { 
			filename = "__camedo-microwave__/graphics/entity/receivers/microwave1.png", 
			width = 64,
			height = 64, 
			priority = "medium", 
		},
        shape = { width = 2, height = 2, type = "full",},
        energy_source = { 
			type = "electric", 
			buffer_capacity = "500kJ",--"200kJ", 
			input_flow_limit="500kW",--"200kW", 
			output_flow_limit="50kW",--"20kW", 
			usage_priority = "tertiary" 
		},
        categories = {"armor"},
    },
    {
        type = "battery-equipment",
        name = "microwave-receiver-large",
        sprite = { 
			filename = "__camedo-microwave__/graphics/entity/receivers/microwave2.png", 
			width = 96, 
			height = 96, 
			priority = "medium", 
		},
        shape = { width = 3, height = 3, type = "full",},
        energy_source = { 
			type = "electric", 
			buffer_capacity = "1MW",--"550kJ", 
			input_flow_limit = "1MW",--"550kW", 
			output_flow_limit = "100kW",--"55kW", 
			usage_priority = "tertiary" 
		},
        categories = {"armor"},
    }
})
