local lwcomp = ...
local S = lwcomp.S



if lwcomp.digilines_supported then



local MAX_PAGES_PER_BOOK = 12



local function get_formspec ()
	local spec =
	"formspec_version[3]"..
	"size[11.75,12.75;true]"..
	"no_prepend[]"..
	"bgcolor[#E7DAA8]"..
	"field[1.0,1.0;4.0,0.8;channel;Channel;${channel}]"..
	"button[5.5,1.0;2.0,0.8;setchannel;Set]"..
	"item_image[1.0,2.5;1.0,1.0;lwcomputers:ink_cartridge]"..
	"list[context;ink;2.25,2.5;1,1;]"..
	"item_image[3.5,2.5;1.0,1.0;default:paper]"..
	"list[context;paper;4.75,2.5;1,1;]"..
	"item_image_button[8.5,2.5;1.0,1.0;lwcomputers:book;book;]"..
	"tooltip[book;Make Book;#094109;#FFFFFF]"..
	"list[context;book;9.75,2.5;1,1;]"..
	"list[context;main;2.25,3.75;6,2;]"..
	"list[current_player;main;1.0,7.0;8,4;]"..
	"listring[]"..
	"listcolors[#545454;#6E6E6E;#DBCF9F]"

	return spec
end



local function get_new_page ()
	local width, height = lwcomp.page_size ()
	local page = { }

	for y = 0, height - 1 do
		for x = 0, width - 1 do
			page[(y * width) + x + 1] =
			{
				fg = lwcomp.colors.black,
				bg = lwcomp.colors.white,
				char = 0
			}
		end
	end

	return page
end



