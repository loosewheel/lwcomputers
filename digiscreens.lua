local lwcomp = ...
local S = lwcomp.S



if lwcomp.digilines_supported then


-- this code is based on cheapie's digiscreen mod


local function removeEntity (pos)
	local entitiesNearby = minetest.get_objects_inside_radius (pos, 0.5)
	for _,i in pairs (entitiesNearby) do
		if i:get_luaentity () and i:get_luaentity ().name == "lwcomputers:digiscreenimage" then
			i:remove ()
		end
	end
end



local function generateTexture (pos, serdata, resolution)
	--The data *should* always be valid, but it pays to double-check anyway
	-- due to how easily this could crash if something did go wrong
	if type (serdata) ~= "string" then
		minetest.log ("error",
						  "[lwcomputers:digiscreen] Serialized display data appears to be missing at "..
						  minetest.pos_to_string (pos, 0))

		return
	end

	local data = minetest.deserialize (serdata)
	if type (data) ~= "table" then
		minetest.log ("error", "[lwcomputers:digiscreen] Failed to deserialize display data at "..
									  minetest.pos_to_string (pos, 0))

		return
	end

	for y = 1, resolution, 1 do
		if type (data[y]) ~= "table" then
			minetest.log ("error", "[lwcomputers:digiscreen] Invalid row "..y..
										  " at "..minetest.pos_to_string (pos, 0))

			return
		end
	end

	local ret = string.format ("[combine:%dx%d", resolution, resolution)
	for y = 1, resolution, 1 do
		for x = 1, resolution, 16 do
			ret = ret..
					string.format (":%d,%d=(lwdspx.png\\^[colorize\\:#%06X\\:255)"..
										":%d,%d=(lwdspx.png\\^[colorize\\:#%06X\\:255)"..
										":%d,%d=(lwdspx.png\\^[colorize\\:#%06X\\:255)"..
										":%d,%d=(lwdspx.png\\^[colorize\\:#%06X\\:255)"..
										":%d,%d=(lwdspx.png\\^[colorize\\:#%06X\\:255)"..
										":%d,%d=(lwdspx.png\\^[colorize\\:#%06X\\:255)"..
										":%d,%d=(lwdspx.png\\^[colorize\\:#%06X\\:255)"..
										":%d,%d=(lwdspx.png\\^[colorize\\:#%06X\\:255)"..
										":%d,%d=(lwdspx.png\\^[colorize\\:#%06X\\:255)"..
										":%d,%d=(lwdspx.png\\^[colorize\\:#%06X\\:255)"..
										":%d,%d=(lwdspx.png\\^[colorize\\:#%06X\\:255)"..
										":%d,%d=(lwdspx.png\\^[colorize\\:#%06X\\:255)"..
										":%d,%d=(lwdspx.png\\^[colorize\\:#%06X\\:255)"..
										":%d,%d=(lwdspx.png\\^[colorize\\:#%06X\\:255)"..
										":%d,%d=(lwdspx.png\\^[colorize\\:#%06X\\:255)"..
										":%d,%d=(lwdspx.png\\^[colorize\\:#%06X\\:255)",
										x - 1, y - 1, tonumber (data[y][x], 16) or 0,
										x, y - 1, tonumber (data[y][x + 1], 16) or 0,
										x + 1, y - 1, tonumber (data[y][x + 2], 16) or 0,
										x + 2, y - 1, tonumber (data[y][x + 3], 16) or 0,
										x + 3, y - 1, tonumber (data[y][x + 4], 16) or 0,
										x + 4, y - 1, tonumber (data[y][x + 5], 16) or 0,
										x + 5, y - 1, tonumber (data[y][x + 6], 16) or 0,
										x + 6, y - 1, tonumber (data[y][x + 7], 16) or 0,
										x + 7, y - 1, tonumber (data[y][x + 8], 16) or 0,
										x + 8, y - 1, tonumber (data[y][x + 9], 16) or 0,
										x + 9, y - 1, tonumber (data[y][x + 10], 16) or 0,
										x + 10, y - 1, tonumber (data[y][x + 11], 16) or 0,
										x + 11, y - 1, tonumber (data[y][x + 12], 16) or 0,
										x + 12, y - 1, tonumber (data[y][x + 13], 16) or 0,
										x + 13, y - 1, tonumber (data[y][x + 14], 16) or 0,
										x + 14, y - 1, tonumber (data[y][x + 15], 16) or 0)
		end
	end
	return ret
end



