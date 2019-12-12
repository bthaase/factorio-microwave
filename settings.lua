data:extend{
    {
        type = "bool-setting",
        name = "mw-show-debug",
        setting_type = "runtime-global",
        default_value = false,
		order="a-a"
    },
    {
        type = "int-setting",
        name = "mw-charge-radius",
        setting_type = "runtime-global",
        default_value = 20,
        minimum_value = 2,
        maximum_value = 5000,
		order="b-a"
    },
    {
        type = "int-setting",
        name = "mw-charge-interval",
        setting_type = "runtime-global",
        default_value = 15,
        minimum_value = 1,
        maximum_value = 100000,
		order="i-a"
    },	
    {
        type = "int-setting",
        name = "mw-search-interval",
        setting_type = "runtime-global",
        default_value = 60,
        minimum_value = 1,
        maximum_value = 100000,
		order="i-b"
    },
}
