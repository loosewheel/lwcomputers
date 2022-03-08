local lwcomp = ...
local S = lwcomp.S



local function on_construct (pos)
	local meta = minetest.get_meta (pos)

	meta:set_int ("robot", 0)
end



local function on_construct_robot (pos)
	local meta = minetest.get_meta (pos)

	meta:set_int ("robot", 1)
end



local function on_destruct (pos)
	local meta = minetest.get_meta (pos)

	if meta then
		local id = meta:get_int ("lwcomputer_id")
		local persists = false

		if id > 0 then
			persists = meta:get_int ("persists") == 1
			local data = lwcomp.get_computer_data (id, pos)

			if data then
				data.mesecons_set (false)
			end

			lwcomp.remove_computer_data (id)
		end

		if persists then
			minetest.forceload_free_block (pos, false)
		end
	end
end



local function on_receive_fields (pos, formname, fields, sender)
	if not lwcomp.can_interact_with_node (pos, sender) then
		return
	end

	if fields.reboot then
		local meta = minetest.get_meta (pos)

		if meta then
			local id = meta:get_int ("lwcomputer_id")
			local data = lwcomp.get_computer_data (id, pos)

			if data then
				data.reboot ()
			end
		end

	elseif fields.power then
		local meta = minetest.get_meta (pos)

		if meta then
			local id = meta:get_int ("lwcomputer_id")
			local data = lwcomp.get_computer_data (id, pos)

			if data then
				if data.running then
					data.shutdown ()
				else
					data.startup ()
				end
			end
		end

	elseif fields.persists then
		local meta = minetest.get_meta (pos)

		if meta then
			local id = meta:get_int ("lwcomputer_id")
			local data = lwcomp.get_computer_data (id, pos)

			if data then
				data.toggle_persists ()
				data.update_formspec ()
			end
		end

	elseif fields.storage then
		local meta = minetest.get_meta (pos)

		if meta then
			local id = meta:get_int ("lwcomputer_id")
			local data = lwcomp.get_computer_data (id, pos)

			if data then
				data.suspend_redraw = true

				local spec =
				"formspec_version[3]"..
				"size[11.75,12.25,false]"..
				"no_prepend[]"..
				"bgcolor[#E7DAA8]"..
				"list[context;storage;1.0,1.0;8,4;]"..
				"list[current_player;main;1.0,6.5;8,4;]"..
				"listring[]"..
				"listcolors[#545454;#6E6E6E;#DBCF9F]"

				meta:set_string ("formspec", spec)
			end
		end

	elseif fields.quit then
		local meta = minetest.get_meta (pos)

		if meta then
			local id = meta:get_int ("lwcomputer_id")
			local data = lwcomp.get_computer_data (id, pos)

			if data then
				data.suspend_redraw = false
				data.update_formspec ()
			end
		end

	else
		for k, v in pairs (fields) do
			local key = lwcomp.keys[k]

			if key then
				local meta = minetest.get_meta (pos)

				if meta then
					local id = meta:get_int ("lwcomputer_id")
					local data = lwcomp.get_computer_data (id, pos)

					if data then
						data.id = id

						if k == "KEY_SHIFT" then
							data.shift = not data.shift
							data.update_formspec ()
							data.queue_event ("key", key, data.ctrl, data.alt, data.shift)

						elseif k == "KEY_CAPS" then
							data.caps = not data.caps
							data.update_formspec ()
							data.queue_event ("key", key, data.ctrl, data.alt, data.shift)

						elseif k == "KEY_CTRL" then
							data.ctrl = not data.ctrl
							data.update_formspec ()
							data.queue_event ("key", key, data.ctrl, data.alt, data.shift)

						elseif k == "KEY_ALT" then
							data.alt = not data.alt
							data.update_formspec ()
							data.queue_event ("key", key, data.ctrl, data.alt, data.shift)

						else

							if k == "KEY_V" and data.ctrl and data.alt then
								local contents = data.get_clipboard_contends ()

								if contents then
									data.queue_event ("clipboard", contents)

									return
								end
							end

							data.queue_event ("key", key, data.ctrl, data.alt, data.shift)

							if not data.ctrl and not data.alt then
								local char = key

								if char < lwcomp.keys.KEY_DELETE then
									if char >= lwcomp.keys.KEY_A and char <= lwcomp.keys.KEY_Z then
										if (data.caps and data.shift) or (not data.caps and not data.shift) then
											-- to lower
											char = char + 32
										end
									else
										char = (data.shift and lwcomp.shift_keys[k]) or key
									end

									data.queue_event ("char", string.char (char), char)
								end
							end

						end
					end
				end

			else
				local click = lwcomp.click_buttons[k]

				if click then
					local meta = minetest.get_meta (pos)

					if meta then
						local id = meta:get_int ("lwcomputer_id")
						local data = lwcomp.get_computer_data (id, pos)
						local count = 1

						if (os.clock () - data.clicked_when) <= lwcomp.settings.double_click_time then
							if data.clicked.x == click.x and data.clicked.y == click.y then
								count = data.click_count + 1
							end
						end

						data.clicked_when = os.clock ()
						data.clicked = { x = click.x, y = click.y }
						data.click_count = count

						data.queue_event ("click", click.x, click.y, count)
					end
				end
			end

		end
	end
