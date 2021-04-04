local lwcomp = ...
local S = lwcomp.S



local function on_construct (pos)
	local meta = minetest.get_meta (pos)

	if meta then
		local inv = meta:get_inventory ()

		if inv then
			meta:set_string ("inventory", "{ trash = { [1] = '' } }")
			meta:set_string ("formspec",
				"formspec_version[3]"..
				"size[11.75,10.25,false]"..
				"no_prepend[]"..
				"bgcolor[#CCBD86]"..
				"label[5.25,1.0;Trash]"..
				"list[context;trash;5.25,2.0;1,1;]"..
				"list[current_player;main;1.0,4.5;8,4;]"..
				"listcolors[#545454;#6E6E6E;#B3A575]")

			inv:set_size ("trash", 1)
			inv:set_width ("trash", 1)
		end
	end
end



local function on_metadata_inventory_put (pos, listname, index, stack, player)
	if listname == "trash" and stack and not stack:is_empty () then
		local meta = minetest.get_meta (pos)

		if meta then
			local inv = meta:get_inventory ()

			if inv then
				lwdrops.on_destroy (stack)

				inv:set_stack (listname, index, nil)

				if player and player:is_player () then
					minetest.sound_play ("lwtrash", { to_player = player:get_player_name (), gain = 1.0 })
				end
			end
		end
	end
end



minetest.register_node("lwcomputers:trash", {
   description = S("Trash"),
   tiles = { "trash.png", "trash.png", "trash_side.png",
				 "trash_side.png", "trash_side.png", "trash_side.png" },
   sunlight_propagates = false,
   drawtype = "normal",
   node_box = {
      type = "fixed",
      fixed = {
         {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
      }
   },
	groups = { cracky = 2, oddly_breakable_by_hand = 2 },
	sounds = default.node_sound_wood_defaults (),

   on_construct = on_construct,
	on_metadata_inventory_put = on_metadata_inventory_put
})



--
