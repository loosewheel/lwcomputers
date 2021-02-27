local lwcomp = ...
local S = lwcomp.S



local function on_use (itemstack, user, pointed_thing)
	if itemstack and user and user:is_player () then
		local meta = itemstack:get_meta()

		if meta then
			local id = meta:get_int ("lwcomputer_id")
			local label = meta:get_string ("label")
			local sid = "ID:<not used>"

			if id > 0 then
				sid = "ID:"..tostring (id)
			end

			if label == "" then
				label = "Label:<no label>"
			else
				label = "Label:"..label
			end

			local formspec =
			"formspec_version[3]\n"..
			"size[6.0,4.0]\n"..
			"label[2.25,0.8;"..minetest.formspec_escape (sid).."]\n"..
			"label[2.0,1.8;"..minetest.formspec_escape (label).."]\n"..
			"button_exit[2.0,2.5;2.0,1.0;close;Close]"

			minetest.show_formspec (user:get_player_name (), "lwcomputers:floppy", formspec)
		end
	end

	return nil
end



lwcomputers.register_floppy_disk ("lwcomputers:floppy_black", nil, {
   description = S("Floppy disk"),
   short_description = S("Floppy disk"),
   inventory_image = "floppy_black.png",
   on_use = on_use,
	groups = { floppy_disk = 1 }
})



lwcomputers.register_floppy_disk ("lwcomputers:floppy_blue", nil, {
   description = S("Floppy disk"),
   short_description = S("Floppy disk"),
   inventory_image = "floppy_blue.png",
   on_use = on_use,
	groups = { floppy_disk = 1 }
})



lwcomputers.register_floppy_disk ("lwcomputers:floppy_red", nil, {
   description = S("Floppy disk"),
   short_description = S("Floppy disk"),
   inventory_image = "floppy_red.png",
   on_use = on_use,
	groups = { floppy_disk = 1 }
})



lwcomputers.register_floppy_disk ("lwcomputers:floppy_green", nil, {
   description = S("Floppy disk"),
   short_description = S("Floppy disk"),
   inventory_image = "floppy_green.png",
   on_use = on_use,
	groups = { floppy_disk = 1 }
})



lwcomputers.register_floppy_disk ("lwcomputers:floppy_yellow", nil, {
   description = S("Floppy disk"),
   short_description = S("Floppy disk"),
   inventory_image = "floppy_yellow.png",
   on_use = on_use,
	groups = { floppy_disk = 1 }
})



lwcomputers.register_floppy_disk ("lwcomputers:floppy_white", nil, {
   description = S("Floppy disk"),
   short_description = S("Floppy disk"),
   inventory_image = "floppy_white.png",
   on_use = on_use,
	groups = { floppy_disk = 1 }
})



lwcomputers.register_floppy_disk ("lwcomputers:floppy_lua", "lua_disk", {
   description = S("Lua disk"),
   short_description = S("Lua disk"),
   inventory_image = "floppy_lua.png",
   on_use = on_use,
	groups = { floppy_disk = 1 },
	diskfiles = {
		{ source = lwcomp.modpath.."/res/lua_boot", target = "/boot" }
	}
})



lwcomputers.register_floppy_disk ("lwcomputers:floppy_los", "los_disk", {
   description = S("Los disk"),
   short_description = S("Los disk"),
   inventory_image = "floppy_los.png",
   on_use = on_use,
	groups = { floppy_disk = 1 },
	diskfiles = {
		{ source = lwcomp.modpath.."/res/los_boot", target = "/boot" },
		{ source = lwcomp.modpath.."/res/los_startup", target = "/startup" },
		{ source = lwcomp.modpath.."/res/los_lua", target = "/progs/lua" },
		{ source = lwcomp.modpath.."/res/los_edit", target = "/progs/edit" },
		{ source = lwcomp.modpath.."/res/los_edit.man", target = "/progs/edit.man" },
		{ source = lwcomp.modpath.."/res/los_print", target = "/progs/print" },
		{ source = lwcomp.modpath.."/res/los_install", target = "/progs/install" }
	}
})



--
