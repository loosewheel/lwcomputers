local lwcomp = ...
local S = lwcomp.S



function lwcomp.book_decode (rawstring)
	local width, height = lwcomp.page_size ()
	local chars = width * height
	local pages = rawstring:len () / (chars * 2)
	local contents = { }

	for i = 1, pages do
		local firstbyte = ((i - 1) * (chars * 2)) + 1
		local lastbyte = i * (chars * 2)
		local raw = rawstring:sub (firstbyte, lastbyte)
		contents[i] = lwcomp.page_decode (raw)
	end

	return contents
end



function lwcomp.book_encode (contents)
	local raw = ""

	for i = 1, #contents do
		raw = raw..lwcomp.page_encode (contents[i])
	end

	return raw
end



local function get_book_formspec (meta)
	local contents = lwcomp.book_decode (meta:get_string ("contents"))
	local curpage = meta:get_int ("page")
	local width, height = lwcomp.page_size ()
	local hscale, vscale = lwcomp.page_scale ()
	local fw = (width * hscale) + 0.2
	local fh = (height * vscale) + 1.3

	if contents and #contents > 0 then
		if curpage < 1 then
			curpage = 1
		end

		if curpage > #contents then
			curpage = #contents
		end
	else
		curpage = 0
	end

	meta:set_int ("page", curpage)

	local spec = string.format ("formspec_version[3]\n"..
										 "size[%f,%f;true]\n"..
										 "no_prepend[]\n"..
										 "bgcolor[#753C1D]\n"..
										 "container[0.1,0.1]\n",
										 fw, fh)
	if curpage > 0 then
		for y = 0, height - 1 do
			for x = 0, width - 1 do
				local c = contents[curpage][(y * width) + x + 1]

				spec = spec..
				string.format ("animated_image[%f,%f;%f,%f;d;%02d%02d.png;256;0;%d]\n",
									(x * hscale), (y * vscale),
									(hscale + 0.03), (vscale + 0.03),
									c.fg, c.bg, ((c.char % 256) + 1))
			end
		end
	end

	spec = spec..
	"container_end[]\n"..
	"button[0.2,"..tostring (fh - 1.0)..";1.0,0.8;prior;<]\n"..
	"label["..tostring ((fw / 2) - 0.3)..","..tostring (fh - 0.6)..";"..tostring (curpage).."]\n"..
	"button["..tostring (fw - 1.2)..","..tostring (fh - 1.0)..";1.0,0.8;next;>]\n"

	return spec
end



minetest.register_craftitem("lwcomputers:book", {
   description = S("LWComputers Book"),
   short_description = S("LWComputers Book"),
   inventory_image = "book.png",
   stack_max = 99,
   groups = { not_in_creative_inventory = 1 },

   on_use = function (itemstack, user, pointed_thing)
		if itemstack and user and user:is_player () then
			local meta = itemstack:get_meta()

			if meta then
				minetest.show_formspec(user:get_player_name(),
											  "lwcomputers:book",
											  get_book_formspec (meta))
			end
		end

      return nil
   end,

	on_drop = function (itemstack, dropper, pos)
		-- one or more string fields
		local drops = lwdrops.store (itemstack, "contents")

		if drops then
			return minetest.item_drop (drops, dropper, pos)
		end

		return itemstack
	end,

	on_pickup = function (itemstack, fields)
		local meta = itemstack:get_meta ()

		if meta then
			for k, v in pairs (fields) do
				meta:set_string (k, v)
			end
		end

		-- this itemstack is the one picked up
		return itemstack
	end
})



minetest.register_on_player_receive_fields(function (player, formname, fields)
   if formname == "lwcomputers:book" then
		if player then
			if player:is_player () then
				local stack = player:get_wielded_item ()

				if stack then
					if stack:get_name() == "lwcomputers:book" then
						local meta = stack:get_meta ()

						if meta then

							if fields.prior then
								local page = meta:get_int ("page")

								if page > 1 then
									page = page - 1
									meta:set_int ("page", page)
									player:set_wielded_item (stack)

									minetest.show_formspec(player:get_player_name(),
																  "lwcomputers:book",
																  get_book_formspec (meta))
								end
							end

							if fields.next then
								local page = meta:get_int ("page")
								local pages = meta:get_int ("pages")

								if page < pages then
									page = page + 1
									meta:set_int ("page", page)
									player:set_wielded_item (stack)

									minetest.show_formspec(player:get_player_name(),
																  "lwcomputers:book",
																  get_book_formspec (meta))
								end
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