local function updateDisplay (pos)
	removeEntity (pos)
	local node = minetest.get_node (pos)
	local def = minetest.registered_nodes[node.name]
	local meta = minetest.get_meta (pos)
	local data = meta:get_string ("data")
	local entity = minetest.add_entity (pos, "lwcomputers:digiscreenimage")
	local fdir = minetest.facedir_to_dir (minetest.get_node (pos).param2)
	local etex = "lwdspx.png"
	etex = generateTexture (pos, data, def._resolution) or etex
	entity:set_properties ({ textures = { etex } })
	entity:set_yaw ((fdir.x ~= 0) and math.pi / 2 or 0)
	entity:set_pos (vector.add (pos, vector.multiply (fdir, def._display_offset)))
end



minetest.register_entity ("lwcomputers:digiscreenimage", {
	initial_properties = {
		visual = "upright_sprite",
		physical = false,
		collisionbox = { 0, 0, 0, 0, 0, 0, },
		textures = { "lwdspx.png", },
	},
})



local function registerNode (name, description, box, resolution, display_offset)
	minetest.register_node (name, {
		description = description,
		tiles = { "lwcomputers_digiscreen_bg.png", },
		groups = { cracky = 2, oddly_breakable_by_hand = 2 },
		paramtype = "light",
		paramtype2 = "facedir",
		on_rotate = minetest.global_exists ("screwdriver") and screwdriver.rotate_simple,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = box,
		},
		_digistuff_channelcopier_fieldname = "channel",
		light_source = 10,
		_resolution = resolution,
		_display_offset = display_offset,

		on_construct = function (pos)
			local meta = minetest.get_meta (pos)
			meta:set_string ("formspec", "field[channel;Channel;${channel}]")

			local disp = { }
			for y = 1, resolution, 1 do
				disp[y] = { }

				for x = 1, resolution, 1 do
					disp[y][x] = "000000"
				end
			end

			meta:set_string ("data", minetest.serialize (disp))
			updateDisplay (pos)
		end,

		on_destruct = removeEntity,

		on_receive_fields = function (pos, _, fields, sender)
			local player_name = sender:get_player_name ()

			if not fields.channel then
				return
			end

			if minetest.is_protected (pos, player_name) and
				not minetest.check_player_privs (player_name, "protection_bypass") then

				minetest.record_protection_violation (pos, player_name)

				return
			end

			local meta = minetest.get_meta (pos)
			meta:set_string ("channel", fields.channel)
		end,

		digiline = {
			wire = {
				rules = digiline.rules.default,
			},

			effector = {
				action = function (pos, _, channel, msg)
					local meta = minetest.get_meta (pos)
					local setchan = meta:get_string ("channel")

					if type(msg) ~= "table" or setchan ~= channel then
						return
					end

					local data = { }
					for y = 1, resolution, 1 do
						data[y] = { }

						if type(msg[y]) ~= "table" then
							msg[y] = { }
						end

						for x = 1, resolution, 1 do
							if type (msg[y][x]) ~= "string" then
								msg[y][x] = string.format ("%06X", tonumber (msg[y][x] or 0) or 0)
							else
								if string.sub (msg[y][x], 1, 1) == "#" then
									msg[y][x] = string.sub (msg[y][x], 2, -1)
								end

								msg[y][x] = string.format ("%06X", tonumber (msg[y][x], 16) or 0)
							end

							data[y][x] = msg[y][x]
						end
					end

					meta:set_string ("data", minetest.serialize (data))
					updateDisplay (pos)
				end,
			},
		},
	})
end



registerNode (
	"lwcomputers:digipanel32",
	S("Digilines Graphical Panel 32"),
	{ -0.5, -0.5, 0.4, 0.5, 0.5, 0.5 },
	32,
	0.39
)


registerNode (
	"lwcomputers:digiscreen32",
	S("Digilines Graphical Display 32"),
	{ -0.5, -0.5, -0.49, 0.5, 0.5, 0.5 },
	32,
	-0.5
)


registerNode (
	"lwcomputers:digipanel16",
	S("Digilines Graphical Panel 16"),
	{ -0.5, -0.5, 0.4, 0.5, 0.5, 0.5 },
	16,
	0.39
)


registerNode (
	"lwcomputers:digiscreen16",
	S("Digilines Graphical Display 16"),
	{ -0.5, -0.5, -0.49, 0.5, 0.5, 0.5 },
	16,
	-0.5
)



minetest.register_lbm ({
	name = "lwcomputers:digiscreenrespawn",
	label = "Respawn lwdigiscreen entities",
	nodenames = {
		"lwcomputers:digipanel32",
		"lwcomputers:digiscreen32",
		"lwcomputers:digipanel16",
		"lwcomputers:digiscreen16"
	},
	run_at_every_load = true,
	action = updateDisplay,
})



end