local function on_receive_fields (pos, formname, fields, sender)
	if fields.setchannel then
		local meta = minetest.get_meta (pos)

		if meta then
			meta:set_string ("channel", fields.channel)
			meta:set_string ("infotext", fields.channel)
		end
	end

	if fields.book then
		local meta = minetest.get_meta (pos)

		if meta then
			local inv = meta:get_inventory ()

			if inv and inv:is_empty ("book") then
				local slots = inv:get_size ("main")
				local pages = 0
				local contents = ""
				local description = nil
				local used = { }

				for i = 1, slots do
					local page = inv:get_stack ("main", i)

					if page and page:get_name () == "lwcomputers:page" then
						local imeta = page:get_meta ()

						if imeta then
							local content = imeta:get_string ("contents")

							if content:len () > 0 then
								contents = contents..content
								pages = pages + 1
								used[#used + 1] = i

								if not description then
									description = imeta:get_string ("description")

									if description:len () < 1 then
										description = S("Book")
									end
								end

								if pages == MAX_PAGES_PER_BOOK then
									break
								end
							end
						end
					end
				end

				if pages > 0 then
					local book = ItemStack ("lwcomputers:book")

					if book then
						local imeta = book:get_meta ()

						if imeta then
							imeta:set_int ("page", 1)
							imeta:set_int ("pages", pages)
							imeta:set_string ("contents", contents)
							imeta:set_string ("description", description)
							imeta:set_string ("title", description)

							for i = 1, #used do
								local page = inv:get_stack ("main", used[i])

								if page and page:get_name () == "lwcomputers:page" then
									page:clear ()
									inv:set_stack ("main", i, page)
								end
							end

							inv:set_stack ("book", 1, book)
						end
					end
				end
			end
		end
	end
end



local function preserve_metadata (pos, oldnode, oldmeta, drops)
	if #drops > 0 then
		if drops[1]:get_name () == "lwcomputers:printer" then
			local meta = minetest.get_meta (pos)
			local imeta = drops[1]:get_meta ()
			local channel = meta:get_string ("channel")
			local description = channel

			if description:len () < 1 then
				description = S("Printer")
			end

			imeta:set_string ("channel", channel)
			imeta:set_string ("infotext", meta:get_string ("infotext"))
			imeta:set_string ("inventory", meta:get_string ("inventory"))
			imeta:set_string ("description", description)
		end
	end
end



local function after_place_node (pos, placer, itemstack, pointed_thing)
	local meta = minetest.get_meta (pos)
	local imeta = itemstack:get_meta ()
	local infotext = ""
	local channel = imeta:get_string ("channel")
	local inventory =
	"{ "..
	"main = { [1] = '', [2] = '', [3] = '', [4] = '', [5] = '', [6] = '', "..
	"         [7] = '', [8] = '', [9] = '', [10] = '', [11] = '', [12] = '' }, "..
	"ink = { [1] = '' }, "..
	"paper = { [1] = '' }, "..
	"book = { [1] = '' } }"

	if channel:len () > 0 then
		channel = imeta:get_string ("channel")
		infotext = imeta:get_string ("infotext")
		inventory = imeta:get_string ("inventory")
	end

	meta:set_string ("channel", channel)
	meta:set_string ("infotext", infotext)
	meta:set_string ("inventory", inventory)
	meta:set_int ("x", 0)
	meta:set_int ("y", 0)
	meta:set_int ("fg", lwcomp.colors.black)
	meta:set_int ("bg", lwcomp.colors.white)

	local inv = meta:get_inventory ()

	inv:set_size("main", 12)
	inv:set_width("main", 6)
	inv:set_size("ink", 1)
	inv:set_width("ink", 1)
	inv:set_size("paper", 1)
	inv:set_width("paper", 1)
	inv:set_size("book", 1)
	inv:set_width("book", 1)

	meta:set_string ("formspec", get_formspec ())

	-- orientate
	if placer then
		if placer:is_player () then
			local angle = placer:get_look_horizontal ()
			local node = minetest.get_node (pos)
			local param2 = 2

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

			if node.name ~= "ignore" then
				node.param2 = param2
			end
		end
	end

	-- If return true no item is taken from itemstack
	return false
end



local function can_dig (pos, player)
	local meta = minetest.get_meta (pos)

	if meta then
		local inv = meta:get_inventory ()

		if inv then
			return inv:is_empty ("main") and
					 inv:is_empty ("ink") and
					 inv:is_empty ("paper") and
					 inv:is_empty ("book")
		end
	end

	return true
end



local function allow_metadata_inventory_put (pos, listname, index, stack, player)
	if stack then
		if not stack:is_empty () then
			local itemname = stack:get_name ()

			if listname == "main" then
				if itemname == "lwcomputers:page" then
					return 1
				end
			elseif listname == "ink" then
				if itemname == "lwcomputers:ink_cartridge" then
					return 1
				end
			elseif listname == "paper" then
				if itemname == "default:paper" then
					return 200
				end
			elseif listname == "book" then
				return 0
			end
		end
	end

	return 0
end



local function get_ink (meta)
	local inv = meta:get_inventory ()

	if inv then
		local stack = inv:get_stack ("ink", 1)

		if stack and stack:get_name () == "lwcomputers:ink_cartridge" then
			return math.ceil ((65535 - stack:get_wear ()) / math.floor (65535 / 199))
		end
	end

	return 0
end



local function get_paper (meta)
	local inv = meta:get_inventory ()

	if inv then
		local stack = inv:get_stack ("paper", 1)

		if stack and stack:get_name () == "default:paper" then
			return stack:get_count ()
		end
	end

	return 0
end



local function get_pages (meta)
	local inv = meta:get_inventory ()

	if inv then
		local count = 0
		local slots = inv:get_size ("main")

		for i = 1, slots do
			local stack = inv:get_stack ("main", i)

			if stack and stack:get_name () == "lwcomputers:page" then
				count = count + 1
			end
		end

		return 12 - count
	end

	return 0
end



local function query_ink (pos, meta, channel)
	lwcomp.digilines_receptor_send (
		pos,
		digiline.rules.default,
		channel,
		tostring (get_ink (meta)))
end



local function query_paper (pos, meta, channel)
	lwcomp.digilines_receptor_send (
		pos,
		digiline.rules.default,
		channel,
		tostring (get_paper (meta)))
end



local function query_pages (pos, meta, channel)
	lwcomp.digilines_receptor_send (
		pos,
		digiline.rules.default,
		channel,
		tostring (get_pages (meta)))
end



local function query_size (pos, meta, channel)
	local width, height = lwcomp.page_size ()

	lwcomp.digilines_receptor_send (
		pos,
		digiline.rules.default,
		channel,
		string.format ("%d,%d", width, height))
end



local function query_status (pos, meta, channel)
	local status = "ready"

	if get_ink (meta) < 1 then
		status = "no ink"
	elseif get_paper (meta) < 1 then
		status = "no paper"
	elseif get_pages (meta) < 1 then
		status = "tray full"
	elseif meta:get_int ("has_page") == 1 then
		status = "printing"
	end

	lwcomp.digilines_receptor_send (
		pos,
		digiline.rules.default,
		channel,
		status)
end



local function start_page (pos, meta, title)
	if meta:get_int ("has_page") == 0 then
		local inv = meta:get_inventory ()

		if inv then
			local ink = inv:get_stack ("ink", 1)

			if ink and not ink:is_empty () then
				local stack = inv:get_stack ("paper", 1)

				if stack and stack:get_name () == "default:paper" then
					if stack:get_count () > 0 then
						stack:take_item (1)
						inv:set_stack ("paper", 1, stack)
						meta:set_int ("has_page", 1)
						meta:set_string ("contents", lwcomp.page_encode (get_new_page ()))
						meta:set_string ("title", title)
					end
				end
			end
		end
	end
end



local function end_page (pos, meta)
	if meta:get_int ("has_page") == 1 then
		local inv = meta:get_inventory ()

		if inv then
			local page = ItemStack ("lwcomputers:page 1")

			if page and inv:room_for_item ("main", page) then
				local imeta = page:get_meta ()

				if imeta then
					local title = meta:get_string ("title")

					if title:len () < 1 then
						title = "untitled"
					end

					imeta:set_string ("contents", meta:get_string ("contents"))
					imeta:set_string ("title", title)
					imeta:set_string ("description", title)
					inv:add_item ("main", page)

					local ink = inv:get_stack ("ink", 1)
					if ink then
						local wear = ink:get_wear ()
						local pagewear = math.floor (65535 / 199)

						if (wear + pagewear) >= 65535 then
							ink:clear ()
						else
							ink:set_wear (wear + pagewear)
						end

						inv:set_stack ("ink", 1, ink)
					end

					meta:set_int ("has_page", 0)
				end
			end
		end
	end
end



local function set_colors (pos, meta, colors)
	if meta:get_int ("has_page") == 1 then
		local cols = string.split (colors, ",")
		local fg = lwcomp.colors.black
		local bg = lwcomp.colors.white

		if #cols < 1 then
			cols[1] = fg
		end

		if #cols < 2 then
			cols[2] = lwcomp.colors.white
		end

		cols[1] = tonumber (cols[1] or fg) or fg
		cols[2] = tonumber (cols[2] or bg) or bg

		meta:set_int ("fg", cols[1])
		meta:set_int ("bg", cols[2])
	end
end



local function set_position (pos, meta, position)
	if meta:get_int ("has_page") == 1 then
		local cpos = string.split (position, ",")
		local fg = lwcomp.colors.black
		local bg = lwcomp.colors.white

		if #cpos < 1 then
			cpos[1] = 0
		end

		if #cpos < 2 then
			cpos[2] = 0
		end

		cpos[1] = tonumber (cpos[1] or 0) or 0
		cpos[2] = tonumber (cpos[2] or 0) or 0

		meta:set_int ("x", cpos[1])
		meta:set_int ("y", cpos[2])
	end
end



local function write_out (pos, meta, str)
	if meta:get_int ("has_page") == 1 then
		local width, height = lwcomp.page_size ()
		local x = meta:get_int ("x")
		local y = meta:get_int ("y")

		if y >= 0 and y < height then
			local fg = meta:get_int ("fg")
			local bg = meta:get_int ("bg")
			local page = lwcomp.page_decode (meta:get_string ("contents"))
			local c = 1

			while c <= str:len () and x < width do
				page[(y * width) + x + 1] =
				{
					fg = fg % 16,
					bg = bg % 16,
					char = str:byte (c)
				}

				x = x + 1
				c = c + 1
			end

			meta:set_int ("x", x)
			meta:set_string ("contents", lwcomp.page_encode (page))
		end
	end
end



local function process_input (pos, node, channel, msg)
	local meta = minetest.get_meta(pos)

	if meta then
		local mychannel = meta:get_string ("channel")

		if mychannel == channel then
			msg = tostring (msg or "")

			if msg == "ink" then
				query_ink (pos, meta, mychannel)

			elseif msg == "paper" then
				query_paper (pos, meta, mychannel)

			elseif msg == "pages" then
				query_pages (pos, meta, mychannel)

			elseif msg == "size" then
				query_size (pos, meta, mychannel)

			elseif msg == "status" then
				query_status (pos, meta, mychannel)

			elseif msg:sub (1, 5) == "start" then
				start_page (pos, meta, msg:sub (7))

			elseif msg == "end" then
				end_page (pos, meta)

			elseif msg:sub (1, 5) == "color" then
				set_colors (pos, meta, msg:sub (7))

			elseif msg:sub (1, 8) == "position" then
				set_position (pos, meta, msg:sub (10))

			elseif msg:sub (1, 5) == "write" then
				write_out (pos, meta, msg:sub (7))

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
				action = process_input,
			}
		}
	end

	return nil
end



minetest.register_node("lwcomputers:printer", {
   description = S("Printer"),
   tiles = { "lwcomputers_printer.png", "lwcomputers_printer.png", "lwcomputers_printer.png",
				 "lwcomputers_printer.png", "lwcomputers_printer.png", "lwcomputers_printer_face.png" },
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
	paramtype2 = "facedir",
	param2 = 1,
	digiline = digilines_support (),

	on_receive_fields = on_receive_fields,
	preserve_metadata = preserve_metadata,
	after_place_node = after_place_node,
	can_dig = can_dig,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
})



end