end



local function preserve_metadata (pos, oldnode, oldmeta, drops)
	if #drops > 0 then
		if drops[1]:get_name ():sub (1, 20) == "lwcomputers:computer" then
			local meta = minetest.get_meta (pos)
			local id = meta:get_int ("lwcomputer_id")

			if id > 0 then
				local imeta = drops[1]:get_meta ()
				local description = meta:get_string ("label")

				if description:len () < 1 then
					description = S("Computer ")..tostring (id)
				end

				imeta:set_int ("lwcomputer_id", id)
				imeta:set_string ("name", meta:get_string ("name"))
				imeta:set_string ("label", meta:get_string ("label"))
				imeta:set_string ("infotext", meta:get_string ("infotext"))
				imeta:set_string ("inventory", meta:get_string ("inventory"))
				imeta:set_string ("digilines_channel", meta:get_string ("digilines_channel"))
				imeta:set_string ("description", description)
				imeta:set_string ("owner", meta:get_string ("owner"))
				imeta:set_string ("access_by", meta:get_string ("access_by"))
				imeta:set_int ("persists", meta:get_int ("persists"))
			end
		end
	end
end



local function after_place_node (pos, placer, itemstack, pointed_thing)
	local meta = minetest.get_meta (pos)
	local is_robot = meta:get_int ("robot") == 1
	local imeta = itemstack:get_meta ()
	local id = imeta:get_int ("lwcomputer_id")
	local name = ""
	local label = ""
	local infotext = ""
	local digilines_channel = ""
	local inventory
	local owner = ""
	local access_by = ""
	local persists = 0

	if is_robot then
		inventory = "{ "..
		"main = { [1] = '', [2] = '', [3] = '' }, "..
		"storage = { [1] = '', [2] = '', [3] = '', [4] = '', [5] = '', [6] = '', [7] = '', [8] = '', "..
		"            [9] = '', [10] = '', [11] = '', [12] = '', [13] = '', [14] = '', [15] = '', [16] = '', "..
		"            [17] = '', [18] = '', [19] = '', [20] = '', [21] = '', [22] = '', [23] = '', [24] = '', "..
		"            [25] = '', [26] = '', [27] = '', [28] = '', [29] = '', [30] = '', [31] = '', [32] = '' } }"
	else
		inventory = "{ main = { [1] = '', [2] = '', [3] = '' } }"
	end

	local unique = false

	if id > 0 then
		name = imeta:get_string ("name")
		label = imeta:get_string ("label")
		infotext = imeta:get_string ("infotext")
		inventory = imeta:get_string ("inventory")
		digilines_channel = imeta:get_string ("digilines_channel")
		owner = imeta:get_string ("owner")
		access_by = imeta:get_string ("access_by")
		persists =  imeta:get_int ("persists")

		unique = true
	else
		id = math.random (1000000)
	end

	meta:set_int ("lwcomputer_id", id)
	meta:set_string ("name", name)
	meta:set_string ("label", label)
	meta:set_int ("running", 0)
	meta:set_string ("infotext", infotext)
	meta:set_string ("inventory", inventory)
	meta:set_string ("digilines_channel", digilines_channel)
	meta:set_string ("owner", owner)
	meta:set_string ("access_by", access_by)

	meta:set_string ("mesecon_front", lwcomp.mesecon_state_off)
	meta:set_string ("mesecon_back", lwcomp.mesecon_state_off)
	meta:set_string ("mesecon_left", lwcomp.mesecon_state_off)
	meta:set_string ("mesecon_right", lwcomp.mesecon_state_off)
	meta:set_string ("mesecon_up", lwcomp.mesecon_state_off)

	if not is_robot then
		persists = 0
	end

	meta:set_int ("persists", persists)

	local inv = meta:get_inventory ()

	inv:set_size ("main", 3)
	inv:set_width ("main", 3)

	if is_robot then
		inv:set_size ("storage", 32)
		inv:set_width ("storage", 8)
	end

	local data = lwcomp.reset_computer_data (id, pos)

	if data then
		meta:set_string ("formspec", lwcomp.term_formspec (data))
	end

	-- orientate
	if placer and placer:is_player () then
		local angle = placer:get_look_horizontal ()
		local node = minetest.get_node (pos)
		local param2

		if angle >= (math.pi * 0.25) and angle < (math.pi * 0.75) then
			-- x-
			param2 = 3
		elseif angle >= (math.pi * 0.75) and angle < (math.pi * 1.25) then
			-- z-
			param2 = 1
		elseif angle >= (math.pi * 1.25) and angle < (math.pi * 1.75) then
			-- x+
			param2 = 4
		else
			-- z+
			param2 = 2
		end

		meta:set_int ("param2", param2)

		if node.name ~= "ignore" then
			node.param2 = param2
		end
	end

	if persists == 1 then
		minetest.forceload_block (pos, false)
	end

	if unique and placer and placer:is_player () and
		minetest.is_creative_enabled (placer:get_player_name ()) then

		-- no duplicates in creative mode
		itemstack:clear ()

		return true

	elseif not unique and placer and placer:is_player () then
		local spec =
		"formspec_version[3]"..
		"size[8.0,3.0,false]"..
		"no_prepend[]"..
		"bgcolor[#E7DAA8]"..
		"style[public;bgcolor=green;textcolor=white]"..
		"style[private_"..tostring (id)..";bgcolor=red;textcolor=white]"..
		"button_exit[1.0,1.0;2.5,1.0;public;Public]"..
		"button_exit[4.5,1.0;2.5,1.0;private_"..tostring (id)..";Private]"

		minetest.show_formspec (placer:get_player_name (),
										"lwcomputers:computer_set_owner",
										spec)
	end

	-- If return true no item is taken from itemstack
	return false
