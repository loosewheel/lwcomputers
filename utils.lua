local lwcomp, mod_storage, http_api = ...



if minetest.get_translator and minetest.get_translator("lwcomputers") then
	lwcomp.S = minetest.get_translator("lwcomputers")
elseif minetest.global_exists("intllib") then
   if intllib.make_gettext_pair then
      lwcomp.S = intllib.make_gettext_pair()
   else
      lwcomp.S = intllib.Getter()
   end
else
   lwcomp.S = function(s) return s end
end



lwcomp.modpath = minetest.get_modpath("lwcomputers")
lwcomp.worldpath = minetest.get_worldpath()
lwcomp.computer_data = { }
lwcomp.computer_list = minetest.deserialize (mod_storage:get_string ("computer_list") or "")

if type (lwcomp.computer_list) ~= "table" then
	lwcomp.computer_list = { }
end



function lwcomp.store_computer_list ()
	mod_storage:set_string ("computer_list",
				minetest.serialize (lwcomp.computer_list))
end



-- check for mesecon
if minetest.global_exists ("mesecon") then
	lwcomp.mesecon_supported = true
	lwcomp.mesecon_state_on = mesecon.state.on
	lwcomp.mesecon_state_off = mesecon.state.off
	lwcomp.mesecon_receptor_on = mesecon.receptor_on
	lwcomp.mesecon_receptor_off = mesecon.receptor_off
	lwcomp.mesecon_default_rules = mesecon.rules.default

else
	lwcomp.mesecon_supported = false
	lwcomp.mesecon_state_on = "on"
	lwcomp.mesecon_state_off = "off"
	lwcomp.mesecon_default_rules = { }

	-- dummies
	lwcomp.mesecon_receptor_on = function (pos, rules)
	end

	lwcomp.mesecon_receptor_off = function (pos, rules)
	end

end



-- check for digilines
if minetest.global_exists ("digilines") then
	lwcomp.digilines_supported = true
	lwcomp.digilines_receptor_send = digilines.receptor_send
else
	lwcomp.digilines_supported = false

	-- dummy
	lwcomp.digilines_receptor_send = function (pos, rules, channel, msg)
	end
end



lwcomp.colors =
{
	black		= 0,
	orange	= 1,
	magenta	= 2,
	sky		= 3,
	yellow	= 4,
	pink		= 5,
	cyan		= 6,
	gray		= 7,
	silver	= 8,
	red		= 9,
	green		= 10,
	blue		= 11,
	brown		= 12,
	lime		= 13,
	purple	= 14,
	white		= 15
}



lwcomp.keys =
{
	KEY_BACKSPACE		= 8,
	KEY_TAB				= 9,
	KEY_LINE				= 10,
	KEY_ENTER			= 13,
	KEY_ESC				= 27, -- depreciated
	KEY_ESCAPE			= 27,
	KEY_SPACE			= 32,
	KEY_EXCLAIM			= 33,
	KEY_QUOTE			= 34,
	KEY_HASH				= 35,
	KEY_CURRENCY		= 36,
	KEY_PERCENT			= 37,
	KEY_AMP				= 38,
	KEY_APOSTROPHE		= 39,
	KEY_OPENPAREN		= 40,
	KEY_CLOSEPAREN		= 41,
	KEY_MULTIPLY		= 42,
	KEY_ADD				= 43,
	KEY_COMMA			= 44,
	KEY_SUBTRACT		= 45,
	KEY_DOT				= 46,
	KEY_DIVIDE			= 47,
	KEY_0					= 48,
	KEY_1					= 49,
	KEY_2					= 50,
	KEY_3					= 51,
	KEY_4					= 52,
	KEY_5					= 53,
	KEY_6					= 54,
	KEY_7					= 55,
	KEY_8					= 56,
	KEY_9					= 57,
	KEY_COLON			= 58,
	KEY_SEMICOLON		= 59,
	KEY_LESS				= 60,
	KEY_EQUAL			= 61,
	KEY_GREATER			= 62,
	KEY_QUESTION		= 63,
	KEY_AT				= 64,
	KEY_A					= 65,
	KEY_B					= 66,
	KEY_C					= 67,
	KEY_D					= 68,
	KEY_E					= 69,
	KEY_F					= 70,
	KEY_G					= 71,
	KEY_H					= 72,
	KEY_I					= 73,
	KEY_J					= 74,
	KEY_K					= 75,
	KEY_L					= 76,
	KEY_M					= 77,
	KEY_N					= 78,
	KEY_O					= 79,
	KEY_P					= 80,
	KEY_Q					= 81,
	KEY_R					= 82,
	KEY_S					= 83,
	KEY_T					= 84,
	KEY_U					= 85,
	KEY_V					= 86,
	KEY_W					= 87,
	KEY_X					= 88,
	KEY_Y					= 89,
	KEY_Z					= 90,
	KEY_OPENSQUARE		= 91,
	KEY_SLASH			= 92,
	KEY_CLOSESQUARE	= 93,
	KEY_CARET			= 94,
	KEY_UNDERSCORE		= 95,
	KEY_TICK				= 96,
	KEY_OPENBRACE		= 123,
	KEY_BAR				= 124,
	KEY_CLOSEBRACE		= 125,
	KEY_TILDE			= 126,
	KEY_DELETE			= 127,
	KEY_INSERT			= 128,
	KEY_HOME				= 129,
	KEY_END				= 130,
	KEY_PAGEUP			= 131,
	KEY_PAGEDOWN		= 132,
	KEY_SHIFT			= 133,
	KEY_CAPS				= 134,
	KEY_CTRL				= 135,
	KEY_ALT				= 136,
	KEY_UP				= 137,
	KEY_DOWN				= 138,
	KEY_LEFT				= 139,
	KEY_RIGHT			= 140,
	KEY_F1				= 141,
	KEY_F2				= 142,
	KEY_F3				= 143,
	KEY_F4				= 144,
	KEY_F5				= 145,
	KEY_F6				= 146,
	KEY_F7				= 147,
	KEY_F8				= 148,
	KEY_F9				= 149,
	KEY_F10				= 150,
	KEY_F11				= 151,
	KEY_F12				= 152
}



