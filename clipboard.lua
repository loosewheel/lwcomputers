local lwcomp = ...
local S = lwcomp.S



local function on_use (itemstack, user, pointed_thing)
	if itemstack and user and user:is_player () then
		local meta = itemstack:get_meta()
		local formspec =
		"formspec_version[3]\n"..
		"size[13,12.5]\n"..
		"textarea[0.5,0.5;12,10;clipboard;;"..
		 minetest.formspec_escape (meta:get_string ("contents"))..
		"]\nbutton_exit[5.5,11;2,1;save;Save]"

		minetest.show_formspec (user:get_player_name (), "lwcomputers:clipboard", formspec)
	end

	return nil
end



lwcomputers.register_clipboard ("lwcomputers:clipboard", nil, {
   description = S("Computer Clipboard"),
   short_description = S("Computer Clipboard"),
   inventory_image = "lwcomputers_clipboard_item.png",
   on_use = on_use
})



minetest.register_on_player_receive_fields(function (player, formname, fields)
   if formname == "lwcomputers:clipboard" then
      if fields.save then
			if player then
				if player:is_player () then
					local stack = player:get_wielded_item ()

					if stack then
						if stack:get_name() == "lwcomputers:clipboard" then
							local meta = stack:get_meta ()

							if meta then
								local content = (fields.clipboard or ""):sub (1, lwcomp.settings.max_clipboard_length)

								meta:set_string ("contents", content)

								player:set_wielded_item (stack)
							end
						end
					end
				end
			end
		end
	end

	return nil
end)




--
