local http_api = ...

local S = lwcomputers.S


-- settings
local term_hres = tonumber(minetest.settings:get("lwcomputers_term_hres") or 50)
local term_vres = tonumber(minetest.settings:get("lwcomputers_term_vres") or 19)
local running_tick = tonumber(minetest.settings:get("lwcomputers_running_tick") or 0.1)
local click_events = minetest.settings:get_bool("lwcomputers_click_events", true)
local double_click_time = tonumber(minetest.settings:get("lwcomputers_double_click_time") or 0.5)
-- as microseconds
local max_no_yield_Msecs = tonumber(minetest.settings:get("lwcomputers_max_no_yield_secs") or 5.0) * 1000000.0
local max_string_rep_size = tonumber(minetest.settings:get("lwcomputers_max_string_rep_size") or 64000)
local max_clipboard_length = tonumber(minetest.settings:get("lwcomputers_max_clipboard_length") or 64000)
local time_scale = tonumber(minetest.settings:get("time_speed") or 0)
local epoch_year = tonumber(minetest.settings:get("lwcomputers_epoch_year") or 2000)

local epoch_offset = os.time ({
	year = epoch_year,
	month = 1,
	day = 1,
	hour = 0,
	min = 0,
	sec = 0,
	isdst = false
})


local robot_move_delay = tonumber(minetest.settings:get("lwcomputers_robot_move_delay") or 0.5)
local robot_action_delay = tonumber(minetest.settings:get("lwcomputers_robot_action_delay") or 0.2)

if robot_move_delay < 0.1 then
	robot_move_delay = 0.1
end

if robot_action_delay < 0.1 then
	robot_action_delay = 0.1
end


local http_white_list = minetest.settings:get("lwcomputers_http_white_list") or ""

http_white_list = string.split (http_white_list, " ")
for l = 1, #http_white_list do
	http_white_list[l] = string.gsub (http_white_list[l], "*", ".*")
end



local function http_fetch (request, computer)
	if http_api and computer.id then
		if not request then
			return nil, "no request"
		end

		if type (request.url) ~= "string" then
			return nil, "no url"
		end

		if request.url:len () < 1 then
			return nil, "no url"
		end

		-- check white list
		local found = false
		for l = 1, #http_white_list do
			if string.match (request.url, http_white_list[l]) then
				found = true
			end
		end

		if not found then
			return nil, "denied"
		end

		if request.timeout then
			if request.timeout > 30 then
				request.timeout = 30
			end
		end

		computer.timed_out = false
		http_api.fetch (request, computer.http_callback)
		computer.resumed_at = minetest.get_us_time ()

		local result, msg = coroutine.yield ("http_fetch")

		if result then
			return computer.http_result
		end

		return nil, msg
	end

	return nil, "no http"
end



local place_substitute = dofile (lwcomputers.modpath.."/place_substitute.lua")
local crafting_mods = dofile (lwcomputers.modpath.."/crafting_mods.lua")



local term_form_width = 16.8 -- formspec units
local hscale = term_form_width / term_hres
local vscale = hscale * 1.5

-- contains static parts of formspec
local form_header = ""
local form_footer = ""

-- contains click button array for easy lookup
local click_buttons = { }



-- returns a formspec click button
local function click_button (x, y)
	local c = (y * term_hres) + x

	click_buttons[string.format ("c_%04d", c)] = { x = x, y = y }

	return string.format ("button[%1.2f,%1.2f;%1.2f,%1.2f;c_%04d;]",
								 x * hscale, y * vscale,
								 hscale, vscale, c)
end



-- builds static formspec components
local function build_form_constants ()
	local fw = (term_hres * hscale) + 1.0
	local fh = (term_vres * vscale) + 5.25

	form_header =
	string.format ("formspec_version[3]"..
						"size[%1.2f,%1.2f,false]"..
						"no_prepend[]"..
						"bgcolor[#E7DAA8]"..
						"container[0.5,0.5]",
						fw, fh)

	if click_events then
		for y = 0, (term_vres - 1) do
			for x = 0, (term_hres - 1) do
				form_header = form_header..click_button (x, y)
			end
		end
	end



	local kby = (term_vres * vscale) + 0.75

	form_footer =
	"container_end[]"..
	"button[0.5,"..tostring (kby)..";0.9,0.7;KEY_ESC;Esc]"..
	"button[1.4,"..tostring (kby)..";0.8,0.7;KEY_F1;F1]"..
	"button[2.2,"..tostring (kby)..";0.8,0.7;KEY_F2;F2]"..
	"button[3.0,"..tostring (kby)..";0.8,0.7;KEY_F3;F3]"..
	"button[3.8,"..tostring (kby)..";0.8,0.7;KEY_F4;F4]"..
	"button[4.6,"..tostring (kby)..";0.8,0.7;KEY_F5;F5]"..
	"button[5.4,"..tostring (kby)..";0.8,0.7;KEY_F6;F6]"..
	"button[6.2,"..tostring (kby)..";0.8,0.7;KEY_F7;F7]"..
	"button[7.0,"..tostring (kby)..";0.8,0.7;KEY_F8;F8]"..
	"button[7.8,"..tostring (kby)..";0.8,0.7;KEY_F9;F9]"..
	"button[8.6,"..tostring (kby)..";0.8,0.7;KEY_F10;F10]"..
	"button[9.4,"..tostring (kby)..";0.8,0.7;KEY_F11;F11]"..
	"button[10.2,"..tostring (kby)..";0.8,0.7;KEY_F12;F12]"..
	"button[11.0,"..tostring (kby)..";0.95,0.7;KEY_DELETE;Del]"..
	"list[context;main;12.5,"..tostring (kby)..";3,1;]"..
	"image_button["..tostring (fw - 1.2)..","..tostring (kby)..
	";0.7,0.7;power_button.png;power;;false;false;power_button.png]"..
	"image_button["..tostring (fw - 1.2)..","..tostring (fh - 3.4).. --tostring (kby + 0.8)..
	";0.7,0.7;reboot_button.png;reboot;;false;false;reboot_button.png]"

	kby = kby + 0.7

	form_footer = form_footer..
	"button[0.5,"..tostring (kby)..";0.8,0.7;KEY_TICK;` ~]"..
	"button[1.3,"..tostring (kby)..";0.8,0.7;KEY_1;1 !]"..
	"button[2.1,"..tostring (kby)..";0.8,0.7;KEY_2;2 @]"..
	"button[2.9,"..tostring (kby)..";0.8,0.7;KEY_3;3 #]"..
	"button[3.7,"..tostring (kby)..";0.8,0.7;KEY_4;4 $]"..
	"button[4.5,"..tostring (kby)..";0.8,0.7;KEY_5;5 %]"..
	"button[5.3,"..tostring (kby)..";0.8,0.7;KEY_6;6 ^]"..
	"button[6.1,"..tostring (kby)..";0.8,0.7;KEY_7;7 &]"..
	"button[6.9,"..tostring (kby)..";0.8,0.7;KEY_8;8 *]"..
	"button[7.7,"..tostring (kby)..";0.8,0.7;KEY_9;9 (]"..
	"button[8.5,"..tostring (kby)..";0.8,0.7;KEY_0;0 )]"..
	"button[9.3,"..tostring (kby)..";0.8,0.7;KEY_SUBTRACT;- _]"..
	"button[10.1,"..tostring (kby)..";0.8,0.7;KEY_EQUAL;= +]"..
	"button[10.9,"..tostring (kby)..";1.05,0.7;KEY_BACKSPACE;Back]"

	kby = kby + 0.7

	form_footer = form_footer..
	"button[0.5,"..tostring (kby)..";1.05,0.7;KEY_TAB;Tab]"..
	"button[1.55,"..tostring (kby)..";0.8,0.7;KEY_Q;Q]"..
	"button[2.35,"..tostring (kby)..";0.8,0.7;KEY_W;W]"..
	"button[3.15,"..tostring (kby)..";0.8,0.7;KEY_E;E]"..
	"button[3.95,"..tostring (kby)..";0.8,0.7;KEY_R;R]"..
	"button[4.75,"..tostring (kby)..";0.8,0.7;KEY_T;T]"..
	"button[5.55,"..tostring (kby)..";0.8,0.7;KEY_Y;Y]"..
	"button[6.35,"..tostring (kby)..";0.8,0.7;KEY_U;U]"..
	"button[7.15,"..tostring (kby)..";0.8,0.7;KEY_I;I]"..
	"button[7.95,"..tostring (kby)..";0.8,0.7;KEY_O;O]"..
	"button[8.75,"..tostring (kby)..";0.8,0.7;KEY_P;P]"..
	"button[9.55,"..tostring (kby)..";0.8,0.7;KEY_OPENSQUARE;\\[ {]"..
	"button[10.35,"..tostring (kby)..";0.8,0.7;KEY_CLOSESQUARE;\\] }]"..
	"button[11.15,"..tostring (kby)..";0.8,0.7;KEY_SLASH;\\\\ |]"

	kby = kby + 0.7

	form_footer = form_footer..
