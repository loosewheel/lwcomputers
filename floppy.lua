

local S = lwcomputers.S



local function on_use (itemstack, user, pointed_thing)
	if itemstack then
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
			"label[2.25,0.8;"..minetest.formspec_escape(sid).."]\n"..
			"label[2.0,1.8;"..minetest.formspec_escape(label).."]\n"..
			"button_exit[2.0,2.5;2.0,1.0;close;Close]"

			minetest.show_formspec(user:get_player_name(), "lwcomputers:floppy", formspec)
		end
	end

	return nil
end



minetest.register_craftitem ("lwcomputers:floppy_black", {
   description = S("Floppy disk"),
   short_description = S("Floppy disk"),
   inventory_image = "floppy_black.png",
   stack_max = 1,
   on_use = on_use,
	groups = { floppy = 1 }
})



minetest.register_craftitem ("lwcomputers:floppy_blue", {
   description = S("Floppy disk"),
   short_description = S("Floppy disk"),
   inventory_image = "floppy_blue.png",
   stack_max = 1,
   on_use = on_use,
	groups = { floppy = 1 }
})



minetest.register_craftitem ("lwcomputers:floppy_red", {
   description = S("Floppy disk"),
   short_description = S("Floppy disk"),
   inventory_image = "floppy_red.png",
   stack_max = 1,
   on_use = on_use,
	groups = { floppy = 1 }
})



minetest.register_craftitem ("lwcomputers:floppy_green", {
   description = S("Floppy disk"),
   short_description = S("Floppy disk"),
   inventory_image = "floppy_green.png",
   stack_max = 1,
   on_use = on_use,
	groups = { floppy = 1 }
})



minetest.register_craftitem ("lwcomputers:floppy_yellow", {
   description = S("Floppy disk"),
   short_description = S("Floppy disk"),
   inventory_image = "floppy_yellow.png",
   stack_max = 1,
   on_use = on_use,
	groups = { floppy = 1 }
})



minetest.register_craftitem ("lwcomputers:floppy_white", {
   description = S("Floppy disk"),
   short_description = S("Floppy disk"),
   inventory_image = "floppy_white.png",
   stack_max = 1,
   on_use = on_use,
	groups = { floppy = 1 }
})



minetest.register_craftitem ("lwcomputers:floppy_lua", {
   description = S("Lua disk"),
   short_description = S("Lua disk"),
   inventory_image = "floppy_lua.png",
   stack_max = 1,
   on_use = on_use
})






--