end



local function on_timer (pos, elapsed)
	local meta = minetest.get_meta (pos)

	if meta then
		local id = meta:get_int ("lwcomputer_id")
		local data = lwcomp.get_computer_data (id, pos)

		if data then
			data.tick ()
		end
	end

	-- return true to run the timer for another cycle with the same timeout
	return true
end



local function can_dig (pos, player)
	if not lwcomp.can_interact_with_node (pos, player) then
		return false
	end

	local meta = minetest.get_meta (pos)

	if meta then
		local inv = meta:get_inventory ()

		if inv then
			if not inv:is_empty ("main") then
				return false
			end
		end

		if meta:get_int ("robot") == 1 then
			if not inv:is_empty ("storage") then
				return false
			end
		end

	end

	return true
end



local function allow_metadata_inventory_move (pos, from_list, from_index, to_list, to_index, count, player)
	if not lwcomp.can_interact_with_node (pos, player) then
		return 0
	end

	return lwcomp.settings.default_stack_max
end



local function allow_metadata_inventory_put (pos, listname, index, stack, player)
	if not lwcomp.can_interact_with_node (pos, player) then
		return 0
	end

	if listname == "main" then
		if stack and not stack:is_empty () then
			local itemname = stack:get_name ()

			if lwcomp.is_floppy_disk (itemname) or
				lwcomp.is_clipboard (itemname) then

				return 1
			end
		end
	elseif listname == "storage" then
		return lwcomp.settings.default_stack_max
	end

	return 0
end



