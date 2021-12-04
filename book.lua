local lwcomp = ...
local S = lwcomp.S



function lwcomp.book_decode (rawstring)
	local width, height = lwcomp.page_size ()
	local chars = width * height
	local pages = rawstring:len () / (chars * 4)
	local contents = { }

	for i = 1, pages do
		local firstbyte = ((i - 1) * (chars * 4)) + 1
		local lastbyte = i * (chars * 4)
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
	local pages = meta:get_int ("pages")
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

	local page_label = string.format ("%d / %d", curpage, pages)

	spec = string.format ("%scontainer_end[]\n"..
								 "button[0.2,%0.2f;1.0,0.8;first;<<]\n"..
								 "button[1.2,%0.2f;1.0,0.8;prior;<]\n"..
								 "label[%0.2f,%0.2f;%s]\n"..
								 "button[%0.2f,%0.2f;1.0,0.8;next;>]\n"..
								 "button[%0.2f,%0.2f;1.0,0.8;last;>>]\n",
								 spec,
								 fh - 1.0,
								 fh - 1.0,
								 (fw / 2) - (page_label:len () * 0.05), fh - 0.6, page_label,
								 fw - 2.2, fh - 1.0,
								 fw - 1.2, fh - 1.0)

	return spec
end



minetest.register_craftitem ("lwcomputers:book", {
   description = S("LWComputers Book"),
   short_description = S("LWComputers Book"),
   inventory_image = "lwcomputers_book.png",
   stack_max = 99,
   groups = { not_in_creative_inventory = 1 },

   on_use = function (itemstack, user, pointed_thing)
		if itemstack and user and user:is_player () then
			local meta = itemstack:get_meta()

			if meta then
				minetest.show_formspec (user:get_player_name (),
												"lwcomputers:book",
												get_book_formspec (meta))
			end
		end

      return nil
   end,
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

							if fields.first then
								local page = meta:get_int ("page")

								if page > 1 then
									meta:set_int ("page", 1)
									player:set_wielded_item (stack)

									minetest.show_formspec (player:get_player_name (),
																	"lwcomputers:book",
																	get_book_formspec (meta))
								end
							end

							if fields.prior then
								local page = meta:get_int ("page")

								if page > 1 then
									page = page - 1
									meta:set_int ("page", page)
									player:set_wielded_item (stack)

									minetest.show_formspec (player:get_player_name (),
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

									minetest.show_formspec (player:get_player_name (),
																	"lwcomputers:book",
																	get_book_formspec (meta))
								end
							end

							if fields.last then
								local page = meta:get_int ("page")
								local pages = meta:get_int ("pages")

								if page < pages then
									meta:set_int ("page", pages)
									player:set_wielded_item (stack)

									minetest.show_formspec (player:get_player_name (),
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
