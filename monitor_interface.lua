local lwcomp = ...
local S = lwcomp.S



if lwcomp.digilines_supported then



function lwcomputers.get_monitor_interface (pos, channel)
	local monitor = { }

	local _buffer = { }
	local _scale = 1
	local _pos = { x = pos.x, y = pos.y, z = pos.z }
	local _cur_pos = 0
	local _fg = 7
	local _bg = 0

	for y = 1, _scale * 6, 1 do
		_buffer[y] = { }

		for x = 1, _scale * 9, 1 do
			_buffer[y][x] = 0
		end
	end


	monitor.channel = function ()
		return channel
	end


	monitor.update = function ()
		digilines.receptor_send (_pos,
										 digiline.rules.default,
										 channel,
										 _buffer)
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
		_scale = math.min (math.max (tonumber (scale) or 1, 1), 5)

		local buffer = { }
		for y = 1, _scale * 6, 1 do
			buffer[y] = { }

			if type(_buffer[y]) ~= "table" then
				_buffer[y] = { }
			end

			for x = 1, _scale * 9, 1 do
				buffer[y][x] = tonumber (_buffer[y][x]) or 0
			end
		end

		_buffer = buffer

		digilines.receptor_send (_pos,
										 digiline.rules.default,
										 channel,
										 "scale:"..tostring (_scale))

		_cur_pos = 0
	end


	monitor.get_scale = function ()
		return _scale
	end


	monitor.get_resolution = function ()
		return (_scale * 9), (_scale * 6)
	end


	monitor.get_cursor = function ()
		local mw, mh = monitor.get_resolution ()
		local y = math.floor (_cur_pos / mw)
		local x = _cur_pos - math.floor (y * mw)

		return x, y
	end


	monitor.set_cursor = function (x, y)
		local mw, mh = monitor.get_resolution ()
		x = math.min (math.max (math.floor (tonumber (x) or 0), 0), mw)
		y = math.min (math.max (math.floor (tonumber (y) or 0), 0), mh)

		_cur_pos = (y * (_scale * 9)) + x
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
		x = (math.modf (x))
		y = (math.modf (y))

		if x >= 0 and x < mw and y >= 0 and y < mh then
			return lwcomputers.unformat_character (_buffer[y + 1][x + 1])
		end

		return nil
	end


	monitor.write = function (str, update)
		local mw, mh = monitor.get_resolution ()
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
		local cur_pos = _cur_pos

		for r = 0, h - 1 do
			monitor.set_cursor (x, y + r)
			monitor.write (str, false)
		end

		_cur_pos = cur_pos

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


	return monitor
end



end
