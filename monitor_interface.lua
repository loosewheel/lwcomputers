local lwcomp = ...



if lwcomp.digilines_supported then



local function fixScale (scale)
	local s = string.format ("%0.1f", scale)

	if s == "0.3" then
		return 0.3
	elseif s == "0.6" then
		return 0.6
	elseif s == "2.0" then
		return 2
	elseif s == "3.0" then
		return 3
	elseif s == "4.0" then
		return 4
	elseif s == "5.0" then
		return 5
	end

	return 1
end


local function getScaleResolution (scale)
	if scale == 0.3 then
		return 3, 2, 42
	elseif scale == 0.6 then
		return 6, 4, 84
	elseif scale == 2 then
		return 18, 12, 252
	elseif scale == 3 then
		return 27, 18, 378
	elseif scale == 4 then
		return 35, 24, 504
	elseif scale == 5 then
		return 45, 30, 630
	end

	return 9, 6, 126
end



function lwcomputers.get_monitor_interface (pos, channel)
	local monitor = { }

	local _buffer = { }
	local _scale = 1
	local _pos = { x = pos.x, y = pos.y, z = pos.z }
	local _fg = 7
	local _bg = 0
	local _cur_x = 0
	local _cur_y = 0
	local _cur_blink = false

	for y = 1, 6, 1 do
		_buffer[y] = { }

		for x = 1, 9, 1 do
			_buffer[y][x] = 0
		end
	end


	monitor.channel = function ()
		return channel
	end


	monitor.monitors = function ()
		return 1, 1
	end


	monitor.update = function ()
		local char, fg, bg

		if _cur_blink then
			char, fg, bg = monitor.get_char (_cur_x, _cur_y)

			if char then
				monitor.set_char (_cur_x, _cur_y, char, 15 - fg, 15 - bg, false)
			end
		end

		digilines.receptor_send (_pos,
										 digiline.rules.default,
										 channel,
										 table.copy (_buffer))

		if char then
			monitor.set_char (_cur_x, _cur_y, char, fg, bg, false)
		end
	end


	monitor.get_colors = function ()
		return _fg, _bg
	end


	monitor.set_colors = function (fg, bg)
		if fg then
			_fg = (tonumber (fg) or 15) % 16
		end

		if bg then
			_bg = (tonumber (bg) or 0) % 16
		end
	end


	monitor.set_scale = function (scale)
		_scale = fixScale (tonumber (scale) or 1)
		local sx, sy = getScaleResolution (_scale)

		local buffer = { }
		for y = 1, sy, 1 do
			buffer[y] = { }

			if type(_buffer[y]) ~= "table" then
				_buffer[y] = { }
			end

			for x = 1, sx, 1 do
				buffer[y][x] = tonumber (_buffer[y][x]) or 0
			end
		end

		_buffer = buffer

		digilines.receptor_send (_pos,
										 digiline.rules.default,
										 channel,
										 "scale:"..tostring (_scale))

		_cur_x = 0
		_cur_y = 0
	end


	monitor.get_scale = function ()
		return _scale
	end


	monitor.get_resolution = function ()
		local sx, sy = getScaleResolution (_scale)

		return sx, sy
	end


	monitor.get_cursor = function ()
		return _cur_x, _cur_y
	end


	monitor.set_cursor = function (x, y)
		local mw, mh = monitor.get_resolution ()
		x = math.min (math.max (math.floor (tonumber (x) or 0), 0), mw)
		y = math.min (math.max (math.floor (tonumber (y) or 0), 0), mh)

		_cur_x = x
		_cur_y = y

		if _cur_blink then
			monitor.update ()
		end
	end


	monitor.set_blink = function (blink, update)
		if _cur_blink ~= blink then
			_cur_blink = blink

			if update ~= false then
				monitor.update ()
			end
		end
	end


	monitor.get_blink = function ()
		return _cur_blink
	end


	monitor.set_char = function (x, y, char, fg, bg, update)
		local mw, mh = monitor.get_resolution ()
		x = math.floor (tonumber (x or 0) or 0)
		y = math.floor (tonumber (y or 0) or 0)

		if x >= 0 and x < mw and y >= 0 and y < mh then
			if type (char) == "string" then
				char = char:byte (1) or 0
			else
				char = math.min (math.max (tonumber (char) or 0, 0), 255)
			end

			if fg ~= nil then
				fg = (tonumber (fg) or 0) % 16
			else
				fg = _fg
			end

			if bg ~= nil then
				bg = (tonumber (bg) or 0) % 16
			else
				bg = _bg
			end

			_buffer[y + 1][x + 1] = lwcomputers.format_character (char, fg, bg)

			if update ~= false then
				monitor.update ()
			end
		end
	end


	monitor.get_char = function (x, y)
		local mw, mh = monitor.get_resolution ()
		x = (math.modf (x or -1))
		y = (math.modf (y or -1))

		if x >= 0 and x < mw and y >= 0 and y < mh then
			return lwcomputers.unformat_character (_buffer[y + 1][x + 1])
		end

		return nil
	end


	monitor.write = function (str, update)
		local mw = monitor.get_resolution ()
		local x, y = monitor.get_cursor ()

		for i = 1, str:len () do
			monitor.set_char (x, y, str:byte (i), nil, nil, false)

			x = x + 1
			if x >= mw then
				x = 0
				y = y + 1
			end
		end

		if update ~= false then
			monitor.update ()
		end
	end


	monitor.blit = function (buff, x, y, w, h, update)
		local mw, mh = monitor.get_resolution ()
		x = tonumber (x or 0) or 0
		y = tonumber (y or 0) or 0
		w = tonumber (w or mw) or mw
		h = tonumber (h or mh) or mh

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

				if sx >= 0 and sx < mw and sy >= 0 and sy < mh then
					local b = buff[(cy * w) + cx + 1]

					if type (b) == "table" then
						local char = (b.char or 0) % 256
						local fg = (b.fg or lwcomp.colors.white) % 16
						local bg = (b.bg or lwcomp.colors.black) % 16

						monitor.set_char (sx, sy, char, fg, bg, update)
					end
				end
			end
		end

		if update ~= false then
			monitor.update ()
		end

		return true
	end


	monitor.cache = function (x, y, w, h)
		local mw, mh = monitor.get_resolution ()
		local buff = { }
		x = tonumber (x or 0) or 0
		y = tonumber (y or 0) or 0
		w = tonumber (w or mw) or mw
		h = tonumber (h or mh) or mh

		if w < 1 or h < 1 then
			return nil
		end

		for cy = 0, h - 1 do
			for cx = 0, w - 1 do
				local sx = x + cx
				local sy = y + cy

				if sx >= 0 and sx < mw and sy >= 0 and sy < mh then
					local char, fg, bg = monitor.get_char (sx, sy)

					buff[(cy * w) + cx + 1] =
					{
						char = char,
						fg = fg,
						bg = bg
					}
				else
					-- if not defined leave transparent
					buff[(cy * w) + cx + 1] = 0
				end
			end
		end

		return buff
	end


	monitor.clear = function (char, x, y, w, h, update)
		local mw, mh = monitor.get_resolution ()
		x = tonumber (x or 0) or 0
		y = tonumber (y or 0) or 0
		w = tonumber (w or mw) or mw
		h = tonumber (h or mh) or mh

		if type (char) == "string" then
			char = char:sub (1, 1)

			if char:len () < 1 then
				char = "\0"
			end
		else
			char = string.char (math.min (math.max (tonumber (char) or 0, 0), 255))
		end

		if (x + w) > mw then
			w = mw - x
		end

		if (y + h) > mh then
			h = mh - y
		end

		if w < 1 or h < 1 then
			return
		end

		local str = string.rep (char, w)
		local cur_x = _cur_x
		local cur_y = _cur_y

		for r = 0, h - 1 do
			monitor.set_cursor (x, y + r)
			monitor.write (str, false)
		end

		_cur_x = cur_x
		_cur_y = cur_y

		if update ~= false then
			monitor.update ()
		end
	end


	monitor.scroll = function (lines, x, y, w, h, update)
		local mw, mh = monitor.get_resolution ()
		lines = tonumber (lines or 0) or 0
		x = tonumber (x or 0) or 0
		y = tonumber (y or 0) or 0
		w = tonumber (w or mw) or mw
		h = tonumber (h or mh) or mh

		if lines == 0 then
			return
		end

		if (x + w) > mw then
			w = mw - x
		end

		if (y + h) > mh then
			h = mh - y
		end

		if w < 1 or h < 1 then
			return
		end

		if lines > 0 then
			-- move down
			for r = h - 2, 0, -1 do
				for cx = 0, w do
					local char, fg, bg = monitor.get_char (x + cx, y + r)
					monitor.set_char (x + cx, y + r + 1, char, fg, bg, false)
				end
			end

		else
			-- move up
			for r = 1, h - 1, 1 do
				for cx = 0, w do
					local char, fg, bg = monitor.get_char (x + cx, y + r)
					monitor.set_char (x + cx, y + r - 1, char, fg, bg, false)
				end
			end
		end

		if update ~= false then
			monitor.update ()
		end
	end


	monitor.print = function (fmt, ... )
		local result, str = pcall (string.format, fmt, ... )

		if not result then
			error (str, 2)
		end

		local w, h = monitor.get_resolution ()
		local x, y = monitor.get_cursor ()

		if x >= w then
			x = 0
			y = y + 1
		end

		while y >= h do
			monitor.scroll (-1, 0, 0, w, h, false)
			y = y - 1
			monitor.clear (0, 0, h - 1, w, 1, false)
		end

		for p = 1, str:len () do
			local char = str:byte (p)

			if char == 10 then
				x = 0
				y = y + 1
			elseif char == 13 then
				x = 0
			else
				monitor.set_char (x, y, char, nil, nil, false)
				x = x + 1
			end

			if x >= w then
				x = 0
				y = y + 1
			end

			while y >= h do
				monitor.scroll (-1, 0, 0, w, h, false)
				y = y - 1
				monitor.clear (0, 0, h - 1, w, 1, false)
			end
		end

		monitor.set_cursor (x, y)
		monitor.update ()
	end


	monitor.is_touch = function (msgchannel, msg)
		if type (msg) == "string" and msg:sub (1, 6) == "touch:" and
			msgchannel == channel then

			local coords = msg:sub (7, -1):split ()

			if #coords == 2 then
				return tonumber (coords[1]), tonumber (coords[2])
			end
		end

		return nil
	end


	return monitor
