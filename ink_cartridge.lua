
local S = lwcomputers.S



minetest.register_tool ("lwcomputers:ink_cartridge", {
   description = S("Ink Cartridge"),
   short_description = S("Ink Cartridge"),
	groups = { },
	inventory_image = "ink_cartridge.png",
	range = 0.0,
	stack_max = 1,
	sound = { },
	tool_capabilities = {
		full_punch_interval = 0.0,
		max_drop_level = 0,
		groupcaps = { },
		damage_groups = { },
	},
})