--	"button[0.5,"..tostring (kby)..";1.2,0.7;KEY_CAPS;"..caps_lbl.."]"..
	"button[1.7,"..tostring (kby)..";0.8,0.7;KEY_A;A]"..
	"button[2.5,"..tostring (kby)..";0.8,0.7;KEY_S;S]"..
	"button[3.3,"..tostring (kby)..";0.8,0.7;KEY_D;D]"..
	"button[4.1,"..tostring (kby)..";0.8,0.7;KEY_F;F]"..
	"button[4.9,"..tostring (kby)..";0.8,0.7;KEY_G;G]"..
	"button[5.7,"..tostring (kby)..";0.8,0.7;KEY_H;H]"..
	"button[6.5,"..tostring (kby)..";0.8,0.7;KEY_J;J]"..
	"button[7.3,"..tostring (kby)..";0.8,0.7;KEY_K;K]"..
	"button[8.1,"..tostring (kby)..";0.8,0.7;KEY_L;L]"..
	"button[8.9,"..tostring (kby)..";0.8,0.7;KEY_SEMICOLON;\\; :]"..
	"button[9.7,"..tostring (kby)..";0.8,0.7;KEY_APOSTROPHE;' \"]"..
	"button[10.5,"..tostring (kby)..";1.45,0.7;KEY_ENTER;Enter]"

	kby = kby + 0.7

	form_footer = form_footer..
--	"button[0.5,"..tostring (kby)..";1.3,0.7;KEY_SHIFT;"..shift_lbl.."]"..
	"button[1.8,"..tostring (kby)..";0.8,0.7;KEY_Z;Z]"..
	"button[2.6,"..tostring (kby)..";0.8,0.7;KEY_X;X]"..
	"button[3.4,"..tostring (kby)..";0.8,0.7;KEY_C;C]"..
	"button[4.2,"..tostring (kby)..";0.8,0.7;KEY_V;V]"..
	"button[5.0,"..tostring (kby)..";0.8,0.7;KEY_B;B]"..
	"button[5.8,"..tostring (kby)..";0.8,0.7;KEY_N;N]"..
	"button[6.6,"..tostring (kby)..";0.8,0.7;KEY_M;M]"..
	"button[7.4,"..tostring (kby)..";0.8,0.7;KEY_COMMA;, <]"..
	"button[8.2,"..tostring (kby)..";0.8,0.7;KEY_DOT;. >]"..
	"button[9.0,"..tostring (kby)..";0.8,0.7;KEY_DIVIDE;/ ?]"..
	"button[9.8,"..tostring (kby)..";1.075,0.7;KEY_HOME;Hm]"..
	"button[10.875,"..tostring (kby)..";1.075,0.7;KEY_END;End]"

	kby = kby + 0.7

	form_footer = form_footer..
--	"button[0.5,"..tostring (kby)..";1.05,0.7;KEY_CTRL;"..ctrl_lbl.."]"..
--	"button[1.55,"..tostring (kby)..";1.05,0.7;KEY_ALT;"..alt_lbl.."]"..
	"button[2.6,"..tostring (kby)..";3.1,0.7;KEY_SPACE; ]"..
	"button[5.7,"..tostring (kby)..";0.8,0.7;KEY_LEFT;<]"..
	"button[6.5,"..tostring (kby)..";0.8,0.7;KEY_UP;^]"..
	"button[7.3,"..tostring (kby)..";0.8,0.7;KEY_DOWN;v]"..
	"button[8.1,"..tostring (kby)..";0.8,0.7;KEY_RIGHT;>]"..
	"button[8.9,"..tostring (kby)..";0.9,0.7;KEY_INSERT;Ins]"..
	"button[9.8,"..tostring (kby)..";1.075,0.7;KEY_PAGEUP;Pu]"..
	"button[10.875,"..tostring (kby)..";1.075,0.7;KEY_PAGEDOWN;Pd]"

	form_footer = form_footer..
	"list[current_player;main;12.5,"..tostring (fh - 2.6)..";4,2;]"..
	"listcolors[#545454;#6E6E6E;#DBCF9F]"
end



-- build static formspec components once at startup
build_form_constants ()



local function term_formspec (data)
	local fw = (data.width * hscale) + 1.0
	local fh = (data.height * vscale) + 5.25
	local shift_lbl = "Shift"..((data.shift and "*") or "")
	local caps_lbl = "Cap"..((data.caps and "*") or "")
	local ctrl_lbl = "Ctrl"..((data.ctrl and "*") or "")
	local alt_lbl = "Alt"..((data.alt and "*") or "")

	local display = ""
	local line = ""

	for y = 0, (data.height - 1) do
		for x = 0, (data.width - 1) do
			local c = data.display[(y * data.width) + x + 1]
			local bg = c.bg
			local fg = c.fg

			if data.blink then
				if x == data.cursorx and y == data.cursory then
					bg = 15 - bg
					fg = 15 - fg
				end
			end

			line = line..
			string.format ("animated_image[%1.2f,%1.2f;%1.2f,%1.2f;d;%02d%02d.png;256;0;%d]",
								(x * hscale), (y * vscale),
								(hscale + 0.03), (vscale + 0.03),
								fg, bg, ((c.char % 256) + 1))
		end

		display = display..line
		line = ""
	end


	local kby = (data.height * vscale) + 0.75
	local btns =
	"label["..tostring (((fw - 15.8) / 2) + 12.5)..","..
	tostring (fh - 3.05)..";ID:"..tostring (data.id).."]"

	if data.persists then
		btns = btns..
		"image_button["..tostring (fw - 2.2)..","..tostring (fh - 3.4)..
		";0.7,0.7;persist_button_on.png;persists;;false;false;persist_button_on.png]"
	else
		btns = btns..
		"image_button["..tostring (fw - 2.2)..","..tostring (fh - 3.4)..
		";0.7,0.7;persist_button_off.png;persists;;false;false;persist_button_off.png]"
	end

	if data.robot then
		btns = btns.."button[12.5,"..tostring (fh - 3.4)..";0.7,0.7;storage;S]"
	end

	kby = kby + 2.1
	btns = btns.."button[0.5,"..tostring (kby)..";1.2,0.7;KEY_CAPS;"..caps_lbl.."]"

	kby = kby + 0.7
	btns = btns.."button[0.5,"..tostring (kby)..";1.3,0.7;KEY_SHIFT;"..shift_lbl.."]"

	kby = kby + 0.7
	btns = btns.."button[0.5,"..tostring (kby)..";1.05,0.7;KEY_CTRL;"..ctrl_lbl.."]"..
					 "button[1.55,"..tostring (kby)..";1.05,0.7;KEY_ALT;"..alt_lbl.."]"

	return string.format ("%s%s%s%s", form_header, display, form_footer, btns)
end



local function new_computer_env (computer)
	local ENV = { }

	ENV.assert = _G.assert
	ENV.tostring = _G.tostring
	ENV.tonumber = _G.tonumber
	ENV.rawget = _G.rawget
	ENV.ipairs = _G.ipairs
	ENV.pcall = _G.pcall
	ENV.rawset = _G.rawset
	ENV.vector = _G.vector
	ENV.rawequal = _G.rawequal
	ENV._VERSION = _G._VERSION
	ENV.next = _G.next
	ENV.string = { }
	ENV.string.split = _G.string.split
