

minetest.register_craft({
	output = "lwcomputers:computer 1",
	recipe = {
		{ "default:stone", "default:tin_ingot", "default:glass" },
		{ "default:steel_ingot", "default:clay_lump", "default:steel_ingot" },
		{ "default:stick", "default:copper_ingot", "default:coal_lump" }
	}
})


minetest.register_craft({
	output = "lwcomputers:floppy_black 1",
	recipe = {
		{ "farming:flour", "default:paper" },
		{ "default:iron_lump", "dye:black" }
	}
})


minetest.register_craft({
	output = "lwcomputers:floppy_blue 1",
	recipe = {
		{ "farming:flour", "default:paper" },
		{ "default:iron_lump", "dye:blue" }
	}
})


minetest.register_craft({
	output = "lwcomputers:floppy_red 1",
	recipe = {
		{ "farming:flour", "default:paper" },
		{ "default:iron_lump", "dye:red" }
	}
})


minetest.register_craft({
	output = "lwcomputers:floppy_green 1",
	recipe = {
		{ "farming:flour", "default:paper" },
		{ "default:iron_lump", "dye:green" }
	}
})


minetest.register_craft({
	output = "lwcomputers:floppy_yellow 1",
	recipe = {
		{ "farming:flour", "default:paper" },
		{ "default:iron_lump", "dye:yellow" }
	}
})


minetest.register_craft({
	output = "lwcomputers:floppy_white 1",
	recipe = {
		{ "farming:flour", "default:paper" },
		{ "default:iron_lump", "dye:white" }
	}
})


minetest.register_craft({
	output = "lwcomputers:floppy_lua 1",
	recipe = {
		{ "group:floppy" },
		{ "default:book" }
	}
})


minetest.register_craft({
   output = 'lwcomputers:clipboard',
   recipe = {
      { '', 'group:wood', ''},
      { '', 'default:paper', ''},
      { '', '', '' },
   }
})



--
