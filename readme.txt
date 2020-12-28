LWComputers
	by loosewheel


Licence
=======
Code licence:
LGPL 2.1

Font images:
Are derived from Liberation Mono licensed under the Liberation Fonts license,
see https://fedoraproject.org/wiki/Licensing/LiberationFontLicense

Art licence:
CC-BY-SA


Version
=======
0.1.0


Minetest Version
================
This mod was developed on version 5.3.0


Dependencies
============
default


Optional Dependencies
=====================
intllib
mesecon
digilines


Installation
============
Copy the 'lwcomputers' folder to your mods folder.


Bug Report
==========
Don't know


Description
===========
LWComputers provides programmable computers and floppy disks.

Each computer has an internal hard drive, and 3 slots for floppy disks
(or a clipboard). The terminal display has a resolution of 50 characters
wide by 19 characters high by default. This can be changed through the
mod settings. 16 colors are supported for both fore-ground and back-ground.
The computer GUI has a keyboard, a reboot button, a power button and a
persistence button. The terminal also responds to mouse clicks, which can
be disabled through the mod settings.

The persistence button toggles on and off. If persistence is on the block
the computer is in remains loaded when out of range. This persistence is
retained across world startups.

The Ctrl, Cap, Shift and Alt keys on the keyboard toggle down and up. When
in the down state the key's label is suffixed with a "*".

If a floppy is "used" (left click) a form displays the floppy's id and
label. If the floppy has never been put in a computer's slot its id shows
as "<not used>". If a floppy has no label its label shows as "<no label>".

Each disk has its own directory under the world folder with its contents.

Each computer and floppy disk has a unique integer id assigned to it.

The path to a computers hard drive's contents:
<minetest path>/worlds/<world>/lwcomputers/computer_<id>

The path to a floppy disk's contents:
<minetest path>/worlds/<world>/lwcomputers/floppy_<id>

The contents of the disks can be edited with an external editor.

A computer's hard drive folder is created the first time it is powered up.
A floppy disk's folder is created the first time it is placed in a computer's
slot.

The computers don't have an inbuilt os. When the computer is powered up
it looks for a file named 'boot' in the root folder of the drives in order
slot 1 (left), slot 2, slot 3 then internal hard drive. The first one found
is loaded and run. If none is found the computer halts and displays
"No boot media ...".

When a world is restarted, any computers running from the last shut down is
rebooted. It does not keep running from where it left off, but boots
clean.

The mod also has a clipboard item, and copy and paste actions are possible
through it. It must be placed in one of the computer's slots to use it.
"Using" the clipboard (left click) displays its contents.

The computer can provide a mesecon power source, if mesecon is loaded.
It can also send digilines messages, and be given a channel and receive
them if its loaded. These are all done through the computer's api.

The api provides access to the http api if privileges for the mod have been
set. Address must be entered into the mods white list to be accessible.

The computers programming language is lua. Each computer's running environment
is sand-boxed and runs in its own thread. See the docs/api_ref.txt file for
the computer's lua environment.

The programs running in the computer should run in short bursts to not hog
processor. There are 2 functions in the computer's environment that will
yield processing back to the game: os.get_event and os.sleep. If a program
runs longer than 5 seconds without yielding, the program halts with the error
'too long without yielding'. This duration can be changed through the mod
settings.

When a program yields through os.get_event the thread is resumed when an
event is queued. Supported event:

key			key was pressed
char			character following key press, not queued if the ctrl and/or
				alt keys are down.
click			the mouse was clicked on the terminal's display.
wireless		received a wireless message from another computer.
timer			a set timer elapsed
clipboard	the ctrl, alt and v key where pressed with a clipboard in a slot.
disk			floppy disk inserted or ejected.
digilines	a digilines message was received.


A computers file system starts at a single root "/". Any floppies are
accessed as "/<mount>". The mount will be the label of the floppy or
"floppy_<id>" if the label isn't set.

If a computer is moved it retains its id and hard drive data. If a computer
or floppy is disposed of the disk's folder in the world save remains.


Lua disk
--------
The lua disk boots into a lua prompt.

Enter: If the line ends with "\" (must be last character) continues on the
	next line, otherwise runs the entered code.
Backspace: Remove the last character entered.
Escape: Aborts the current line and displays "ABORT" if multi-line input
	or "ESC" for single line. If the code is multi-lined and pressed on an
	empty line the whole code is aborted and displays "ABORT".
Up arrow: The last code run is added to the current line.
Ctrl+Alt+V: If a clipboard is in a slot its contents are copied to the
	code line. This content can be lengthy. New lines in the content are
	input as is (new line, not as an enter press).


The mod supports the following settings:

Restart delay on startup (float)
	How many seconds after mods are loaded to delay restarting running
	computers (reduce processor load at game start).
	Default: 3.0

Terminal horizontal resolution (int)
	Terminal character width.
	Default: 50

Terminal vertical resolution (int)
	Terminal character height.
	Default: 19

Running interval seconds (float)
	Seconds interval between running ticks (time between a computer's
	program yielding and it being resumed).
	Default: 0.1

Maximum no yield seconds (float)
	Maximum number of seconds a computer's tick can run before generating
	a 'too long without yielding' error.
	Default: 5.0

Generate click events (bool)
	Weather the terminal generates click events.
	Default: true

Double click seconds (float)
	The duration of time in seconds from one click to the next on the same
	character for it to be considered a double click. There is no double
	click event, but the click event includes a click count. Successive
	clicks on the same character increase the click count. It is not limited
	to two.
	Default: 0.5

Maximum string.rep length (int)
	The maximum length of a string for the string.rep function. This is
	the given string length by the repeat value.
	Default: 64000

Maximum clipboard content length (int)
	The maximum length of a string for clipboard item.
	Default: 64000

The year the in-game calendar begins (int)
	Computer time values are relative to the beginning of the given year.
	The minimum year is 1970.
	Default: 2000
	* Careful being too ambitious with this year. It may exceed the system
	counter and truncate.

HTTP white list, space separated list (string)
	Space separated white list of permissible addresses to access via HTTP
	calls. The list entries can contain * wild cards.
	eg, *here.com* https://www.there.com*
	Default is an empty list (no permissible addresses)


** Notes

The form for the terminal contains many elements. This amount is increased
with larger terminal character sizes, and is nearly doubled to support click
events. If the terminal is too sluggish, try reducing the character resolution
and/or disabling click events.


--
