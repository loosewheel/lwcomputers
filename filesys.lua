

local filesys = { }



-- helpers
local function copy_file (srcpath, destpath)
	local success = false

	local file = io.open (srcpath, "r")
	if file then
		local contents = file:read ("*a")

		file:close ()

		if contents then
			file = io.open (destpath, "w")

			if file then
				file:write (contents)

				file:close ()

				success = true
			end
		end
	end

	return success
end



-- static
function filesys:get_root_path (id, form)
	id = tonumber (id or 0)
	form = tostring (form or "")

	if id > 0 and form:len () > 0 then
		return lwcomputers.worldpath.."/lwcomputers/"..form.."_"..tostring (id)
	end

	return nil
end



-- static
function filesys:get_floppy_base (id)
	return filesys:get_root_path (id, "floppy")
end



-- static
function filesys:prep_lua_disk (id)
	-- create floppy dir
	if not lwcomputers.filesys:create_floppy (id) then
		return false
	end

	local root = filesys:get_floppy_base (id)

	if not root then
		return false
	end

	if not copy_file (lwcomputers.modpath.."/res/lua_disk.lua", root.."/boot") then
		return false
	end

	return true
end



-- static
function filesys:create_hdd (id)
	local path = filesys:get_root_path (id, "computer")

	return minetest.mkdir (path)
end



-- static
function filesys:create_floppy (id)
	local path = filesys:get_root_path (id, "floppy")

	return minetest.mkdir (path)
end



-- static
function filesys:path_folder (path)
	path = tostring (path or "")

	local tokens = path:split("/", true)

	if #tokens > 1 then
		return table.concat (tokens, "/", 1, #tokens - 1)
	end

	if #tokens == 1 then
		return "/"
	end

	return nil
end



-- static
function filesys:path_name (path)
	path = tostring (path or "")

	local tokens = path:split("/", true)

	if #tokens > 0 then
		return tokens[#tokens]
	end

	return nil
end



-- static
function filesys:path_extension (path)
	local name = filesys:path_name (path)

	if name then
		name = name:reverse ()

		local pos = name:find (".", 1, true)

		if pos then
			name = name:sub (1, pos - 1)

			return name:reverse ()
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
			name = name:sub (pos + 1)

			return name:reverse ()
		end
	end

	return nil
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
				label = label
			}
		}

		local inv = meta:get_inventory ()
		if inv then
			local slots = inv:get_size ("main")

			for i = 1, slots do
				local stack = inv:get_stack ("main", i)

				if stack then
					if not stack:is_empty () then
						if stack:get_name ():sub (1, 18) == "lwcomputers:floppy" then
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
										label = label
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



function filesys:get_full_path (path)
	path = tostring (path or "")

	if path:sub (1, 1) ~= "/" then
		return nil, "invalid path"
	end

	local tokens = path:split("/")
	local drives = self:get_drive_list ()

	if not drives then
		return nil, "no drives"
	end

	if #tokens > 0 then
		for d = 2, #drives do
			if drives[d].mount == tokens[1] then
				local root = self:get_root_path (drives[d].id, drives[d].form)

				if not root then
					return nil, "invalid path"
				end

				if #tokens > 1 then
					return root.."/"..table.concat (tokens, "/", 2)
				end

				return root
			end
		end
	end

	if path:len () > 1 then
		return self:get_root_path (drives[1].id, drives[1].form)..path
	end

	return self:get_root_path (drives[1].id, drives[1].form)
end



function filesys:mkdir (path)
	local fpath = self:get_full_path (path)

	if fpath then
		return minetest.mkdir (fpath)
	end

	return false
end



function filesys:remove (path)
	local fpath = self:get_full_path (path)

	if fpath then
		return os.remove (fpath)
	end

	return nil, "invalid path"
end



function filesys:rename (oldname, newname)
	local oldpath = self:get_full_path (oldname)
	local newpath = self:get_full_path (newname)

	if oldpath and newpath then
		return os.rename (oldpath, newpath)
	end

	return nil, "invalid path"
end



function filesys:open (path, mode)
	local fpath = self:get_full_path (path)

	if fpath then
		return io.open (fpath, mode)
	end

	return nil, "invalid path"
end



-- types: nil = all, true = only dirs, false = only files
function filesys:ls (path, types)
	if path then
		local fpath = self:get_full_path (path)

		if fpath then
			local list = minetest.get_dir_list (fpath, types)

			if path:len () == 1 and types ~= false then
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



-- types: nil = all, true = only dirs, false = only files
function filesys:file_exists (path, types)
	local fpath = self:get_full_path (path)

	if fpath then
		local folder = self:path_folder (fpath)
		local name = self:path_name (fpath)

		if folder and name then
			local list = minetest.get_dir_list (folder, types)

			if list then
				for i = 1, #list do
					if list[i] == name then
						return true
					end
				end
			end
		end
	end

	return false
end



function filesys:file_type (path)
	if self:file_exists (path, false) then
		return "file"
	end

	if self:file_exists (path, true) then
		return "dir"
	end

	return nil
end



function filesys:file_size (path)
	if self:file_type (path) == "file" then
		local file = self:open (path, "r")

		if file then
			local size = file:seek ("end")
			file:close ()

			return size
		end
	end

	return nil
end



function filesys:get_boot_file ()
	local drives = self:get_drive_list ()

	if not drives then
		return nil
	end

	for d = 2, #drives do
		local path = filesys:get_root_path (drives[d].id, drives[d].form).."/boot"
		local file = io.open (path, "r")

		if file then
			file:close ()

			return path
		end
	end

	local path = filesys:get_root_path (drives[1].id, drives[1].form).."/boot"
	local file = io.open (path, "r")

	if file then
		file:close ()

		return path
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

		local tokens = drivepath:split("/")

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

		local tokens = drivepath:split("/")

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
					if stack:get_name ():sub (1, 18) == "lwcomputers:floppy" then
						local imeta = stack:get_meta ()

						if imeta then
							local mount = imeta:get_string ("label")

							if mount:len () < 1 then
								mount = "floppy_"..tostring (id)
							end

							if tokens[1] == mount then
								imeta:set_string ("label", label)
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
					if stack:get_name ():sub (1, 18) == "lwcomputers:floppy" then
						local imeta = stack:get_meta ()

						if imeta then
							if drivepath == 1 then
								imeta:set_string ("label", label)
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
		return nil, "no drives"
	end

	if type (drivepath) == "string" then
		if drivepath == "/" then
			return drives[1].id
		end

		local tokens = drivepath:split("/")

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
			return nil, "invalid drives"
		end

		return drives[drivepath + 1].id
	end

	return nil, "bad param"
end



function filesys:copy_file (srcpath, destpath)
	local src = self:get_full_path (srcpath)
	local dest = self:get_full_path (destpath)

	if src and dest then
		local result = copy_file (src, dest)

		if not result then
			return false, "copy error"
		end

		return true
	end

	return false, "invalid path"
end



lwcomputers.filesys = filesys

--
