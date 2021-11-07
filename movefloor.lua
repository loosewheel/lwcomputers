local lwcomp = ...
local S = lwcomp.S



-- depreciated
local movefloor_groups = { cracky = 2 }
if minetest.global_exists ("lwcomponents") then
	movefloor_groups.not_in_creative_inventory = 1
end



if lwcomp.mesecon_supported and mesecon.mvps_push then



local mesecon_rules =
{
	{ x =  1, y =  1, z =  0 },
	{ x = -1, y =  1, z =  0 },
	{ x =  0, y =  1, z =  1 },
	{ x =  0, y =  1, z = -1 },
	{ x =  1, y = -1, z =  0 },
	{ x = -1, y = -1, z =  0 },
	{ x =  0, y = -1, z =  1 },
	{ x =  0, y = -1, z = -1 },
}



-- use mesecons movestone settings
local timer_interval = 1 / mesecon.setting ("movestone_speed", 3)
local max_push = 3
local max_pull = 3



-- helper functions:
local function get_movefloor_direction (rulename)
	if rulename.y > 0 then
		return { x = 0, y = 1, z = 0 }
	elseif rulename.y < 0 then
		return { x = 0, y = -1, z = 0 }
	end
end


local function add_movefloor_list (pos, list)
	for i = 1, #list do
		if list[i].x == pos.x and
			list[i].y == pos.y and
			list[i].z == pos.z then

			return false
		end
	end

	list[#list + 1] = { x = pos.x, y = pos.y, z = pos.z }

	return true
end



local function find_adjoining_movefloor (pos, list)
	local tpos =
	{
		{ x = pos.x + 1, y = pos.y, z = pos.z },
		{ x = pos.x - 1, y = pos.y, z = pos.z },
		{ x = pos.x, y = pos.y, z = pos.z + 1 },
		{ x = pos.x, y = pos.y, z = pos.z - 1 }
	}

	for i = 1, #tpos do
		local node = minetest.get_node (tpos[i])
		if node and node.name == "lwcomputers:movefloor" then
			if add_movefloor_list (tpos[i], list) then
				find_adjoining_movefloor (tpos[i], list)
			end
		end
	end
end



-- copied from mesecons movestone
local function movefloor_move (pos, node, rulename, is_sticky)
	local direction = get_movefloor_direction (rulename)
	local play_sound = false

	local list =
	{
		{ x = pos.x, y = pos.y, z = pos.z }
	}

	find_adjoining_movefloor (pos, list)

	for i = 1, #list do
		local frontpos = vector.add (list[i], direction)
		local meta = minetest.get_meta (list[i])
		local owner = meta:get_string ("owner")
		local continue = true

		-- ### Step 1: Push nodes in front ###
		local success, stack, oldstack = mesecon.mvps_push (frontpos, direction, max_push, owner)
		if not success then
			if stack == "protected" then
				meta:set_string ("infotext", "Can't move: protected area on the way")
			else
				minetest.get_node_timer (list[i]):start (timer_interval)
				continue = false
			end
		end

		if continue then
			mesecon.mvps_move_objects (frontpos, direction, oldstack)

			-- ### Step 2: Move the movestone ###
			minetest.set_node (frontpos, node)
			local meta2 = minetest.get_meta (frontpos)
			meta2:set_string ("owner", owner)
			minetest.remove_node (list[i])
			mesecon.on_dignode (list[i], node)
			mesecon.on_placenode (frontpos, node)
			minetest.get_node_timer (frontpos):start (timer_interval)
			play_sound = true

			-- ### Step 3: If sticky, pull stack behind ###
			if is_sticky and direction.y < 0 then
				local backpos = vector.subtract (list[i], direction)
				success, stack, oldstack = mesecon.mvps_pull_all (backpos, direction, max_pull, owner)
				if success then
					mesecon.mvps_move_objects (backpos, vector.multiply (direction, -1), oldstack, -1)
				end
			end

			-- ### Step 4: Let things fall ###
			minetest.check_for_falling (vector.add (list[i], { x = 0, y = 1, z = 0 }))
		end
	end

	if play_sound then
		minetest.sound_play("movestone", { pos = list[i], max_hear_distance = 20, gain = 0.5 }, true)
	end

end



local function on_timer (pos, elapsed)
	local sourcepos = mesecon.is_powered (pos)

	if not sourcepos then
		return
	end

	local rulename = vector.subtract (sourcepos[1], pos)

	mesecon.activate (pos, minetest.get_node (pos), rulename, 0)
end



local function mesecon_support ()
	return
	{
		effector =
		{
			rules = table.copy (mesecon_rules),

			action_on = function (pos, node, rulename)
				-- do something to turn the effector on

				if rulename and not minetest.get_node_timer (pos):is_started () then
					movefloor_move (pos, node, rulename, true)
				end
			end
		}
	}
end



minetest.register_node("lwcomputers:movefloor", {
   description = S("Moving Floor"),
   tiles = { "lwmovefloortop.png", "lwmovefloortop.png",
				 "lwmovefloorside.png", "lwmovefloorside.png",
				 "lwmovefloorside.png", "lwmovefloorside.png" },
   sunlight_propagates = false,
   drawtype = "normal",
   node_box = {
      type = "fixed",
      fixed = {
         {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
      }
   },
	groups = movefloor_groups,
	sounds = default.node_sound_wood_defaults (),
	mesecons = mesecon_support (),

	on_timer = on_timer,
})



end
