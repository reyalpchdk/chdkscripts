--[[
License: GPL

Copyright 2014-2021 reyalp (at) gmail.com

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
-- display control module. License: GPL
local disp={
	state=true,
	shutoff_time=false,
	mode='on'
}

function disp:init(opts)
	if opts then
		if opts.mode then
			if not ({on=1,blt_off=1,off=1})[opts.mode] then
				error(('invalid disp mode %s'):format(opts.mode))
			end
			self.mode = opts.mode
		end
		if opts.start_delay then
			self.shutoff_time = get_tick_count() + opts.start_delay
		end
	end
	if self.mode == 'on' then
		self.control_fn=function() end
	elseif self.mode == 'blt_off' then
		self.control_fn=set_backlight
	else
		self.control_fn=set_lcd_display
	end
end

function disp:update()
	-- toggled on, not expired, do nothing (should have been turned on in toggle)
	if self.shutoff_time and get_tick_count() < self.shutoff_time then
		return
	end

	-- if on, and timeout expired turn off
	if self.state then
		self:enable(false)
		self.shutoff_time = false
		return
	end
	-- turn off every shot in backlight mode
	if self.mode == 'blt_off' then
		self:enable(false)
	end
end

function disp:enable(state,timeout)
	if self.mode == 'on' then
		return
	end
	if state and timeout then
		self.shutoff_time = get_tick_count() + timeout
	end
	self.state=state
	self.control_fn(state)
end

function disp:toggle(timeout)
	if not timeout then
		timeout = 30000
	end
	if self.state then
		log:log_desc('disp:toggle off')
		self.shutoff_time = false
		self:enable(false)
	else
		log:log_desc('disp:toggle on')
		self:enable(true,timeout)
	end
end
return disp