local function allow_metadata_inventory_take (pos, listname, index, stack, player)
	if not lwcomp.can_interact_with_node (pos, player) then
		return 0
	end

	return lwcomp.settings.default_stack_max
end



local function on_metadata_inventory_put (pos, listname, index, stack, player)
	if listname == "main" then
		if stack and not stack:is_empty () then
			local itemname = stack:get_name ()

			local floppy = lwcomp.is_floppy_disk (itemname)
			if floppy then
				local imeta = stack:get_meta ()

				if imeta then
					local id = imeta:get_int ("lwcomputer_id")

					if id < 1 then
						id = math.random (1000000)
						imeta:set_int ("lwcomputer_id", id)
						imeta:set_string ("label", floppy.label)

						if floppy.label:len () > 0 then
							imeta:set_string ("description", floppy.label)
						else
							imeta:set_string ("description", S("floppy ")..tostring (id))
						end

						if not lwcomp.filesys:prep_floppy_disk (id, imeta, floppy.files) then
							minetest.log ("error", "lwcomputers - could not prep "..floppy.name)
						end

						local inv = minetest.get_meta (pos):get_inventory ()
						inv:set_stack (listname, index, stack)
					end

					-- create floppy if not yet
					lwcomp.filesys:create_floppy (id)
				end

				local meta = minetest.get_meta (pos)
				if meta then
					local id = meta:get_int ("lwcomputer_id")
					local data = lwcomp.get_computer_data (id, pos)

					if data then
						data.queue_event ("disk", true)
					end
				end
			end
		end
	end
end



local function on_metadata_inventory_take (pos, listname, index, stack, player)
	if listname == "main" then
		if stack and not stack:is_empty () then
			local itemname = stack:get_name ()

			if lwcomp.is_floppy_disk (itemname) then
				local meta = minetest.get_meta (pos)

				if meta then
					local id = meta:get_int ("lwcomputer_id")
					local data = lwcomp.get_computer_data (id, pos)

					if data then
						data.queue_event ("disk", false)
					end
				end
			end
		end
	end
end



local function on_punch_robot (pos, node, puncher, pointed_thing)
	if not lwcomp.can_interact_with_node (pos, puncher) then
		return
	end

	if puncher and puncher:is_player () and
		puncher:get_player_control ().sneak then

		local meta = minetest.get_meta (pos)

		if meta then
			local id = meta:get_int ("lwcomputer_id")

			if id > 0 then
				local data = lwcomp.get_computer_data (id, pos)

				if data and data.running then
				local spec =
					"formspec_version[3]"..
					"size[4.5,3.0,false]"..
					"no_prepend[]"..
					"bgcolor[#E7DAA8]"..
					"style_type[button_exit;bgcolor=red;textcolor=white]"..
					"button_exit[1.0,1.0;2.5,1.0;stop_"..tostring (id)..";Stop]"

					minetest.show_formspec (puncher:get_player_name (),
													"lwcomputers:computer_robot_stop",
													spec)
				end
			end
		end
	end
end



local function on_destroy (itemstack)
	local meta = itemstack:get_meta ()

	if meta then
		local id = meta:get_int ("lwcomputer_id")

		if id > 0 then
			lwcomp.filesys:delete_hdd (id)
		end
	end
end



local function on_rightclick (pos, node, clicker, itemstack, pointed_thing)
	if not lwcomp.can_interact_with_node (pos, clicker) then
		if clicker and clicker:is_player () then
			local owner = "<unknown>"
			local meta = minetest.get_meta (pos)

			if meta then
				owner = meta:get_string ("owner")
			end

			local spec =
			"formspec_version[3]"..
			"size[8.0,4.0,false]"..
			"label[1.0,1.0;Owned by "..minetest.formspec_escape (owner).."]"..
			"button_exit[3.0,2.0;2.0,1.0;close;Close]"

			minetest.show_formspec (clicker:get_player_name (),
											"lwcomputers:computer_privately_owned",
											spec)
		end
	end

	return itemstack
end



