local lwcomp = ...
local S = lwcomp.S



local depreciated = minetest.global_exists ("lwcomponents")



local touchscreen = minetest.registered_nodes["digistuff:touchscreen"]
if touchscreen then
	local touchblock = table.copy (touchscreen)

	touchblock.description = S("LWComputers Touchscreen")

	touchblock.node_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
		}
    }

	touchblock.selection_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
		}
    }

	touchblock.collision_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
		}
    }

if depreciated then
	touchblock.groups.not_in_creative_inventory = 1
end

	minetest.register_node ("lwcomputers:touchscreen", touchblock)

if not depreciated then
	minetest.register_craft({
		output = "lwcomputers:touchscreen",
		recipe = {
			{"mesecons_luacontroller:luacontroller0000","default:glass","default:glass"},
			{"default:glass","digilines:lcd","default:glass"},
			{"default:glass","default:glass","default:stone"}
		}
	})
end
end



local panel = minetest.registered_nodes["digistuff:panel"]
if panel then
	local panelblock = table.copy (panel)

	panelblock.description = S("LWComputers Control Panel")

	panelblock.node_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
		}
    }

	panelblock.selection_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
		}
    }

	panelblock.collision_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
		}
    }

if depreciated then
	panelblock.groups.not_in_creative_inventory = 1
end

	minetest.register_node ("lwcomputers:panel", panelblock)

if not depreciated then
	minetest.register_craft({
		output = "lwcomputers:panel",
		recipe = {
			{"","digistuff:button",""},
			{"digistuff:button","digilines:lcd","digistuff:button"},
			{"","digistuff:button","default:stone"}
		}
	})
end
end



--