end



function lwcomputers.get_multimonitor_interface (pos, width, height, ... )
	local channels = { ... }

	if #channels ~= (width * height) then
		return nil
	end

	local monitors = { }

	local _buffer = { }
	local _scale = 1
	local _pos = { x = pos.x, y = pos.y, z = pos.z }
	local _fg = 7
	local _bg = 0
	local _cur_x = 0
	local _cur_y = 0
	local _cur_blink = false
	local _invalid = { }


	local function invalidate (x, y)
		local sx, sy = getScaleResolution (_scale)

		_invalid[math.floor (y / sy) + 1][math.floor (x / sx) + 1] = true
	end


	for y = 1, 6 * height, 1 do
		_buffer[y] = { }

		for x = 1, 9 * width, 1 do
			_buffer[y][x] = 0
		end
	end


	for h = 1, height, 1 do
		_invalid[h] = { }
		for w = 1, width, 1 do
			_invalid[h][w] = true
		end
	end


	monitors.channel = function (index)
		return channels[index]
	end


	monitors.monitors = function ()
		return width, height
	end


	monitors.update = function ()
		local char, fg, bg

		if _cur_blink then
			char, fg, bg = monitors.get_char (_cur_x, _cur_y)

			if char then
				monitors.set_char (_cur_x, _cur_y, char, 15 - fg, 15 - bg, false)
			end
		end

		local sx, sy = getScaleResolution (_scale)

		for h = 1, height do
			for w = 1, width do
				if _invalid[h][w] then
					local buf = { }

					for r = 1, sy do
						buf[r] = { }

						for c = 1, sx do
							local sr = ((h - 1) * sy) + r
							local sc = ((w - 1) * sx) + c

							buf[r][c] = _buffer[sr][sc]
						end
					end

					digilines.receptor_send (_pos,
													 digiline.rules.default,
													 channels[((h - 1) * width) + w],
													 buf)
				end
			end
		end

		if char then
			monitors.set_char (_cur_x, _cur_y, char, fg, bg, false)
		end

		_invalid = { }
		for h = 1, height, 1 do
			_invalid[h] = { }
		end
	end


	monitors.get_colors = function ()
		return _fg, _bg
	end


	monitors.set_colors = function (fg, bg)
		if fg then
			_fg = (tonumber (fg) or 15) % 16
		end

		if bg then
			_bg = (tonumber (bg) or 0) % 16
		end
	end


	monitors.set_scale = function (scale)
		_scale = fixScale (tonumber (scale) or 1)
		local sx, sy = getScaleResolution (_scale)

		local buffer = { }
		for y = 1, sy * height, 1 do
			buffer[y] = { }

			if type (_buffer[y]) ~= "table" then
				_buffer[y] = { }
			end

			for x = 1, sx * width, 1 do
				buffer[y][x] = tonumber (_buffer[y][x]) or 0
			end
		end

		_buffer = buffer

		for i = 1, #channels do

			digilines.receptor_send (_pos,
											 digiline.rules.default,
											 channels[i],
											 "scale:"..tostring (_scale))
		end

		_invalid = { }
		for h = 1, height, 1 do
			_invalid[h] = { }
			for w = 1, width, 1 do
				_invalid[h][w] = true
			end
		end

		_cur_x = 0
		_cur_y = 0
	end


	monitors.get_scale = function ()
		return _scale
	end


	monitors.get_resolution = function ()
		local sx, sy = getScaleResolution (_scale)

		return (sx * width), (sy * height)
	end


	monitors.get_cursor = function ()
		return _cur_x, _cur_y
	end


	monitors.set_cursor = function (x, y)
		local mw, mh = monitors.get_resolution ()
		x = math.min (math.max (math.floor (tonumber (x) or 0), 0), mw)
		y = math.min (math.max (math.floor (tonumber (y) or 0), 0), mh)

		if _cur_blink then
			invalidate (_cur_x, _cur_y)
		end

		_cur_x = x
		_cur_y = y

		if _cur_blink then
			invalidate (_cur_x, _cur_y)
			monitors.update ()
		end
	end


	monitors.set_blink = function (blink, update)
		if _cur_blink ~= blink then
			invalidate (_cur_x, _cur_y)

			_cur_blink = blink

			if update ~= false then
				monitors.update ()
			end
		end
	end


	monitors.get_blink = function ()
		return _cur_blink
	end


	monitors.set_char = function (x, y, char, fg, bg, update)
		local mw, mh = monitors.get_resolution ()
		x = math.floor (tonumber (x or 0) or 0)
		y = math.floor (tonumber (y or 0) or 0)

		if x >= 0 and x < mw and y >= 0 and y < mh then
			if type (char) == "string" then
				char = char:byte (1) or 0
			else
				char = math.min (math.max (tonumber (char) or 0, 0), 255)
			end

			if fg ~= nil then
				fg = (tonumber (fg) or 0) % 16
			else
				fg = _fg
			end

			if bg ~= nil then
				bg = (tonumber (bg) or 0) % 16
			else
				bg = _bg
			end

			_buffer[y + 1][x + 1] = lwcomputers.format_character (char, fg, bg)

			invalidate (x, y)

			if update ~= false then
				monitors.update ()
			end
		end
	end


	monitors.get_char = function (x, y)
		local mw, mh = monitors.get_resolution ()
		x = (math.modf (x or -1))
		y = (math.modf (y or -1))

		if x >= 0 and x < mw and y >= 0 and y < mh then
			return lwcomputers.unformat_character (_buffer[y + 1][x + 1])
		end

		return nil
	end


	monitors.write = function (str, update)
		local mw = monitors.get_resolution ()
		local x, y = monitors.get_cursor ()

		for i = 1, str:len () do
			monitors.set_char (x, y, str:byte (i), nil, nil, false)

			x = x + 1
			if x >= mw then
				x = 0
				y = y + 1
			end
		end

		if update ~= false then
			monitors.update ()
		end
	end


	monitors.blit = function (buff, x, y, w, h, update)
		local mw, mh = monitors.get_resolution ()
		x = tonumber (x or 0) or 0
		y = tonumber (y or 0) or 0
		w = tonumber (w or mw) or mw
		h = tonumber (h or mh) or mh

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

				if sx >= 0 and sx < mw and sy >= 0 and sy < mh then
					local b = buff[(cy * w) + cx + 1]

					if type (b) == "table" then
						local char = (b.char or 0) % 256
						local fg = (b.fg or lwcomp.colors.white) % 16
						local bg = (b.bg or lwcomp.colors.black) % 16

						monitors.set_char (sx, sy, char, fg, bg, update)
					end
				end
			end
		end

		if update ~= false then
			monitors.update ()
		end

		return true
	end


	monitors.cache = function (x, y, w, h)
		local mw, mh = monitors.get_resolution ()
		local buff = { }
		x = tonumber (x or 0) or 0
		y = tonumber (y or 0) or 0
		w = tonumber (w or mw) or mw
		h = tonumber (h or mh) or mh

		if w < 1 or h < 1 then
			return nil
		end

		for cy = 0, h - 1 do
			for cx = 0, w - 1 do
				local sx = x + cx
				local sy = y + cy

				if sx >= 0 and sx < mw and sy >= 0 and sy < mh then
					local char, fg, bg = monitors.get_char (sx, sy)

					buff[(cy * w) + cx + 1] =
					{
						char = char,
						fg = fg,
						bg = bg
					}
				else
					-- if not defined leave transparent
					buff[(cy * w) + cx + 1] = 0
				end
			end
		end

		return buff
	end


	monitors.clear = function (char, x, y, w, h, update)
		local mw, mh = monitors.get_resolution ()
		x = tonumber (x or 0) or 0
		y = tonumber (y or 0) or 0
		w = tonumber (w or mw) or mw
		h = tonumber (h or mh) or mh

		if type (char) == "string" then
			char = char:sub (1, 1)

			if char:len () < 1 then
				char = "\0"
			end
		else
			char = string.char (math.min (math.max (tonumber (char) or 0, 0), 255))
		end

		if (x + w) > mw then
			w = mw - x
		end

		if (y + h) > mh then
			h = mh - y
		end

		if w < 1 or h < 1 then
			return
		end

		local str = string.rep (char, w)
		local cur_x = _cur_x
		local cur_y = _cur_y

		for r = 0, h - 1 do
			monitors.set_cursor (x, y + r)
			monitors.write (str, false)
		end

		_cur_x = cur_x
		_cur_y = cur_y

		if update ~= false then
			monitors.update ()
		end
	end


	monitors.scroll = function (lines, x, y, w, h, update)
		local mw, mh = monitors.get_resolution ()
		lines = tonumber (lines or 0) or 0
		x = tonumber (x or 0) or 0
		y = tonumber (y or 0) or 0
		w = tonumber (w or mw) or mw
		h = tonumber (h or mh) or mh

		if lines == 0 then
			return
		end

		if (x + w) > mw then
			w = mw - x
		end

		if (y + h) > mh then
			h = mh - y
		end

		if w < 1 or h < 1 then
			return
		end

		if lines > 0 then
			-- move down
			for r = h - 2, 0, -1 do
				for cx = 0, w do
					local char, fg, bg = monitors.get_char (x + cx, y + r)
					monitors.set_char (x + cx, y + r + 1, char, fg, bg, false)
				end
			end

		else
			-- move up
			for r = 1, h - 1, 1 do
				for cx = 0, w do
					local char, fg, bg = monitors.get_char (x + cx, y + r)
					monitors.set_char (x + cx, y + r - 1, char, fg, bg, false)
				end
			end
		end

		if update ~= false then
			monitors.update ()
		end
	end


	monitors.print = function (fmt, ... )
		local result, str = pcall (string.format, fmt, ... )

		if not result then
			error (str, 2)
		end

		local w, h = monitors.get_resolution ()
		local x, y = monitors.get_cursor ()

		if x >= w then
			x = 0
			y = y + 1
		end

		while y >= h do
			monitors.scroll (-1, 0, 0, w, h, false)
			y = y - 1
			monitors.clear (0, 0, h - 1, w, 1, false)
		end

		for p = 1, str:len () do
			local char = str:byte (p)

			if char == 10 then
				x = 0
				y = y + 1
			elseif char == 13 then
				x = 0
			else
				monitors.set_char (x, y, char, nil, nil, false)
				x = x + 1
			end

			if x >= w then
				x = 0
				y = y + 1
			end

			while y >= h do
				monitors.scroll (-1, 0, 0, w, h, false)
				y = y - 1
				monitors.clear (0, 0, h - 1, w, 1, false)
			end
		end

		monitors.set_cursor (x, y)
		monitors.update ()
	end


	monitors.is_touch = function (channel, msg)
		if type (msg) == "string" and msg:sub (1, 6) == "touch:" then
			for i = 1, #channels do
				if channels[i] == channel then
					local coords = msg:sub (7, -1):split ()

					if #coords == 2 then
						local x = tonumber (coords[1])
						local y = tonumber (coords[2])
						local sx, sy = getScaleResolution (_scale)

						local mx = ((i - 1) % width) * sx
						local my = math.floor ((i - 1) / width) * sy

						return (x + mx), (y + my)
					end
				end
			end
		end

		return nil
	end


	return monitors
end



end
