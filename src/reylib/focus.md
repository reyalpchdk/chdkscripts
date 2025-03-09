focus.lua - Module for portable focus control

# Overview
This module provides a simple interface to handle platform and setting specific requirements to enable focus control (SD override) in CHDK Lua scripts. Many CHDK ports need to be in a specific focus mode (Auto Focus, Auto Focus Lock or Manual Focus) to override focus, and settings such as Continuous AF and Servo AF prevent overrides in AF mode.


# Usage
Methods in the this module should only be called when the camera is in rec (shooting) mode.

In this module, focus modes are identified by the strings "AF", "AFL" or "MF" for Auto Focus, Auto Focus Lock and Manual Focus respectively.

Basic example
```lua
focus=require'focus'
if not focus:enable_override() then
  error("focus override not available")
end
set_focus(distance)
```
The `focus:get_mode()` and `focus:set_mode()` methods can be used to save and restore the focus mode.

# Primary Methods
* `focus:enable_override(prefmode)` Set the focus mode to one which supports overrides. Automatically calls `focus:init()` if needed. `prefmode` is an optional mode name, as returned by `focus:get_mode()` which specifies a mode to prefer if available. If `prefmode` is not supported, another mode will be used, preferring MF or AFL if available. Returns true if a mode supporting focus override was set, otherwise false.
* `focus:init()` Initialize the module based on modes supported by the port and current settings.
* `mode=focus:get_mode()` return the current mode as a string, one of "AF", "AFL" or "MF"
* `focus:set_mode(mode,force)` set the focus mode, using a string name as returned by `focus:get_mode()`. An optional second parameter forces the mode to be set even if it appears to already be set.

# Module fields
Set at module load
* `focus.mode_names` Array of possible focus modes, in the same order as bits returned by `get_sd_over_modes()`: "AF","AFL","MF"

The following are set after `focus:init` or `focus:enable_override` has been called:
* `focus.valid_modes` Table of modename=true, so `focus.valid_modes.MF` is true if CHDK can override focus in MF mode.
* `focus.modes` Array of modes which in which focus override is supported, in the same order as `focus.mode_names`.
* `focus.modebits` Bitmask of modes which support focus override, as returned by `focus:get_modebits()`.

# Helper methods
* `bitmask=focus:get_modebits()` Return bitmask of modes which support focus overrides, like CHDK `get_sd_over_modes()` but excluding AF if disabled by Servo or Continuous AF.
* `bool=focus:af_override_blocked()` Reports whether override in AF mode is blocked by Servo or Continuous AF
* `focus:set(dist)` Calls CHDK `set_focus(dist)`

# Examples
See [rawopint](/src/rawopint) and [fixedint](/src/fixedint) in this repository.
