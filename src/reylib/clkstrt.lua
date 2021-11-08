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
-- clock time startup module. License: GPL
local stru=require'reylib/strutil' --[!inline]
local clockstart={
	prestart_sec=15, -- seconds between main wait and final, to allow rec switching, zoom etc
}
function clockstart:init(opts)
	if not opts.active then
		return
	end
	-- get current date as table
	local dt=os.date('*t')
	dt.hour=opts.hour
	dt.min=opts.min
	dt.sec=opts.sec
	-- clear irrelevant fields
	dt.yday=nil
	dt.wday=nil
	self.ts_start=os.time(dt)

	local ts_now = os.time()

	if self.ts_start < ts_now then
		-- if script is started within one minute of schedule time, run immediately
		if ts_now - self.ts_start < 60 then
			logecho('WARN: late start %s < now %s',os.date('%H:%M:%S',self.ts_start),os.date('%H:%M:%S'))
			self.ts_start = ts_now
		else
			-- otherwise, add a day
			logecho('%s < now %s:+1 day',os.date('%H:%M:%S',self.ts_start),os.date('%H:%M:%S'))
			self.ts_start = self.ts_start + (24*60*60)
		end
	end
	if self.ts_start - ts_now >= 10 then
		-- ensure message is visible in initial wait
		disp:enable(true,10000)
	end
	logecho('start %s (+%s)',os.date('%H:%M:%S',self.ts_start), stru.sec2hms(self.ts_start - ts_now))
end
-- wait for the bulk of startup up (>30 sec) with keyboard handling to toggle display,
-- low power shutdown handling
-- returns false on user exit or shutdown
function clockstart:main_wait()
	if not self.ts_start then
		return true
	end
	local ts_prestart = self.ts_start - self.prestart_sec -- sleep before rec switch
	while os.time() < ts_prestart do
		-- handle keys to allow early abort
		wait_click(1000)
		if is_key('menu') then
			-- prevent shutdown on finish if user abort
			shutdown.opts.finish = false
			logdesc('user exit')
			log:write()
			return false
		end
		if is_key('set') then
			disp:toggle(10000)
			-- show remaining wait if display toggled on
			if disp.state then
				stru.printf("start in %s",stru.sec2hms(self.ts_start - os.time()))
			end
		end
		if shutdown:check() then
			-- low power could apply
			logdesc('shutdown:%s',shutdown:reason())
			log:write()
			return false
		end
		disp:update()
	end
	return true
end
-- final delay, for after switching to rec
function clockstart:final_wait()
	if not self.ts_start then
		return
	end
	while self.ts_start > os.time() do
		sleep(10)
	end
end
return clockstart
