local lwcomp = ...
local S = lwcomp.S



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



local function remove_dir (path)
	local list = minetest.get_dir_list (path, false)
	local result = true

	for i = 1, #list do
		if not os.remove (path.."/"..list[i]) then
			result = false
		end
	end

	list = minetest.get_dir_list (path, true)

	for i = 1, #list do
		if not remove_dir (path.."/"..list[i]) then
			result = false
		end
	end

	if not os.remove (path) then
		result = false
	end

	return result
end



-- return (total byte size), (total count of files and dirs)
local function get_disk_used (dirpath)
	local size = 0
	local count = 0
	local files = minetest.get_dir_list (dirpath, false)
	local dirs = minetest.get_dir_list (dirpath, true)

	if files then
		count = count + #files

		for f = 1, #files do
			local file = io.open (dirpath.."/"..files[f], "r")

			if file then
				size = size + (file:seek ("end") or 0)
				file:close ()
			end
		end
	end

	if dirs then
		count = count + #dirs

		for d = 1, #dirs do
			local s, c = get_disk_used (dirpath.."/"..dirs[d])
			size = size + s
			count = count + c
		end
	end

	return size, count
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



local function resolve_path (path, root, form)
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

	if recon:len () < root:len () or
		recon:sub (1, root:len ()) ~= root then

		return nil, "invalid path"
	end

	return recon, root, form
end



----------------------- safefile -----------------------



local safefile = { }



function safefile:new (file, max_size, root)
	local obj = { }

   setmetatable(obj, self)
   self.__index = self

	obj.safefile_obj = true
	obj.file = file
	obj.max_size = max_size
	obj.root = root

	obj.last_write_time = 0
	obj.last_size = 0
	obj.last_items = 0

	return obj
end



function safefile:close ()
	if not self or not self.file then
		error ("file:close () not called as class", 2)
	end

	return self.file:close ()
end



function safefile:flush ()
	if not self or not self.file then
		error ("file:flush () not called as class", 2)
	end

	return self.file:flush ()
end



function safefile:lines ()
	if not self or not self.file then
		error ("file:lines () not called as class", 2)
	end

	return self.file:lines ()
end



function safefile:read ( ... )
	if not self or not self.file then
		error ("file:read () not called as class", 2)
	end

	return self.file:read ( ... )
end



function safefile:seek ( ... )
	if not self or not self.file then
		error ("file:seek () not called as class", 2)
	end

	return self.file:seek ( ... )
end



function safefile:setvbuf ( ... )
	if not self or not self.file then
		error ("file:setvbuf () not called as class", 2)
	end

	return self.file:setvbuf ( ... )
end



function safefile:get_disk_used ()
	if not self or not self.file then
		error ("file:get_disk_used () not called as class", 2)
	end

	local us_time = minetest.get_us_time ()

	if (us_time < self.last_write_time) or
		((self.last_write_time + 1000) > us_time) then

		self.last_write_time = minetest.get_us_time()
		self.last_size, self.last_items = get_disk_used (self.root)
	end

	return self.last_size, self.last_items
end



function safefile:write ( ... )
	if not self or not self.file then
		error ("file:write () not called as class", 2)
	end

	local args = { ... }
	local used = self:get_disk_used ()
	local size = 0

	for i = 1, #args do
		if type (args[i]) == "string" then
			size = size + args[i]:len ()
		elseif type (args[i]) == "number" then
			size = size + 8
		end
	end

	if (size + used) > self.max_size then
		error ("disk full", 2)
	end

	local result = { self.file:write ( ... ) }
	self:flush ()

	return unpack (result)
end



----------------- filesys -------------------------------



local filesys = { }



-- static
function filesys:get_root_path (id, form)
	id = tonumber (id or 0)
	form = tostring (form or "")

	if id > 0 and form:len () > 0 then
		return lwcomp.worldpath.."/lwcomputers/"..form.."_"..tostring (id)
	end

	return nil
end



-- static
function filesys:get_floppy_base (id)
	return filesys:get_root_path (id, "floppy")
end



-- static
function filesys:prep_floppy_disk (id, meta, files)
	-- create floppy dir
	if not filesys:create_floppy (id) then
		return false
	end

	if files then
		local root = filesys:get_floppy_base (id)

		if not root then
			return false
		end

		local result = true

		for i = 1, #files do
			local size, items = get_disk_used (root)

			if size >= lwcomp.settings.floppy_max_size or
				items >= lwcomp.settings.floppy_max_items then

				return false
			end

			local target = root.."/"..files[i].target
			local folder = filesys:path_folder (target)

			if not folder or not minetest.mkdir (folder) or
				not copy_file (files[i].source, target) then

				result = false
			end
		end

		return result
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
function filesys:delete_hdd (id)
	local path = filesys:get_root_path (id, "computer")
	local file = io.open (path, "r")

	if file then
		file:close ()

		if not remove_dir (path) then
			minetest.log ("warning", "lwcomputers - error removing disk folder "..path)
		end
	end
end



