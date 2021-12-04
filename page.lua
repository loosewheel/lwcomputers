local lwcomp = ...
local S = lwcomp.S



local width = 40
local height = 30
local hscale = 0.30
local vscale = hscale * 1.5



function lwcomp.page_size ()
	return width, height
end



function lwcomp.page_scale ()
	return hscale, vscale
end



function lwcomp.page_decode (rawstring)
	local chars = width * height
	local content = { }

	rawstring = lwcomp.from_hex (rawstring)

	for i = 1, chars do
		if i <= rawstring:len () then
			local byte = ((i - 1) * 2) + 1

			content[i] =
			{
				fg = (math.modf ((rawstring:byte (byte) / 16) % 16)),
				bg = rawstring:byte (byte) % 16,
				char = rawstring:byte (byte + 1)
			}
		else
			content[i] =
			{
				fg = lwcomp.colors.black,
				bg = lwcomp.colors.white,
				char = 0
			}
		end
	end

	return content
end



function lwcomp.page_encode (page)
	local chars = width * height
	local raw = ""
	local blank = string.char ((lwcomp.colors.black * 16) + lwcomp.colors.white, 0)

	if not page then
		return string.rep (blank, chars)
	end

	for i = 1, chars do
		if i <= #page then
			raw = raw..string.char ((page[i].fg * 16) + page[i].bg, page[i].char)
		else
			raw = raw..blank
		end
	end

	return lwcomp.to_hex (raw)
end



local function get_page_formspec (raw)
	local page = lwcomp.page_decode (raw)

	local spec = string.format ("formspec_version[3]\n"..
										 "size[%f,%f;true]\n"..
										 "no_prepend[]\n"..
										 "bgcolor[#DCDCDC]\n"..
										 "container[0.1,0.1]\n",
										 (width * hscale) + 0.2, (height * vscale) + 0.2)

	for y = 0, height - 1 do
		for x = 0, width - 1 do
			local c = page[(y * width) + x + 1]

			spec = spec..
			string.format ("animated_image[%f,%f;%f,%f;d;%02d%02d.png;256;0;%d]\n",
								(x * hscale), (y * vscale),
								(hscale + 0.03), (vscale + 0.03),
								c.fg, c.bg, ((c.char % 256) + 1))
		end
	end

	spec = spec..
	"container_end[]\n"

	return spec
end



minetest.register_craftitem ("lwcomputers:page", {
   description = S("LWComputers Page"),
   short_description = S("LWComputers Page"),
   inventory_image = "lwcomputers_page.png",
   stack_max = 1,
   groups = { not_in_creative_inventory = 1 },

   on_use = function (itemstack, user, pointed_thing)
		if itemstack and user and user:is_player () then
			local meta = itemstack:get_meta()
			local contents = meta:get_string ("contents")


			minetest.show_formspec (user:get_player_name (),
											"lwcomputers:page",
											get_page_formspec (meta:get_string ("contents")))
		end

      return nil
   end,
})



--
