local lwcomp = ...



local function new_computer_env (computer)
	local ENV = { }

	ENV.assert = _G.assert
	ENV.tostring = _G.tostring
	ENV.tonumber = _G.tonumber
--	ENV.rawget = _G.rawget -- omitted
	ENV.ipairs = _G.ipairs
	ENV.pcall = _G.pcall
--	ENV.rawset = _G.rawset -- omitted
--	ENV.rawequal = _G.rawequal -- omitted
	ENV._VERSION = _G._VERSION
	ENV.next = _G.next
	ENV.type = _G.type
	ENV.xpcall = _G.xpcall
--	ENV.setfenv = _G.setfenv -- modify
--	ENV.getmetatable = _G.getmetatable -- modify
	ENV.error = _G.error
	ENV.pairs = _G.pairs
--	ENV.setmetatable = _G.setmetatable -- modify
	ENV.select = _G.select
	ENV.unpack = _G.unpack
--	ENV.getfenv = _G.getfenv -- modify
--	ENV.load = _G.load -- modify
--	ENV.loadfile = _G.loadfile -- modify
--	ENV.loadstring = _G.loadstring -- modify
--	ENV.dofile = _G.dofile -- modify
--	ENV.print = _G.print -- modify
--	ENV.require = _G.require -- omitted
--	ENV.debug = _G.debug -- omitted
--	ENV.package = _G.package -- omitted
--	ENV.jit = _G.jit -- omitted
--	ENV.collectgarbage = _G.collectgarbage -- omitted
	ENV._G = ENV


	ENV.getfenv = function (func)
		if type (func) == "number" then
			if func == 0 then
				return ENV
			elseif func > 0 then
				-- over this function
				func = func + 1
			end
		end

		local env = getfenv (func)

		if env and env ~= _G then
			return env
		end

		return nil
	end


	ENV.setfenv = function (func, table)
		if type (func) == "number" then
			if func > 0 then
				-- over this function
				func = func + 1
			end
		end

		local env = getfenv (func)

		if not env or env ~= _G then
			setfenv (func, table)

			return func
		end
	end


	ENV.getmetatable = function (object)
		if type (object) == "table" then
			local mt = getmetatable (object)

			if mt ~= getmetatable (ENV.string) and
				mt ~= getmetatable (ENV.coroutine) and
				mt ~= getmetatable (ENV.table) and
				mt ~= getmetatable (ENV.math) and
				mt ~= getmetatable (ENV.vector) then

				return mt
			end
		end

		return nil
	end


	ENV.setmetatable = function (object, metatable)
		if type (object) == "table" then
			if object ~= ENV.string and
				object ~= ENV.coroutine and
				object ~= ENV.table and
				object ~= ENV.math and
				object ~= ENV.vector then

				setmetatable (object, metatable)
			end
		end
	end


	ENV.string = { }
	for key, value in pairs (_G.string) do
		ENV.string[key] = value
	end
	setmetatable (ENV.string, getmetatable (_G.string))
--	ENV.string.find modified below
--	ENV.string.rep modified below

	ENV.coroutine = { }
	for key, value in pairs (_G.coroutine) do
		ENV.coroutine[key] = value
	end
	setmetatable (ENV.coroutine, getmetatable (_G.coroutine))

	ENV.table = { }
	for key, value in pairs (_G.table) do
		ENV.table[key] = value
	end
	setmetatable (ENV.table, getmetatable (_G.table))

	ENV.math = { }
	for key, value in pairs (_G.math) do
		ENV.math[key] = value
	end
	setmetatable (ENV.math, getmetatable (_G.math))

	ENV.vector = { }
	for key, value in pairs (_G.vector) do
		ENV.vector[key] = value
	end
	setmetatable (ENV.vector, getmetatable (_G.vector))

	ENV.io = { }
--	ENV.io.input = _G.io.input -- omitted
--	ENV.io.write = _G.io.write -- omitted
--	ENV.io.read = _G.io.read -- omitted
--	ENV.io.output = _G.io.output -- omitted
--	ENV.io.open = _G.io.open -- modify
--	ENV.io.close = _G.io.close -- modify
--	ENV.io.flush = _G.io.flush -- omitted
--	ENV.io.type = _G.io.type -- modify
--	ENV.io.lines = _G.io.lines -- modify

	ENV.os = { }
--	ENV.os.clock = _G.os.clock -- modify
--	ENV.os.date = _G.os.date -- modify
	ENV.os.difftime = _G.os.difftime
