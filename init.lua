local version = "0.2.5"
local mod_storage = minetest.get_mod_storage ()
local http_api = minetest.request_http_api ()



lwcomputers = { }



function lwcomputers.version ()
	return version
end



local lwcomp = { }
local modpath = minetest.get_modpath ("lwcomputers")
local worldpath = minetest.get_worldpath ()


loadfile (modpath.."/settings.lua") (lwcomp)
loadfile (modpath.."/utils.lua") (lwcomp, mod_storage, http_api)
loadfile (modpath.."/api.lua") (lwcomp)
minetest.mkdir (worldpath.."/lwcomputers")
loadfile (modpath.."/filesys.lua") (lwcomp)
loadfile (modpath.."/clipboard.lua") (lwcomp)
loadfile (modpath.."/floppy.lua") (lwcomp)
loadfile (modpath.."/term_formspec.lua") (lwcomp)
loadfile (modpath.."/computer_env.lua") (lwcomp)
loadfile (modpath.."/computer.lua") (lwcomp)
loadfile (modpath.."/digiswitch.lua") (lwcomp)
loadfile (modpath.."/page.lua") (lwcomp)
loadfile (modpath.."/book.lua") (lwcomp)
loadfile (modpath.."/ink_cartridge.lua") (lwcomp)
loadfile (modpath.."/printer.lua") (lwcomp)
loadfile (modpath.."/crafting.lua") (lwcomp)
loadfile (modpath.."/trash.lua") (lwcomp)
loadfile (modpath.."/extras.lua") (lwcomp)
loadfile (modpath.."/movefloor.lua") (lwcomp)
loadfile (modpath.."/solid_conductor.lua") (lwcomp)
loadfile (modpath.."/digiscreens.lua") (lwcomp)
loadfile (modpath.."/monitors.lua") (lwcomp)
loadfile (modpath.."/monitor_interface.lua") (lwcomp)



local function restart_computers ()
	local remove_list = { }

	for sid, stats in pairs (lwcomp.computer_list) do
		local id = tonumber (sid)
		local data = lwcomp.computer_data[sid]
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
						local comp_data = lwcomp.get_computer_data (id, stats.pos)

						if comp_data then
							comp_data.startup ()
						end
					end
				end
			-- else out of range or doesn't exist
			end
		end
	end

	-- remove redundant machines
	for c = 1, #remove_list do
		lwcomp.remove_computer_data (remove_list[c])
	end
end



local function on_mods_loaded ()
	minetest.after (lwcomp.settings.startup_delay, restart_computers)
end



minetest.register_on_mods_loaded (on_mods_loaded)



local function on_shutdown ()
	lwcomp.store_computer_list ()
end



minetest.register_on_shutdown (on_shutdown)


--
