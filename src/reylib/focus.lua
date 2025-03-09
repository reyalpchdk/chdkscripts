--[[
License: GPL

Copyright 2014-2025 reyalp (at) gmail.com

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
with CHDK. If not, see <http://www.gnu.org/licenses/>.
]]

--[!inline:module_start]
-- Focus override module. Author: reyalp (at) gmail.com. License: GPL.
-- Source: https://github.com/reyalpchdk/chdkscripts
local focus={
	mode_names={'AF','AFL','MF'},
	-- populated after init
	-- valid_modes={} -- table of name=true
	-- modes={} -- array of usable mode names
	-- modebits -- bitmask of available modes
}

local props=require'propcase'

--[[
override in AF ignored in cont or servo AF
but does not affect get_sd_over_modes
]]
function focus:af_override_blocked()
	if props.CONTINUOUS_AF and get_prop(props.CONTINUOUS_AF) ~= 0 then
		return true
	end
	if props.SERVO_AF and get_prop(props.SERVO_AF) ~= 0 then
		return true
	end
end

--[[
get bitmask representing available modes, as defined by
port and servo + cont AF state
]]
function focus:get_modebits()
	local bits=get_sd_over_modes()
	if self:af_override_blocked() then
		bits = bitand(bits,bitnot(1))
	end
	return bits
end

-- initialize valid modes for sd over
function focus:init()
	local modebits = self:get_modebits()
	if self.modebits == modebits then
		return
	end
	self.modebits=modebits
	self.valid_modes={} -- table of name=true
	self.modes={} -- array of usable mode names
	for i,name in ipairs(self.mode_names) do
		if bitand(1,modebits) == 1 then
			table.insert(self.modes,name)
			self.valid_modes[name]=true
		end
		modebits = bitshru(modebits,1)
	end
end

-- get current AF/AFL/MF state as string, one of 'AF', 'AFL', 'MF'
function focus:get_mode()
	if get_prop(props.AF_LOCK) == 1 then
		return 'AFL'
	end
	if get_prop(props.FOCUS_MODE) == 1 then
		return 'MF'
	end
	return 'AF'
end
--[[
set AF/AFL/MF state
mode is one of 'AF','MF', 'AFL'
unless force is true, does not call set functions if already in desired state
]]
function focus:set_mode(mode,force)
	local cur_mode = self:get_mode()
	if not force and cur_mode == mode then
		return
	end
	if mode == 'AF' then
		if cur_mode == 'MF' then
			set_mf(false)
		elseif cur_mode == 'AFL' then
			set_aflock(false)
		end
	elseif mode == 'AFL' then
		if cur_mode == 'MF' then
			set_mf(false)
		end
		set_aflock(true)
	elseif mode == 'MF' then
		if cur_mode == 'AFL' then
			set_aflock(false)
		end
		set_mf(true)
	end
end
--[[
set to a mode that allows override, defaulting to prefmode, or the current mode if not set
if prefmode is 'MF' or 'AFL' and not available, then the other is preffered over AF
returns true if a mode supporting SD overrides is available, false otherwise
]]
function focus:enable_override(prefmode)
	-- ensure initialized
	self:init()
	-- override not supported or in playback
	if #self.modes == 0 or not get_mode() then
		return false
	end
	-- no pref, default to overriding in current mode if possible
	if not prefmode then
		prefmode = self:get_mode()
	end
	local usemode
	if self.valid_modes[prefmode] then
		usemode = prefmode
	else
		-- if pref is MF or AFL, prefer locked if available
		if prefmode == 'MF' and self.valid_modes['AFL'] then
			usemode = 'AFL'
		elseif prefmode == 'AFL' and self.valid_modes['MF'] then
			usemode = 'MF'
		elseif self.valid_modes[self:get_mode()] then
			usemode = self:get_mode()
		else
			-- no pref, use last available (MF if present)
			usemode = self.modes[#self.modes]
		end
	end
	self:set_mode(usemode)
	return true
end
function focus:set(dist)
	set_focus(dist)
end
return focus
