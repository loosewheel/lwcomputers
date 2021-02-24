local lwcomp = ...


lwcomp.settings = { }

lwcomp.settings.startup_delay =
	tonumber(minetest.settings:get ("lwcomputers_startup_delay") or 3.0)

lwcomp.settings.meta_disks =
	minetest.settings:get_bool ("lwcomputers_use_meta_disks", false)

lwcomp.settings.term_hres =
	tonumber(minetest.settings:get("lwcomputers_term_hres") or 50)

lwcomp.settings.term_vres =
	tonumber(minetest.settings:get("lwcomputers_term_vres") or 19)

lwcomp.settings.running_tick =
	tonumber(minetest.settings:get("lwcomputers_running_tick") or 0.1)

lwcomp.settings.click_events =
	minetest.settings:get_bool("lwcomputers_click_events", true)

lwcomp.settings.double_click_time =
	tonumber(minetest.settings:get("lwcomputers_double_click_time") or 0.5)

-- as microseconds
lwcomp.settings.max_no_yield_Msecs =
	tonumber(minetest.settings:get("lwcomputers_max_no_yield_secs") or 5.0) * 1000000.0

lwcomp.settings.max_string_rep_size =
	tonumber(minetest.settings:get("lwcomputers_max_string_rep_size") or 64000)

lwcomp.settings.max_clipboard_length =
	tonumber(minetest.settings:get("lwcomputers_max_clipboard_length") or 64000)

lwcomp.settings.time_scale =
	tonumber(minetest.settings:get("time_speed") or 0)

lwcomp.settings.epoch_year =
	tonumber(minetest.settings:get("lwcomputers_epoch_year") or 2000)

lwcomp.settings.epoch_offset = os.time ({
	year = lwcomp.settings.epoch_year,
	month = 1,
	day = 1,
	hour = 0,
	min = 0,
	sec = 0,
	isdst = false
})

lwcomp.settings.robot_move_delay =
	tonumber(minetest.settings:get("lwcomputers_robot_move_delay") or 0.5)

lwcomp.settings.robot_action_delay =
	tonumber(minetest.settings:get("lwcomputers_robot_action_delay") or 0.2)

if lwcomp.settings.robot_move_delay < 0.1 then
	lwcomp.settings.robot_move_delay = 0.1
end

if lwcomp.settings.robot_action_delay < 0.1 then
	lwcomp.settings.robot_action_delay = 0.1
end

lwcomp.settings.http_white_list =
	string.split (minetest.settings:get("lwcomputers_http_white_list") or "", " ")

for l = 1, #lwcomp.settings.http_white_list do
	lwcomp.settings.http_white_list[l] = string.gsub (lwcomp.settings.http_white_list[l], "*", ".*")
end

lwcomp.settings.hdd_max_size =
	tonumber(minetest.settings:get("lwcomputers_max_hard_disk_size") or 1000000)

lwcomp.settings.floppy_max_size =
	tonumber(minetest.settings:get("lwcomputers_max_floppy_disk_size") or 125000)

lwcomp.settings.hdd_max_items =
	tonumber(minetest.settings:get("lwcomputers_max_hard_disk_items") or 8000)

lwcomp.settings.floppy_max_items =
	tonumber(minetest.settings:get("lwcomputers_max_floppy_disk_items") or 1000)



--
