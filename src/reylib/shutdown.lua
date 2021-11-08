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

--[!inline_start]
-- shutdown handling module. License: GPL
local shutdown={}
function shutdown:init(opts)
	self.reasons={}
	if not opts then
		opts={}
	end
	self.opts = opts -- note, reference not copy
	if not self.opts.lowbat_val then
		self.opts.lowbat_val = get_config_value(require'GEN/cnf_osd'.batt_volts_min)
	end
	if not self.opts.lowspace_kb_val then
		self.opts.lowspace_kb_val = 50*1024 -- 50 megs... could calc 1 raw + jpeg but not worth it
	end
end
function shutdown:check()
	if self.opts.lowbat and get_vbatt() < self.opts.lowbat_val then
		table.insert(self.reasons,'lowbat')
	end
	if self.opts.lowspace and get_free_disk_space() < self.opts.lowspace_kb_val then
		table.insert(self.reasons,'lowspace')
	end
	return #self.reasons > 0
end

function shutdown:reason()
	return table.concat(self.reasons,' ')
end

function shutdown:do_shutdown()
	post_levent_to_ui("PressPowerButton")
	-- probably not needed
	sleep(100)
	post_levent_to_ui("UnpressPowerButton")
end

function shutdown:finish()
	if #self.reasons == 0 and self.opts.finish then
		table.insert(self.reasons,'finish')
	end
	if #self.reasons > 0 then
		self:do_shutdown()
	end
end
return shutdown
