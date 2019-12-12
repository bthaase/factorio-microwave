data:extend({
	-- ------------------------------------------------
	-- MICROWAVE CHARGING TECHNOLOGIES
	-- ------------------------------------------------
	
	-- Technology (Tier 1 Basic, Tier 2 Improved Receiver, Maybe a few tiers of throughput improvement?)
	{
		type = "technology",
		name = "microwave-charging1",
		icon = "__camedo-microwave__/graphics/technology/microwave1.png",
		icon_size = 128,
		prerequisites = {"advanced-electronics-2", "battery-equipment"},
		effects = 
		{
		  { type = "unlock-recipe", recipe = "microwave-tower" },
		  { type = "unlock-recipe", recipe = "microwave-receiver-small" },
		},
		unit = { count = 200, ingredients = { {"automation-science-pack", 1}, {"logistic-science-pack", 1}, {"chemical-science-pack", 1} }, time = 30 },
		order = "g-i-a"
	},
	{
		type = "technology",
		name = "microwave-charging2",
		icon = "__camedo-microwave__/graphics/technology/microwave2.png",
		icon_size = 128,
		prerequisites = {"battery-mk2-equipment", "microwave-charging1"},
		effects = 
		{
		  { type = "unlock-recipe", recipe = "microwave-receiver-large" },
		},
		unit = { count = 100, ingredients = { {"automation-science-pack", 1}, {"logistic-science-pack", 1}, {"chemical-science-pack", 1} }, time = 30 },
		order = "g-i-b"
	}
})