local function on_blast (pos, intensity)
	local meta = minetest.get_meta (pos)

	if meta then
		local id = meta:get_int ("lwcomputer_id")

		if id > 0 then
			local is_robot = meta:get_int ("robot") == 1

			if intensity >= 1.0 then
				local inv = meta:get_inventory ()

				if inv then
					local slots = inv:get_size ("main")

					for slot = 1, slots do
						local stack = inv:get_stack ("main", slot)

						if stack and not stack:is_empty () then
							if math.floor (math.random (0, 5)) == 3 then
								lwcomp.item_drop (stack, nil, pos)
							else
								lwcomp.on_destroy (stack)
							end
						end
					end

					if is_robot then
						local rslots = inv:get_size ("storage")

						for slot = 1, rslots do
							local stack = inv:get_stack ("storage", slot)

							if stack and not stack:is_empty () then
								if math.floor (math.random (0, 5)) == 3 then
									lwcomp.item_drop (stack, nil, pos)
								else
									lwcomp.on_destroy (stack)
								end
							end
						end
					end
				end

				lwcomp.filesys:delete_hdd (id)

				on_destruct (pos)
				minetest.remove_node (pos)


			else -- intensity < 1.0
				local inv = meta:get_inventory ()

				if inv then
					local slots = inv:get_size ("main")

					for slot = 1, slots do
						local stack = inv:get_stack ("main", slot)

						if stack and not stack:is_empty () then
							lwcomp.item_drop (stack, nil, pos)
						end
					end

					if is_robot then
						local rslots = inv:get_size ("storage")

						for slot = 1, rslots do
							local stack = inv:get_stack ("storage", slot)

							if stack and not stack:is_empty () then
								lwcomp.item_drop (stack, nil, pos)
							end
						end
					end
				end

				local node = minetest.get_node_or_nil (pos)
				if node then
					local items = minetest.get_node_drops (node, nil)

					if items and #items > 0 then
						local stack = ItemStack (items[1])

						if stack then
							preserve_metadata (pos, node, meta, { stack })
							lwcomp.item_drop (stack, nil, pos)
							on_destruct (pos)
							minetest.remove_node (pos)
						end
					end
				end
			end
		end
	end
end



local function digilines_support ()
	if lwcomp.digilines_supported then
		return
		{
			wire =
			{
				rules = digiline.rules.default,
			},

			effector =
			{
				action = function (pos, node, channel, msg)
					local meta = minetest.get_meta(pos)

					if meta then
						local id = meta:get_int ("lwcomputer_id")

						if id > 0 then
							local data = lwcomp.get_computer_data (id, pos)

							if data then
								local mychannel = meta:get_string ("digilines_channel")

								data.queue_event ("digilines", msg, channel, mychannel)
							end
						end
					end
				end,
			}
		}
	end

	return nil
end



local function get_mesecon_side_for_rule (pos, param2, rule)
	if type (rule) == "table" and param2 >= 1 and param2 <= 4 then
		if rule.x == -1 then
			return ({ "left", "right", "back", "front" })[param2]
		elseif rule.x == 1 then
			return ({ "right", "left", "front", "back" })[param2]
		elseif rule.z == -1 then
			return ({ "back", "front", "right", "left" })[param2]
		elseif rule.z == 1 then
			return ({ "front", "back", "left", "right" })[param2]
		end
	end

	return nil
end



local function mesecon_support ()
	if lwcomp.mesecon_supported then
		return
		{
			receptor =
			{
				state = mesecon.state.off, -- /on,
				rules =
				{
					{ x = 1, y = 0, z = 0 },
					{ x = -1, y = 0, z = 0 },
					{ x = 0, y = 0, z = 1 },
					{ x = 0, y = 0, z = -1 },
					{ x = 0, y = 1, z = 0 },
					--{ x = 0, y = -1, z = 0 }, down doesn't work
				}
			},

			effector =
			{
				rules = mesecon.rules.flat,

				action_change = function (pos, node, rule, new_state)
					local meta = minetest.get_meta (pos)

					if meta then
						local id = meta:get_int ("lwcomputer_id")

						if id > 0 then
							local data = lwcomp.get_computer_data (id, pos)

							if data then
								data.queue_event ("mesecons", new_state,
														get_mesecon_side_for_rule (pos, meta:get_int ("param2"), rule))
							end
						end
					end
				end
			}
		}
	end

	return nil
end