--	ENV.string.find = _G.string.find -- modify
	ENV.string.trim = _G.string.trim
	ENV.string.format = _G.string.format
--	ENV.string.rep = _G.string.rep -- modify
	ENV.string.gsub = _G.string.gsub
	ENV.string.len = _G.string.len
	ENV.string.gmatch = _G.string.gmatch
	ENV.string.dump = _G.string.dump
	ENV.string.match = _G.string.match
	ENV.string.reverse = _G.string.reverse
	ENV.string.byte = _G.string.byte
	ENV.string.char = _G.string.char
	ENV.string.upper = _G.string.upper
	ENV.string.lower = _G.string.lower
	ENV.string.sub = _G.string.sub
	ENV.type = _G.type
	ENV.coroutine = _G.coroutine
	ENV.xpcall = _G.xpcall
	ENV.setfenv = _G.setfenv
--	ENV.debug = _G.debug -- omitted
	ENV.getmetatable = _G.getmetatable
	ENV.error = _G.error
	ENV._G = ENV
--	ENV.jit = _G.jit -- omitted
	ENV.pairs = _G.pairs
--	ENV.loadstring = _G.loadstring -- modify
	ENV.table = _G.table
	ENV.math = _G.math
	ENV.setmetatable = _G.setmetatable
	ENV.select = _G.select
	ENV.unpack = _G.unpack
	ENV.getfenv = _G.getfenv
