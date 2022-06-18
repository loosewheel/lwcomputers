local lwcomp = ...
local S = lwcomp.S



local function on_use (itemstack, user, pointed_thing)
	if itemstack and user and user:is_player () then
		local ver = lwcomp.get_minetest_version ()
		local meta = itemstack:get_meta()
		local formspec

		if ver.major >= 5 and ver.minor >= 4 then
			formspec =
			"formspec_version[3]\n"..
			"size[17,12.5]\n"..
			"style[clipboard;font=mono]\n"..
			"textarea[0.5,0.5;16,10;clipboard;;"..
			 minetest.formspec_escape (meta:get_string ("contents"))..
			"]\nbutton_exit[7.5,11;2,1;save;Save]"

		else
			formspec =
			"formspec_version[3]\n"..
			"size[17,12.5]\n"..
			"textarea[0.5,0.5;16,10;clipboard;;"..
			 minetest.formspec_escape (meta:get_string ("contents"))..
			"]\nbutton_exit[7.5,11;2,1;save;Save]"
		end

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
