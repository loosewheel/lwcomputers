local lwcomp = ...
local S = lwcomp.S



if minetest.global_exists ("unifieddyes") and
	lwcomp.mesecon_supported and
	lwcomp.digilines_supported then



mesecon.register_node (":lwcomputers:solid_conductor",
	{
		description = "Solid Color Conductor",
		tiles = { "solid_conductor.png" },
		is_ground_content = false,
		sounds = ( default and default.node_sound_wood_defaults() ),
		paramtype2 = "color",
		palette = "unifieddyes_palette_extended.png",
		on_rotate = false,
		drop = "lwcomputers:solid_conductor_off",
		digiline = { wire = { rules = mesecon.rules.default } },
		on_construct = unifieddyes.on_construct,
		on_dig = unifieddyes.on_dig,
	},
	{
		tiles = { "solid_conductor.png" },
		mesecons =
		{
			conductor =
			{
				rules = mesecon.rules.default,
				state = mesecon.state.off,
				onstate = "lwcomputers:solid_conductor_on",
			}
		},
		groups = {
			dig_immediate = 2,
			ud_param2_colorable = 1,
		},
	},
	{
		tiles = { "solid_conductor.png" },
		mesecons =
		{
			conductor =
			{
				rules = mesecon.rules.default,
				state = mesecon.state.on,
				offstate = "lwcomputers:solid_conductor_off",
			}
		},
		groups = {
			dig_immediate = 2,
			ud_param2_colorable = 1,
			not_in_creative_inventory = 1
		},
	}
)



unifieddyes.register_color_craft ({
	output = "lwcomputers:solid_conductor_off 3",
	palette = "extended",
	type = "shapeless",
	neutral_node = "lwcomputers:solid_conductor_off",
	recipe = {
		"NEUTRAL_NODE",
		"NEUTRAL_NODE",
		"NEUTRAL_NODE",
		"MAIN_DYE"
	}
})



mesecon.register_node (":lwcomputers:solid_horizontal_conductor",
	{
		description = "Solid Color Horizontal Conductor",
		tiles = { "solid_conductor.png" },
		is_ground_content = false,
		sounds = ( default and default.node_sound_wood_defaults() ),
		paramtype2 = "color",
		palette = "unifieddyes_palette_extended.png",
		on_rotate = false,
		drop = "lwcomputers:solid_horizontal_conductor_off",
		digiline = { wire = { rules = mesecon.rules.flat } },
		on_construct = unifieddyes.on_construct,
		on_dig = unifieddyes.on_dig,
	},
	{
		tiles = { "solid_conductor.png" },
		mesecons =
		{
			conductor =
			{
				rules = mesecon.rules.flat,
				state = mesecon.state.off,
				onstate = "lwcomputers:solid_horizontal_conductor_on",
			}
		},
		groups = {
			dig_immediate = 2,
			ud_param2_colorable = 1,
		},
	},
	{
		tiles = { "solid_conductor.png" },
		mesecons =
		{
			conductor =
			{
				rules = mesecon.rules.flat,
				state = mesecon.state.on,
				offstate = "lwcomputers:solid_horizontal_conductor_off",
			}
		},
		groups = {
			dig_immediate = 2,
			ud_param2_colorable = 1,
			not_in_creative_inventory = 1
		},
	}
)



unifieddyes.register_color_craft ({
	output = "lwcomputers:solid_horizontal_conductor_off 3",
	palette = "extended",
	type = "shapeless",
	neutral_node = "lwcomputers:solid_horizontal_conductor_off",
	recipe = {
		"NEUTRAL_NODE",
		"NEUTRAL_NODE",
		"NEUTRAL_NODE",
		"MAIN_DYE"
	}
})



end
