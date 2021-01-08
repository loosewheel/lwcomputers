local version = "0.1.3"
local mod_storage = minetest.get_mod_storage ()
local http_api = minetest.request_http_api ()

lwcomputers = { }



-- settings
local startup_delay = tonumber(minetest.settings:get("lwcomputers_startup_delay") or 3.0)
local http_white_list = minetest.settings:get("lwcomputers_http_white_list") or ""

http_white_list = string.split (http_white_list, " ")
for l = 1, #http_white_list do
	http_white_list[l] = string.gsub (http_white_list[l], "*", ".*")
end



if minetest.global_exists("intllib") then
   if intllib.make_gettext_pair then
      lwcomputers.S = intllib.make_gettext_pair()
   else
      lwcomputers.S = intllib.Getter()
   end
else
   lwcomputers.S = function(s) return s end
end



lwcomputers.modpath = minetest.get_modpath("lwcomputers")
lwcomputers.worldpath = minetest.get_worldpath()
lwcomputers.computer_data = { }
lwcomputers.computer_list = minetest.deserialize (mod_storage:get_string ("computer_list") or "")

if type (lwcomputers.computer_list) ~= "table" then
	lwcomputers.computer_list = { }
end



minetest.mkdir (lwcomputers.worldpath.."/lwcomputers")



function lwcomputers.version ()
	return version
end


function lwcomputers.store_computer_list ()
	mod_storage:set_string ("computer_list",
				minetest.serialize (lwcomputers.computer_list))

end



function lwcomputers.http_fetch (request, computer)
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



-- check for mesecon
if minetest.global_exists ("mesecon") then
	lwcomputers.mesecon_supported = true
	lwcomputers.mesecon_state_on = mesecon.state.on
	lwcomputers.mesecon_state_off = mesecon.state.off
	lwcomputers.mesecon_receptor_on = mesecon.receptor_on
	lwcomputers.mesecon_receptor_off = mesecon.receptor_off
	lwcomputers.mesecon_default_rules = mesecon.rules.default

else
	lwcomputers.mesecon_supported = false
	lwcomputers.mesecon_state_on = "on"
	lwcomputers.mesecon_state_off = "off"
	lwcomputers.mesecon_default_rules = { }

	-- dummies
	lwcomputers.mesecon_receptor_on = function (pos, rules)
	end

	lwcomputers.mesecon_receptor_off = function (pos, rules)
	end

end



-- check for digilines
if minetest.global_exists ("digilines") then
	lwcomputers.digilines_supported = true
	lwcomputers.digilines_receptor_send = digilines.receptor_send
else
	lwcomputers.digilines_supported = false

	-- dummy
	lwcomputers.digilines_receptor_send = function (pos, rules, channel, msg)
	end
end



lwcomputers.colors =
{
	black		= 0,
	orange	= 1,
	magenta	= 2,
	sky		= 3,
	yellow	= 4,
	pink		= 5,
	cyan		= 6,
	gray		= 7,
	silver	= 8,
	red		= 9,
	green		= 10,
	blue		= 11,
	brown		= 12,
	lime		= 13,
	purple	= 14,
	white		= 15
}



lwcomputers.keys =
{
	KEY_BACKSPACE		= 8,
	KEY_TAB				= 9,
	KEY_LINE				= 10,
	KEY_ENTER			= 13,
	KEY_ESC				= 27,
	KEY_SPACE			= 32,
	KEY_EXCLAIM			= 33,
	KEY_QUOTE			= 34,
	KEY_HASH				= 35,
	KEY_CURRENCY		= 36,
	KEY_PERCENT			= 37,
	KEY_AMP				= 38,
	KEY_APOSTROPHE		= 39,
	KEY_OPENPAREN		= 40,
	KEY_CLOSEPAREN		= 41,
	KEY_MULTIPLY		= 42,
	KEY_ADD				= 43,
	KEY_COMMA			= 44,
	KEY_SUBTRACT		= 45,
	KEY_DOT				= 46,
	KEY_DIVIDE			= 47,
	KEY_0					= 48,
	KEY_1					= 49,
	KEY_2					= 50,
	KEY_3					= 51,
	KEY_4					= 52,
	KEY_5					= 53,
	KEY_6					= 54,
	KEY_7					= 55,
	KEY_8					= 56,
	KEY_9					= 58,
	KEY_COLON			= 58,
	KEY_SEMICOLON		= 59,
	KEY_LESS				= 60,
	KEY_EQUAL			= 61,
	KEY_GREATER			= 62,
	KEY_QUESTION		= 63,
	KEY_AT				= 64,
	KEY_A					= 65,
	KEY_B					= 66,
	KEY_C					= 67,
	KEY_D					= 68,
	KEY_E					= 69,
	KEY_F					= 70,
	KEY_G					= 71,
	KEY_H					= 72,
	KEY_I					= 73,
	KEY_J					= 74,
	KEY_K					= 75,
	KEY_L					= 76,
	KEY_M					= 77,
	KEY_N					= 78,
	KEY_O					= 79,
	KEY_P					= 80,
	KEY_Q					= 81,
	KEY_R					= 82,
	KEY_S					= 83,
	KEY_T					= 84,
	KEY_U					= 85,
	KEY_V					= 86,
	KEY_W					= 87,
	KEY_X					= 88,
	KEY_Y					= 89,
	KEY_Z					= 90,
	KEY_OPENSQUARE		= 91,
	KEY_SLASH			= 92,
	KEY_CLOSESQUARE	= 93,
	KEY_CARET			= 94,
	KEY_UNDERSCORE		= 95,
	KEY_TICK				= 96,
	KEY_OPENBRACE		= 123,
	KEY_BAR				= 124,
	KEY_CLOSEBRACE		= 125,
	KEY_TILDE			= 126,
	KEY_DELETE			= 127,
	KEY_INSERT			= 128,
	KEY_HOME				= 129,
	KEY_END				= 130,
	KEY_PAGEUP			= 131,
	KEY_PAGEDOWN		= 132,
	KEY_SHIFT			= 133,
	KEY_CAPS				= 134,
	KEY_CTRL				= 135,
	KEY_ALT				= 136,
	KEY_UP				= 137,
	KEY_DOWN				= 138,
	KEY_LEFT				= 139,
	KEY_RIGHT			= 140,
	KEY_F1				= 141,
	KEY_F2				= 142,
	KEY_F3				= 143,
	KEY_F4				= 144,
	KEY_F5				= 145,
	KEY_F6				= 146,
	KEY_F7				= 147,
	KEY_F8				= 148,
	KEY_F9				= 149,
	KEY_F10				= 150,
	KEY_F11				= 151,
	KEY_F12				= 152
}