minetest.register_node("lwcomputers:computer", {
   description = S("Computer"),
   tiles = { "lwcomputers_computer.png", "lwcomputers_computer.png", "lwcomputers_computer.png",
				 "lwcomputers_computer.png", "lwcomputers_computer.png", "lwcomputers_computer_face.png" },
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
	paramtype = "light",
	param1 = 0,
	paramtype2 = "facedir",
	param2 = 1,
	drop = "lwcomputers:computer",
	floodable = false,

	mesecons = mesecon_support (),
	digiline = digilines_support (),

   on_construct = on_construct,
   on_destruct = on_destruct,
	on_receive_fields = on_receive_fields,
	preserve_metadata = preserve_metadata,
	after_place_node = after_place_node,
	on_timer = on_timer,
	can_dig = can_dig,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	on_metadata_inventory_put = on_metadata_inventory_put,
	on_metadata_inventory_take = on_metadata_inventory_take,
	on_rightclick = on_rightclick,
	on_destroy = on_destroy,
	on_blast = on_blast
})



minetest.register_node("lwcomputers:computer_on", {
   description = S("Computer"),
   tiles = { "lwcomputers_computer.png", "lwcomputers_computer.png", "lwcomputers_computer.png",
				 "lwcomputers_computer.png", "lwcomputers_computer.png", "lwcomputers_computer_face_on.png" },
   sunlight_propagates = false,
   drawtype = "normal",
   node_box = {
      type = "fixed",
      fixed = {
         {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
      }
   },
	groups = { cracky = 2, oddly_breakable_by_hand = 2, not_in_creative_inventory = 1 },
	sounds = default.node_sound_wood_defaults (),
	paramtype = "light",
	param1 = 0,
	paramtype2 = "facedir",
	param2 = 1,
	drop = "lwcomputers:computer",
	floodable = false,

	mesecons = mesecon_support (),
	digiline = digilines_support (),

   on_construct = on_construct,
   on_destruct = on_destruct,
	on_receive_fields = on_receive_fields,
	preserve_metadata = preserve_metadata,
	after_place_node = after_place_node,
	on_timer = on_timer,
	can_dig = can_dig,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	on_metadata_inventory_put = on_metadata_inventory_put,
	on_metadata_inventory_take = on_metadata_inventory_take,
	on_rightclick = on_rightclick,
	on_destroy = on_destroy,
	on_blast = on_blast
})



minetest.register_node("lwcomputers:computer_robot", {
   description = S("Robot"),
   tiles = { "lwcomputers_robot_top.png", "lwcomputers_robot_bottom.png", "lwcomputers_robot_left.png",
				 "lwcomputers_robot_right.png", "lwcomputers_robot_back.png", "lwcomputers_robot_face.png" },
   drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			 -- left_foot
			{ -0.3125, -0.5, -0.3125, -0.0625, -0.375, 0.3125 },
			-- right_foot
			{ 0.0625, -0.5, -0.3125, 0.3125, -0.375, 0.3125 },
			-- left_leg
			{ -0.25, -0.375, 0, -0.125, -0.3125, 0.125 },
			-- right_left
			{ 0.125, -0.375, 0, 0.25, -0.3125, 0.125 },
			-- body
			{ -0.375, -0.3125, -0.375, 0.375, 0.1875, 0.375 },
			-- upper_arm
			{ -0.5, -0.1875, -0.0625, 0.5, 0.1875, 0.125 },
			-- lower_arm
			{ -0.5, -0.1875, -0.25, 0.5, 0, 0.125 },
			-- neck
			{ -0.125, 0.1875, -0.0625, 0.125, 0.25, 0.1875 },
			-- head
			{ -0.3125, 0.25, -0.3125, 0.3125, 0.5, 0.3125 },
		}
	},
   selection_box = {
      type = "fixed",
      fixed = { -0.5, -0.5, -0.375, 0.5, 0.5, 0.375 }
   },
   collision_box = {
      type = "fixed",
      fixed = { -0.5, -0.5, -0.375, 0.5, 0.5, 0.375 }
   },
	groups = { cracky = 2, oddly_breakable_by_hand = 2 },
	sounds = default.node_sound_wood_defaults (),
	paramtype = "light",
	param1 = 0,
	paramtype2 = "facedir",
	param2 = 1,
   sunlight_propagates = true,
	drop = "lwcomputers:computer_robot",
	floodable = false,

	mesecons = mesecon_support (),
	digiline = digilines_support (),

   on_construct = on_construct_robot,
   on_destruct = on_destruct,
	on_receive_fields = on_receive_fields,
	preserve_metadata = preserve_metadata,
	after_place_node = after_place_node,
	on_timer = on_timer,
	can_dig = can_dig,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	on_metadata_inventory_put = on_metadata_inventory_put,
	on_metadata_inventory_take = on_metadata_inventory_take,
	on_punch = on_punch_robot,
	on_rightclick = on_rightclick,
	on_destroy = on_destroy,
	on_blast = on_blast
})



