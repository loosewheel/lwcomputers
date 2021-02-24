local lwcomp = ...
local S = lwcomp.S



-- helpers

local function load_file (path)
	local file = io.open (path, "r")

	if file then
		local contents = file:read ("*a")

		file:close ()

		return contents
	end

	return nil
end



local function tokenize_path (path)
	path = tostring (path or "")

	local ts = { }

	if path:sub (1, 1) == "/" then
		ts[1] = ""
	end

	for t in string.gmatch (path, "[^/]+") do
		ts[#ts + 1] = t
	end

	if path:len () > 1 and path:sub (-1) == "/" then
		ts[#ts + 1] = ""
	end

	return ts
end



local function resolve_path (path, slot, form, id)
	local tokens = tokenize_path (path)
	local complete = { }

	for i = 1, #tokens do
		if tokens[i] == ".." then
			if #complete < 1 then
				return nil, "invalid path"
			end

			table.remove (complete, #complete)
		else
			complete[#complete + 1] = tokens[i]
		end
	end

	local recon = table.concat (complete, "/")

	return recon, slot, form, id
end



------------------------- disk -------------------------



local diskobj = { }



-- constructor
function diskobj:new (pos, slot)
	slot = tonumber (slot or -1) or -1
	local obj = { }

   setmetatable(obj, self)
   self.__index = self

	obj.pos = pos
	obj.slot = slot

	local meta = minetest.get_meta (pos)

	if meta then
		if slot == 0 then
			local data = meta:get_string ("disk_data")

			if data:len () < 1 then
				data = minetest.serialize ({ })
				meta:set_string ("disk_data", data)
			end

			obj.data = minetest.deserialize (data)
			obj.form = "computer"
			obj.id = meta:get_int ("lwcomputer_id")

		else
			local inv = meta:get_inventory ()

			if inv then
				if slot >= 1 and slot <= inv:get_size ("main") then
					local stack = inv:get_stack ("main", slot)

					if stack and not stack:is_empty () and
						lwcomp.is_floppy_disk (stack:get_name ()) then

						local imeta = stack:get_meta ()

						if imeta then
							local id = imeta:get_int ("lwcomputer_id")

							if id > 0 then
								local data = imeta:get_string ("disk_data")

								if data:len () < 1 then
									data = minetest.serialize ({ })
									imeta:set_string ("disk_data", data)
								end

								obj.data = minetest.deserialize (data)
								obj.form = "floppy"
								obj.id = id
							end
						end
					end
				end
			end
		end
	end

	if not obj.data then
		return nil
	end

	return obj
end



function diskobj:save ()
	local meta = minetest.get_meta (self.pos)

	if meta then
		if self.slot == 0 then
			meta:set_string ("disk_data", minetest.serialize (self.data))

			return true
		end

		local inv = meta:get_inventory ()
		if inv then
			if self.slot >= 1 and self.slot <= inv:get_size ("main") then
				local stack = inv:get_stack ("main", self.slot)

				if stack and not stack:is_empty () and
					lwcomp.is_floppy_disk (stack:get_name ()) then

					local imeta = stack:get_meta ()

					if imeta then
						local id = imeta:get_int ("lwcomputer_id")

						if id > 0 then
							imeta:set_string ("disk_data", minetest.serialize (self.data))
							inv:set_stack ("main", self.slot, stack)

							return true
						end
					end
				end
			end
		end
	end

	return false
end



function diskobj:get_item (path)
	path = tostring (path or "")
	local data = self.data

	if path:len () < 1 then
		return data
	end

	local tokens = string.split (path, "/")

	for i = 1, #tokens - 1 do
		if type (data) ~= "table" then
			return nil
		end

		data = data[tokens[i]]

		if not data then
			return nil
		end
	end

	return data[tokens[#tokens]]
end



function diskobj:set_item (path, item)
	path = tostring (path or "")
	local data = self.data

	if path:len () < 1 then
		return false
	end

	local tokens = string.split (path, "/")

	for i = 1, #tokens - 1 do
		if type (data) ~= "table" then
			return false
		end

		data = data[tokens[i]]
	end

	data[tokens[#tokens]] = item

	return true
end



local function get_used (dir)
	local size = 0
	local count = 0

	for k, v in pairs (dir) do
		if type (v) == "table" then
			local s, c = get_used (v)
			count = count + c + 1
			size = size + s
		else
			count = count + 1
			size = size + v:len ()
		end
	end

	return size, count
end



-- return (total byte size), (total count of files and dirs)
function diskobj:get_used (path)
	local size = 0
	local count = 0
	local item = self:get_item (path)

	if type (item) == "string" then
		return item:len (), 1
	end

	if type (item) == "table" then
		return get_used (item)
	end

	return nil
end



function diskobj:mkdir (path)
	path = tostring (path or "")
	local data = self.data
	local used, items = self:get_used ()
	local max_items = (self.form == "floppy" and lwcomp.settings.floppy_max_items) or
							lwcomp.settings.hdd_max_items

	if path:len () < 1 then
		return true -- root false, "invalid path"
	end

	local tokens = string.split (path, "/")

	for i = 1, #tokens do
		if not data[tokens[i]] then
			if items >= max_items then
				return false, "disk full"
			end

			data[tokens[i]] = { }
			items = items + 1

		elseif type (data[tokens[i]]) == "string" then
			return false, "invalid path"

		end

		data = data[tokens[i]]
	end

	return true
end



function diskobj:remove (path, recursive)
	local item = self:get_item (path)

	if item then
		if type (item) == "table" then
			if recursive then
				self:set_item (path, nil)

				return true
			else
				local has_items = false
				for k, v in pairs (item) do
					has_items = true
				end

				if not has_items then
					self:set_item (path, nil)

					return true
				end
			end

		elseif type (item) == "string" then
			self:set_item (path, nil)

			return true
		end
	end

	return false
end



----------------------- safefile -----------------------



local function number_to_string (number)
	number = tonumber(number or 0) or 0
	local e = 0
	local num = math.abs (number)

	for i = 0, 15 do
		local n, m = math.modf (num)

		if m == 0 then
			break
		end

		e = e + 1
		num = num * 10
	end

	num = (math.modf (num))

	local str = ""

	for i = 1, 8 do
		local n = num % 256
		num = math.modf (num / 256)
		str = str..string.char (n)
	end

	str = str..string.char (((number < 0 and 128) or 0) + e)

	return str
end



local function string_to_number (str)
	local bytes = { str:byte (1, 9) }

	assert (#bytes == 9)

	local number = 0

	for i = 8, 1, -1 do
		number = (number * 256) + bytes[i]
	end

	local p = bytes[9]

	if p >= 128 then
		p = p - 128
	end

	if p > 16 then
		return nil
	end

	for i = 1, p do
		number = number / 10
	end

	if bytes[9] >= 128 then
		number = number * -1
	end

	return number
end



local safefile = { }



function safefile:new (max_size, filesys, id, path, mode)
	local obj = { }

   setmetatable(obj, self)
   self.__index = self

	if mode:sub (-2) == "b" then
		mode = mode:sub (1, -2)
	end

	obj.safefile_obj = true
	obj.max_size = max_size

	obj.filesys = filesys
	obj.id = id
	obj.path = path
	obj.cur_pos = 0
	obj.base_pos = 0
	obj.mode = mode
	obj.status = "file"

	local disk, msg = filesys:get_disk_by_id (id)

	if not disk then
		return nil, msg
	end

	local item = disk:get_item (path)

	if mode == "r" then
		if type (item) ~= "string" then
			return nil, "invalid path"
		end

	elseif mode == "w" or mode == "w+" then
		if type (item) == "table" then
			return nil, "invalid path"
		end

		if not disk:set_item (path, "") or
			not disk:save () then

			return nil, "disk error"
		end

	elseif mode == "a" then
		if type (item) == "table" then
			return nil, "invalid path"
		end

		if type (item) ~= "string" then
			if not disk:set_item (path, "") or
				not disk:save () then

				return nil, "disk error"
			end

			item = ""
		end

		obj.cur_pos = item:len ()

	elseif mode == "r+" then
		if type (item) == "table" then
			return nil, "invalid path"
		end

		if type (item) ~= "string" then
			if not disk:set_item (path, "") or
			not disk:save () then

				return nil, "disk error"
			end

			item = ""
		end

	elseif mode == "a+" then
		if type (item) == "table" then
			return nil, "invalid path"
		end

		if type (item) ~= "string" then
			if not disk:set_item (path, "") or
				not disk:save () then

				return nil, "disk error"
			end

			item = ""
		end

		obj.cur_pos = item:len ()
		obj.base_pos = item:len ()

	else
		return nil, "invalid mode"
	end

	return obj
end



function safefile:close ()
	self.status = "closed file"
end



function safefile:flush ()
end



function safefile:lines ()
	return function ()
		return self:read ("*l")
	end
end



function safefile:read (fmt)
	if self.status == "file" then
		local disk, msg = self.filesys:get_disk_by_id (self.id)

		if not disk then
			return false, msg
		end

		local contents = disk:get_item (self.path)

		if not contents then
			return nil
		end

		if type (fmt) == "number" then
			if self.cur_pos >= contents:len () then
				return nil
			end

			if fmt <= 0 then
				return ""
			end

			local result = contents:sub (self.cur_pos + 1, self.cur_pos + fmt)
			self.cur_pos = self.cur_pos + result:len ()

			return result

		elseif type (fmt) == "string" then
			if fmt == "*n" then
				if self.cur_pos >= contents:len () then
					return nil
				end

				local result = contents:sub (self.cur_pos + 1, self.cur_pos + 9)
				self.cur_pos = self.cur_pos + result:len ()

				if result:len () ~= 9 then
					return nil
				end

				return string_to_number (result)

			elseif fmt == "*a" then
				if self.cur_pos >= contents:len () then
					return ""
				end

				local result = contents:sub (self.cur_pos + 1)
				self.cur_pos = contents:len ()

				return result

			elseif fmt == "*l" then
				if self.cur_pos >= contents:len () then
					return nil
				end

				local pos = contents:find ("[\n\r]", self.cur_pos + 1, false)
				local line = nil

				if pos == nil then
					line = contents:sub (self.cur_pos + 1, -1)
					self.cur_pos = contents:len ()
				else
					line = contents:sub (self.cur_pos + 1, pos - 1)
					self.cur_pos = self.cur_pos + line:len () + 1

					local eol1, eol2 = contents:byte (pos, pos + 1)

					if eol1 == 13 and eol2 == 10 then
						self.cur_pos = self.cur_pos + 1
					end
				end

				return line

			end
		end
	end

	return nil
end



function safefile:seek (whence, offset)
	if self.status == "file" then
		whence = whence or "cur"
		offset = offset or 0

		local disk, msg = self.filesys:get_disk_by_id (self.id)

		if not disk then
			return nil, msg
		end

		local size = disk:get_used (self.path)

		if not size then
			return nil, "disk error"
		end

		if whence == "cur" then
			offset = offset + self.cur_pos

		elseif whence == "end" then
			offset = size - offset

		elseif whence ~= "set" then
			return nil, "invalid whence"
		end

		if offset < self.base_pos and offset > size then
			return nil, "out of range"
		end

		self.cur_pos = offset

		return self.cur_pos
	end

	return false, "invalid handle"
end



function safefile:setvbuf (mode, size)
end



function safefile:write ( ... )
	if self.status == "file" then
		if self.mode == "w" or self.mode == "r+" or self.mode == "w+" or
			self.mode == "a" or self.mode == "a+" then

			local args = { ... }
			local disk, msg = self.filesys:get_disk_by_id (self.id)
			local str = ""

			if not disk then
				return false, msg
			end

			local used = disk:get_used ()

			for i = 1, #args do
				if type (args[i]) == "string" then
					str = str..args[i]
				elseif type (args[i]) == "number" then
					str = str..number_to_string (args[i])
				end
			end

			if (str:len () + used) > self.max_size then
				error ("disk full", 2)
			end

			local contents = disk:get_item (self.path)

			if not contents then
				return false, "disk error"
			end

			local pre = contents:sub (1, self.cur_pos)
			local post = contents:sub (self.cur_pos + str:len () + 1)

			if not disk:set_item (self.path, pre..str..post) then
				return false, "disk error"
			end

			if not disk:save ()then
				return false, "disk error"
			end

			self.cur_pos = self.cur_pos + str:len ()

			return true
		end

		return false, "read mode"
	end

	return false, "invalid handle"
end



----------------- filesys -------------------------------



local filesys = { }



-- static
function filesys:create_hdd (id)
	return true
end



-- static
function filesys:create_floppy (id)
	return true
end



-- static
function filesys:delete_hdd (id)
end



-- static
function filesys:delete_floppy (id)
end



-- static
function filesys:path_folder (path)
	path = tostring (path or "")

	local tokens = tokenize_path (path)

	if #tokens > 2 then
		return table.concat (tokens, "/", 1, #tokens - 1)
	end

	if #tokens == 2 then
		if tokens[1] == "" then
			return "/"
		end

		return tokens[1]
	end

	if #tokens == 1 then
		if tokens[1] == "" then
			return "/"
		end

		return ""
	end

	return nil
end



-- static
function filesys:path_name (path)
	local rpath = tostring (path or ""):reverse ()
	local pos = rpath:find ("/")

	if pos then
		return rpath:sub (1, pos - 1):reverse ()
	end

	return path
end



-- static
function filesys:path_extension (path)
	local name = filesys:path_name (path)

	if name then
		name = name:reverse ()

		local pos = name:find (".", 1, true)

		if pos then
			return name:sub (1, pos - 1):reverse ()
		else
			return ""
		end
	end

	return nil
end



-- static
function filesys:path_title (path)
	local name = filesys:path_name (path)

	if name then
		name = name:reverse ()

		local pos = name:find (".", 1, true)

		if pos then
			return name:sub (pos + 1):reverse ()
		end

		return name:reverse ()
	end

	return nil
end



-- static
function filesys:abs_path (basepath, relpath)
	relpath = tostring (relpath or "")
	basepath = tostring (basepath or "")

	if relpath:len () == 0 then
		if basepath:len () == 0 then
			return nil, "invalid path"
		end

		return basepath
	end

	if relpath:sub (1, 1) == "/" then
		return relpath
	end

	local rel = tokenize_path (relpath)
	local base = tokenize_path (basepath)

	for i = 1, #rel do
		if rel[i] == ".." then
			if (#base == 0) or (base[1] == "" and #base == 1) then
				return nil, "invalid path"
			end

			table.remove (base, #base)
		else
			base[#base + 1] = rel[i]
		end
	end

	if #base == 1 and base[1] == "" then
		return "/"
	end

	return table.concat (base, "/")
end



-- constructor
function filesys:new (computer_id, pos)
	local obj = { }

   setmetatable(obj, self)
   self.__index = self

	obj.id = computer_id
	obj.pos = pos

	return obj
end



function filesys:get_drive_list ()
	local meta = minetest.get_meta (self.pos)

	if meta then
		local label = meta:get_string ("label")
		local list =
		{
			{
				id = self.id,
				form = "computer",
				mount = "",
				label = label,
				slot = 0
			}
		}

		local inv = meta:get_inventory ()
		if inv then
			local slots = inv:get_size ("main")

			for i = 1, slots do
				local stack = inv:get_stack ("main", i)

				if stack then
					if not stack:is_empty () then
						if lwcomp.is_floppy_disk (stack:get_name ()) then
							local imeta = stack:get_meta ()

							if imeta then
								local id = imeta:get_int ("lwcomputer_id")
								label = imeta:get_string ("label")

								if id > 0 then
									local mount = label

									if mount:len () < 1 then
										mount = "floppy_"..tostring (id)
									end

									list[#list + 1] =
									{
										id = id,
										form = "floppy",
										mount = mount,
										label = label,
										slot = i
									}
								end
							end
						end
					end
				end
			end
		end

		return list
	end

	return nil
end



-- return diskpath, slot, form, id
function filesys:get_disk_path (path)
	path = tostring (path or "")

	if path:sub (1, 1) ~= "/" then
		return nil, "invalid path"
	end

	local tokens = tokenize_path (path)
	table.remove (tokens, 1)

	local drives = self:get_drive_list ()

	if not drives then
		return nil, "no drives"
	end

	if #tokens > 0 then
		for d = 2, #drives do
			if drives[d].mount == tokens[1] then
				if #tokens > 1 then
					return resolve_path (table.concat (tokens, "/", 2), drives[d].slot,
												drives[d].form, drives[d].id)
				end

				return "", drives[d].slot, drives[d].form, drives[d].id
			end
		end
	end

	if path:len () > 1 then
		return resolve_path (path:sub (2, -1), drives[1].slot, drives[1].form, drives[1].id)
	end

	return "", drives[1].slot, drives[1].form, drives[1].id
end



function filesys:get_disk_by_id (id)
	local drives = self:get_drive_list ()

	if not drives then
		return nil, "no drives"
	end

	for i = 1, #drives do
		if drives[i].id == id then
			local disk = diskobj:new (self.pos, drives[i].slot)

			if not disk then
				return nil, "disk error"
			end

			return disk
		end
	end

	return nil, "invalid id"
end



local function prep_copy_file (disk_data, source, target)
	local contents = load_file (source)
	if not contents then
		return false
	end

	local tokens = string.split (target, "/")
	local data = disk_data

	for i = 1, #tokens - 1 do
		if type (data[tokens[i]]) == "string" then
			return false
		end

		if not data[tokens[i]] then
			data[tokens[i]] = { }
		end

		data = data[tokens[i]]
	end

	if type (data[tokens[#tokens]]) == "table" then
		return false
	end

	data[tokens[#tokens]] = contents

	return true
end



-- static
function filesys:prep_floppy_disk (id, meta, files)
		local result = true
	local data = { }

	if files then
		for i = 1, #files do
			local size, items = get_used (data)

			if size >= lwcomp.settings.floppy_max_size or
				items >= lwcomp.settings.floppy_max_items then

				meta:set_string ("disk_data", minetest.serialize (data))

				return false
			end

			if not prep_copy_file (data, files[i].source, files[i].target) then
				result = false
			end
		end
	end

	meta:set_string ("disk_data", minetest.serialize (data))

	return result
end



function filesys:file_type (path)
	local diskpath, slot, form = self:get_disk_path (path)

	if not diskpath then
		return nil, slot
	end

	local disk = diskobj:new (self.pos, slot)

	assert (disk, "disk not found")

	local item = disk:get_item (diskpath)

	if type (item) == "table" then
		return "dir"
	end

	if type (item) == "string" then
		return "file"
	end

	return nil
end



-- types: nil = all, true = only dirs, false = only files
function filesys:file_exists (path, types)
	local file_type = self:file_type (path)

	if not file_type then
		return false
	end

	if file_type == "file" then
		if types == false or types == nil then
			return true
		end

	elseif file_type == "dir" then
		if types == true or types == nil then
			return true
		end

	end

	return false
end



function filesys:file_size (path)
	local diskpath, slot, form = self:get_disk_path (path)

	if not diskpath then
		return nil, slot
	end

	local disk = diskobj:new (self.pos, slot)

	assert (disk, "disk not found")

	return (disk:get_used (diskpath))
end



function filesys:mkdir (path)
	local diskpath, slot, form = self:get_disk_path (path)

	if not diskpath then
		return false, slot
	end

	local disk = diskobj:new (self.pos, slot)

	assert (disk, "disk not found")

	local result, msg = disk:mkdir (diskpath)

	if not result then
		return false, msg
	end

	if not disk:save () then
		return false, "disk error"
	end

	return true
end



function filesys:remove (path)
	local diskpath, slot, form = self:get_disk_path (path)

	if not diskpath then
		return nil, slot
	end

	if diskpath:len () < 1 then
		return nil, "invalid path"
	end

	local disk = diskobj:new (self.pos, slot)

	assert (disk, "disk not found")

	if not disk:remove (diskpath, false) then
		return nil, "invalid path"
	end

	if not disk:save () then
		return nil, "disk error"
	end

	return true
end



function filesys:rename (oldname, newname)
	local oldpath, oldslot, oldform = self:get_disk_path (oldname)
	local newpath, newslot, newform = self:get_disk_path (newname)

	if not oldpath then
		return nil, oldslot
	end

	if not newpath then
		return nil, newslot
	end

	if oldslot == newslot and oldpath == newpath then
		return true
	end

	if oldpath:len () < 1 then
		return nil, "invalid src"
	end

	if newpath:len () < 1 then
		return nil, "invalid dest"
	end

	local olddisk = diskobj:new (self.pos, oldslot)
	local newdisk = nil

	assert (olddisk, "disk not found")

	if oldslot == newslot then
		newdisk = olddisk
	else
		newdisk = diskobj:new (self.pos, newslot)

		assert (newdisk, "disk not found")
	end

	item = olddisk:get_item (oldpath)

	if not item then
		return nil, "invalid src"
	end

	if not newdisk:set_item (newpath, item) then
		return nil, "invalid dest"
	end

	olddisk:set_item (oldpath, nil)

	local newsaved = newdisk:save ()
	local oldsaved = true

	if oldslot ~= newslot then
		oldsaved = olddisk:save ()
	end

	if not newsaved or not oldsaved then
		return nil, "disk error"
	end

	return true
end



function filesys:open (path, mode)
	local diskpath, slot, form, id = self:get_disk_path (path)

	if not diskpath then
		return nil, slot
	end

	local disk = diskobj:new (self.pos, slot)

	assert (disk, "disk not found")

	local max_size = (form == "floppy" and lwcomp.settings.floppy_max_size) or
							lwcomp.settings.hdd_max_size
	local max_items = (form == "floppy" and lwcomp.settings.floppy_max_items) or
							lwcomp.settings.hdd_max_items

	if mode:sub (-2) == "b" then
		mode = mode:sub (1, -2)
	end

	if mode == "w" or mode == "a" or mode == "r+" or
		mode == "w+" or mode == "a+" then

		if not disk:get_item (diskpath) then
			local used, items = disk:get_used ()

			if ((used >= max_size) or (items >= max_items)) then
				return nil, "disk full"
			end
		end
	end

	return safefile:new (max_size, self, id, diskpath, mode)
end



-- types: nil = all, true = only dirs, false = only files
function filesys:ls (path, types)
	if path then
		local diskpath, slot, form = self:get_disk_path (path)

		if not diskpath then
			return nil, slot
		end

		local disk = diskobj:new (self.pos, slot)

		assert (disk, "disk not found")

		local dir = disk:get_item (diskpath)

		if type (dir) == "table" then
			local list = { }

			for k, v in pairs (dir) do
				if type (v) == "table" then
					if types ~= false then
						list[#list + 1] = k
					end
				elseif type (v) == "string" then
					if types ~= true then
						list[#list + 1] = k
					end
				end
			end

			if path == "/" and types ~= false then
				local drives = self:get_drive_list ()

				if drives then
					for d = 2, #drives do
						list[#list + 1] = drives[d].mount
					end
				end
			end

			return list
		end

	else
		local list = { }
		local drives = self:get_drive_list ()

		if drives then
			for d = 1, #drives do
				list[#list + 1] = "/"..drives[d].mount
			end
		end

		return list
	end

	return nil, "invalid path"
end



function filesys:get_boot_file ()
	local drives = self:get_drive_list ()

	if not drives then
		return nil
	end

	for d = 2, #drives do
		local diskpath, slot, form = self:get_disk_path ("/"..drives[d].mount.."/boot")

		if diskpath then
			local disk = diskobj:new (self.pos, slot)

			assert (disk, "disk not found")

			local item = disk:get_item (diskpath)

			if type (item) == "string" then
				return item
			end
		end
	end

	local diskpath, slot, form = self:get_disk_path ("/boot")

	if diskpath then
		local disk = diskobj:new (self.pos, slot)

		assert (disk, "disk not found")

		local item = disk:get_item (diskpath)

		if type (item) == "string" then
			return item
		end
	end

	return nil
end



-- str path of root of drive or zero based drive number
function filesys:get_label (drivepath)
	local drives = self:get_drive_list ()

	if not drives then
		return nil, "no drives"
	end

	if type (drivepath) == "string" then
		if drivepath == "/" then
			return drives[1].label
		end

		local tokens = tokenize_path (drivepath)
		table.remove (tokens, 1)

		if #tokens ~= 1 then
			return nil, "invalid path"
		end

		for d = 2, #drives do
			if tokens[1] == drives[d].mount then
				return drives[d].label
			end
		end

		return nil, "invalid path"

	elseif type (drivepath) == "number" then
		if drivepath < 0 or drivepath >= #drives then
			return nil, "invalid drives"
		end

		return drives[drivepath + 1].label
	end

	return nil, "bad param"
end



-- str path of root of drive or zero based drive number
function filesys:set_label (drivepath, label)
	label = tostring (label or "")
	local meta = minetest.get_meta (self.pos)

	if not meta then
		return false, "not found"
	end

	if type (drivepath) == "string" then

		if drivepath == "/" then
			meta:set_string ("label", label)

			return true
		end

		local tokens = tokenize_path (drivepath)
		table.remove (tokens, 1)

		if #tokens ~= 1 then
			return false, "invalid path"
		end

		local inv = meta:get_inventory ()

		if not inv then
			return false, "not found"
		end

		local slots = inv:get_size ("main")

		for i = 1, slots do
			local stack = inv:get_stack ("main", i)

			if stack then
				if not stack:is_empty () then
					if lwcomp.is_floppy_disk (stack:get_name ()) then
						local imeta = stack:get_meta ()

						if imeta then
							local mount = imeta:get_string ("label")

							if mount:len () < 1 then
								mount = "floppy_"..tostring (id)
							end

							if tokens[1] == mount then
								local description = label

								if description:len () < 1 then
									description = S("floppy ")..tostring (imeta:get_int ("lwcomputer_id"))
								end

								imeta:set_string ("label", label)
								imeta:set_string ("description", description)
								inv:set_stack ("main", i, stack)

								return true
							end
						end
					end
				end
			end
		end

	elseif type (drivepath) == "number" then
		if drivepath < 0 then
			return false, "invalid drive"
		end

		if drivepath == 0 then
			meta:set_string ("label", label)

			return true
		end

		local inv = meta:get_inventory ()

		if not inv then
			return false, "not found"
		end

		local slots = inv:get_size ("main")

		for i = 1, slots do
			local stack = inv:get_stack ("main", i)

			if stack then
				if not stack:is_empty () then
					if lwcomp.is_floppy_disk (stack:get_name ()) then
						local imeta = stack:get_meta ()

						if imeta then
							if drivepath == 1 then
								local description = label

								if description:len () < 1 then
									description = S("floppy ")..tostring (imeta:get_int ("lwcomputer_id"))
								end

								imeta:set_string ("label", label)
								imeta:set_string ("description", description)
								inv:set_stack ("main", i, stack)

								return true
							end

							drivepath = drivepath - 1
						end
					end
				end
			end
		end

	end

	return false, "bad param"
end



-- str path of root of drive or zero based drive number
function filesys:get_drive_id (drivepath)
	local drives = self:get_drive_list ()

	if not drives then
		return nil, "no drive"
	end

	if type (drivepath) == "string" then
		if drivepath == "/" then
			return drives[1].id
		end

		local tokens = tokenize_path (drivepath)
		table.remove (tokens, 1)

		if #tokens ~= 1 then
			return nil, "invalid path"
		end

		for d = 2, #drives do
			if tokens[1] == drives[d].mount then
				return drives[d].id
			end
		end

		return nil, "invalid path"

	elseif type (drivepath) == "number" then
		if drivepath < 0 or drivepath >= #drives then
			return nil, "invalid drive"
		end

		return drives[drivepath + 1].id
	end

	return nil, "bad param"
end



function filesys:copy_file (srcpath, destpath)
	local spath, sslot, sform = self:get_disk_path (srcpath)
	local dpath, dslot, dform = self:get_disk_path (destpath)

	if not spath then
		return nil, sslot
	end

	if not dpath then
		return nil, dslot
	end

	if sslot == dslot and spath == dpath then
		return false, "invalid path"
	end

	local sdisk = diskobj:new (self.pos, sslot)
	local ddisk = nil

	assert (sdisk, "disk not found")

	if sslot == dslot then
		ddisk = sdisk
	else
		ddisk = diskobj:new (self.pos, dslot)

		assert (ddisk, "disk not found")
	end

	local used, items = ddisk:get_used ()
	local destsize = 0

	local item = ddisk:get_item (dpath)

	if item then
		if type (item) == "table" then
			return false, "invalid path"
		end

		destsize = item:len ()
		items = items - 1
	end

	item = sdisk:get_item (spath)

	if type (item) ~= "string" then
		return false, "invalid path"
	end

	local srcsize = item:len ()

	local max_size = (form == "floppy" and lwcomp.settings.floppy_max_size) or
							lwcomp.settings.hdd_max_size
	local max_items = (form == "floppy" and lwcomp.settings.floppy_max_items) or
							lwcomp.settings.hdd_max_items

	if ((used + srcsize - destsize) > max_size) or
		((items + 1) > max_items) then

		return false, "disk full"
	end

	if not ddisk:set_item (dpath, item) then
		return false, "copy error"
	end

	if not ddisk:save () then
		return false, "disk error"
	end

	return true
end



function filesys:get_disk_free (drivepath)
	local path = nil
	local drives = self:get_drive_list ()

	if not drives then
		return nil, "no drive"
	end

	if type (drivepath) == "string" then
		if drivepath == "/" then
			path = "/"
		else
			local tokens = tokenize_path (drivepath)
			table.remove (tokens, 1)

			if #tokens ~= 1 then
				return nil, "invalid path"
			end

			for d = 2, #drives do
				if tokens[1] == drives[d].mount then
					path = "/"..drives[d].mount
					break
				end
			end
		end

		if not path then
			return nil, "invalid path"
		end

	elseif type (drivepath) == "number" then
		if drivepath < 0 or drivepath >= #drives then
			return nil, "invalid drive"
		end

		path = "/"..drives[drivepath + 1].mount
	end

	local diskpath, slot, form = self:get_disk_path (path)

	if not diskpath then
		return nil, "invalid drivepath"
	end

	local disk = diskobj:new (self.pos, slot)

	assert (disk, "disk not found")

	local used = disk:get_used ()
	local max_size = (form == "floppy" and lwcomp.settings.floppy_max_size) or
							lwcomp.settings.hdd_max_size

	return ((max_size - used) >= 0 and (max_size - used)) or 0
end



function filesys:get_disk_size (drivepath)
	local drives = self:get_drive_list ()

	if not drives then
		return nil, "no drive"
	end

	if type (drivepath) == "string" then
		if drivepath == "/" then
			return lwcomp.settings.hdd_max_size
		else
			local tokens = tokenize_path (drivepath)
			table.remove (tokens, 1)

			if #tokens ~= 1 then
				return nil, "invalid path"
			end

			for d = 2, #drives do
				if tokens[1] == drives[d].mount then
					return lwcomp.settings.floppy_max_size
				end
			end
		end

	elseif type (drivepath) == "number" then
		if drivepath < 0 or drivepath >= #drives then
			return nil, "invalid drive"
		end

		if drives[drivepath + 1].form == "floppy" then
			return lwcomp.settings.floppy_max_size
		else
			return lwcomp.settings.hdd_max_size
		end
	end

	return nil, "invalid drivepath"
end



lwcomp.filesys = filesys



--