--	ENV.os.getenv = _G.os.getenv -- modify
--	ENV.os.setenv -- added
--	ENV.os.remove = _G.os.remove -- modify
--	ENV.os.rename = _G.os.rename -- modify
--	ENV.os.time = _G.os.time -- modify
--	ENV.os.setlocale = _G.os.setlocale -- omitted
--	ENV.os.tmpname = _G.os.tmpname -- omitted

	ENV.os.environs = { }
	ENV.fs = { }
	ENV.keys = { }
	ENV.term = { }
	ENV.term.colors = { }
	ENV.utils = { }
	ENV.wireless = { }
	ENV.digilines = { }
	ENV.mesecons = { }
	ENV.http = { }
	ENV.printer = { }



	-- io

	ENV.io.close = function (file)
		if file and file.close then
			file:close ()
		end
	end


	ENV.io.lines = function (path)
		if path then
			local file = computer.filesys:open (path, "r")

			if file then
				return function ()
					local line = file:read ("*l")

					if not line then
						file:close ()
					end

					return line
				end
			end
		end

		return function ()
			return nil
		end
	end


	ENV.io.open = function (path, mode)
		return computer.filesys:open (path, mode)
	end


	ENV.io.type = function (obj)
		if obj and obj.safefile_obj then
			if obj.status then
				return obj.status
			else
				return io.type (obj.file)
			end
		end

		return io.type (obj)
	end



	-- os

	ENV.os.clock = function ()
		return (minetest.get_us_time () - computer.clock_base) / 1000000.0
	end


	ENV.os.remove = function (path)
		return computer.filesys:remove (path)
	end


	ENV.os.rename = function (oldname, newname)
		return computer.filesys:rename (oldname, newname)
	end


	ENV.os.getenv = function (varname)
		if not varname then
			return nil
		end

		return ENV.os.environs[tostring (varname)]
	end


	ENV.os.setenv = function (varname, value)
		if not value then
			ENV.os.environs[varname] = nil
		else
			ENV.os.environs[varname] = tostring (value or "")
		end
	end


	ENV.os.envstr = function (str)
		for k, v in pairs (ENV.os.environs) do
			str = string.gsub (str, "$"..k, tostring (v))
		end

		return str
	end


	ENV.os.time = function (tm)
		if type (tm) == "table" then
			return os.time (tm)
		end

		return lwcomp.get_worldtime ()
	end


	ENV.os.date = function (fmt, tm)
		if not tm then
			tm = lwcomp.get_worldtime ()
		end

		if not fmt then
			fmt = "%c"
		end

		return os.date (fmt, tm)
	end


	ENV.os.get_event = function (event)
		return coroutine.yield ("get_event", tostring (event or ""))
	end


	ENV.os.peek_event = function (event)
		return computer.peek_event (tostring (event or ""))
	end


	ENV.os.queue_event = function ( ... )
		computer.queue_event ( ... )
	end


	ENV.os.sleep = function (secs)
		coroutine.yield ("sleep", secs)
	end


	ENV.os.reboot = function ()
		coroutine.yield ("reboot")
	end


	ENV.os.shutdown = function ()
		coroutine.yield ("shutdown")
	end


	ENV.os.key_state = function (key)
		if key then
			if key == ENV.keys.KEY_CTRL then
				return computer.ctrl
			elseif key == ENV.keys.KEY_ALT then
				return computer.alt
			elseif key == ENV.keys.KEY_SHIFT then
				return computer.shift
			elseif key == ENV.keys.KEY_CAPS then
				return computer.caps
			end

			return nil
		end

		return computer.ctrl, computer.alt, computer.shift, computer.caps
	end


	ENV.os.computer_id = function ()
		return computer.computer_id ()
	end


	ENV.os.get_name = function ()
		return computer.get_name ()
	end


	ENV.os.set_name = function (name)
		return computer.set_name (name)
	end


	ENV.os.start_timer = function (secs)
		return computer.start_timer (secs)
	end


	ENV.os.kill_timer = function (tid)
		computer.kill_timer (tid)
	end


	ENV.os.chat = function (message, name)
		computer.chat (message, name)
	end


	ENV.os.copy_to_clipboard = function (contents)
		return computer.set_clipboard_contents (contents)
	end


	ENV.os.paste_from_clipboard = function ()
		return computer.get_clipboard_contends ()
	end


	ENV.os.to_worldtime = function (secs)
		return lwcomp.to_worldtime (secs)
	end


	ENV.os.to_realtime = function (secs)
		return lwcomp.to_realtime (secs)
	end


	-- security
	ENV.security = { }


	ENV.security.add_access = function (name)
		return computer.add_access (name)
	end


	ENV.security.remove_access = function (name)
		return computer.remove_access (name)
	end


	ENV.security.access_list = function ()
		return computer.access_list ()
	end


	ENV.security.owner = function ()
		return computer.owner ()
	end


	-- string

	-- thank you mesecons developers
	ENV.string.rep = function (str, n)
		if (#str * n) > lwcomp.settings.max_string_rep_size then
			error ("string.rep string too long", 2)
		end

		return string.rep (str, n)
	end


	-- thank you mesecons developers
	ENV.string.find = function (str, pattern , init)
		return string.find(str, pattern , init, true)
	end



	-- fs

	ENV.fs.remove = function (path)
		return computer.filesys:remove (path)
	end


	ENV.fs.rename = function (oldname, newname)
		return computer.filesys:rename (oldname, newname)
	end


	ENV.fs.mkdir = function (path)
		return computer.filesys:mkdir (path)
	end


	ENV.fs.ls = function (path, types)
		return computer.filesys:ls (path, types)
	end


	ENV.fs.file_type = function (path)
		return computer.filesys:file_type (path)
	end


	ENV.fs.file_size = function (path)
		return computer.filesys:file_size (path)
	end


	ENV.fs.file_exists = function (path, types)
		return computer.filesys:file_exists (path, types)
	end


	ENV.fs.get_label = function (drivepath)
		return computer.filesys:get_label (drivepath)
	end


	ENV.fs.set_label = function (drivepath, label)
		return computer.filesys:set_label (drivepath, label)
	end


	ENV.fs.get_drive_id = function (drivepath)
		return computer.filesys:get_drive_id (drivepath)
	end


	ENV.fs.copy_file = function (srcpath, destpath)
		return computer.filesys:copy_file (srcpath, destpath)
	end


	ENV.fs.path_folder = function (path)
		return computer.filesys:path_folder (path)
	end


	ENV.fs.path_name = function (path)
		return computer.filesys:path_name (path)
	end


	ENV.fs.path_extension = function (path)
		return computer.filesys:path_extension (path)
	end


	ENV.fs.path_title = function (path)
		return computer.filesys:path_title (path)
	end


	ENV.fs.abs_path = function (basepath, relpath)
		return computer.filesys:abs_path (basepath, relpath)
	end


	ENV.fs.disk_free = function (drivepath)
		return computer.filesys:get_disk_free (drivepath)
	end


	ENV.fs.disk_size = function (drivepath)
		return computer.filesys:get_disk_size (drivepath)
	end



	-- copy keys
	for k, v in pairs (lwcomp.keys) do
		ENV.keys[k] = v
	end



	-- term

	-- copy colors
	for k, v in pairs (lwcomp.colors) do
		ENV.term.colors[k] = v
	end


	ENV.term.get_cursor = function ()
		return computer.cursorx, computer.cursory
	end


	ENV.term.set_cursor = function (x, y)
		x = tonumber (x or 0)
		y = tonumber (y or 0)

		if x < 0 then
			x = 0
		end

		if x >= computer.width then
			x = computer.width - 1
		end

		if y < 0 then
			y = 0
		end

		if y >= computer.height then
			y = computer.height - 1
		end

		computer.cursorx = x
		computer.cursory = y
		computer.redraw = true
	end


	ENV.term.set_blink = function (blink)
		computer.blink = blink
		computer.redraw = true
	end


	ENV.term.get_blink = function ()
		return computer.blink
	end


	ENV.term.get_resolution = function ()
		return computer.width, computer.height
	end


	-- stores current colors
	local forecolor = lwcomp.colors.white
	local backcolor = lwcomp.colors.black

	ENV.term.get_colors = function ()
		return forecolor, backcolor
	end


	ENV.term.set_colors = function (fg, bg)
		if fg then
			fg = tonumber (fg or lwcomp.colors.white)

			forecolor = fg % 16
		end

		if bg then
			bg = tonumber (bg or lwcomp.colors.black)

			backcolor = bg % 16
		end
	end


	ENV.term.set_char = function (x, y, char, fg, bg)
		x = tonumber (x or -1)
		y = tonumber (y or -1)

		if x >= 0 and x < computer.width and y >= 0 and y < computer.height then
			local c = computer.display[(y * computer.width) + x + 1]

			if char ~= nil then
				c.char = char % 256
			end

			if fg ~= nil then
				c.fg = fg % 16
			end

			if bg ~= nil then
				c.bg = bg % 16
			end
		end

		computer.redraw = true
	end


	ENV.term.get_char = function (x, y)
		x = tonumber (x or -1)
		y = tonumber (y or -1)

		if x >= 0 and x < computer.width and y >= 0 and y < computer.height then
			local c = computer.display[(y * computer.width) + x + 1]

			return c.char, c.fg, c.bg
		end

		return nil, nil, nil
	end


	ENV.term.write = function (str, fg, bg)
		local d = computer.display
		str = tostring (str or "")
		local size = computer.width * computer.height
		local base = (computer.cursory * computer.width) + computer.cursorx

		if base < 0 then
			base = 0
		end

		if base >= size then
			return
		end

		for p = 1, str:len () do
			if (base + p) > size then
				return
			end

			local c = d[base + p]

			c.char = str:byte (p) or 0

			if fg ~= nil then
				c.fg = fg % 16
			else
				c.fg = forecolor
			end

			if bg ~= nil then
				c.bg = bg % 16
			else
				c.bg = backcolor
			end
		end

		computer.redraw = true
	end


	ENV.term.blit = function (buff, x, y, w, h)
		local d = computer.display
		x = tonumber (x or 0)
		y = tonumber (y or 0)
		w = tonumber (w or computer.width)
		h = tonumber (h or computer.height)

		if w < 1 or h < 1 then
			return false, "no size"
		end

		if type (buff) ~= "table" then
			return false, "buffer not a table"
		end

		if #buff < (w * h) then
			return false, "buffer too small"
		end

		for cy = 0, h - 1 do
			for cx = 0, w - 1 do
				local sx = x + cx
				local sy = y + cy

				if sx >= 0 and sx < computer.width and sy >= 0 and sy < computer.height then
					local c = d[(sy * computer.width) + sx + 1]
					local b = buff[(cy * w) + cx + 1]

					if type (b) == "table" then
						c.char = (b.char or 0) % 256
						c.fg = (b.fg or lwcomp.colors.white) % 16
						c.bg = (b.bg or lwcomp.colors.black) % 16
					end
				end
			end
		end

		computer.redraw = true

		return true
	end


	ENV.term.cache = function (x, y, w, h)
		local buff = { }
		local d = computer.display
		x = tonumber (x or 0)
		y = tonumber (y or 0)
		w = tonumber (w or computer.width)
		h = tonumber (h or computer.height)

		if w < 1 or h < 1 then
			return nil
		end

		for cy = 0, h - 1 do
			for cx = 0, w - 1 do
				local sx = x + cx
				local sy = y + cy

				if sx >= 0 and sx < computer.width and sy >= 0 and sy < computer.height then
					local c = d[(sy * computer.width) + sx + 1]

					buff[(cy * w) + cx + 1] =
					{
						char = c.char,
						fg = c.fg,
						bg = c.bg
					}
				else
					-- if not defined leave transparent
					buff[(cy * w) + cx + 1] = 0
				end
			end
		end

		return buff
	end


	ENV.term.clear = function (char, fg, bg, x, y, w, h)
		local d = computer.display

		char = ((char or 0) % 256)
		fg = fg or forecolor
		bg = bg or backcolor
		x = tonumber (x or 0) or 0
		y = tonumber (y or 0) or 0
		w = tonumber (w or computer.width) or computer.width
		h = tonumber (h or computer.height) or computer.height

		for cy = 0, h - 1 do
			for cx = 0, w - 1 do
				local sx = x + cx
				local sy = y + cy

				if sx >= 0 and sx < computer.width and sy >= 0 and sy < computer.height then
					local c = d[(sy * computer.width) + sx + 1]

					c.char = char
					c.fg = fg
					c.bg = bg
				end
			end
		end

		computer.redraw = true
	end


	ENV.term.scroll = function (lines, x, y, w, h)
		local d = computer.display

		lines = tonumber (lines or 0) or 0
		x = tonumber (x or 0) or 0
		y = tonumber (y or 0) or 0
		w = tonumber (w or computer.width) or computer.width
		h = tonumber (h or computer.height) or computer.height

		if x < 0 then
			w = w + x
			x = 0
		end

		if y < 0 then
			h = h + y
			y = 0
		end

		if (x + w) > computer.width then
			w = computer.width - x
		end

		if (y + h) > computer.height then
			h = computer.height - y
		end

		if w > 0 and h > 0 then
			if lines > 0 then
				for cy = (h - 1), 0, -1 do
					for cx = 0, w - 1 do
						local mx = x + cx
						local ry = y + cy
						local wy = y + cy + lines

						if wy < computer.height then
							local r = d[(ry * computer.width) + mx + 1]
							local wr = d[(wy * computer.width) + mx + 1]

							wr.char = r.char
							wr.fg = r.fg
							wr.bg = r.bg
						end
					end
				end

				computer.redraw = true

			elseif lines < 0 then
				for cy = 0, h - 1 do
					for cx = 0, w - 1 do
						local mx = x + cx
						local ry = y + cy
						local wy = y + cy + lines

						if wy >= 0 then
							local r = d[(ry * computer.width) + mx + 1]
							local wr = d[(wy * computer.width) + mx + 1]

							wr.char = r.char
							wr.fg = r.fg
							wr.bg = r.bg
						end
					end
				end

				computer.redraw = true
			end
		end
	end


	local function print_raw (fmt, ... )
		local result, str = pcall (string.format, fmt, ... )

		if not result then
			error (str, 3)
		end

		local x = computer.cursorx
		local y = computer.cursory
		local d = computer.display

		if x >= computer.width then
			x = 0
			y = y + 1
		end

		while y >= computer.height do
			ENV.term.scroll (-1)
			y = y - 1
			ENV.term.clear (0, lwcomp.colors.white, lwcomp.colors.black,
								 0, computer.height - 1, computer.width, 1)
		end

		for p = 1, str:len () do
			local char = str:byte (p)

			if char == 10 then
				x = 0
				y = y + 1
			elseif char == 13 then
				x = 0
			else
				local c = d[(y * computer.width) + x + 1]
				c.char = char
				c.fg = forecolor
				c.bg = backcolor
				x = x + 1
			end

			if x >= computer.width then
				x = 0
				y = y + 1
			end

			while y >= computer.height do
				ENV.term.scroll (-1)
				y = y - 1
				ENV.term.clear (0, lwcomp.colors.white, lwcomp.colors.black,
									 0, computer.height - 1, computer.width, 1)
			end
		end

		computer.cursorx = x
		computer.cursory = y
		computer.redraw = true
	end


	ENV.term.print = function (fmt, ... )
		print_raw (fmt, ... )
	end


	ENV.term.redraw = function (force)
		computer.redraw_formspec (force)
	end


	ENV.term.invalidate = function ()
		computer.redraw = true
	end



	-- utils

	ENV.utils.serialize = function (data)
		return minetest.serialize (data)
	end


	ENV.utils.deserialize = function (str)
		return minetest.deserialize (str)
	end


	ENV.utils.parse_json = function (str, nullvalue)
		return minetest.parse_json (str, nullvalue)
	end


	ENV.utils.write_json = function (data, styled)
		return minetest.write_json (data, styled)
	end


	ENV.utils.compress = function (data, method, ... )
		return minetest.compress (data, method, ... )
	end


	ENV.utils.decompress = function (compressed_data, method, ... )
		return minetest.decompress (compressed_data, method, ... )
	end


	ENV.utils.dump = function (obj, name, dumped)
		return dump2 (obj, name, dumped)
	end



	-- wireless

	ENV.wireless.send_message = function (msg, target_id)
		return computer.send_message (msg, target_id)
	end


	ENV.wireless.lookup_name = function (id)
		return computer.name_from_id (id)
	end


	ENV.wireless.lookup_id = function (name)
		return computer.id_from_name (name)
	end



	-- globals

	ENV.load = function (func, chunkname)
		local fxn, msg = load (func, chunkname)

		if not fxn then
			return fxn, msg
		end

		setfenv (fxn, ENV)

		if jit then
			jit.off (fxn, true)
		end

		return fxn
	end


	ENV.loadstring = function (str, chunkname)
		local fxn, msg = loadstring (str, chunkname)

		if not fxn then
			return fxn, msg
		end

		setfenv (fxn, ENV)

		if jit then
			jit.off (fxn, true)
		end

		return fxn
	end


	ENV.loadfile = function (filename)
		filename = tostring (filename or "")

		if filename:len () < 1 then
			return nil, "no path"
		end

		local file = ENV.io.open (filename, "r")

		if not file then
			return nil, "no open"
		end

		local src = file:read ("*a")
		file:close ()

		if not src then
			return nil, "no read"
		end

		return ENV.loadstring (src, filename)
	end


	ENV.dofile = function (filename)
		local fxn, msg = ENV.loadfile (filename)

		if not fxn then
			ENV.error (msg)
		end

		return fxn ()
	end


	ENV.print = function (fmt, ... )
		print_raw (fmt, ... )
	end



	-- digilines

	ENV.digilines.supported = function ()
		return computer.digilines_supported ()
	end


	ENV.digilines.get_channel = function ()
		return computer.digilines_get_channel ()
	end


	ENV.digilines.set_channel = function (channel)
		computer.digilines_set_channel (channel)
	end


	ENV.digilines.send = function (channel, msg)
		computer.digilines_send (channel, msg)
	end



	-- mesecons

	ENV.mesecons.supported = function ()
		return computer.mesecons_supported ()
	end


	ENV.mesecons.get = function (side)
		return computer.mesecons_get (side)
	end


	ENV.mesecons.set = function (state, side)
		computer.mesecons_set (state, side)
	end



	-- http

	ENV.http.fetch = function (request)
		return lwcomp.http_fetch (request, computer)
	end


	ENV.http.get = function (url, timeout, extra_headers, user_agent)
		url = tostring (url or "")
		timeout = tonumber (timeout or 3)

		local request =
		{
			url = url,
			timeout = tonumber (timeout or 3),
			method = "GET",
			extra_headers = extra_headers,
			user_agent = user_agent
		}

		local result, msg = ENV.http.fetch (request)

		if result then
			if not result.completed then
				return nil, "incomplete"
			end

			if result.timeout then
				return nil, "timed out"
			end

			if result.succeeded then
				return result.data, result.code
			end

			return nil, result.code or "request failed"
		end

		return nil, msg
	end



	-- printer

	ENV.printer.start_page = function (channel, title, pageno)
		title = tostring (title or "untitled")
		pageno = tonumber (pageno or 0) or 0

		if title:len () < 1 then
			title = "untitled"
		end

		if pageno > 1 then
			title = title.." "..tostring (pageno)
		end

		computer.digilines_send (channel, "start:"..title)
	end


	ENV.printer.end_page = function (channel)
		computer.digilines_send (channel, "end")
	end


	ENV.printer.color = function (channel, fg, bg)
		fg = (tonumber (fg) or lwcomp.colors.black) % 16
		bg = (tonumber (bg) or lwcomp.colors.white) % 16

		computer.digilines_send (channel, "color:"..tostring (fg)..","..tostring (bg))
	end


	ENV.printer.position = function (channel, x, y)
		x = tonumber (x or 0) or 0
		y = tonumber (y or 0) or 0

		computer.digilines_send (channel, "position:"..tostring (x)..","..tostring (y))
	end


	ENV.printer.write = function (channel, str)
		str = tostring (str or "")

		computer.digilines_send (channel, "write:"..str)
	end


	ENV.printer.query_ink = function (channel)
		if lwcomp.digilines_supported then
			computer.digilines_send (channel, "ink")

			local stamp = ENV.os.clock ()
			while (ENV.os.clock () - stamp) < 1.0 do
				if ENV.os.peek_event ("digilines") then
					local event = { ENV.os.get_event ("digilines") }

					if event[3] == channel then
						return tonumber (event[2] or 0) or 0
					else
						ENV.os.queue_event (unpack (event))
					end
				end

				ENV.os.sleep (0.1)
			end
		end

		return nil
	end


	ENV.printer.query_pages = function (channel)
		if lwcomp.digilines_supported then
			computer.digilines_send (channel, "pages")

			local stamp = ENV.os.clock ()
			while (ENV.os.clock () - stamp) < 1.0 do
				if ENV.os.peek_event ("digilines") then
					local event = { ENV.os.get_event ("digilines") }

					if event[3] == channel then
						return tonumber (event[2] or 0) or 0
					else
						ENV.os.queue_event (unpack (event))
					end
				end

				ENV.os.sleep (0.1)
			end
		end

		return nil
	end


	ENV.printer.query_paper = function (channel)
		if lwcomp.digilines_supported then
			computer.digilines_send (channel, "paper")

			local stamp = ENV.os.clock ()
			while (ENV.os.clock () - stamp) < 1.0 do
				if ENV.os.peek_event ("digilines") then
					local event = { ENV.os.get_event ("digilines") }

					if event[3] == channel then
						return tonumber (event[2] or 0) or 0
					else
						ENV.os.queue_event (unpack (event))
					end
				end

				ENV.os.sleep (0.1)
			end
		end

		return nil
	end


	ENV.printer.query_size = function (channel)
		if lwcomp.digilines_supported then
			computer.digilines_send (channel, "size")

			local stamp = ENV.os.clock ()
			while (ENV.os.clock () - stamp) < 1.0 do
				if ENV.os.peek_event ("digilines") then
					local event = { ENV.os.get_event ("digilines") }

					if event[3] == channel then
						local res = string.split (event[2] or "0,0")

						return (tonumber (res[1] or 0) or 0), (tonumber (res[2] or 0) or 0)
					else
						ENV.os.queue_event (unpack (event))
					end
				end

				ENV.os.sleep (0.1)
			end
		end

		return nil
	end


	ENV.printer.query_status = function (channel)
		if lwcomp.digilines_supported then
			computer.digilines_send (channel, "status")

			local stamp = ENV.os.clock ()
			while (ENV.os.clock () - stamp) < 1.0 do
				if ENV.os.peek_event ("digilines") then
					local event = { ENV.os.get_event ("digilines") }

					if event[3] == channel then
						return event[2]
					else
						ENV.os.queue_event (unpack (event))
					end
				end

				ENV.os.sleep (0.1)
			end
		end

		return nil
	end


	-- robot

	if computer.robot then
		ENV.robot = { }

		local sides = { "up", "down",
							 "front", "front_up", "front_down",
							 "back", "back_up", "back_down",
							 "left", "left_up", "left_down",
							 "right", "right_up", "right_down" }
		for s = 1, #sides do
			ENV.robot["detect_"..sides[s]] = function ()
				return computer.detect (sides[s])
			end

			ENV.robot["move_"..sides[s]] = function ()
				return computer.move (sides[s])
			end

			ENV.robot["dig_"..sides[s]] = function ()
				return computer.dig (sides[s])
			end

			ENV.robot["place_"..sides[s]] = function (nodename, dir)
				return computer.place (sides[s], nodename, dir)
			end

			ENV.robot["put_"..sides[s]] = function (item, listname)
				return computer.put (sides[s], item, listname)
			end

			ENV.robot["pull_"..sides[s]] = function (item, listname)
				return computer.pull (sides[s], item, listname)
			end
		end

		ENV.robot.turn_left = function ()
			return computer.turn ("left")
		end

		ENV.robot.turn_right = function ()
			return computer.turn ("right")
		end

		ENV.robot.contains = function (nodename)
			return computer.contains (nodename)
		end

		ENV.robot.slots = function ()
			return computer.slots ()
		end

		ENV.robot.slot = function (slot)
			return computer.slot (slot)
		end

		ENV.robot.craft = function (item)
			return computer.craft (item)
		end

		ENV.robot.find_inventory = function (listname)
			return computer.find_inventory (listname)
		end

		ENV.robot.drop = function (item)
			return computer.remove_item (item, true)
		end

		ENV.robot.trash = function (item)
			return computer.remove_item (item, false)
		end

		ENV.robot.room_for = function (item)
			return computer.room_for (item)
		end

		ENV.robot.cur_pos = function ()
			return computer.cur_pos ()
		end
	end


	-- monitor support

	ENV.monitor = { }

	ENV.monitor.interface = function (channel)
		if lwcomp.digilines_supported then
			return lwcomputers.get_monitor_interface (computer.pos, channel)
		end

		return nil
	end

	ENV.monitor.multi_interface = function (width, height, ... )
		if lwcomp.digilines_supported then
			return lwcomputers.get_multimonitor_interface (computer.pos, width, height, ... )
		end

		return nil
	end

	ENV.monitor.format_character = function (ascii, fg, bg)
		if lwcomp.digilines_supported then
			return lwcomputers.format_character (ascii, fg, bg)
		end

		return nil
	end

	ENV.monitor.unformat_character = function (character)
		if lwcomp.digilines_supported then
			return lwcomputers.unformat_character (character)
		end

		return nil
	end


	-- wires support

	ENV.wires = { }


	ENV.wires.supported = function ()
		return computer.wires_supported ()
	end


	ENV.wires.current_state = function (side)
		local cur = computer.wires_current_state (side)

		if cur["white"] ~= nil then
			return cur
		end

		return nil
	end


	ENV.wires.wire = function (idx)
		return computer.wires_wire (idx)
	end


	ENV.wires.color_string_list = function ()
		return computer.wires_color_string_list ()
	end


	ENV.wires.is_wire_in_list = function (wire, list)
		return computer.wires_is_wire_in_list (wire, list)
	end


	ENV.wires.bundle_on = function (side, wires)
		return computer.wires_bundle_on (side, wires)
	end


	ENV.wires.bundle_off = function (side, wires)
		return computer.wires_bundle_off (side, wires)
	end


	ENV.wires.bundle_power = function (side, wires)
		return computer.wires_bundle_power (side, wires)
	end


	return ENV
end



local function get_far_node (pos)
	local node = minetest.get_node (pos)

	if node.name == "ignore" then
		minetest.get_voxel_manip ():read_from_map (pos, pos)

		node = minetest.get_node (pos)

		if node.name == "ignore" then
			return nil
		end
	end

	return node
end



local function get_mesecon_rule_for_side (pos, param2, side)
	local base

	if side == "up" then
		return { { x = 0, y = 1, z = 0 } }
	elseif side == "left" then
		base = { x = 1, y = 0, z = 0 }
	elseif side == "right" then
		base = { x = -1, y = 0, z = 0 }
	elseif side == "front" then
		base = { x = 0, y = 0, z = -1 }
	elseif side == "back" then
		base = { x = 0, y = 0, z = 1 }
	else
		return nil
	end

	local rule

	if param2 == 3 then -- -x
		rule = { x = base.z * -1, y = 0, z = base.x }
	elseif param2 == 1 then -- -z
		rule = { x = base.x * -1, y = 0, z = base.z * -1 }
	elseif param2 == 4 then -- +x
		rule = { x = base.z, y = 0, z = base.x * -1 }
	else -- param2 == 2 -- +z
		rule = { x = base.x, y = 0, z = base.z }
	end

	return { rule }
end



local function get_robot_side (pos, param2, side)
	local base

	if side == "up" then
		return { x = pos.x, y = pos.y + 1, z = pos.z }
	elseif side == "down" then
		return { x = pos.x, y = pos.y - 1, z = pos.z }
	elseif side == "left" then
		base = { x = -1, y = pos.y, z = 0 }
	elseif side == "left_up" then
		base = { x = -1, y = pos.y + 1, z = 0 }
	elseif side == "left_down" then
		base = { x = -1, y = pos.y - 1, z = 0 }
	elseif side == "right" then
		base = { x = 1, y = pos.y, z = 0 }
	elseif side == "right_up" then
		base = { x = 1, y = pos.y + 1, z = 0 }
	elseif side == "right_down" then
		base = { x = 1, y = pos.y - 1, z = 0 }
	elseif side == "front" then
		base = { x = 0, y = pos.y, z = 1 }
	elseif side == "front_up" then
		base = { x = 0, y = pos.y + 1, z = 1 }
	elseif side == "front_down" then
		base = { x = 0, y = pos.y - 1, z = 1 }
	elseif side == "back" then
		base = { x = 0, y = pos.y, z = -1 }
	elseif side == "back_up" then
		base = { x = 0, y = pos.y + 1, z = -1 }
	elseif side == "back_down" then
		base = { x = 0, y = pos.y - 1, z = -1 }
	else
		return nil
	end

	if param2 == 3 then -- +x
		return { x = base.z + pos.x, y = base.y, z = (base.x * -1) + pos.z }
	elseif param2 == 0 then -- -z
		return { x = (base.x * -1) + pos.x, y = base.y, z = (base.z * -1) + pos.z }
	elseif param2 == 1 then -- -x
		return { x = (base.z * -1) + pos.x, y = base.y, z = base.x + pos.z }
	elseif param2 == 2 then -- +z
		return { x = base.x + pos.x, y = base.y, z = base.z + pos.z }
	end

	return nil
end



local function get_place_dir (itemname, robot_pos, robot_param2, dir, pallet_index)
	if dir then
		local side_pos = get_robot_side (robot_pos, robot_param2, dir)

		if side_pos then
			local vdir = vector.subtract (side_pos, robot_pos)
			local def = lwcomp.find_item_def (itemname)

			if def and def.paramtype2 then
				if def.paramtype2 == "wallmounted" or
					def.paramtype2 == "colorwallmounted" then

					return minetest.dir_to_wallmounted (vdir) + (pallet_index * 8)

				elseif def.paramtype2 == "facedir" or
						 def.paramtype2 == "colorfacedir" then

					return minetest.dir_to_facedir (vdir, false) + (pallet_index * 32)

				elseif def.paramtype2 == "color" then
					return pallet_index

				end
			end
		end
	end

	return 0
end



local function get_robot_side_vector (param2, side)
	local dir = minetest.facedir_to_dir (param2)

	if side == "up" then
		return { x = 0, y = 1, z = 0 }
	elseif side == "down" then
		return { x = 0, y = -1, z = 0 }
	elseif side == "left" then
		return vector.rotate (dir, { x = 0, y = (math.pi * 1.5), z = 0 })
	elseif side == "right" then
		return vector.rotate (dir, { x = 0, y = (math.pi * 0.5), z = 0 })
	elseif side == "back" then
		return dir
	else --if side == "front" then
		return vector.rotate (dir, { x = 0, y = math.pi, z = 0 })
	end
end



local function get_computer_side_name (pos, param2, side_pos)
	local side = vector.round (vector.subtract (side_pos, pos))
	local dir = minetest.facedir_to_dir (param2)

	if vector.equals (side, { x = 0, y = 1, z = 0 }) then
		return "up"
	elseif vector.equals (side, { x = 0, y = -1, z = 0 }) then
		return "down"
	elseif vector.equals (side, vector.round (vector.rotate (dir, { x = 0, y = (math.pi * 1.5), z = 0 }))) then
		return "left"
	elseif vector.equals (side, vector.round (vector.rotate (dir, { x = 0, y = (math.pi * 0.5), z = 0 }))) then
		return "right"
	elseif vector.equals (side, dir) then
		return "back"
	elseif vector.equals (side, vector.round (vector.rotate (dir, { x = 0, y = math.pi, z = 0 }))) then
		return "front"
	end

	return nil
end



local function get_palette_index (itemstack)
	local stack = ItemStack (itemstack)
	local color = 0

	if stack then
		local tab = stack:to_table ()

		if tab and tab.meta and tab.meta.palette_index then
			color = tonumber (tab.meta.palette_index) or 240
		end
	end

	return color
end



function lwcomp.new_computer (computer_pos, computer_id, computer_persists, robot)
	local computer =
	{
		id = computer_id,
		pos =  vector.new (computer_pos),
		robot = robot,
		width = lwcomp.settings.term_hres,
		height = lwcomp.settings.term_vres,
		cursorx = 0,
		cursory = 0,
		blink = false,
		redraw = false,
		suspend_redraw = false,
		clicked = { x = -1, y = -1 },
		clicked_when = -20,
		click_count = 0,
		running = false,
		clock_base = 0,
		thread = nil,
		yielded = "dead",
		resumed_at = 0,
		sleep_secs = 0,
		sleep_start = 0,
		event_name = "",
		caps = false,
		shift = false,
		ctrl = false,
		alt = false,
		persists = computer_persists,
		filesys = { },
		display = { },
		events = { },
		timers = { },
		ENV = { }
	}

	-- setup display
	for c = 0, (computer.width * computer.height) - 1 do
		computer.display[c + 1] =
		{
			bg = lwcomp.colors.black,
			fg = lwcomp.colors.silver,
			char = 0
		}
	end


	computer.filesys = lwcomp.filesys:new (computer_id, computer_pos)


	computer.ENV = new_computer_env (computer)


	computer.redraw_formspec = function (force)
		if not computer.suspend_redraw and (computer.redraw or force) then
			local meta = minetest.get_meta (computer.pos)

			meta:set_string("formspec", lwcomp.term_formspec (computer))

			computer.redraw = false
		end
	end


	computer.update_formspec = function ()
		if computer.running and computer.thread then
			computer.redraw = true
		else
			computer.redraw_formspec (true)
		end
	end


	computer.queue_event = function ( ... )
		local args = { ... }

		if computer.running and computer.thread then
			args[1] = tostring (args[1] or "")

			if args[1]:len () > 0 then
				computer.events[#computer.events + 1] = args
			end
		end
	end


	computer.peek_event = function (event)
		if #computer.events > 0 then
			if event:len () > 0 then
				for i = 1, #computer.events do
					if computer.events[i][1] == event then
						return unpack (computer.events[i])
					end
				end

			else
				return unpack (computer.events[1])

			end
		end

		return nil
	end


	-- hook callback
	computer.overrun = function ()
		if (minetest.get_us_time () - computer.resumed_at) > lwcomp.settings.max_no_yield_Msecs then
			debug.sethook ()
			error ("too long without yielding", 100)
		end
	end


	computer.tick = function ()
		if computer.running and computer.thread then

			for k, v in pairs (computer.timers) do
				if v <= minetest.get_us_time() then
					computer.queue_event ("timer", tonumber (k))
					computer.timers[k] = nil
				end
			end

			if coroutine.status (computer.thread) == "suspended" then
				local run = false
				local result, yielded, param; --, sleep_secs, event_name;

				if computer.yielded == "get_event" then
					if #computer.events > 0 then

						if computer.event_name:len () > 0 then
							for  i = 1, #computer.events do
								if computer.events[i][1] == computer.event_name then
									local event = table.remove (computer.events, i)
									run = true

									computer.resumed_at = minetest.get_us_time ()
									debug.sethook (computer.thread, computer.overrun, "", 10000)

									result, yielded, param = coroutine.resume (computer.thread, unpack (event))

									debug.sethook ()

									break
								end
							end
						else
							local event = table.remove (computer.events, 1)
							run = true

							computer.resumed_at = minetest.get_us_time ()
							debug.sethook (computer.thread, computer.overrun, "", 10000)

							result, yielded, param = coroutine.resume (computer.thread, unpack (event))

							debug.sethook ()
						end

					end

				elseif computer.yielded == "sleep" then
					if ((minetest.get_us_time () - computer.sleep_start) / 1000000.0) >= computer.sleep_secs then
						run = true

						computer.resumed_at = minetest.get_us_time ()
						debug.sethook (computer.thread, computer.overrun, "", 10000)

						result, yielded, param = coroutine.resume (computer.thread)

						debug.sethook ()
					end

				elseif computer.yielded == "http_result" then
					run = true

					computer.resumed_at = minetest.get_us_time ()
					debug.sethook (computer.thread, computer.overrun, "", 10000)

					result, yielded, param = coroutine.resume (computer.thread, true)

					debug.sethook ()

				elseif computer.yielded == "booting" then
					run = true

					computer.resumed_at = minetest.get_us_time ()
					debug.sethook (computer.thread, computer.overrun, "", 10000)

					result, yielded, param = coroutine.resume (computer.thread)

					debug.sethook ()

				elseif computer.yielded == "http_fetch" then
					if (minetest.get_us_time () - computer.resumed_at) > 31000000 then
						computer.timed_out = true
						run = true

						computer.resumed_at = minetest.get_us_time ()
						debug.sethook (computer.thread, computer.overrun, "", 10000)

						result, yielded, param = coroutine.resume (computer.thread, false, "timed out")

						debug.sethook ()
					end
				end

				if run then
					if result then
						computer.yielded = yielded
						computer.sleep_secs = tonumber (param or 0) or 0
						computer.sleep_start = minetest.get_us_time ()
						computer.event_name = tostring (param or "")

						if computer.yielded == "dead" then
							computer.thread = nil
							minetest.get_node_timer (computer.pos):stop ()
						elseif computer.yielded == "reboot" then
							computer.reboot ()
						elseif computer.yielded == "shutdown" then
							computer.shutdown (true)
						end

					else
						computer.thread = nil
						computer.yielded = "dead"
						computer.ENV.term.set_colors (lwcomp.colors.red, lwcomp.colors.black)
						computer.ENV.term.print ("Error: %s\n", yielded)
						computer.redraw = true
					end
				end
			end
		end

		computer.redraw_formspec ()
	end


	computer.startup = function ()
		local timer = minetest.get_node_timer (computer.pos)

		timer:stop ()

		-- create hdd if not yet
		lwcomp.filesys:create_hdd (computer.id)

		computer.ENV.term.clear ()
		computer.ENV.term.set_cursor (0, 0)
		computer.ENV.term.set_blink (true)
		computer.ENV.term.set_colors (lwcomp.colors.silver, lwcomp.colors.black)

		-- boot
		local src = computer.filesys:get_boot_file ()

		if src then
			local fxn, status = loadstring (src, "boot")

			if not fxn then
				computer.ENV.term.set_colors (lwcomp.colors.red, lwcomp.colors.black)
				computer.ENV.term.print ("Error: %s\n", status)
				computer.redraw_formspec (true)
			else
				status = "dead"
				setfenv (fxn, computer.ENV)

				computer.yielded = "dead"

				local container = function ()
					local result, msg = pcall (fxn)

					if not result then
						computer.ENV.term.set_colors (lwcomp.colors.red, lwcomp.colors.black)
						computer.ENV.term.print ("Error: %s\n", msg)
						computer.ENV.term.redraw ()
					end

					return "dead"
				end

				if jit then
					jit.off (fxn, true)
				end

				computer.thread = coroutine.create (container)

				if computer.thread then
					status = coroutine.status (computer.thread)

					if status == "suspended" then
						computer.yielded = "booting"
						computer.sleep_secs = 0
						computer.sleep_start = 0
						minetest.get_meta (computer.pos):set_int ("running", 1)
						computer.clock_base = minetest.get_us_time ()

						timer:start (lwcomp.settings.running_tick)
					end
				end

				if status ~= "suspended" then
					computer.thread = nil
					computer.yielded = "dead"
					computer.ENV.term.set_colors (lwcomp.colors.red, lwcomp.colors.black)
					computer.ENV.term.print ("Error: could not start thread\n")
					computer.redraw_formspec (true)
				end
			end
		else
			computer.ENV.term.print ("No boot media ...\n")
			computer.redraw_formspec (true)
		end

		computer.running = true

		local node = minetest.get_node (computer.pos)
		if node then
			if computer.robot then
				node.name = "lwcomputers:computer_robot_on"
			else
				node.name = "lwcomputers:computer_on"
			end

			minetest.swap_node (computer.pos, node)
		end
	end


	computer.shutdown = function (silent)
		minetest.get_node_timer (computer.pos):stop ()

		computer.mesecons_set (false)

		computer.ENV.term.clear ()
		computer.ENV.term.set_cursor (0, 0)
		computer.ENV.term.set_blink (true)

		computer.running = false
		minetest.get_meta (computer.pos):set_int ("running", 0)
		computer.thread = nil
		computer.yielded = "dead"
		computer.cursorx = 0
		computer.cursory = 0
		computer.blink = false
		computer.caps = false
		computer.shift = false
		computer.ctrl = false
		computer.alt = false
		computer.events = { }
		computer.timers = { }
		computer.ENV = new_computer_env (computer)

		if not silent then
			computer.redraw_formspec (true)
		end

		local node = minetest.get_node (computer.pos)
		if node then
			if computer.robot then
				node.name = "lwcomputers:computer_robot"
			else
				node.name = "lwcomputers:computer"
			end

			minetest.swap_node (computer.pos, node)
		end
	end


	computer.reboot = function ()
		if computer.running then
			computer.shutdown (true)
			computer.startup ()
		end
	end


	computer.computer_id = function ()
		return minetest.get_meta (computer.pos):get_int ("lwcomputer_id")
	end


	computer.get_name = function ()
		return minetest.get_meta (computer.pos):get_string ("name")
	end


	computer.set_name = function (name)
		local meta = minetest.get_meta (computer.pos)

		if meta then
			meta:set_string ("name", tostring (name or ""))
			meta:set_string ("infotext", tostring (name or ""))
		end
	end


	computer.send_message = function (msg, target_id)
		local id = computer.computer_id ()

		return lwcomp.send_message (id, msg, target_id)
	end


	computer.name_from_id = function (id)
		return lwcomp.name_from_id (id)
	end


	computer.id_from_name = function (name)
		return lwcomp.id_from_name (name)
	end


	computer.start_timer = function (secs)
		local tid = math.random (1000000)

		computer.timers[tostring (tid)] = (minetest.get_us_time() + (secs * 1000000.0))

		return tid
	end


	computer.kill_timer = function (tid)
		computer.timers[tostring (tid)] = nil
	end


	computer.chat = function (message, name)
		if lwcomp.settings.allow_chat then
			local meta = minetest.get_meta (computer.pos)
			local player = tostring (name or "")

			message = tostring (message or "")

			if meta then
				local owner = meta:get_string ("owner")

				if owner:len () > 0 then
					if player:len () > 0 and player ~= owner then
						local access = computer.access_list ()

						if access then
							for i = 1, #access do
								if access[i] == player then
									local msg = string.format ("<%s %d> %s",
																		owner,
																		computer.computer_id (),
																		message)

									minetest.chat_send_player (player, msg)
									break
								end
							end
						end

					else
						minetest.chat_send_player (owner, message)
					end

				elseif lwcomp.settings.public_chat then
					if player:len () > 0 then
						minetest.chat_send_player (player, message)
					else
						minetest.chat_send_all (message)
					end

				end
			end
		end
	end


	computer.add_access = function (name)
		local meta = minetest.get_meta (computer.pos)

		if meta then
			local owner = meta:get_string ("owner")

			if owner:len () > 0 then
				local access = meta:get_string ("access_by")
				local list = { }

				if access:len () > 0 then
					list = minetest.deserialize (access)
				end

				list[name] = true

				meta:set_string ("access_by", minetest.serialize (list))

				return true
			end
		end

		return false
	end


	computer.remove_access = function (name)
		local meta = minetest.get_meta (computer.pos)

		if meta then
			local owner = meta:get_string ("owner")

			if owner:len () > 0 then
				local access = meta:get_string ("access_by")
				local list = { }

				if access:len () > 0 then
					list = minetest.deserialize (access)
				end

				list[name] = nil

				meta:set_string ("access_by", minetest.serialize (list))

				return true
			end
		end

		return false
	end


	computer.access_list = function ()
		local meta = minetest.get_meta (computer.pos)

		if meta then
			local owner = meta:get_string ("owner")

			if owner:len () > 0 then
				local access = meta:get_string ("access_by")
				local list = { }
				local result = { }

				if access:len () > 0 then
					list = minetest.deserialize (access)
				end

				for k, v in pairs (list) do
					result[#result + 1] = k
				end

				return result
			end
		end

		return nil
	end


	computer.owner = function ()
		local meta = minetest.get_meta (computer.pos)

		if meta then
			local owner = meta:get_string ("owner")

			if owner:len () > 0 then
				return owner
			end
		end

		return nil
	end


	computer.digilines_supported = function ()
		return lwcomp.digilines_supported
	end


	computer.digilines_get_channel = function ()
		if lwcomp.digilines_supported then
			local meta = minetest.get_meta (computer.pos)

			if meta then
				return meta:get_string ("digilines_channel")
			end
		end

		return ""
	end


	computer.digilines_set_channel = function (channel)
		if lwcomp.digilines_supported then
			local meta = minetest.get_meta (computer.pos)

			if meta then
				meta:set_string ("digilines_channel", tostring (channel or ""))
			end
		end
	end


	computer.digilines_send = function (channel, msg)
		if lwcomp.digilines_supported then
			lwcomp.digilines_receptor_send (computer.pos, digiline.rules.default, channel, msg or "")
		end
	end


	computer.mesecons_supported = function ()
		return lwcomp.mesecon_supported
	end


	computer.mesecons_get = function (side)
		if lwcomp.mesecon_supported then
			local meta = minetest.get_meta (computer.pos)

			if meta then
				if side then
					return meta:get_string ("mesecon_"..side) == lwcomp.mesecon_state_on
				else
					-- any
					return meta:get_string ("mesecon_front") == lwcomp.mesecon_state_on or
							 meta:get_string ("mesecon_back") == lwcomp.mesecon_state_on or
							 meta:get_string ("mesecon_left") == lwcomp.mesecon_state_on or
							 meta:get_string ("mesecon_right") == lwcomp.mesecon_state_on or
							 meta:get_string ("mesecon_up") == lwcomp.mesecon_state_on
				end
			end
		end

		return false
	end


	computer.mesecons_set = function (state, side)
		if lwcomp.mesecon_supported then
			local meta = minetest.get_meta (computer.pos)

			if meta then
				if side then
					local rule = get_mesecon_rule_for_side (computer.pos, meta:get_int ("param2"), side)

					if rule then
						local cur_state = meta:get_string ("mesecon_"..side) == lwcomp.mesecon_state_on

						if state then
							if not cur_state then
								lwcomp.mesecon_receptor_on (computer.pos, rule)
								meta:set_string ("mesecon_"..side, lwcomp.mesecon_state_on)
							end
						else
							if cur_state then
								lwcomp.mesecon_receptor_off (computer.pos, rule)
								meta:set_string ("mesecon_"..side, lwcomp.mesecon_state_off)
							end
						end
					end

				else
					local rules = { }
					local actioned = { }
					local param2 = meta:get_int ("param2")
					local sides = { "front",  "back",  "left",  "right",   "up" }

					for i = 1, #sides do
						local cur_state = meta:get_string ("mesecon_"..sides[i]) == lwcomp.mesecon_state_on

						if state then
							if not cur_state then
								rules[#rules + 1] = get_mesecon_rule_for_side (computer.pos, param2, sides[i])[1]
								actioned[#actioned + 1] = sides[i]
							end
						else
							if cur_state then
								rules[#rules + 1] = get_mesecon_rule_for_side (computer.pos, param2, sides[i])[1]
								actioned[#actioned + 1] = sides[i]
							end
						end
					end

					if #rules then
						if state then
							lwcomp.mesecon_receptor_on (computer.pos, rules)

							for i = 1, #actioned do
								meta:set_string ("mesecon_"..actioned[i], lwcomp.mesecon_state_on)
							end
						else
							lwcomp.mesecon_receptor_off (computer.pos, rules)

							for i = 1, #actioned do
								meta:set_string ("mesecon_"..actioned[i], lwcomp.mesecon_state_off)
							end
						end
					end
				end
			end
		end
	end


	computer.get_clipboard_contends = function ()
		local meta = minetest.get_meta (computer.pos)

		if meta then
			local inv = meta:get_inventory ()

			if inv then
				local slots = inv:get_size ("main")

				for i = 1, slots do
					local stack = inv:get_stack ("main", i)

					if stack and not stack:is_empty () then
						local clipboard = lwcomp.is_clipboard (stack:get_name ())

						if clipboard then
							local imeta = stack:get_meta ()

							if imeta then
								return imeta:get_string (clipboard.contents):sub (1, clipboard.size)
							end
						end
					end
				end
			end
		end

		return nil
	end


	computer.set_clipboard_contents = function (contents)
		contents = (tostring (contents or "")):sub (1, lwcomp.settings.max_clipboard_length)

		local meta = minetest.get_meta (computer.pos)

		if meta then
			local inv = meta:get_inventory ()

			if inv then
				local slots = inv:get_size ("main")

				for i = 1, slots do
					local stack = inv:get_stack ("main", i)

					if stack and not stack:is_empty () then
						local clipboard = lwcomp.is_clipboard (stack:get_name ())

						if clipboard then
							local imeta = stack:get_meta ()

							if imeta then
								imeta:set_string (clipboard.contents, contents)
								inv:set_stack("main", i, stack)

								return true
							end
						end
					end
				end
			end
		end

		return false
	end


	computer.toggle_persists = function ()
		local meta = minetest.get_meta (computer.pos)

		if meta then
			if computer.persists then
				minetest.forceload_free_block (computer.pos, false)
				computer.persists = false
				meta:set_int ("persists", 0)
			else
				if minetest.forceload_block (computer.pos, false) then
					computer.persists = true
					meta:set_int ("persists", 1)
				end
			end
		end
	end



	-- http

	-- stores the result from callback
	computer.http_result = nil

	-- indicates if computer.tick cancelled the call
	computer.timed_out = false


	computer.http_callback = function (result)
		if not computer.timed_out then
			computer.http_result = result
			computer.yielded = "http_result"
		end
	end


	-- wires


	computer.wires_supported = function ()
		return lwcomp.wires_supported
	end


	computer.wires_queue_bundle_on = function (side_pos, wires)
		if lwcomp.wires_supported then
			local node = get_far_node (computer.pos)

			if node then
				local side = get_computer_side_name (computer.pos, node.param2, side_pos)

				if side then
					computer.queue_event ("bundle_on", side, wires)
				end
			end
		end
	end


	computer.wires_queue_bundle_off = function (side_pos, wires)
		if lwcomp.wires_supported then
			local node = get_far_node (computer.pos)

			if node then
				local side = get_computer_side_name (computer.pos, node.param2, side_pos)

				if side then
					computer.queue_event ("bundle_off", side, wires)
				end
			end
		end
	end


	computer.wires_current_state = function (side)
		local wires = { }

		if lwcomp.wires_supported then
			local sides = { ["up"] = true, ["down"] = true, ["left"] = true,
								 ["right"] = true, ["front"] = true, ["back"] = true }
			local meta = minetest.get_meta (computer.pos)

			if meta and sides[side] then
				wires = minetest.deserialize (meta:get_string ("bundle_state_"..side))

				if type (wires) ~= "table" then
					local colors = lwwires.color_string_list ()
					wires = { }

					for k, v in pairs (colors) do
						wires[v] = false
					end
				end
			end
		end

		return wires
	end


	computer.wires_set_current_state = function (side, wires, state)
		if lwcomp.wires_supported then
			local cur = computer.wires_current_state (side)
			local meta = minetest.get_meta (computer.pos)
			wires = (type (wires) == "table" and wires) or { wires }

			if meta then
				for k, v in ipairs (wires) do
					local color = lwwires.wire (v)

					if color then
						if type (color) == "string" then
							cur[color] = state
						else
							cur[v] = state
						end
					end
				end

				meta:set_string ("bundle_state_"..side, minetest.serialize (cur))

				return true
			end
		end

		return false
	end


	computer.wires_current_state_by_pos = function (side_pos)
		if lwcomp.wires_supported then
			local node = get_far_node (computer.pos)

			if node then
				local side = get_computer_side_name (computer.pos, node.param2, side_pos)

				if side then
					return computer.wires_current_state (side)
				end
			end
		end

		return { }
	end


	computer.wires_wire = function (idx)
		if lwcomp.wires_supported then
			return lwwires.wire (idx)
		end

		return nil
	end


	computer.wires_color_string_list = function ()
		if lwcomp.wires_supported then
			return lwwires.color_string_list ()
		end

		return { }
	end


	computer.wires_is_wire_in_list = function (wire, list)
		if lwcomp.wires_supported then
			return lwwires.is_wire_in_list (wire, list)
		end

		return false
	end


	computer.wires_bundle_on = function (side, wires)
		if lwcomp.wires_supported and wires then
			local sides = { ["up"] = true, ["down"] = true, ["left"] = true,
								 ["right"] = true, ["front"] = true, ["back"] = true }

			if sides[side] then
				local node = get_far_node (computer.pos)

				if node then
					local bundle_pos = get_robot_side (computer.pos, node.param2, side)

					if bundle_pos then
						if lwwires.bundle_on (computer.pos, bundle_pos, wires) then
							computer.wires_set_current_state (side, wires, true)

							return true
						end
					end
				end
			end
		end

		return false
	end


	computer.wires_bundle_off = function (side, wires)
		if lwcomp.wires_supported and wires then
			local sides = { ["up"] = true, ["down"] = true, ["left"] = true,
								 ["right"] = true, ["front"] = true, ["back"] = true }

			if sides[side] then
				local node = get_far_node (computer.pos)

				if node then
					local bundle_pos = get_robot_side (computer.pos, node.param2, side)

					if bundle_pos then
						local old = computer.wires_current_state (side)

						computer.wires_set_current_state (side, wires, false)
						if lwwires.bundle_off (computer.pos, bundle_pos, wires) then
							return true
						else
							local meta = minetest.get_meta (computer.pos)

							if meta then
								meta:set_string ("bundle_state_"..side, minetest.serialize (old))
							end
						end
					end
				end
			end
		end

		return false
	end


	computer.wires_bundle_power = function (side, wires)
		if lwcomp.wires_supported then
			local sides = { ["up"] = true, ["down"] = true, ["left"] = true,
								 ["right"] = true, ["front"] = true, ["back"] = true }

			if sides[side] then
				local node = get_far_node (computer.pos)

				if node then
					local bundle_pos = get_robot_side (computer.pos, node.param2, side)

					if bundle_pos then
						return lwwires.bundle_power (bundle_pos, wires)
					end
				end
			end
		end

		return nil
	end



	-- robot


	computer.detect = function (side)
		local node = minetest.get_node_or_nil (computer.pos)

		if node then
			local pos = get_robot_side (computer.pos, node.param2, side)

			if pos then
				node = get_far_node (pos)

				if node then
					return node.name
				end
			end
		end

		return nil
	end


	computer.move = function (side)
		local cur_node = minetest.get_node_or_nil (computer.pos)
		if not cur_node then
			return false
		end

		local pos = get_robot_side (computer.pos, cur_node.param2, side)
		if not pos then
			return false
		end

		local node = get_far_node (pos)
		if not node then
			return false
		end

		local nodedef = minetest.registered_nodes[node.name]

		if not nodedef or nodedef.walkable then
			return false
		end

		local meta = minetest.get_meta (computer.pos)
		if not meta then
			return false
		end

		local inv = meta:get_inventory ()
		if not inv then
			return false
		end

		minetest.get_node_timer (computer.pos):stop ()

		local inv_main = { }
		local slots = inv:get_size ("main")

		for i = 1, slots do
			inv_main[i] = inv:get_stack ("main", i)
		end

		local inv_storage = { }
		local stores = inv:get_size ("storage")

		for i = 1, stores do
			inv_storage[i] = inv:get_stack ("storage", i)
		end

		local id = meta:get_int ("lwcomputer_id")
		local running = meta:get_int ("running")
		local persists = meta:get_int ("persists")
		local name = meta:get_string ("name")
		local label = meta:get_string ("label")
		local infotext = meta:get_string ("infotext")
		local digilines_channel = meta:get_string ("digilines_channel")
		local formspec = meta:get_string ("formspec")
		local inventory = "{ "..
		"main = { [1] = '', [2] = '', [3] = '' }, "..
		"storage = { [1] = '', [2] = '', [3] = '', [4] = '', [5] = '', [6] = '', [7] = '', [8] = '', "..
		"            [9] = '', [10] = '', [11] = '', [12] = '', [13] = '', [14] = '', [15] = '', [16] = '', "..
		"            [17] = '', [18] = '', [19] = '', [20] = '', [21] = '', [22] = '', [23] = '', [24] = '', "..
		"            [25] = '', [26] = '', [27] = '', [28] = '', [29] = '', [30] = '', [31] = '', [32] = '' } }"

		if persists == 1 then
			minetest.forceload_free_block (computer.pos, false)
		end

		computer.mesecons_set (false)

		meta:set_int ("lwcomputer_id", 0)
		minetest.remove_node (computer.pos)

		-- update position
		lwcomp.get_computer_data (id, pos)
		minetest.add_node (pos, cur_node)

		meta = minetest.get_meta (pos)
		inv = meta:get_inventory ()

		inv:set_size ("main", 3)
		inv:set_width ("main", 3)
		inv:set_size ("storage", 32)
		inv:set_width ("storage", 8)

		meta:set_int ("lwcomputer_id", id)
		meta:set_int ("running", running)
		meta:set_int ("robot", 1)
		meta:set_int ("persists", persists)
		meta:set_string ("name", name)
		meta:set_string ("label", label)
		meta:set_string ("infotext", infotext)
		meta:set_string ("digilines_channel", digilines_channel)
		meta:set_string ("formspec", formspec)
		meta:set_string ("inventory", inventory)

		for i = 1, slots do
			if inv_main[i] then
				inv:set_stack ("main", i, inv_main[i])
			end
		end

		for i = 1, stores do
			if inv_storage[i] then
				inv:set_stack ("storage", i, inv_storage[i])
			end
		end

		if persists == 1 then
			minetest.forceload_block (pos, false)
		end

		minetest.get_node_timer (pos):start (lwcomp.settings.running_tick)

		coroutine.yield ("sleep", lwcomp.settings.robot_move_delay)

		return true
	end


	computer.turn = function (side)
		local cur_node = minetest.get_node_or_nil (computer.pos)
		if not cur_node then
			return false
		end

		if side == "left" then
			cur_node.param2 = (cur_node.param2 + 3) % 4
		elseif side == "right" then
			cur_node.param2 = (cur_node.param2 + 1) % 4
		else
			return false
		end

		minetest.swap_node(computer.pos, cur_node)

		coroutine.yield ("sleep", lwcomp.settings.robot_action_delay)

		return true
	end


	computer.dig = function (side)
		local meta = minetest.get_meta (computer.pos)
		local cur_node = minetest.get_node_or_nil (computer.pos)
		if not meta or not cur_node then
			return nil
		end

		local pos = get_robot_side (computer.pos, cur_node.param2, side)
		if not pos then
			return nil
		end

		local node = get_far_node (pos)
		if not node then
			return nil
		end

		local nodedef = minetest.registered_nodes[node.name]

		if not nodedef or not nodedef.diggable or minetest.is_protected (pos, "") or
			minetest.get_item_group (node.name, "unbreakable") > 0 then

			return nil
		end

		if nodedef.can_dig then
			local result, diggable = pcall (nodedef.can_dig, pos)

			if not result then
				if lwcomp.settings.alert_handler_errors then
					minetest.log ("error", "can_dig handler for "..node.name.." crashed - "..diggable)
				end

				return nil
			elseif diggable == false then
				return nil
			end
		end

		local inv = meta:get_inventory ()
		if not inv then
			return nil
		end

		local items = minetest.get_node_drops (node, nil)

		if items then
			local drops = { }

			for i = 1, #items do
				drops[i] = ItemStack (items[i])
			end

			if nodedef and nodedef.preserve_metadata then
				nodedef.preserve_metadata (pos, node, minetest.get_meta (pos), drops)
			end

			for i = 1, #items do
				local over = inv:add_item ("storage", drops[i])

				if over and over:get_count () > 0 then
					lwcomp.item_drop (over, nil, pos)
				end
			end
		end

		if nodedef and nodedef.sounds and nodedef.sounds.dug then
			pcall (minetest.sound_play, nodedef.sounds.dug, { pos = pos })
		end

		minetest.remove_node (pos)

		coroutine.yield ("sleep", lwcomp.settings.robot_action_delay)

		return node.name
	end


	computer.place = function (side, nodename, dir)
		nodename = tostring (nodename or "")

		if nodename:len () < 1 or nodename == "air" then
			return false
		end

		local stack = ItemStack (nodename)
		local meta = minetest.get_meta (computer.pos)
		local cur_node = minetest.get_node_or_nil (computer.pos)
		if not stack or not meta or not cur_node  then
			return false
		end

		local param2 = get_place_dir (stack:get_name (), computer.pos, cur_node.param2, dir,
												get_palette_index (stack))

		local inv = meta:get_inventory ()
		if not inv or not inv:contains_item ("storage", stack, false) then
			return false
		end

		local pos = get_robot_side (computer.pos, cur_node.param2, side)
		if not pos then
			return false
		end

		local node = get_far_node (pos)
		if not node then
			return false
		end

		local place_pos = { x = pos.x, y = pos.y, z = pos.z }

		if node.name ~= "air" then
			local nodedef = minetest.registered_nodes[node.name]

			if not nodedef or not nodedef.buildable_to or minetest.is_protected (pos, "") then
				return false
			end

			if nodedef.buildable_to then
				if dir == "up" then
					place_pos = get_robot_side (pos, cur_node.param2, "down")
				elseif dir == "down" then
					place_pos = get_robot_side (pos, cur_node.param2, "up")
				elseif dir == "back" then
					place_pos = get_robot_side (pos, cur_node.param2, "front")
				elseif dir == "right" then
					place_pos = get_robot_side (pos, cur_node.param2, "left")
				elseif dir == "left" then
					place_pos = get_robot_side (pos, cur_node.param2, "right")
				else --if dir == "front" then
					place_pos = get_robot_side (pos, cur_node.param2, "back")
				end
			end
		end

		if not inv:remove_item ("storage", stack) then
			return false
		end

		local def = lwcomp.find_item_def (stack:get_name ())
		local placed = false
		local vec = get_robot_side_vector (cur_node.param2, dir)
		local pointed_thing =
		{
			type = "node",
			under = place_pos,
			above = { x = place_pos.x - vec.x,
						 y = place_pos.y - vec.y,
						 z = place_pos.z - vec.z },
		}

		if stack:get_name ():sub (1, 8) == "farming:" then
			pointed_thing.under = { x = place_pos.x + vec.x,
											y = place_pos.y + vec.y,
											z = place_pos.z + vec.z }
			pointed_thing.above = place_pos
		end

		if lwcomp.settings.use_mod_on_place then
			if def and def.on_place then
				local result, leftover = pcall (def.on_place, stack, nil, pointed_thing)

				placed = result

				if not placed then
					if lwcomp.settings.alert_handler_errors then
						minetest.log ("error", "on_place handler for "..stack:get_name ().." crashed - "..leftover)
					end
				elseif not leftover then
					inv:add_item ("storage", stack)
				elseif leftover and leftover.get_count and leftover:get_count () > 0 then
					inv:add_item ("storage", leftover)
				end
			end
		end

		if not placed then
			local substitute = lwcomp.get_place_substitute (stack:get_name (), dir)
			local orgstack = ItemStack (stack)

			if stack:get_name () ~= substitute then
				stack = ItemStack (substitute)
				def = lwcomp.find_item_def (stack:get_name ())
			end

			if not minetest.registered_nodes[stack:get_name ()] then
				inv:add_item ("storage", orgstack)

				return false
			end

			minetest.set_node (pos, { name = stack:get_name (), param1 = 0, param2 = param2})

			if stack and def and def.after_place_node then
				local result, msg = pcall (def.after_place_node, pos, nil, stack, pointed_thing)

				if not result then
					if lwcomp.settings.alert_handler_errors then
						minetest.log ("error", "after_place_node handler for "..stack:get_name ().." crashed - "..msg)
					end
				end
			end

			if def and  def.sounds and def.sounds.place then
				pcall (minetest.sound_play, def.sounds.place, { pos = pos })
			end
		end

		coroutine.yield ("sleep", lwcomp.settings.robot_action_delay)

		return true
	end


	computer.contains = function (nodename)
		local meta = minetest.get_meta (computer.pos)
		if not meta then
			return false
		end

		local inv = meta:get_inventory ()
		local stack = ItemStack (nodename)
		if not inv or not stack then
			return false
		end

		return inv:contains_item ("storage", stack, false)
	end


	computer.room_for = function (nodename)
		local meta = minetest.get_meta (computer.pos)
		if not meta then
			return false
		end

		local inv = meta:get_inventory ()
		local stack = ItemStack (nodename)
		if not inv or not stack then
			return false
		end

		return inv:room_for_item ("storage", stack)
	end


	computer.cur_pos = function (nodename)
		return vector.new (computer.pos)
	end


	computer.slots = function ()
		local meta = minetest.get_meta (computer.pos)
		if not meta then
			return nil
		end

		local inv = meta:get_inventory ()
		if not inv then
			return nil
		end

		return inv:get_size ("storage")
	end


	computer.slot = function (slot)
		local meta = minetest.get_meta (computer.pos)
		if not meta then
			return nil
		end

		local inv = meta:get_inventory ()
		if not inv then
			return nil
		end

		local slots = inv:get_size ("storage")
		if slot < 1 or slot > slots then
			return nil
		end

		local stack = inv:get_stack ("storage", slot)
		if not stack or stack:is_empty () then
			return nil
		end

		if stack:is_empty () then
			return { name = nil, count = 0 }
		end

		return { name = stack:get_name(), count = stack:get_count() }
	end


	computer.put = function (side, item, listname)
		listname = tostring (listname or "main")
		local count = 1
		local name

		local meta = minetest.get_meta (computer.pos)
		local cur_node = minetest.get_node_or_nil (computer.pos)
		if not meta or not cur_node then
			return false
		end

		local inv = meta:get_inventory ()
		if not inv then
			return false
		end

		local pos = get_robot_side (computer.pos, cur_node.param2, side)
		if not pos then
			return false
		end

		local node = get_far_node (pos)
		if not node then
			return false
		end

		if node.name == "air" then
			return false
		end

		local imeta =  minetest.get_meta (pos)
		if not imeta then
			return false
		end

		local iinv = imeta:get_inventory ()
		if not iinv then
			return false
		end

		if type (item) == "table" then
			if type (item.name) ~= "string" then
				return false
			end

			count = tonumber (item.count or 1) or 1
			name = item.name
		else
			name = item
		end

		if type (name) == "string" then
			local stack = ItemStack ({ name = name, count = count })
			if not stack or not inv:contains_item ("storage", stack, false) then
				return false
			end

			if not iinv:room_for_item (listname, stack) then
				return false
			end

			iinv:add_item(listname, stack)
			inv:remove_item ("storage", stack)

			coroutine.yield ("sleep", lwcomp.settings.robot_action_delay)

			return true

		elseif type (name) == "number" then
			local slots = inv:get_size ("storage")
			if name < 1 or name > slots then
				return false
			end

			local stack = inv:get_stack ("storage", name)
			if not stack or stack:is_empty () then
				return false
			end

			if not iinv:room_for_item (listname, stack) then
				return false
			end

			iinv:add_item (listname, stack)
			inv:set_stack ("storage", name, nil)

			coroutine.yield ("sleep", lwcomp.settings.robot_action_delay)

			return true
		end

		return false
	end


	computer.pull = function (side, item, listname)
		listname = tostring (listname or "main")
		local count = 1
		local name

		local meta = minetest.get_meta (computer.pos)
		local cur_node = minetest.get_node_or_nil (computer.pos)
		if not meta or not cur_node then
			return false
		end

		local inv = meta:get_inventory ()
		if not inv then
			return false
		end

		local pos = get_robot_side (computer.pos, cur_node.param2, side)
		if not pos then
			return false
		end

		local node = get_far_node (pos)
		if not node then
			return false
		end

		if node.name == "air" then
			return false
		end

		local imeta =  minetest.get_meta (pos)
		if not imeta then
			return false
		end

		local iinv = imeta:get_inventory ()
		if not iinv then
			return false
		end

		if type (item) == "table" then
			if type (item.name) ~= "string" then
				return false
			end

			count = tonumber (item.count or 1) or 1
			name = item.name
		else
			name = item
		end

		if type (name) == "string" then
			local stack = ItemStack ({ name = name, count = count })
			if not stack or not iinv:contains_item (listname, stack, false) then
				return false
			end

			if not inv:room_for_item ("storage", stack) then
				return false
			end

			inv:add_item("storage", stack)
			iinv:remove_item (listname, stack)

			coroutine.yield ("sleep", lwcomp.settings.robot_action_delay)

			return true

		elseif type (name) == "number" then
			local slots = iinv:get_size (listname)
			if not slots or name < 1 or name > slots then
				return false
			end

			local stack = iinv:get_stack (listname, name)
			if not stack or stack:is_empty () then
				return false
			end

			if not inv:room_for_item ("storage", stack) then
				return false
			end

			inv:add_item ("storage", stack)
			iinv:set_stack (listname, name, nil)

			coroutine.yield ("sleep", lwcomp.settings.robot_action_delay)

			return true
		end

		return false
	end


	local function substitute_group (item, inv)
		local source = ItemStack (item)

		if item:sub (1, 6) ~= "group:" then
			return source
		end

		local group = item:sub (7)

		local slots = inv:get_size ("storage")
		for s = 1, slots do
			local stack = inv:get_stack ("storage", s)

			if stack and stack:get_count () > 0 then
				if minetest.get_item_group (stack:get_name (), group) > 0 then
					local replace = ItemStack (stack:get_name ())

					if replace then
						replace:set_count (source:get_count ())

						return replace
					end
				end
			end
		end

		return source
	end


	computer.craft = function (item)
		item = tostring (item or "")

		if item:len () < 1 then
			return false
		end

		local meta = minetest.get_meta (computer.pos)
		local inv = meta:get_inventory ()
		if not meta or not inv then
			return false
		end

		local recipes = minetest.get_all_craft_recipes(item)

		if not recipes then
			return false
		end

		for r = 1, #recipes do
			if (recipes[r].type and recipes[r].type == "normal") or
				(recipes[r].method and recipes[r].method == "normal") then

				local match = true

				local items = { }
				for i = 1, #recipes[r].items do
					if type (recipes[r].items[i]) == "string" then
						local stack = substitute_group (recipes[r].items[i], inv)

						if stack then
							if items[stack:get_name ()] then
								items[stack:get_name ()] = items[stack:get_name ()] + stack:get_count ()
							else
								items[stack:get_name ()] = stack:get_count ()
							end
						end
					end
				end

				for k, v in pairs (items) do
					local stack = ItemStack (k)

					if stack then
						stack:set_count (v)

						if not inv:contains_item ("storage", stack, false) then
							match = false
							break
						end
					end
				end

				if match then
					for k, v in pairs (items) do
						local stack = ItemStack (k)

						if stack then
							stack:set_count (v)

							inv:remove_item ("storage", stack)
						end
					end

					inv:add_item ("storage", ItemStack (recipes[r].output))

					local output, leftover = minetest.get_craft_result (recipes[r])

					if output and output.replacements and #output.replacements > 0 then
						for i = 1, #output.replacements do
							if output.replacements[i]:get_count () > 0 then
								inv:add_item ("storage", output.replacements[i])
							end
						end
					end

					if leftover and leftover.items then
						for i = 1, #leftover.items do
							if leftover.items[i]:get_count () > 0 then
								inv:add_item ("storage", leftover.items[i])
							end
						end
					end

					local mods = lwcomp.get_crafting_mods (item)
					if mods then
						if mods.add then
							for i = 1, #mods.add do
								local stack = ItemStack (mods.add[i])

								if stack and stack:get_count () > 0 then
									inv:add_item ("storage", stack)
								end
							end
						end


						if mods.remove then
							for i = 1, #mods.remove do
								local stack = ItemStack (mods.remove[i])

								if stack and stack:get_count () > 0 then
									inv:remove_item ("storage", stack)
								end
							end
						end
					end

					coroutine.yield ("sleep", lwcomp.settings.robot_action_delay)

					return true
				end
			end
		end

		return false
	end


	computer.find_inventory = function (listname)
		local result = { }
		local sides = { "up", "down",
							 "front", "front_up", "front_down",
							 "back", "back_up", "back_down",
							 "left", "left_up", "left_down",
							 "right", "right_up", "right_down" }
		local cur_node = minetest.get_node_or_nil (computer.pos)
		if not cur_node  then
			return false
		end

		if listname then
			listname = tostring (listname)
		end

		for s = 1, #sides do
			local pos = get_robot_side (computer.pos, cur_node.param2, sides[s])

			if pos then
				local node = get_far_node (pos)

				if node and node.name ~= "air" then
					local meta =  minetest.get_meta (pos)

					if meta then
						local inv = meta:get_inventory ()

						if inv then
							if listname then
								local slots = inv:get_size (listname)

								if slots and slots > 0 then
									result[#result + 1] = sides[s]
									result[sides[s]] = slots
								end
							else
								result[#result + 1] = sides[s]
								result[sides[s]] = true
							end
						end
					end
				end
			end
		end

		if #result > 0 then
			return result
		end

		return nil
	end


	computer.remove_item = function (item, drop)
		local count = 1
		local name

		local meta = minetest.get_meta (computer.pos)
		if not meta then
			return false
		end

		local inv = meta:get_inventory ()
		if not inv then
			return false
		end

		if type (item) == "table" then
			if type (item.name) ~= "string" then
				return false
			end

			count = tonumber (item.count or 1) or 1
			name = item.name
		else
			name = item
		end

		if type (name) == "string" then
			local stack = ItemStack ({ name = name, count = count })
			if not stack or not inv:contains_item ("storage", stack, false) then
				return false
			end

			inv:remove_item ("storage", stack)

			if drop then
				lwcomp.item_drop (stack, nil, computer.pos)
			else
				lwcomp.on_destroy (stack)
			end

			coroutine.yield ("sleep", lwcomp.settings.robot_action_delay)

			return true

		elseif type (name) == "number" then
			local slots = inv:get_size ("storage")
			if not slots or name < 1 or name > slots then
				return false
			end

			local stack = inv:get_stack ("storage", name)
			if not stack or stack:is_empty () then
				return false
			end

			inv:set_stack ("storage", name, nil)

			if drop then
				lwcomp.item_drop (stack, nil, computer.pos)
			else
				lwcomp.on_destroy (stack)
			end

			coroutine.yield ("sleep", lwcomp.settings.robot_action_delay)

			return true
		end

		return false
	end


	return computer
end



--
