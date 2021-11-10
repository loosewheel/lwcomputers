local lwcomp = ...



function lwcomputers.key_code (key)
	return lwcomp.keys[key]
end



function lwcomputers.color (color)
	return lwcomp.colors[color]
end



function lwcomputers.register_place_substitute (item, substitute)
	if type (item) == "string" and (type (substitute) == "string" or
			(type (substitute) == "table" and type (substitute[1]) == "string")) then
		if not lwcomp.place_substitute[item] then
			lwcomp.place_substitute[item] = substitute

			return true
		end
	end

	return false
end



function lwcomputers.register_crafting_mods (item, adds, removes)
	local add = nil
	local rem = nil

	if type (item) == "string" and not lwcomp.crafting_mods[item] then
		if type (adds) == "string" then
			add = { adds }
		elseif type (adds) == "table" then
			add = adds
		end

		if type (removes) == "string" then
			rem = { removes }
		elseif type (removes) == "table" then
			rem = removes
		end

		if add or rem then
			local m = { }

			if add then
				m.add = add
			end

			if rem then
				m.remove = rem
			end

			lwcomp.crafting_mods[item] = m

			return true
		end
	end

	return false
end



local function floppy_disk_on_drop (itemstack, dropper, pos)
	-- one or more string fields
	local drops = lwdrops.store (itemstack, "disk_data")

	if drops then
		return minetest.item_drop (drops, dropper, pos)
	end

	return itemstack
end



local function floppy_disk_on_pickup (itemstack, fields)
	local meta = itemstack:get_meta ()

	if meta then
		for k, v in pairs (fields) do
			meta:set_string (k, v)
		end
	end

	-- this itemstack is the one picked up
	return itemstack
end



local function floppy_disk_on_destroy (itemstack)
	local meta = itemstack:get_meta ()

	if meta then
		local id = meta:get_int ("lwcomputer_id")

		if id > 0 then
			lwcomp.filesys:delete_floppy (id)
		end
	end
end



function lwcomputers.register_floppy_disk (name, label, itemdef)
	if type (name) ~= "string" then
		return false
	end

	if lwcomp.floppy_disk[name] then
		return false
	end

	lwcomp.floppy_disk[name] =
	{
		label = tostring (label or "")
	}

	if type (itemdef.diskfiles) == "table" then
		lwcomp.floppy_disk[name].files = { }
		local f = lwcomp.floppy_disk[name].files

		for i = 1, #itemdef.diskfiles do
			if type (itemdef.diskfiles[i]) == "table" then
				if type (itemdef.diskfiles[i].source) == "string" and
					type (itemdef.diskfiles[i].target) == "string" then

					f[#f + 1] =
					{
						source = itemdef.diskfiles[i].source,
						target = itemdef.diskfiles[i].target
					}
				end
			end
		end

		itemdef.diskfiles = nil
	end

	itemdef.on_drop = floppy_disk_on_drop
	itemdef.on_pickup = floppy_disk_on_pickup
	itemdef.on_destroy = floppy_disk_on_destroy
	itemdef.stack_max = 1

	minetest.register_craftitem (name, itemdef)

	return true
end



local function clipboard_on_drop (itemstack, dropper, pos)
	-- one or more string fields
	local drops = lwdrops.store (itemstack, "contents")

	if drops then
		return minetest.item_drop (drops, dropper, pos)
	end

	return itemstack
end



local function clipboard_on_pickup (itemstack, fields)
	local meta = itemstack:get_meta ()

	if meta then
		for k, v in pairs (fields) do
			meta:set_string (k, v)
		end
	end

	-- this itemstack is the one picked up
	return itemstack
end



function lwcomputers.register_clipboard (name, size, itemdef)
	size = tonumber (size or 0) or 0

	if type (name) ~= "string" then
		return false
	end

	if lwcomp.clipboards[name] then
		return false
	end

	if size < 1 or size > lwcomp.settings.max_clipboard_length then
		size = lwcomp.settings.max_clipboard_length
	end

	lwcomp.clipboards[name] =
	{
		contents = "contents",
		size = size
	}

	itemdef.on_drop = clipboard_on_drop
	itemdef.on_pickup = clipboard_on_pickup
	itemdef.stack_max = 1

	minetest.register_craftitem (name, itemdef)

	return true
end



--