--	ENV.load = _G.load -- modify
--	ENV.loadfile = _G.loadfile -- modify
--	ENV.dofile = _G.dofile -- modify
--	ENV.print = _G.print -- modify
--	ENV.package = _G.package -- omitted
--	ENV.collectgarbage = _G.collectgarbage -- omitted
--	ENV.require = _G.require -- omitted
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
	ENV.mesecon = { }
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

		return lwcomputers.get_worldtime ()
	end


	ENV.os.date = function (fmt, tm)
		if not tm then
			tm = lwcomputers.get_worldtime ()
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


	ENV.os.copy_to_clipboard = function (contents)
		return computer.set_clipboard_contents (contents)
	end


	ENV.os.to_worldtime = function (secs)
		return lwcomputers.to_worldtime (secs)
	end


	ENV.os.to_realtime = function (secs)
		return lwcomputers.to_realtime (secs)
	end



	-- string

	-- thank you mesecons developers
	ENV.string.rep = function (str, n)
		if (#str * n) > max_string_rep_size then
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
	for k, v in pairs (lwcomputers.keys) do
		ENV.keys[k] = v
	end



	-- term

	-- copy colors
	for k, v in pairs (lwcomputers.colors) do
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
	local forecolor = lwcomputers.colors.white
	local backcolor = lwcomputers.colors.black

	ENV.term.get_colors = function ()
		return forecolor, backcolor
	end


	ENV.term.set_colors = function (fg, bg)
		if fg then
			fg = tonumber (fg or lwcomputers.colors.white)

			forecolor = fg % 16
		end

		if bg then
			bg = tonumber (bg or lwcomputers.colors.black)

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
						c.fg = (b.fg or lwcomputers.colors.white) % 16
						c.bg = (b.bg or lwcomputers.colors.black) % 16
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
		fg = fg or lwcomputers.colors.white
		bg = bg or lwcomputers.colors.black
		x = tonumber (x or 0)
		y = tonumber (y or 0)
		w = tonumber (w or computer.width)
		h = tonumber (h or computer.height)

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

		lines = tonumber (lines or 0)
		x = tonumber (x or 0)
		y = tonumber (y or 0)
		w = tonumber (w or computer.width)
		h = tonumber (h or computer.height)

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
							local w = d[(wy * computer.width) + mx + 1]

							w.char = r.char
							w.fg = r.fg
							w.bg = r.bg
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
							local w = d[(wy * computer.width) + mx + 1]

							w.char = r.char
							w.fg = r.fg
							w.bg = r.bg
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
			ENV.term.clear (0, lwcomputers.colors.white, lwcomputers.colors.black,
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
				ENV.term.clear (0, lwcomputers.colors.white, lwcomputers.colors.black,
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



	-- mesecon

	ENV.mesecon.supported = function ()
		return computer.digilines_supported ()
	end


	ENV.mesecon.get = function (side)
		return computer.mesecon_get (side)
	end


	ENV.mesecon.set = function (state, side)
		computer.mesecon_set (state, side)
	end



	-- http

	ENV.http.fetch = function (request)
		return http_fetch (request, computer)
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
		fg = (tonumber (fg) or lwcomputers.colors.black) % 16
		bg = (tonumber (bg) or lwcomputers.colors.white) % 16

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
		if lwcomputers.digilines_supported then
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
		if lwcomputers.digilines_supported then
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
		if lwcomputers.digilines_supported then
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
		if lwcomputers.digilines_supported then
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
		if lwcomputers.digilines_supported then
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

		local sides = { "up", "down", "front", "back", "left", "right" }
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

			ENV.robot["place_"..sides[s]] = function (nodename, param2)
				return computer.place (sides[s], nodename, param2)
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
	end



	return ENV
end



local function get_mesecon_rule_for_side (pos, param2, side)
	local base = nil

	if side == "up" then
		return { { x = 0, y = 1, z = 0 } }
	elseif side == "left" then
		base = { x = -1, y = 0, z = 0 }
	elseif side == "right" then
		base = { x = 1, y = 0, z = 0 }
	elseif side == "front" then
		base = { x = 0, y = 0, z = -1 }
	elseif side == "back" then
		base = { x = 0, y = 0, z = 1 }
	else
		return nil
	end

	local rule = nil

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
	local base = nil

	if side == "up" then
		return { x = pos.x, y = pos.y + 1, z = pos.z }
	elseif side == "down" then
		return { x = pos.x, y = pos.y - 1, z = pos.z }
	elseif side == "left" then
		base = { x = 1, y = 0, z = 0 }
	elseif side == "right" then
		base = { x = -1, y = 0, z = 0 }
	elseif side == "front" then
		base = { x = 0, y = 0, z = 1 }
	elseif side == "back" then
		base = { x = 0, y = 0, z = -1 }
	else
		return nil
	end

	if param2 == 3 then -- +x
		return { x = base.z + pos.x, y = pos.y, z = (base.x * -1) + pos.z }
	elseif param2 == 0 then -- -z
		return { x = (base.x * -1) + pos.x, y = pos.y, z = (base.z * -1) + pos.z }
	elseif param2 == 1 then -- -x
		return { x = (base.z * -1) + pos.x, y = pos.y, z = base.x + pos.z }
	elseif param2 == 2 then -- +z
		return { x = base.x + pos.x, y = pos.y, z = base.z + pos.z }
	end

	return nil
end



local function new_computer (pos, id, persists, robot)
	local computer =
	{
		id = id,
		pos =  { x = pos.x, y = pos.y, z = pos.z },
		robot = robot,
		width = term_hres,
		height = term_vres,
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
		persists = persists,
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
			bg = lwcomputers.colors.black,
			fg = lwcomputers.colors.silver,
			char = 0
		}
	end


	computer.filesys = lwcomputers.filesys:new (id, pos)


	computer.ENV = new_computer_env (computer)


	computer.redraw_formspec = function (force)
		if not computer.suspend_redraw and (computer.redraw or force) then
			local meta = minetest.get_meta (computer.pos)
			local id = meta:get_int ("lwcomputer_id")

			meta:set_string("formspec", term_formspec (computer))

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
		if (minetest.get_us_time () - computer.resumed_at) > max_no_yield_Msecs then
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
				local result, yielded, secs; --, event_name;

				if computer.yielded == "get_event" then
					if #computer.events > 0 then

						if computer.event_name:len () > 0 then
							for  i = 1, #computer.events do
								if computer.events[i][1] == computer.event_name then
									local event = table.remove (computer.events, i)
									run = true

									computer.resumed_at = minetest.get_us_time ()
									debug.sethook (computer.thread, computer.overrun, "", 10000)

									result, yielded, secs = coroutine.resume (computer.thread, unpack (event))

									debug.sethook ()

									break
								end
							end
						else
							local event = table.remove (computer.events, 1)
							run = true

							computer.resumed_at = minetest.get_us_time ()
							debug.sethook (computer.thread, computer.overrun, "", 10000)

							result, yielded, secs = coroutine.resume (computer.thread, unpack (event))

							debug.sethook ()
						end

					end

				elseif computer.yielded == "sleep" then
					if ((minetest.get_us_time () - computer.sleep_start) / 1000000.0) >= computer.sleep_secs then
						run = true

						computer.resumed_at = minetest.get_us_time ()
						debug.sethook (computer.thread, computer.overrun, "", 10000)

						result, yielded, secs = coroutine.resume (computer.thread)

						debug.sethook ()
					end

				elseif computer.yielded == "http_result" then
					run = true

					computer.resumed_at = minetest.get_us_time ()
					debug.sethook (computer.thread, computer.overrun, "", 10000)

					result, yielded, secs = coroutine.resume (computer.thread, true)

					debug.sethook ()

				elseif computer.yielded == "booting" then
					run = true

					computer.resumed_at = minetest.get_us_time ()
					debug.sethook (computer.thread, computer.overrun, "", 10000)

					result, yielded, secs = coroutine.resume (computer.thread)

					debug.sethook ()

				elseif computer.yielded == "http_fetch" then
					if (minetest.get_us_time () - computer.resumed_at) > 31000000 then
						computer.timed_out = true
						run = true

						computer.resumed_at = minetest.get_us_time ()
						debug.sethook (computer.thread, computer.overrun, "", 10000)

						result, yielded, secs = coroutine.resume (computer.thread, false, "timed out")

						debug.sethook ()
					end
				end

				if run then
					if result then
						computer.yielded = yielded
						computer.sleep_secs = tonumber (secs or 0) or 0
						computer.sleep_start = minetest.get_us_time ()
						computer.event_name = tostring (secs or "")

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
						computer.ENV.term.set_colors (lwcomputers.colors.red, lwcomputers.colors.black)
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
		lwcomputers.filesys:create_hdd (id)

		computer.ENV.term.clear ()
		computer.ENV.term.set_cursor (0, 0)
		computer.ENV.term.set_blink (true)
		computer.ENV.term.set_colors (lwcomputers.colors.silver, lwcomputers.colors.black)

		-- boot
		local src = computer.filesys:get_boot_file ()

		if src then
			local fxn, status = loadstring (src, "boot")

			if not fxn then
				computer.ENV.term.set_colors (lwcomputers.colors.red, lwcomputers.colors.black)
				computer.ENV.term.print ("Error: %s\n", status)
				computer.redraw_formspec (true)
			else
				status = "dead"
				setfenv (fxn, computer.ENV)

				computer.yielded = "dead"

				local container = function ()
					local result, msg = pcall (fxn)

					if not result then
						computer.ENV.term.set_colors (lwcomputers.colors.red, lwcomputers.colors.black)
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
						minetest.get_meta (pos):set_int ("running", 1)
						computer.clock_base = minetest.get_us_time ()

						timer:start (running_tick)
					end
				end

				if status ~= "suspended" then
					computer.thread = nil
					computer.yielded = "dead"
					computer.ENV.term.set_colors (lwcomputers.colors.red, lwcomputers.colors.black)
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

		computer.mesecon_set (false)

		computer.ENV.term.clear ()
		computer.ENV.term.set_cursor (0, 0)
		computer.ENV.term.set_blink (true)

		computer.running = false
		minetest.get_meta (pos):set_int ("running", 0)
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

		return lwcomputers.send_message (id, msg, target_id)
	end


	computer.name_from_id = function (id)
		return lwcomputers.name_from_id (id)
	end


	computer.id_from_name = function (name)
		return lwcomputers.id_from_name (name)
	end


	computer.start_timer = function (secs)
		local tid = math.random (1000000)

		computer.timers[tostring (tid)] = (minetest.get_us_time() + (secs * 1000000.0))

		return tid
	end


	computer.kill_timer = function (tid)
		computer.timers[tostring (tid)] = nil
	end


	computer.digilines_supported = function ()
		return lwcomputers.digilines_supported
	end


	computer.digilines_get_channel = function ()
		if lwcomputers.digilines_supported then
			local meta = minetest.get_meta (computer.pos)

			if meta then
				return meta:get_string ("digilines_channel")
			end
		end

		return ""
	end


	computer.digilines_set_channel = function (channel)
		if lwcomputers.digilines_supported then
			local meta = minetest.get_meta (computer.pos)

			if meta then
				meta:set_string ("digilines_channel", tostring (channel or ""))
			end
		end
	end


	computer.digilines_send = function (channel, msg)
		if lwcomputers.digilines_supported then
			lwcomputers.digilines_receptor_send (pos, digiline.rules.default, channel, msg or "")
		end
	end


	computer.mesecon_supported = function ()
		return lwcomputers.mesecon_supported
	end


	computer.mesecon_get = function (side)
		if lwcomputers.mesecon_supported then
			local meta = minetest.get_meta (pos)

			if meta then
				if side then
					return meta:get_string ("mesecon_"..side) == lwcomputers.mesecon_state_on
				else
					-- any
					return meta:get_string ("mesecon_front") == lwcomputers.mesecon_state_on or
							 meta:get_string ("mesecon_back") == lwcomputers.mesecon_state_on or
							 meta:get_string ("mesecon_left") == lwcomputers.mesecon_state_on or
							 meta:get_string ("mesecon_right") == lwcomputers.mesecon_state_on or
							 meta:get_string ("mesecon_up") == lwcomputers.mesecon_state_on
				end
			end
		end

		return false
	end


	computer.mesecon_set = function (state, side)
		if lwcomputers.mesecon_supported then
			local meta = minetest.get_meta (pos)

			if meta then
				if side then
					local rule = get_mesecon_rule_for_side (pos, meta:get_int ("param2"), side)

					if rule then
						if state then
							lwcomputers.mesecon_receptor_on (pos, rule)
							meta:set_string ("mesecon_"..side, lwcomputers.mesecon_state_on)
						else
							lwcomputers.mesecon_receptor_off (pos, rule)
							meta:set_string ("mesecon_"..side, lwcomputers.mesecon_state_off)
						end
					end

				else
					local all_rule =
					{
						{ x = 1, y = 0, z = 0 },
						{ x = -1, y = 0, z = 0 },
						{ x = 0, y = 0, z = 1 },
						{ x = 0, y = 0, z = -1 },
						{ x = 0, y = 1, z = 0 },
						--{ x = 0, y = -1, z = 0 }, down doesn't work
					}

					if state then
						lwcomputers.mesecon_receptor_on (pos, all_rule)
						meta:set_string ("mesecon_front", lwcomputers.mesecon_state_on)
						meta:set_string ("mesecon_back", lwcomputers.mesecon_state_on)
						meta:set_string ("mesecon_left", lwcomputers.mesecon_state_on)
						meta:set_string ("mesecon_right", lwcomputers.mesecon_state_on)
						meta:set_string ("mesecon_up", lwcomputers.mesecon_state_on)
					else
						lwcomputers.mesecon_receptor_off (pos, all_rule)
						meta:set_string ("mesecon_front", lwcomputers.mesecon_state_off)
						meta:set_string ("mesecon_back", lwcomputers.mesecon_state_off)
						meta:set_string ("mesecon_left", lwcomputers.mesecon_state_off)
						meta:set_string ("mesecon_right", lwcomputers.mesecon_state_off)
						meta:set_string ("mesecon_up", lwcomputers.mesecon_state_off)
					end
				end
			end
		end
	end


	computer.get_clipboard_contends = function ()
		local meta = minetest.get_meta (pos)

		if meta then
			local inv = meta:get_inventory ()

			if inv then
				local slots = inv:get_size ("main")

				for i = 1, slots do
					local stack = inv:get_stack ("main", i)

					if stack then
						if not stack:is_empty () then
							if stack:get_name () == "lwcomputers:clipboard" then
								local imeta = stack:get_meta ()

								if imeta then
									return imeta:get_string ("contents")
								end
							end
						end
					end
				end
			end
		end

		return nil
	end


	computer.set_clipboard_contents = function (contents)
		contents = (tostring (contents or "")):sub (1, max_clipboard_length)

		local meta = minetest.get_meta (pos)

		if meta then
			local inv = meta:get_inventory ()

			if inv then
				local slots = inv:get_size ("main")

				for i = 1, slots do
					local stack = inv:get_stack ("main", i)

					if stack then
						if not stack:is_empty () then
							if stack:get_name () == "lwcomputers:clipboard" then
								local imeta = stack:get_meta ()

								if imeta then
									imeta:set_string ("contents", contents)
									inv:set_stack("main", i, stack)

									return true
								end
							end
						end
					end
				end
			end
		end

		return false
	end


	computer.toggle_persists = function ()
		local meta = minetest.get_meta (pos)

		if meta then
			if computer.persists then
				minetest.forceload_free_block (pos, false)
				computer.persists = false
				meta:set_int ("persists", 0)
			else
				if minetest.forceload_block (pos, false) then
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


	-- robot

	computer.detect = function (side)
		local node = minetest.get_node_or_nil (computer.pos)

		if node then
			local pos = get_robot_side (computer.pos, node.param2, side)

			if pos then
				node = minetest.get_node_or_nil (pos)

				if node then
					return node.name
				end
			end
		end

		return nil
	end


	local function get_far_node (pos)
		local node = minetest.get_node (pos)

		if node.name == "ignore" then
			minetest.get_voxel_manip ():read_from_map (pos, pos)

			node = minetest.get_node(pos)

			if node.name == "ignore" then
				return nil
			end
		end

		return node
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

		if not minetest.registered_nodes[node.name] or
			minetest.registered_nodes[node.name].walkable then
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
		local disk_data = meta:get_string ("disk_data")
		local inventory = "{ "..
		"main = { [1] = '', [2] = '', [3] = '' }, "..
		"storage = { [1] = '', [2] = '', [3] = '', [4] = '', [5] = '', [6] = '', [7] = '', [8] = '', "..
		"            [9] = '', [10] = '', [11] = '', [12] = '', [13] = '', [14] = '', [15] = '', [16] = '', "..
		"            [17] = '', [18] = '', [19] = '', [20] = '', [21] = '', [22] = '', [23] = '', [24] = '', "..
		"            [25] = '', [26] = '', [27] = '', [28] = '', [29] = '', [30] = '', [31] = '', [32] = '' } }"

		if persists == 1 then
			minetest.forceload_free_block (computer.pos, false)
		end

		computer.mesecon_set (false)

		meta:set_int ("lwcomputer_id", 0)
		minetest.remove_node (computer.pos)

		computer.pos = pos
		computer.filesys.pos = pos
		minetest.add_node (pos, cur_node)

		meta = minetest.get_meta (pos)
		inv = meta:get_inventory ()

		inv:set_size("main", 3)
		inv:set_width("main", 3)
		inv:set_size("storage", 32)
		inv:set_width("storage", 8)

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
		if disk_data:len () > 0 then
			meta:set_string ("disk_data", disk_data)
		end

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

		minetest.get_node_timer (pos):start (running_tick)

		coroutine.yield ("sleep", robot_move_delay)

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

		coroutine.yield ("sleep", robot_action_delay)

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

		local node = minetest.get_node_or_nil (pos)
		if not node then
			return nil
		end

		if not minetest.registered_nodes[node.name] or
			not minetest.registered_nodes[node.name].diggable or
			minetest.is_protected (pos, "") then

			return nil
		end

		if minetest.registered_nodes[node.name].can_dig then
			if minetest.registered_nodes[node.name].can_dig (pos) == false then
				return nil
			end
		end

		local inv = meta:get_inventory ()
		if not inv then
			return nil
		end

		local items = minetest.get_node_drops (node, nil)
		if items then
			for i = 1, #items do
				local over = inv:add_item ("storage", ItemStack (items[i]))

				if over and over:get_count () > 0 then
					minetest.item_drop (over, nil, pos)
				end
			end
		end

		minetest.remove_node (pos)

		coroutine.yield ("sleep", robot_action_delay)

		return node.name
	end


	computer.place = function (side, nodename, param2)
		nodename = tostring (nodename or "")
		param2 = tonumber (param2 or 0) or 0

		if nodename:len () < 1 or nodename == "air" then
			return false
		end

		if param2 < 0 or param2 > 5 then
			param2 = 0
		end

		local stack = ItemStack (nodename)
		local meta = minetest.get_meta (computer.pos)
		local cur_node = minetest.get_node_or_nil (computer.pos)
		if not stack or not meta or not cur_node  then
			return false
		end

		local inv = meta:get_inventory ()
		if not inv or not inv:contains_item ("storage", stack, false) then
			return false
		end

		local pos = get_robot_side (computer.pos, cur_node.param2, side)
		if not pos then
			return false
		end

		local node = minetest.get_node_or_nil (pos)
		if not node then
			return false
		end

		if node.name ~= "air" then
			if not minetest.registered_nodes[node.name] or
				not minetest.registered_nodes[node.name].buildable_to or
				minetest.is_protected (pos, "") then

				return false
			end
		end

		if not inv:remove_item ("storage", stack) then
			return false
		end

		local substitute = place_substitute[nodename]
		if substitute then
			nodename = substitute
		end

		minetest.set_node (pos, { name = nodename, param1 = 0, param2 = param2})

		coroutine.yield ("sleep", robot_action_delay)

		return true
	end


	computer.contains = function (nodename)
		local meta = minetest.get_meta (computer.pos)
		local inv = meta:get_inventory ()
		local stack = ItemStack (nodename)
		if not meta or not inv or not stack then
			return false
		end

		return inv:contains_item ("storage", stack, false)
	end


	computer.slots = function ()
		local meta = minetest.get_meta (computer.pos)
		local inv = meta:get_inventory ()
		if not meta or not inv then
			return nil
		end

		return inv:get_size ("storage")
	end


	computer.slot = function (slot)
		local meta = minetest.get_meta (computer.pos)
		local inv = meta:get_inventory ()
		if not meta or not inv then
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
		local name = nil

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

		local node = minetest.get_node_or_nil (pos)
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

			coroutine.yield ("sleep", robot_action_delay)

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

			coroutine.yield ("sleep", robot_action_delay)

			return true
		end

		return false
	end


	computer.pull = function (side, item, listname)
		listname = tostring (listname or "main")
		local count = 1
		local name = nil

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

		local node = minetest.get_node_or_nil (pos)
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

			coroutine.yield ("sleep", robot_action_delay)

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

			coroutine.yield ("sleep", robot_action_delay)

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
					local stack = substitute_group (recipes[r].items[i], inv)

					if stack then
						if items[stack:get_name ()] then
							items[stack:get_name ()] = items[stack:get_name ()] + stack:get_count ()
						else
							items[stack:get_name ()] = stack:get_count ()
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

					if crafting_mods[item] then
						if crafting_mods[item].add then
							for i = 1, #crafting_mods[item].add do
								local stack = ItemStack (crafting_mods[item].add[i])

								if stack and stack:get_count () > 0 then
									inv:add_item ("storage", stack)
								end
							end
						end


						if crafting_mods[item].remove then
							for i = 1, #crafting_mods[item].remove do
								local stack = ItemStack (crafting_mods[item].remove[i])

								if stack and stack:get_count () > 0 then
									inv:remove_item ("storage", stack)
								end
							end
						end
					end

					coroutine.yield ("sleep", robot_action_delay)

					return true
				end
			end
		end

		return false
	end


	computer.find_inventory = function (listname)
		local result = { }
		local sides = { "up", "down", "front", "back", "left", "right" }
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
				local node = minetest.get_node_or_nil (pos)

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



	return computer
end



function lwcomputers.get_computer_data (id, pos)
	local name = tostring (id)
	local data = lwcomputers.computer_data[name]

	if data == nil and pos then
		local meta = minetest.get_meta (pos)
		data = new_computer (pos,
									id,
									meta:get_int ("persists") == 1,
									meta:get_int ("robot") == 1)

		lwcomputers.computer_data[name] = data

		lwcomputers.computer_list[name] =
		{
			pos = { x = pos.x, y = pos.y, z = pos.z },
		}

		lwcomputers.store_computer_list ()
	end

	return data
end



function lwcomputers.reset_computer_data (id, pos)
	local name = tostring (id)
	local meta = minetest.get_meta (pos)
	local data = new_computer (pos,
										id,
										meta:get_int ("persists") == 1,
										meta:get_int ("robot") == 1)

	lwcomputers.computer_data[name] = data

	lwcomputers.computer_list[name] =
	{
		pos = { x = pos.x, y = pos.y, z = pos.z },
	}

	lwcomputers.store_computer_list ()

	return data
end



function lwcomputers.remove_computer_data (id)
	local name = tostring (id)

	lwcomputers.computer_data[name] = nil
	lwcomputers.computer_list[name] = nil
	lwcomputers.store_computer_list ()
end



function lwcomputers.send_message (sender_id, msg, target_id)
	target_id = tonumber (target_id or 0)
	msg = tostring (msg or "")

	if target_id > 0 then
		local target = tostring (target_id)
		local stats = lwcomputers.computer_list[target]

		if stats then
			local meta = minetest.get_meta (stats.pos)

			if meta then
				local id = meta:get_int ("lwcomputer_id")

				if id == 0 or id ~= target_id then
					-- no longer there
					lwcomputers.remove_computer_data (target_id)

				elseif target_id ~= sender_id then
					local data = lwcomputers.get_computer_data (target_id, stats.pos)

					if data then
						data.queue_event ("wireless", msg, sender_id, target_id)

						return true
					end

				end
			end
			-- else out of range or doesn't exist
		end

	else
		-- broadcast
		local remove_list = { }

		for target, stats in pairs (lwcomputers.computer_list) do
			local meta = minetest.get_meta (stats.pos)

			if meta then
				local id = meta:get_int ("lwcomputer_id")
				target_id = tonumber (target)

				if id == 0 or id ~= target_id then
					-- no longer there
					remove_list[#remove_list + 1] = target_id

				else

					if target_id ~= sender_id then
						local data = lwcomputers.get_computer_data (target_id, stats.pos)

						if data then
							data.queue_event ("wireless", msg, sender_id, nil)
						end
					end
				end
			-- else out of range or doesn't exist
			end
		end

		-- remove redundant machines
		for c = 1, #remove_list do
			lwcomputers.remove_computer_data (remove_list[c])
		end

		return true
	end

	return false
end



function lwcomputers.name_from_id (id)
	id = tonumber (id or 0)
	local name = nil

	if id > 0 then
		local stats = lwcomputers.computer_list[tostring (id)]

		if stats then
			local meta = minetest.get_meta (stats.pos)

			if meta then
				if meta:get_int ("lwcomputer_id") == id then
					name = meta:get_string ("name")
				else
					-- no longer there
					lwcomputers.remove_computer_data (id)
				end
			end
		end
	end

	return name
end



function lwcomputers.id_from_name (name)
	name = tostring (name or "")
	local id = nil
	local remove_list = { }

	for target, stats in pairs (lwcomputers.computer_list) do
		local meta = minetest.get_meta (stats.pos)

		if meta then
			local target_id = tonumber (target)
			local test_id = meta:get_int ("lwcomputer_id")

			if test_id == 0 or test_id ~= target_id then
				-- no longer there
				remove_list[#remove_list + 1] = target_id

			else
				if name == meta:get_string ("name") then
					id = target_id
				end
			end
		-- else out of range or doesn't exist
		end
	end

	-- remove redundant machines
	for c = 1, #remove_list do
		lwcomputers.remove_computer_data (remove_list[c])
	end

	return id
end



function lwcomputers.get_worldtime ()
	return ((minetest.get_timeofday () + minetest.get_day_count ()) * 86400) + epoch_offset
end



function lwcomputers.to_worldtime (secs)
	if time_scale > 0 then
		return secs * time_scale
	end

	return secs
end



function lwcomputers.to_realtime (secs)
	if time_scale > 0 then
		return secs / time_scale
	end

	return secs
end



local function on_construct (pos)
	local meta = minetest.get_meta (pos)

	meta:set_int ("robot", 0)
end



local function on_construct_robot (pos)
	local meta = minetest.get_meta (pos)

	meta:set_int ("robot", 1)
end



local function on_destruct (pos)
	local meta = minetest.get_meta (pos)

	if meta then
		local id = meta:get_int ("lwcomputer_id")

		if id > 0 then
			local persists =  meta:get_int ("persists") == 1
			local data = lwcomputers.get_computer_data (id, pos)

			if data then
				data.mesecon_set (false)
			end

			lwcomputers.remove_computer_data (id)
		end

		if persists then
			minetest.forceload_free_block (pos, false)
		end
	end
end



local function on_receive_fields (pos, formname, fields, sender)
	if fields.reboot then
		local meta = minetest.get_meta (pos)

		if meta then
			local id = meta:get_int ("lwcomputer_id")
			local data = lwcomputers.get_computer_data (id, pos)

			if data then
				data.reboot ()
			end
		end

	elseif fields.power then
		local meta = minetest.get_meta (pos)

		if meta then
			local id = meta:get_int ("lwcomputer_id")
			local data = lwcomputers.get_computer_data (id, pos)

			if data then
				if data.running then
					data.shutdown ()
				else
					data.startup ()
				end
			end
		end

	elseif fields.persists then
		local meta = minetest.get_meta (pos)

		if meta then
			local id = meta:get_int ("lwcomputer_id")
			local data = lwcomputers.get_computer_data (id, pos)

			if data then
				data.toggle_persists ()
				data.update_formspec ()
			end
		end

	elseif fields.storage then
		local meta = minetest.get_meta (pos)


		if meta then
			local id = meta:get_int ("lwcomputer_id")
			local data = lwcomputers.get_computer_data (id, pos)

			if data then
				data.suspend_redraw = true

				local spec =
				"formspec_version[3]"..
				"size[11.75,12.25,false]"..
				"no_prepend[]"..
				"bgcolor[#E7DAA8]"..
				"list[context;storage;1.0,1.0;8,4;]"..
				"list[current_player;main;1.0,6.5;8,4;]"..
				"listcolors[#545454;#6E6E6E;#DBCF9F]"

				meta:set_string("formspec", spec)
			end
		end

	elseif fields.quit then
		local meta = minetest.get_meta (pos)

		if meta then
			local id = meta:get_int ("lwcomputer_id")
			local data = lwcomputers.get_computer_data (id, pos)

			if data then
				data.suspend_redraw = false
				data.update_formspec ()
			end
		end

	else
		for k, v in pairs (fields) do
			local key = lwcomputers.keys[k]

			if key then
				local meta = minetest.get_meta (pos)

				if meta then
					local id = meta:get_int ("lwcomputer_id")
					local data = lwcomputers.get_computer_data (id, pos)

					if data then
						data.id = id

						if k == "KEY_SHIFT" then
							data.shift = not data.shift
							data.update_formspec ()
							data.queue_event ("key", key, data.ctrl, data.alt, data.shift)

						elseif k == "KEY_CAPS" then
							data.caps = not data.caps
							data.update_formspec ()
							data.queue_event ("key", key, data.ctrl, data.alt, data.shift)

						elseif k == "KEY_CTRL" then
							data.ctrl = not data.ctrl
							data.update_formspec ()
							data.queue_event ("key", key, data.ctrl, data.alt, data.shift)

						elseif k == "KEY_ALT" then
							data.alt = not data.alt
							data.update_formspec ()
							data.queue_event ("key", key, data.ctrl, data.alt, data.shift)

						else

							if k == "KEY_V" and data.ctrl and data.alt then
								local contents = data.get_clipboard_contends ()

								if contents then
									data.queue_event ("clipboard", contents)

									return
								end
							end

							data.queue_event ("key", key, data.ctrl, data.alt, data.shift)

							if not data.ctrl and not data.alt then
								local char = key

								if char < lwcomputers.keys.KEY_DELETE then
									if char >= lwcomputers.keys.KEY_A and char <= lwcomputers.keys.KEY_Z then
										if (data.caps and data.shift) or (not data.caps and not data.shift) then
											-- to lower
											char = char + 32
										end
									else
										char = (data.shift and lwcomputers.shift_keys[k]) or key
									end

									data.queue_event ("char", string.char (char), char)
								end
							end

						end
					end
				end

			else
				local click = click_buttons[k]

				if click then
					local meta = minetest.get_meta (pos)

					if meta then
						local id = meta:get_int ("lwcomputer_id")
						local data = lwcomputers.get_computer_data (id, pos)
						local count = 1

						if (os.clock () - data.clicked_when) <= double_click_time then
							if data.clicked.x == click.x and data.clicked.y == click.y then
								count = data.click_count + 1
							end
						end

						data.clicked_when = os.clock ()
						data.clicked = { x = click.x, y = click.y }
						data.click_count = count

						data.queue_event ("click", click.x, click.y, count)
					end
				end
			end

		end
	end
end



local function preserve_metadata (pos, oldnode, oldmeta, drops)
	if #drops > 0 then
		if drops[1]:get_name ():sub (1, 20) == "lwcomputers:computer" then
			local meta = minetest.get_meta (pos)
			local id = meta:get_int ("lwcomputer_id")

			if id > 0 then
				local imeta = drops[1]:get_meta ()
				local description = meta:get_string ("label")

				if description:len () < 1 then
					description = S("Computer ")..tostring (id)
				end

				imeta:set_int ("lwcomputer_id", id)
				imeta:set_string ("name", meta:get_string ("name"))
				imeta:set_string ("label", meta:get_string ("label"))
				imeta:set_string ("infotext", meta:get_string ("infotext"))
				imeta:set_string ("inventory", meta:get_string ("inventory"))
				imeta:set_string ("digilines_channel", meta:get_string ("digilines_channel"))
				imeta:set_string ("description", description)

				local disk_data = meta:get_string ("disk_data")
				if disk_data:len () > 0 then
					imeta:set_string ("disk_data", disk_data)
				end
			end
		end
	end
end



local function after_place_node (pos, placer, itemstack, pointed_thing)
	local meta = minetest.get_meta (pos)
	local is_robot = meta:get_int ("robot") == 1
	local imeta = itemstack:get_meta ()
	local id = imeta:get_int ("lwcomputer_id")
	local name = ""
	local label = ""
	local infotext = ""
	local digilines_channel = ""
	local disk_data = ""
	local inventory = ""

	if is_robot then
		inventory = "{ "..
		"main = { [1] = '', [2] = '', [3] = '' }, "..
		"storage = { [1] = '', [2] = '', [3] = '', [4] = '', [5] = '', [6] = '', [7] = '', [8] = '', "..
		"            [9] = '', [10] = '', [11] = '', [12] = '', [13] = '', [14] = '', [15] = '', [16] = '', "..
		"            [17] = '', [18] = '', [19] = '', [20] = '', [21] = '', [22] = '', [23] = '', [24] = '', "..
		"            [25] = '', [26] = '', [27] = '', [28] = '', [29] = '', [30] = '', [31] = '', [32] = '' } }"
	else
		inventory = "{ main = { [1] = '', [2] = '', [3] = '' } }"
	end

	local unique = false

	if id > 0 then
		name = imeta:get_string ("name")
		label = imeta:get_string ("label")
		infotext = imeta:get_string ("infotext")
		inventory = imeta:get_string ("inventory")
		digilines_channel = imeta:get_string ("digilines_channel")
		disk_data = imeta:get_string ("disk_data")

		unique = true
	else
		id = math.random (1000000)
	end

	meta:set_int ("lwcomputer_id", id)
	meta:set_string ("name", name)
	meta:set_string ("label", label)
	meta:set_int ("running", 0)
	meta:set_string ("infotext", infotext)
	meta:set_string ("inventory", inventory)
	meta:set_string ("digilines_channel", digilines_channel)

	if disk_data:len () > 0 then
		meta:set_string ("disk_data", disk_data)
	end

	meta:set_string ("mesecon_front", lwcomputers.mesecon_state_off)
	meta:set_string ("mesecon_back", lwcomputers.mesecon_state_off)
	meta:set_string ("mesecon_left", lwcomputers.mesecon_state_off)
	meta:set_string ("mesecon_right", lwcomputers.mesecon_state_off)
	meta:set_string ("mesecon_up", lwcomputers.mesecon_state_off)
	meta:set_int ("persists", 0)

	local inv = meta:get_inventory ()

	inv:set_size("main", 3)
	inv:set_width("main", 3)

	if is_robot then
		inv:set_size("storage", 32)
		inv:set_width("storage", 8)
	end

	local data = lwcomputers.reset_computer_data (id, pos)

	if data then
		meta:set_string("formspec", term_formspec (data))
	end

	-- orientate
	if placer then
		if placer:is_player () then
			local angle = placer:get_look_horizontal ()
			local node = minetest.get_node (pos)
			local param2 = 2

			if angle >= (math.pi * 0.25) and angle < (math.pi * 0.75) then
				-- x-
				param2 = 3
			elseif angle >= (math.pi * 0.75) and angle < (math.pi * 1.25) then
				-- z-
				param2 = 1
			elseif angle >= (math.pi * 1.25) and angle < (math.pi * 1.75) then
				-- x+
				param2 = 4
			else
				-- z+
				param2 = 2
			end

			meta:set_int ("param2", param2)

			if node.name ~= "ignore" then
				node.param2 = param2
			end
		end
	end

	if unique and placer:is_player () and
		minetest.is_creative_enabled (placer:get_player_name ()) then

		-- no duplicates in creative mode
		itemstack:clear ()

		return true
	end

	-- If return true no item is taken from itemstack
	return false
end



local function on_timer (pos, elapsed)
	local meta = minetest.get_meta (pos)

	if meta then
		local id = meta:get_int ("lwcomputer_id")
		local data = lwcomputers.get_computer_data (id, pos)

		if data then
			data.tick ()
		end
	end

	-- return true to run the timer for another cycle with the same timeout
	return true
end



local function can_dig (pos, player)
	local meta = minetest.get_meta (pos)

	if meta then
		local inv = meta:get_inventory ()

		if inv then
			if not inv:is_empty ("main") then
				return false
			end
		end

		if meta:get_int ("robot") == 1 then
			if not inv:is_empty ("storage") then
				return false
			end
		end

	end

	return true
end



local function allow_metadata_inventory_put (pos, listname, index, stack, player)
	if listname == "main" then
		if stack then
			if not stack:is_empty () then
				local itemname = stack:get_name ()

				if itemname:sub (1, 18) == "lwcomputers:floppy" or
					itemname == "lwcomputers:clipboard" then

					return 1
				end
			end
		end
	elseif listname == "storage" then
		return 1000
	end

	return 0
end



local function on_metadata_inventory_put (pos, listname, index, stack, player)
	if listname == "main" then
		if stack then
			if not stack:is_empty () then
				local itemname = stack:get_name ()

				if itemname:sub (1, 18) == "lwcomputers:floppy" then
					local imeta = stack:get_meta ()

					if imeta then
						local id = imeta:get_int ("lwcomputer_id")

						if id < 1 then
							id = math.random (1000000)
							imeta:set_int ("lwcomputer_id", id)
							imeta:set_string ("label", "")

							if itemname == "lwcomputers:floppy_lua" then
								imeta:set_string ("label", "lua_disk")
								imeta:set_string ("description", "lua_disk")

								if not lwcomputers.filesys:prep_lua_disk (id, imeta) then
									minetest.log ("error", "lwcomputers - could not prep lua disk")
								end
							elseif itemname == "lwcomputers:floppy_los" then
								imeta:set_string ("label", "los_disk")
								imeta:set_string ("description", "los_disk")

								if not lwcomputers.filesys:prep_los_disk (id, imeta) then
									minetest.log ("error", "lwcomputers - could not prep los disk")
								end
							else
								imeta:set_string ("description", S("floppy ")..tostring (id))
							end

							local inv = minetest.get_meta (pos):get_inventory ()
							inv:set_stack (listname, index, stack)
						end

						-- create floppy if not yet
						lwcomputers.filesys:create_floppy (id)
					end

					local meta = minetest.get_meta (pos)
					if meta then
						local id = meta:get_int ("lwcomputer_id")
						local data = lwcomputers.get_computer_data (id, pos)

						if data then
							data.queue_event ("disk", true)
						end
					end
				end
			end
		end
	end
end



local function on_metadata_inventory_take (pos, listname, index, stack, player)
	local meta = minetest.get_meta (pos)
	if meta then
		local id = meta:get_int ("lwcomputer_id")
		local data = lwcomputers.get_computer_data (id, pos)

		if data then
			data.queue_event ("disk", false)
		end
	end
end



local function on_punch_robot (pos, node, puncher, pointed_thing)
	if puncher and puncher:is_player () then
		if puncher:get_player_control ().sneak then

			local meta = minetest.get_meta (pos)

			if meta then
				local id = meta:get_int ("lwcomputer_id")

				if id > 0 then
					local data = lwcomputers.get_computer_data (id, pos)

					if data and data.running then
					local spec =
						"formspec_version[3]"..
						"size[4.5,3.0,false]"..
						"no_prepend[]"..
						"bgcolor[#E7DAA8]"..
						"style_type[button_exit;bgcolor=red;textcolor=white]"..
						"button_exit[1.0,1.0;2.5,1.0;stop_"..tostring (id)..";Stop]"

						minetest.show_formspec(puncher:get_player_name(),
													  "lwcomputers:computer_robot_stop",
													  spec)

						return true
					end
				end
			end
		end

	end
end



local function digilines_support ()
	if lwcomputers.digilines_supported then
		return
		{
			wire =
			{
				rules = digiline.rules.default,
			},

			effector =
			{
				action = function (pos, node, channel, msg)
					local meta = minetest.get_meta(pos)

					if meta then
						local id = meta:get_int ("lwcomputer_id")

						if id > 0 then
							local data = lwcomputers.get_computer_data (id, pos)

							if data then
								local mychannel = meta:get_string ("digilines_channel")..""

								data.queue_event ("digilines", msg, channel, mychannel)
							end
						end
					end
				end,
			}
		}
	end

	return nil
end



local function get_mesecon_side_for_rule (pos, param2, rule)
	if type (rule) == "table" and param2 >= 1 and param2 <= 4 then
		if rule.x == -1 then
			return ({ "right", "left", "back", "front" })[param2]
		elseif rule.x == 1 then
			return ({ "left", "right", "front", "back" })[param2]
		elseif rule.z == -1 then
			return ({ "back", "front", "left", "right" })[param2]
		elseif rule.z == 1 then
			return ({ "front", "back", "right", "left" })[param2]
		end
	end

	return nil
end



local function mesecon_support ()
	if lwcomputers.mesecon_supported then
		return
		{
			receptor =
			{
				state = mesecon.state.off, -- /on,
				rules =
				{
					{ x = 1, y = 0, z = 0 },
					{ x = -1, y = 0, z = 0 },
					{ x = 0, y = 0, z = 1 },
					{ x = 0, y = 0, z = -1 },
					{ x = 0, y = 1, z = 0 },
					--{ x = 0, y = -1, z = 0 }, down doesn't work
				}
			},

			effector =
			{
				rules = mesecon.rules.flat,

				action_change = function (pos, node, rule, new_state)
					local meta = minetest.get_meta (pos)

					if meta then
						local id = meta:get_int ("lwcomputer_id")

						if id > 0 then
							local data = lwcomputers.get_computer_data (id, pos)

							if data then
								data.queue_event ("mesecon", new_state,
														get_mesecon_side_for_rule (pos, meta:get_int ("param2"), rule))
							end
						end
					end
				end
			}
		}
	end

	return nil
end



minetest.register_node("lwcomputers:computer", {
   description = S("Computer"),
   tiles = { "computer.png", "computer.png", "computer.png",
				 "computer.png", "computer.png", "computer_face.png" },
   sunlight_propagates = false,
   drawtype = "normal",
   node_box = {
      type = "fixed",
      fixed = {
         {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
      }
   },
	groups = { cracky = 2, oddly_breakable_by_hand = 2 },
	sounds = default.node_sound_wood_defaults (),
	paramtype2 = "facedir",
	param2 = 1,
	drop = "lwcomputers:computer",
	mesecons = mesecon_support (),
	digiline = digilines_support (),

   on_construct = on_construct,
   on_destruct = on_destruct,
	on_receive_fields = on_receive_fields,
	preserve_metadata = preserve_metadata,
	after_place_node = after_place_node,
	on_timer = on_timer,
	can_dig = can_dig,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	on_metadata_inventory_put = on_metadata_inventory_put,
	on_metadata_inventory_take = on_metadata_inventory_take
})



minetest.register_node("lwcomputers:computer_on", {
   description = S("Computer"),
   tiles = { "computer.png", "computer.png", "computer.png",
				 "computer.png", "computer.png", "computer_face_on.png" },
   sunlight_propagates = false,
   drawtype = "normal",
   node_box = {
      type = "fixed",
      fixed = {
         {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
      }
   },
	groups = { cracky = 2, oddly_breakable_by_hand = 2, not_in_creative_inventory = 1 },
	sounds = default.node_sound_wood_defaults (),
	paramtype2 = "facedir",
	param2 = 1,
	drop = "lwcomputers:computer",
	mesecons = mesecon_support (),
	digiline = digilines_support (),

   on_construct = on_construct,
   on_destruct = on_destruct,
	on_receive_fields = on_receive_fields,
	preserve_metadata = preserve_metadata,
	after_place_node = after_place_node,
	on_timer = on_timer,
	can_dig = can_dig,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	on_metadata_inventory_put = on_metadata_inventory_put,
	on_metadata_inventory_take = on_metadata_inventory_take
})



minetest.register_node("lwcomputers:computer_robot", {
   description = S("Robot"),
   tiles = { "robot.png", "robot_bottom.png", "robot_left.png",
				 "robot_right.png", "robot_back.png", "robot_face.png" },
   sunlight_propagates = false,
   drawtype = "normal",
   node_box = {
      type = "fixed",
      fixed = {
         {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
      }
   },
	groups = { cracky = 2, oddly_breakable_by_hand = 2 },
	sounds = default.node_sound_wood_defaults (),
	paramtype2 = "facedir",
	param2 = 1,
	drop = "lwcomputers:computer_robot",
	mesecons = mesecon_support (),
	digiline = digilines_support (),

   on_construct = on_construct_robot,
   on_destruct = on_destruct,
	on_receive_fields = on_receive_fields,
	preserve_metadata = preserve_metadata,
	after_place_node = after_place_node,
	on_timer = on_timer,
	can_dig = can_dig,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	on_metadata_inventory_put = on_metadata_inventory_put,
	on_metadata_inventory_take = on_metadata_inventory_take,
	on_punch = on_punch_robot
})



minetest.register_node("lwcomputers:computer_robot_on", {
   description = S("Robot"),
   tiles = { "robot.png", "robot_bottom.png", "robot_left.png",
				 "robot_right.png", "robot_back.png", "robot_face_on.png" },
   sunlight_propagates = false,
   drawtype = "normal",
   node_box = {
      type = "fixed",
      fixed = {
         {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
      }
   },
	groups = { cracky = 2, oddly_breakable_by_hand = 2, not_in_creative_inventory = 1 },
	sounds = default.node_sound_wood_defaults (),
	paramtype2 = "facedir",
	param2 = 1,
	drop = "lwcomputers:computer_robot",
	mesecons = mesecon_support (),
	digiline = digilines_support (),

   on_construct = on_construct_robot,
   on_destruct = on_destruct,
	on_receive_fields = on_receive_fields,
	preserve_metadata = preserve_metadata,
	after_place_node = after_place_node,
	on_timer = on_timer,
	can_dig = can_dig,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	on_metadata_inventory_put = on_metadata_inventory_put,
	on_metadata_inventory_take = on_metadata_inventory_take,
	on_punch = on_punch_robot
})



minetest.register_on_player_receive_fields(function (player, formname, fields)
   if formname == "lwcomputers:computer_robot_stop" and
		player and player:is_player () then

		for k, v in pairs (fields) do
			if k:sub (1, 5) == "stop_" then
				local data = lwcomputers.get_computer_data (tonumber (k:sub (6)))

				if data then
					data.shutdown ()
				end
			end
		end

		return nil
	end
end)


--