lwcomp.shift_keys =
{
	KEY_TICK				= lwcomp.keys.KEY_TILDE,
	KEY_0					= lwcomp.keys.KEY_CLOSEPAREN,
	KEY_1					= lwcomp.keys.KEY_EXCLAIM,
	KEY_2					= lwcomp.keys.KEY_AT,
	KEY_3					= lwcomp.keys.KEY_HASH,
	KEY_4					= lwcomp.keys.KEY_CURRENCY,
	KEY_5					= lwcomp.keys.KEY_PERCENT,
	KEY_6					= lwcomp.keys.KEY_CARET,
	KEY_7					= lwcomp.keys.KEY_AMP,
	KEY_8					= lwcomp.keys.KEY_MULTIPLY,
	KEY_9					= lwcomp.keys.KEY_OPENPAREN,
	KEY_SUBTRACT		= lwcomp.keys.KEY_UNDERSCORE,
	KEY_EQUAL			= lwcomp.keys.KEY_ADD,
	KEY_OPENSQUARE		= lwcomp.keys.KEY_OPENBRACE,
	KEY_SLASH			= lwcomp.keys.KEY_BAR,
	KEY_CLOSESQUARE	= lwcomp.keys.KEY_CLOSEBRACE,
	KEY_SEMICOLON		= lwcomp.keys.KEY_COLON,
	KEY_APOSTROPHE		= lwcomp.keys.KEY_QUOTE,
	KEY_COMMA			= lwcomp.keys.KEY_LESS,
	KEY_DOT				= lwcomp.keys.KEY_GREATER,
	KEY_DIVIDE			= lwcomp.keys.KEY_QUESTION
}



function lwcomp.http_fetch (request, computer)
	if http_api and computer.id then
		if not request then
			return nil, "no request"
		end

		if type (request.url) ~= "string" then
			return nil, "no url"
		end

		if request.url:len () < 1 then
			return nil, "no url"
		end

		-- check white list
		local found = false
		for l = 1, #lwcomp.settings.http_white_list do
			if string.match (request.url, lwcomp.settings.http_white_list[l]) then
				found = true
			end
		end

		if not found then
			return nil, "denied"
		end

		if request.timeout then
			if request.timeout > 30 then
				request.timeout = 30
			end
		end

		computer.timed_out = false
		http_api.fetch (request, computer.http_callback)
		computer.resumed_at = minetest.get_us_time ()

		local result, msg = coroutine.yield ("http_fetch")

		if result then
			return computer.http_result
		end

		return nil, msg
	end

	return nil, "no http"
end



lwcomp.place_substitute = dofile (lwcomp.modpath.."/place_substitute.lua")
lwcomp.crafting_mods = dofile (lwcomp.modpath.."/crafting_mods.lua")



function lwcomp.get_place_substitute (item)
	local subst = lwcomp.place_substitute[item]

	if subst then
		return subst
	end

	return item
end



function lwcomp.get_crafting_mods (item)
	return lwcomp.crafting_mods[item]
end



function lwcomp.get_computer_data (id, pos)
	local name = tostring (id)
	local data = lwcomp.computer_data[name]

	if not data then
		if pos then
			local meta = minetest.get_meta (pos)
			data = lwcomp.new_computer (pos,
												 id,
												 meta:get_int ("persists") == 1,
												 meta:get_int ("robot") == 1)

			lwcomp.computer_data[name] = data

			lwcomp.computer_list[name] =
			{
				pos = { x = pos.x, y = pos.y, z = pos.z },
			}

			lwcomp.store_computer_list ()
		end
	elseif pos then
		data.pos = pos
	end

	return data