lwcomputers.shift_keys =
{
	KEY_TICK				= lwcomputers.keys.KEY_TILDE,
	KEY_0					= lwcomputers.keys.KEY_CLOSEPAREN,
	KEY_1					= lwcomputers.keys.KEY_EXCLAIM,
	KEY_2					= lwcomputers.keys.KEY_AT,
	KEY_3					= lwcomputers.keys.KEY_HASH,
	KEY_4					= lwcomputers.keys.KEY_CURRENCY,
	KEY_5					= lwcomputers.keys.KEY_PERCENT,
	KEY_6					= lwcomputers.keys.KEY_CARET,
	KEY_7					= lwcomputers.keys.KEY_AMP,
	KEY_8					= lwcomputers.keys.KEY_MULTIPLY,
	KEY_9					= lwcomputers.keys.KEY_OPENPAREN,
	KEY_SUBTRACT		= lwcomputers.keys.KEY_UNDERSCORE,
	KEY_EQUAL			= lwcomputers.keys.KEY_ADD,
	KEY_OPENSQUARE		= lwcomputers.keys.KEY_OPENBRACE,
	KEY_SLASH			= lwcomputers.keys.KEY_BAR,
	KEY_CLOSESQUARE	= lwcomputers.keys.KEY_CLOSEBRACE,
	KEY_SEMICOLON		= lwcomputers.keys.KEY_COLON,
	KEY_APOSTROPHE		= lwcomputers.keys.KEY_QUOTE,
	KEY_COMMA			= lwcomputers.keys.KEY_LESS,
	KEY_DOT				= lwcomputers.keys.KEY_GREATER,
	KEY_DIVIDE			= lwcomputers.keys.KEY_QUESTION
}



dofile(lwcomputers.modpath.."/filesys.lua")
dofile(lwcomputers.modpath.."/clipboard.lua")
dofile(lwcomputers.modpath.."/floppy.lua")
dofile(lwcomputers.modpath.."/computer.lua")
dofile(lwcomputers.modpath.."/digiswitch.lua")
dofile(lwcomputers.modpath.."/page.lua")
dofile(lwcomputers.modpath.."/book.lua")
dofile(lwcomputers.modpath.."/ink_cartridge.lua")
dofile(lwcomputers.modpath.."/printer.lua")
dofile(lwcomputers.modpath.."/crafting.lua")



local function restart_computers ()
	local remove_list = { }

	for sid, stats in pairs (lwcomputers.computer_list) do
		local id = tonumber (sid)
		local data = lwcomputers.computer_data[sid]
		local running = false

		if data then
			running = data.running
		end

		-- if not already started
		if not running then
			local meta = minetest.get_meta (stats.pos)

			if meta then
				local test_id = meta:get_int ("lwcomputer_id")

				if test_id == 0 or test_id ~= id then
					-- no longer there
					remove_list[#remove_list + 1] = id

				else
					if meta:get_int ("running") == 1 then
						local data = lwcomputers.get_computer_data (id, stats.pos, meta:get_int ("persists") == 1)

						if data then
							data.startup ()
						end
					end
				end
			-- else out of range or doesn't exist
			end
		end
	end

	-- remove redundant machines
	for c = 1, #remove_list do
		lwcomputers.remove_computer_data (remove_list[c])
	end
end



local function on_mods_loaded ()
	minetest.after (startup_delay, restart_computers)
end



minetest.register_on_mods_loaded (on_mods_loaded)






--
