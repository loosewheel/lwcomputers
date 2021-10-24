local lwcomp = ...


minetest.register_craft ({
	output = "lwcomputers:computer 1",
	recipe = {
		{ "default:stone", "default:tin_ingot", "default:glass" },
		{ "default:steel_ingot", "default:clay_lump", "default:steel_ingot" },
		{ "default:stick", "default:copper_ingot", "default:coal_lump" }
	}
})


minetest.register_craft ({
	output = "lwcomputers:computer_robot 1",
	recipe = {
		{ "", "default:tin_ingot", "" },
		{ "default:steel_ingot", "lwcomputers:computer", "default:steel_ingot" },
		{ "", "default:copper_ingot", "" }
	}
})


minetest.register_craft ({
	output = "lwcomputers:trash 1",
	recipe = {
		{ "", "group:wood", "" },
		{ "group:wood", "", "group:wood" },
		{ "", "group:wood", "" }
	}
})


minetest.register_craft ({
	output = "lwcomputers:floppy_black 1",
	recipe = {
		{ "farming:flour", "default:paper" },
		{ "default:iron_lump", "dye:black" }
	}
})


minetest.register_craft ({
	output = "lwcomputers:floppy_blue 1",
	recipe = {
		{ "farming:flour", "default:paper" },
		{ "default:iron_lump", "dye:blue" }
	}
})


minetest.register_craft ({
	output = "lwcomputers:floppy_red 1",
	recipe = {
		{ "farming:flour", "default:paper" },
		{ "default:iron_lump", "dye:red" }
	}
})


minetest.register_craft ({
	output = "lwcomputers:floppy_green 1",
	recipe = {
		{ "farming:flour", "default:paper" },
		{ "default:iron_lump", "dye:green" }
	}
})


minetest.register_craft ({
	output = "lwcomputers:floppy_yellow 1",
	recipe = {
		{ "farming:flour", "default:paper" },
		{ "default:iron_lump", "dye:yellow" }
	}
})


minetest.register_craft ({
	output = "lwcomputers:floppy_white 1",
	recipe = {
		{ "farming:flour", "default:paper" },
		{ "default:iron_lump", "dye:white" }
	}
})


minetest.register_craft ({
	output = "lwcomputers:floppy_lua 1",
	recipe = {
		{ "group:floppy_disk" },
		{ "default:book" }
	}
})


minetest.register_craft ({
	output = "lwcomputers:floppy_los 1",
	recipe = {
		{ "group:floppy_disk", "default:book" },
		{ "default:book", "" }
	}
})


minetest.register_craft ({
   output = "lwcomputers:clipboard 1",
   recipe = {
      { "group:wood" },
      { "default:paper" },
   }
})


minetest.register_craft ({
   output = "lwcomputers:ink_cartridge 1",
   recipe = {
      { "dye:black", "dye:red" },
      { "dye:yellow", "dye:blue" },
   }
})


if lwcomp.digilines_supported and lwcomp.mesecon_supported then

minetest.register_craft ({
   output = "lwcomputers:digiswitch 2",
   recipe = {
      { "default:stone", "default:stone" },
      { "default:copper_ingot", "default:mese_crystal_fragment" },
      { "default:stick", "default:stick" },
   }
})

end


if lwcomp.digilines_supported then

minetest.register_craft ({
   output = "lwcomputers:printer 1",
   recipe = {
      { "default:stone", "default:steel_ingot", "default:stick" },
      { "default:tin_ingot", "default:clay_lump", "default:tin_ingot" },
      { "default:stick", "default:copper_ingot", "default:coal_lump" },
   }
})


minetest.register_craft ({
   output = "lwcomputers:digipanel32",
   recipe = {
      { "group:wood", "default:glass", "" },
      { "default:copper_ingot", "default:mese_crystal_fragment", "default:mese_crystal_fragment" },
      { "group:wood", "default:glass", "" },
   }
})


minetest.register_craft ({
   output = "lwcomputers:digiscreen32",
   recipe = {
      { "group:wood", "default:glass", "group:wood" },
      { "default:copper_ingot", "default:mese_crystal_fragment", "default:mese_crystal_fragment" },
      { "group:wood", "default:glass", "group:wood" },
   }
})


minetest.register_craft ({
   output = "lwcomputers:digipanel16",
   recipe = {
      { "group:wood", "default:glass", "" },
      { "default:copper_ingot", "default:mese_crystal_fragment", "" },
      { "group:wood", "default:glass", "" },
   }
})


minetest.register_craft ({
   output = "lwcomputers:digiscreen16",
   recipe = {
      { "group:wood", "default:glass", "group:wood" },
      { "default:copper_ingot", "default:mese_crystal_fragment", "" },
      { "group:wood", "default:glass", "group:wood" },
   }
})


minetest.register_craft({
	output = "lwcomputers:monitor",
	recipe = {
		{"default:stone", "default:steel_ingot", "default:glass"},
		{"default:copper_ingot","digilines:wire_std_00000000","default:tin_ingot"},
		{"default:stick","default:steel_ingot","default:coal_lump"}
	}
})


end


if lwcomp.mesecon_supported and mesecon.mvps_push then

minetest.register_craft ({
   output = "lwcomputers:movefloor",
   recipe = {
      { "default:stick", "default:stick", "default:stick" },
      { "default:stick", "default:steel_ingot", "default:stick" },
      { "default:stick", "default:stick", "default:stick" },
   }
})

end



if minetest.global_exists ("unifieddyes") and
	lwcomp.mesecon_supported and
	lwcomp.digilines_supported then

minetest.register_craft ({
	output = "lwcomputers:solid_conductor_off 3",
	recipe = {
		{ "default:mese_crystal_fragment", "group:wood", ""},
		{ "group:wood", "group:wood", "dye:white" },
	},
})


minetest.register_craft ({
	output = "lwcomputers:solid_horizontal_conductor_off 3",
	recipe = {
		{ "group:wood", "group:wood", ""},
		{ "default:mese_crystal_fragment", "group:wood", "dye:white" },
	},
})

end



--