-- static
function filesys:delete_floppy (id)
	local path = filesys:get_root_path (id, "floppy")
	local file = io.open (path, "r")

	if file then
		file:close ()

		if not remove_dir (path) then
			minetest.log ("warning", "lwcomputers - error removing disk folder "..path)
		end
	end
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



-- return fullpath, rootpath, form
function filesys:get_full_path (path)
	path = tostring (path or "")
	local root;

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
				root = self:get_root_path (drives[d].id, drives[d].form)

				if not root then
					return nil, "invalid path"
				end

				if #tokens > 1 then
					return resolve_path (root.."/"..table.concat (tokens, "/", 2),
												root, drives[d].form)
				end

				return root, root, drives[d].form
			end
		end
	end

	root = self:get_root_path (drives[1].id, drives[1].form)

	if not root then
		return nil, "invalid path"
	end

	if path:len () > 1 then
		return resolve_path (root..path, root, drives[1].form)
	end

	return root, root, drives[1].form
end



function filesys:mkdir (path)
	local fpath, root, form = self:get_full_path (path)

	if fpath then
		local _, items = get_disk_used (root)
		local max_items = lwcomp.settings.hdd_max_items

		if form == "floppy" then
			max_items = lwcomp.settings.floppy_max_items
		end

		if items >= max_items then
			return false, "disk full"
		end

		return minetest.mkdir (fpath)
	end

	return false, "mkdir error"
end



function filesys:remove (path)
	local fpath, root = self:get_full_path (path)

	if fpath == root then
		return nil, "invalid path"
	end

	if fpath then
		return os.remove (fpath)
	end

	return nil, "invalid path"
end



function filesys:rename (oldname, newname)
	local oldpath, oldroot = self:get_full_path (oldname)
	local newpath, newroot = self:get_full_path (newname)

	if oldpath == oldroot then
		return nil, "invalid src"
	end

	if newpath == newroot then
		return nil, "invalid dest"
	end

	if oldpath and newpath then
		return os.rename (oldpath, newpath)
	end

	return nil, "invalid path"
end



function filesys:open (path, mode)
	local fpath, root, form = self:get_full_path (path)

	if fpath then
		local max_size = lwcomp.settings.hdd_max_size
		local max_items = lwcomp.settings.hdd_max_items

		if form == "floppy" then
			max_size = lwcomp.settings.floppy_max_size
			max_items = lwcomp.settings.floppy_max_items
		end

		if mode == "w" or mode == "r+" then
			local used, items = get_disk_used (root)

			local exists = false
			local tmp = io.open (fpath, "r")
			if tmp then
				tmp:close ()
				exists = true
			end

			if not exists and
				((used >= max_size) or (items >= max_items)) then

				return nil, "disk full"
			end
		end

		local file, msg = io.open (fpath, mode)

		if not file then
			if msg then
				msg = msg:gsub (root, "")
			end

			return nil, msg
		end

		return safefile:new (file, max_size, root)
	end

	return nil, "invalid path"
end



-- types: nil = all, true = only dirs, false = only files
function filesys:ls (path, types)
	if path then
		local fpath = self:get_full_path (path)

		if fpath then
			local list = minetest.get_dir_list (fpath, types)

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

	elseif self:file_type (path) == "dir" then
		local fpath = self:get_full_path (path)

		if fpath then
			return get_disk_used (fpath)
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
			local contents = file:read ("*a")
			file:close ()

			return contents
		end
	end

	local path = filesys:get_root_path (drives[1].id, drives[1].form).."/boot"
	local file = io.open (path, "r")

	if file then
		local contents = file:read ("*a")
		file:close ()

		return contents
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
								mount = "floppy_"..tostring (imeta:get_int ("lwcomputer_id"))
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
	local src = self:get_full_path (srcpath)
	local dest, root, form = self:get_full_path (destpath)

	if src and dest then
		local used, items = get_disk_used (root)
		local max_size = lwcomp.settings.hdd_max_size
		local max_items = lwcomp.settings.hdd_max_items

		if form == "floppy" then
			max_size = lwcomp.settings.floppy_max_size
			max_items = lwcomp.settings.floppy_max_items
		end

		local destcount = 0
		local destsize = 0
		local srcsize = 0

		local tmp = io.open (dest, "r")
		if tmp then
			destsize = tmp:seek ("end")
			destcount = 1
			tmp:close ()
		end

		tmp = io.open (src, "r")
		if tmp then
			srcsize = tmp:seek ("end")
			tmp:close ()
		end

		if ((used + srcsize - destsize) >= max_size) or
			((items + 1 - destcount) >= max_items) then

			return false, "disk full"
		end

		local result = copy_file (src, dest)

		if not result then
			return false, "copy error"
		end

		return true
	end

	return false, "invalid path"
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

	local fpath, _, form = self:get_full_path (path)

	if fpath then
		local used = get_disk_used (fpath)
		local max_size = lwcomp.settings.hdd_max_size

		if form == "floppy" then
			max_size = lwcomp.settings.floppy_max_size
		end

		return ((max_size - used) >= 0 and (max_size - used)) or 0
	end

	return nil, "invalid drivepath"
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