minetest.register_node("lwcomputers:computer_robot_on", {
   description = S("Robot"),
   tiles = { "lwcomputers_robot_top.png", "lwcomputers_robot_bottom.png", "lwcomputers_robot_left.png",
				 "lwcomputers_robot_right.png", "lwcomputers_robot_back.png", "lwcomputers_robot_face_on.png" },
   drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			 -- left_foot
			{ -0.3125, -0.5, -0.3125, -0.0625, -0.375, 0.3125 },
			-- right_foot
			{ 0.0625, -0.5, -0.3125, 0.3125, -0.375, 0.3125 },
			-- left_leg
			{ -0.25, -0.375, 0, -0.125, -0.3125, 0.125 },
			-- right_left
			{ 0.125, -0.375, 0, 0.25, -0.3125, 0.125 },
			-- body
			{ -0.375, -0.3125, -0.375, 0.375, 0.1875, 0.375 },
			-- upper_arm
			{ -0.5, -0.1875, -0.0625, 0.5, 0.1875, 0.125 },
			-- lower_arm
			{ -0.5, -0.1875, -0.25, 0.5, 0, 0.125 },
			-- neck
			{ -0.125, 0.1875, -0.0625, 0.125, 0.25, 0.1875 },
			-- head
			{ -0.3125, 0.25, -0.3125, 0.3125, 0.5, 0.3125 },
		}
	},
   selection_box = {
      type = "fixed",
      fixed = { -0.5, -0.5, -0.375, 0.5, 0.5, 0.375 }
   },
   collision_box = {
      type = "fixed",
      fixed = { -0.5, -0.5, -0.375, 0.5, 0.5, 0.375 }
   },
	groups = { cracky = 2, oddly_breakable_by_hand = 2, not_in_creative_inventory = 1 },
	sounds = default.node_sound_wood_defaults (),
	paramtype = "light",
	param1 = 0,
	paramtype2 = "facedir",
	param2 = 1,
   sunlight_propagates = true,
	drop = "lwcomputers:computer_robot",
	floodable = false,

	mesecons = mesecon_support (),
	digiline = digilines_support (),

   on_construct = on_construct_robot,
   on_destruct = on_destruct,
	on_receive_fields = on_receive_fields,
	preserve_metadata = preserve_metadata,
	after_place_node = after_place_node,
	on_timer = on_timer,
	can_dig = can_dig,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	on_metadata_inventory_put = on_metadata_inventory_put,
	on_metadata_inventory_take = on_metadata_inventory_take,
	on_punch = on_punch_robot,
	on_rightclick = on_rightclick,
	on_destroy = on_destroy,
	on_blast = on_blast
})



minetest.register_on_player_receive_fields (function (player, formname, fields)
   if formname == "lwcomputers:computer_robot_stop" and
		player and player:is_player () then

		for k, v in pairs (fields) do
			if k:sub (1, 5) == "stop_" then
				local data = lwcomp.get_computer_data (tonumber (k:sub (6)))

				if data then
					data.shutdown ()
				end
			end
		end

		return nil
	end
end)



minetest.register_on_player_receive_fields (function (player, formname, fields)
   if formname == "lwcomputers:computer_set_owner" and
		player and player:is_player () then

		for k, v in pairs (fields) do
			if k:sub (1, 8) == "private_" then
				local data = lwcomp.get_computer_data (tonumber (k:sub (9)))

				if data then
					local meta = minetest.get_meta (data.pos)

					if meta then
						meta:set_string ("owner", player:get_player_name ())
					end
				end
			end
		end

		return nil
	end
end)


--