end



function lwcomp.reset_computer_data (id, pos)
	local name = tostring (id)
	local meta = minetest.get_meta (pos)
	local data = lwcomp.new_computer (pos,
												 id,
												 meta:get_int ("persists") == 1,
												 meta:get_int ("robot") == 1)

	lwcomp.computer_data[name] = data

	lwcomp.computer_list[name] =
	{
		pos = { x = pos.x, y = pos.y, z = pos.z },
	}

	lwcomp.store_computer_list ()

	return data
end



function lwcomp.remove_computer_data (id)
	local name = tostring (id)

	lwcomp.computer_data[name] = nil
	lwcomp.computer_list[name] = nil
	lwcomp.store_computer_list ()
end



function lwcomp.send_message (sender_id, msg, target_id)
	target_id = tonumber (target_id or 0)
	msg = tostring (msg or "")

	if target_id > 0 then
		local target = tostring (target_id)
		local stats = lwcomp.computer_list[target]

		if stats then
			local meta = minetest.get_meta (stats.pos)

			if meta then
				local id = meta:get_int ("lwcomputer_id")

				if id == 0 or id ~= target_id then
					-- no longer there
					lwcomp.remove_computer_data (target_id)

				elseif target_id ~= sender_id then
					local data = lwcomp.get_computer_data (target_id, stats.pos)

					if data then
						data.queue_event ("wireless", msg, sender_id, target_id)

						return true
					end

				end
			end
			-- else out of range or doesn't exist
		end

	else
		-- broadcast
		local remove_list = { }

		for target, stats in pairs (lwcomp.computer_list) do
			local meta = minetest.get_meta (stats.pos)

			if meta then
				local id = meta:get_int ("lwcomputer_id")
				target_id = tonumber (target)

				if id == 0 or id ~= target_id then
					-- no longer there
					remove_list[#remove_list + 1] = target_id

				else

					if target_id ~= sender_id then
						local data = lwcomp.get_computer_data (target_id, stats.pos)

						if data then
							data.queue_event ("wireless", msg, sender_id, nil)
						end
					end
				end
			-- else out of range or doesn't exist
			end
		end

		-- remove redundant machines
		for c = 1, #remove_list do
			lwcomp.remove_computer_data (remove_list[c])
		end

		return true
	end

	return false
end



function lwcomp.name_from_id (id)
	id = tonumber (id or 0)
	local name = nil

	if id > 0 then
		local stats = lwcomp.computer_list[tostring (id)]

		if stats then
			local meta = minetest.get_meta (stats.pos)

			if meta then
				if meta:get_int ("lwcomputer_id") == id then
					name = meta:get_string ("name")
				else
					-- no longer there
					lwcomp.remove_computer_data (id)
				end
			end
		end
	end

	return name
end



function lwcomp.id_from_name (name)
	name = tostring (name or "")
	local id = nil
	local remove_list = { }

	for target, stats in pairs (lwcomp.computer_list) do
		local meta = minetest.get_meta (stats.pos)

		if meta then
			local target_id = tonumber (target)
			local test_id = meta:get_int ("lwcomputer_id")

			if test_id == 0 or test_id ~= target_id then
				-- no longer there
				remove_list[#remove_list + 1] = target_id

			else
				if name == meta:get_string ("name") then
					id = target_id
				end
			end
		-- else out of range or doesn't exist
		end
	end

	-- remove redundant machines
	for c = 1, #remove_list do
		lwcomp.remove_computer_data (remove_list[c])
	end

	return id
end



function lwcomp.get_worldtime ()
	return ((minetest.get_timeofday () + minetest.get_day_count ()) * 86400) + lwcomp.settings.epoch_offset
end



function lwcomp.to_worldtime (secs)
	if lwcomp.settings.time_scale > 0 then
		return secs * lwcomp.settings.time_scale
	end

	return secs
end



function lwcomp.to_realtime (secs)
	if lwcomp.settings.time_scale > 0 then
		return secs / lwcomp.settings.time_scale
	end

	return secs
end



lwcomp.floppy_disk = { }



function lwcomp.is_floppy_disk (item)
	return lwcomp.floppy_disk[item]
end



lwcomp.clipboards = { }



function lwcomp.is_clipboard (item)
	return lwcomp.clipboards[item]
end



function lwcomp.can_interact_with_node (pos, player)
	if not player or not player:is_player () then
		return false
	end

	if minetest.check_player_privs (player, "protection_bypass") then
		return true
	end

	local meta = minetest.get_meta (pos)
	if meta then
		local owner = meta:get_string ("owner")
		local name = player:get_player_name ()

		if not owner or owner == "" or owner == name then
			return true
		end

		local access = meta:get_string ("access_by")

		if access:len () > 0 then
			local list = minetest.deserialize (access)

			if list[name] then
				return true
			end
		end
	end

	return false
end



--
