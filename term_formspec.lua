local lwcomp = ...


local term_form_width = 16.8 -- formspec units
local hscale = term_form_width / lwcomp.settings.term_hres
local vscale = hscale * 1.5

-- contains static parts of formspec
local form_header = ""
local form_footer = ""

-- contains click button array for easy lookup
lwcomp.click_buttons = { }



-- returns a formspec click button
local function click_button (x, y)
	local c = (y * lwcomp.settings.term_hres) + x

	lwcomp.click_buttons[string.format ("c_%04d", c)] = { x = x, y = y }

	return string.format ("button[%1.2f,%1.2f;%1.2f,%1.2f;c_%04d;]",
								 x * hscale, y * vscale,
								 hscale, vscale, c)
end



-- builds static formspec components
local function build_form_constants ()
	local fw = (lwcomp.settings.term_hres * hscale) + 1.0
	local fh = (lwcomp.settings.term_vres * vscale) + 5.25

	form_header =
	string.format ("formspec_version[3]"..
						"size[%1.2f,%1.2f,false]"..
						"no_prepend[]"..
						"bgcolor[#E7DAA8]"..
						"container[0.5,0.5]",
						fw, fh)

	if lwcomp.settings.click_events then
		for y = 0, (lwcomp.settings.term_vres - 1) do
			for x = 0, (lwcomp.settings.term_hres - 1) do
				form_header = form_header..click_button (x, y)
			end
		end
	end



	local kby = (lwcomp.settings.term_vres * vscale) + 0.75

	form_footer =
	"container_end[]"..
	"button[0.5,"..tostring (kby)..";0.9,0.7;KEY_ESCAPE;Esc]"..
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
	";0.7,0.7;lwcomputers_power_button.png;power;;false;false;lwcomputers_power_button.png]"..
	"image_button["..tostring (fw - 1.2)..","..tostring (fh - 3.4).. --tostring (kby + 0.8)..
	";0.7,0.7;lwcomputers_reboot_button.png;reboot;;false;false;lwcomputers_reboot_button.png]"

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



function lwcomp.term_formspec (data)
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
		";0.7,0.7;lwcomputers_persist_button_on.png;persists;;false;false;lwcomputers_persist_button_on.png]"
	else
		btns = btns..
		"image_button["..tostring (fw - 2.2)..","..tostring (fh - 3.4)..
		";0.7,0.7;lwcomputers_persist_button_off.png;persists;;false;false;lwcomputers_persist_button_off.png]"
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



--
