--[[
@title raw meter intervalometer
@chdk_version 1.5.1
#ui_shots=0 "Shots (0 = unlimited)"
#ui_interval_s10=20 "Interval Sec/10"
#ui_use_remote=false "USB remote interval control"
#ui_meter_width_pct=90 "Meter width %" [1 100]
#ui_meter_height_pct=90 "Meter height %" [1 100]
#ui_meter_left_pct=-1 "Meter left % (-1 center)" [-1 99]
#ui_meter_top_pct=-1 "Meter top % (-1 center)" [-1 99]
#ui_meter_step=15 "Meter step"
#ui_max_ev_change_e=3 "Max Ev change" {1/16 1/8 1/4 1/3 1/2 1}
#ui_smooth_factor=5 "Ev chg smooth factor/10"[0 9]
#ui_smooth_limit_frac=7 "Ev chg smooth limit frac/10" [0 10]
#ui_ev_chg_rev_limit_frac=5 "Ev chg reverse limit frac/10" [0 10]
#ui_ev_use_initial=false "Use initial Ev as target"
#ui_ev_shift_e=10 "Ev shift" {-2.1/2 -2.1/4 -2 -1.3/4  -1.1/2 -1.1/4 -1 -3/4 -1/2 -1/4 0 1/4 1/2 3/4 1 1.1/4 1.1/2 1.3/4 2 2.1/4 2.1/2}
#ui_bv_ev_shift_pct=0 "Bv Ev shift %" [0 100]
#ui_bv_ev_shift_base_e=0 "Bv Ev shift base Bv" {First -1 -1/2 0 1/2 1 1.1/2 2 2.1/2 3 3.1/2 4 4.1/2 5 5.1/2 6 6.1/2 7 7.1/2 8 8.1/2 9 9.1/2 10 10.1/2 11 11.1/2 12 12.1/2 13}
#ui_tv_max_s1k=1000 "Max Tv Sec/1000"
#ui_tv_min_s100k=10 "Min Tv Sec/100K" [1 99999]
#ui_sv_target_mkt=80 "Target ISO"
#ui_tv_sv_adj_s1k=250 "ISO adj Tv Sec/1000"
#ui_sv_max_mkt=800 "Max ISO"
#ui_tv_nd_thresh_s10k=1 "ND Tv Sec/10000"
#ui_nd_hysteresis_e=2 "ND hysteresis Ev" {none 1/4 1/2 3/4 1}
#ui_nd_value=0 "ND value APEX*96 (0=firmware)" [0 1000]
#ui_meter_high_thresh_e=2 "Meter high thresh Ev" {1/2 3/4 1 1.1/4 1.1/2 1.3/4}
#ui_meter_high_limit_e=3 "Meter high limit Ev" {1 1.1/4 1.1/2 1.3/4 2 2.1/4}
#ui_meter_high_limit_weight=200 "Meter high max weight" [100 300]
#ui_meter_low_thresh_e=5 "Meter low thresh -Ev" {1/2 3/4 1 1.1/4 1.1/2 1.3/4 2 2.1/4 2.1/2 2.3/4 3 3.1/4 3.1/2 3.3/4 4 4.1/4 4.1/2 4.3/4 5}
#ui_meter_low_limit_e=7 "Meter low limit -Ev" {1 1.1/4 1.1/2 1.3/4 2 2.1/4 2.1/2 2.3/4 3 3.1/4 3.1/2 3.3/4 4 4.1/4 4.1/2 4.3/4 5 5.1/4 5.1/2 5.3/4 6}
#ui_meter_low_limit_weight=200 "Meter low max weight" [100 300]
#ui_exp_over_thresh_frac=3000 "Overexp thresh x/100k (0=Off)" long
#ui_exp_over_margin_e=3 "Overexp Ev range" {1/32 1/16 1/8 1/4 1/3 1/2 2/3 3/4 1}
#ui_exp_over_weight_max=200 "Overexp max weight" [100 300]
#ui_exp_over_prio=0 "Overexp prio" [0 200]
#ui_exp_under_thresh_frac=10000 "Underexp thresh x/100k (0=Off)" long
#ui_exp_under_margin_e=5 "Underexp -Ev" {7 6 5.1/2 5 4.1/2 4 3.1/2 3 2.1/2 2}
#ui_exp_under_weight_max=200 "Underexp max weight" [100 300]
#ui_exp_under_prio=0 "Underexp prio" [0 200]
#ui_histo_step_t=5 "Histogram step (pixels)" {5 7 9 11 15 19 23 27 31} table
#ui_zoom_mode_t=1 "Zoom mode" {Off Pct Step} table
#ui_zoom=0 "Zoom value" [0 500]
#ui_sd_mode_t=1 "Focus override mode" {Off MF AFL AF} table
#ui_sd=0 "Focus dist (mm)" long
#ui_image_size_e=0 "Image size" {Default L M1 M2 M3 S W}
#ui_use_raw_e=0 "Use CHDK raw" {Default Yes No}
#ui_canon_img_fmt=0 "Canon image format" {Default JPG RAW RAW+JPG}
#ui_use_cont=true "Use cont. mode if set"
#ui_start_hour=-1 "Start hour (-1 off)" [-1 23]
#ui_start_min=0 "Start minute" [0 59]
#ui_start_sec=0 "Start second" [0 59]
#ui_display_mode_t=1 "Display" {On Off Blt_Off} table
#ui_shutdown_finish=false "Shutdown on finish"
#ui_shutdown_lowbat=true "Shutdown on low battery"
#ui_shutdown_lowspace=true "Shutdown on low space"
#ui_interval_warn_led=-1 "Interval warn LED (-1=off)"
#ui_interval_warn_beep=false "Interval warn beep"
#ui_do_draw=false "Draw debug info"
#ui_draw_meter_t=1 " Meter area" {None Corners Box} table
#ui_draw_gauge_y_pct=0 " Gauge Y offset %" [0 94]
#ui_log_mode=2 "Log mode" {None Append Replace} table
#ui_raw_hook_sleep=0 "Raw hook sleep ms (0=off)" [0 100]
#ui_noyield=false "Disable script yield"

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

rawopint_version="0.26-dev"

require'hookutil'
require'rawoplib'
props=require'propcase'
capmode=require'capmode'

stru=(function() -- inline reylib/strutil
-- general string utilities. License: GPL
local strutil={}
function strutil.printf(...)
	print(string.format(...))
end

function strutil.sec2hms(sec)
	local sign=''
	if sec < 0 then
		sec = -sec
		sign='-'
	end
	return string.format('%s%02d:%02d:%02d',sign,sec/(60*60),(sec/60)%60,sec%60)
end

function strutil.imath2str(imval)
	local sign=''
	if imval < 0 then
		imval = -imval
		sign='-'
	end
	return string.format("%s%d.%03d",sign,imval/1000,imval%1000)
end
return strutil

end)()
package.loaded['reylib/strutil']=stru -- end inline reylib/strutil

xsvlog=(function() -- inline reylib/xsvlog
-- csv log module. License: GPL
local csvlog={}
local log_methods = {}

-- 'cols' can be either a simple array of names, or include sub-arrays
-- to allow modules to export their own list of columns
local function unpack_cols(cols_init, cols, depth)
	if not depth then
		depth=0
	elseif depth > 10 then
		error('too many nested column specs')
	end
	if not cols then
		cols = {}
	end
	for i,v in ipairs(cols_init) do
		if type(v) == 'table' then
			unpack_cols(v,cols,depth+1)
		elseif type(v) == 'string' then
			table.insert(cols,v)
		else
			error('invalid column spec '..type(v))
		end
	end
	return cols
end

function log_methods:init(opts)
	if not opts then
		error('missing opts')
	end
	if not opts.name then
		error('missing name')
	end
	if type(opts.cols) ~= 'table' or #opts.cols < 1 then
		error('bad or empty cols')
	end
	self.delim = opts.delim or ','
	if self.delim:match('["\r\n]') or self.delim:len() ~= 1 then
		error('bad delimiter')
	end
	if self.delim:match('[%a%d]') then
		self.delim_pat = self.delim
	else
		self.delim_pat = '%'..self.delim
	end

	self.cols=unpack_cols(opts.cols)
	self.vals={}
	self.funcs={}
	self.tables={}
	if opts.funcs then
		for n,f in pairs(opts.funcs) do
			if type(f) ~= 'function' then
				error('expected function')
			end
			self.funcs[n] = f
		end
	end
	self.name = opts.name
	self.dummy = opts.dummy
	self.buffer_mode = opts.buffer_mode or 'os'
	if self.buffer_mode == 'table' then
		self.lines={}
	elseif self.buffer_mode ~= 'os' and self.buffer_mode ~= 'sync' then
		error('invalid buffer mode '..tostring(self.buffer_mode))
	end
	if opts.quote_mode ~= nil then
		if opts.quote_mode == 'never' then
			self.quote_mode = false
		else
			self.quote_mode = opts.quote_mode
		end
	else
		self.quote_mode = 'auto'
	end
	if self.quote_mode ~= 'auto' and self.quote_mode ~= 'always' and self.quote_mode ~= false then
		error('invalid quote mode '..tostring(self.quote_mode))
	end

	-- TODO may accept other options than sep later
	if opts.tables then
		for n,sep in pairs(opts.tables) do
			self.tables[n] = {sep=sep}
		end
	end
	self:reset_vals()

	if opts.text_loggers then
		for n,col in pairs(opts.text_loggers) do
			if not self.vals[col] then
				error('invalid text_logger col '..col)
			end
			local name = 'log_'..col
			if self[name] ~= nil then
				error('conflicting text_logger '..name)
			end
			self[name]=function(self,fmt,...)
				self:set{[col]=string.format(fmt,...)}
			end
		end
	end
	if opts.dt_loggers then
		for n,base_col in pairs(opts.dt_loggers) do
			if not self.vals[base_col] then
				error('invalid dt_logger base col '..base_col)
			end
			local name = 'dt_'..base_col
			if self[name] ~= nil then
				error('conflicting dt_logger '..name)
			end
			self[name]=function(self,col)
				if not self.vals[col] then
					error('invalid dt_logger col name '..tostring(col))
				end
				self:set{[col]=tostring(get_tick_count() - self.vals[base_col])}
			end
		end
	end

	-- checks after vals initialized
	for n, v in pairs(self.funcs) do
		if not self.vals[n] then
			error('missing func col '.. tostring(n))
		end
	end
	for n, v in pairs(self.tables) do
		if not self.vals[n] then
			error('missing table col '.. tostring(n))
		end
	end
	if self.dummy then
		local nop =function() return end
		self.write=nop
		self.write_data=nop
		self.flush=nop
		self.set=nop
	else
		-- TODO name should accept autonumber or date based options
		if not opts.append then
			os.remove(self.name)
		end
		if self.buffer_mode == 'os' then
			self.fh = io.open(self.name,'ab')
			if not self.fh then
				error('failed to open log')
			end
		end
		self:write_data(self.cols)
		self:flush()
	end
end
function log_methods:prepare_write()
	if self.buffer_mode == 'os' then
		return
	end
	-- if self.buffer_mode == 'sync' or self.buffer_mode then
	self.fh = io.open(self.name,'ab')
	if not self.fh then
		error('failed to open log')
	end
end
function log_methods:finish_write()
	if self.buffer_mode == 'os' then
		return
	end
	self.fh:close()
	self.fh=nil
end

function log_methods:quote_csv_cell(cell)
	if not self.quote_mode then
		return cell
	end
	-- ensure string
	cell = tostring(cell)
	if self.quote_mode == 'always' or cell:match('['..self.delim_pat..'"\r\n]') then
		return '"'..cell:gsub('"','""')..'"'
	end
	return cell
end
function log_methods:write_csv(data)
	local quoted
	if self.quote_mode then
		quoted = {}
		for i, cell in ipairs(data) do
			table.insert(quoted,self:quote_csv_cell(cell))
		end
	else
		quoted = data
	end
	self.fh:write(string.format("%s\n",table.concat(quoted,self.delim)))
end
function log_methods:write_data(data)
	if self.buffer_mode == 'table' then
		table.insert(self.lines,data)
		return
	end
	self:prepare_write()
	self:write_csv(data)
	self:finish_write()
end

function log_methods:flush()
	if self.buffer_mode == 'os' then
		if self.fh then
			self.fh:flush()
		end
	elseif self.buffer_mode == 'table' then
		if #self.lines == 0 then
			return
		end
		self:prepare_write()
		for i,data in ipairs(self.lines) do
			self:write_csv(data)
		end
		self:finish_write()
		self.lines={}
	end
	-- 'sync' is flushed every line
end

function log_methods:write()
	local data={}
	for i,name in ipairs(self.cols) do
		local v
		if self.funcs[name] then
			v=tostring(self.funcs[name]())
		elseif self.tables[name] then
			v=table.concat(self.vals[name],self.tables[name].sep)
		else
			v=self.vals[name]
		end
		table.insert(data,v)
	end
	self:write_data(data)
	self:reset_vals()
end
function log_methods:reset_vals()
	for i,name in ipairs(self.cols) do
		if self.tables[name] then
			self.vals[name] = {}
		else
			self.vals[name] = ''
		end
	end
end
function log_methods:set(vals)
	for name,v in pairs(vals) do
		if not self.vals[name] then
			error("unknown log col "..tostring(name))
		end
		if self.funcs[name] then
			error("tried to set func col "..tostring(name))
		end
		if self.tables[name] then
			table.insert(self.vals[name],v)
		else
			self.vals[name] = tostring(v)
		end
	end
end

function log_methods:close()
	if self.buffer_mode == 'table' then
		self:flush()
	end
	if self.fh then
		self.fh:close()
	end
end

function csvlog.new(opts)
	local t={}
	for k,v in pairs(log_methods) do
		t[k] = v
	end
	t:init(opts)
	return t
end
return csvlog

end)()
package.loaded['reylib/xsvlog']=xsvlog -- end inline reylib/xsvlog

disp=(function() -- inline reylib/disp
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

end)()
package.loaded['reylib/disp']=disp -- end inline reylib/disp

shutdown=(function() -- inline reylib/shutdown
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

end)()
package.loaded['reylib/shutdown']=shutdown -- end inline reylib/shutdown

focus=(function() -- inline reylib/focus
-- focus override module. License: GPL
local focus={
	mode_names={'AF','AFL','MF'},
	valid_modes={}, -- table of name=true
	modes={}, -- array of usable mode names
}
-- initialize valid modes for sd over
function focus:init()
	-- bits: 1 = AF, 2 = AFL, 3 = MF
	local modes=get_sd_over_modes()
	self.modes={}
	for i=1,3 do
		if bitand(1,modes) == 1 then
			table.insert(self.modes,self.mode_names[i])
		end
		modes = bitshru(modes,1)
	end
	for i,m in ipairs(self.modes) do
		self.valid_modes[m]=true
	end
end
-- get current AF/AFL/MF state
function focus:get_mode()
	if get_prop(require'propcase'.AF_LOCK) == 1 then
		return 'AFL'
	end
	if get_prop(require'propcase'.FOCUS_MODE) == 1 then
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
]]
function focus:enable_override(prefmode)
	-- override not supported or in playback
	if #self.modes == 0 or not get_mode() then
		return false
	end
	-- no pref, default to overriding in current mode if possible
	if not prefmode then
		prefmode=self:get_mode()
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
 			-- no pref, use first available
			usemode = self.modes[1]
		end
	end
	self:set_mode(usemode)
	return true
end
function focus:set(dist)
	set_focus(dist)
end
return focus

end)()
package.loaded['reylib/focus']=focus -- end inline reylib/focus

clockstart=(function() -- inline reylib/clkstrt
-- clock time startup module. License: GPL
local stru=require'reylib/strutil' -- previously inlined
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
			log:log_desc('user exit')
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
			log:log_desc('shutdown:%s',shutdown:reason())
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

end)()
package.loaded['reylib/clkstrt']=clockstart -- end inline reylib/clkstrt

exp=(function() -- inline reylib/rawexp
-- exposure module. License: GPL
local stru=require'reylib/strutil' -- previously inlined
local exp={}

--[[
log columns used with log:set
note log must also provide a method log_desc, for free-form messages
typically using the xsvlog text_logger option
]]
exp.log_columns={
	'meter_time', -- milliseconds spent measuring meter area
	'histo_time', -- milliseconds spent measuring histogram
	'draw_time',  -- time to draw debug info on raw, if enabled
	'sv', -- "market" ISO
	'sv96', -- APEX*96 "real" ISO
	'sv_l1',   -- amount calculated sv is over sv96_max
	'sv_tv_tr', -- amount of sv over limit put back on tv
	'tv', -- shutter speed in seconds
	'tv96', -- APEX*96 shutter speed
	'tv_l1', -- amount calculated tv is over tv96_short_limit or under tv96_long_limit
	'tv_sv_tr', -- amount of calculated tv moved to ISO due to being over tv96_sv_thresh
	'av', -- aperture as F number. Includes ND value on ND-only cameras
	'av96', -- APEX*96 aperture
	'nd', -- 1 ND active, 0 ND not active
	'nd_tv_tr', -- when nd active, amount over ND trigger threshold, negative if if hysteresis active
	'nd_hookfix', -- nd was activated in shoot hook. 1 succeeded, 0 failed. Blank if ND not active
	'bv96', -- brightness value calculated from meter and exposure settings
	'meter', -- average pixel value of meter area
	'meter96', -- meter value as APEX*96 exposure, where 0 is an aribtrary chosen "correct" exposure
	'meter96_tgt', -- target meter value for calculated for this exposure
	'meter_weight',
	'over_frac', -- fraction of pixels over (whitelevel - over_margin_ev)
	'over_weight',
	'under_frac', -- fraction of pixels under under_margin_ev
	'under_weight',
	'bv_ev_shift', -- bv ev shift applied to this exposure
	'bv_ev_l1', -- original calculated bv/ev shift value if over threshold or limit
	-- all of the following are the calculated change for the *next* exposure
	'd_ev_base', -- calculated ev change for next exposure, with over, under and ev change limit applied
	'd_ev_s1', -- ev change after smoothing
	'd_ev_s2', -- ev change after smooth overshoot logic
	'd_ev_r1', -- ev change after reverse limit logic
	'd_ev_f', -- final ev change with whichever of the preceding applied
	'd_ev', -- used ev change, as integer
}

function exp:init(opts)
	local logvals={}
	for i,name in ipairs{
		'ev_change_max',
		'ev_shift',
		'ev_use_initial',
		'bv_ev_shift_pct',
		'bv_ev_shift_base_bv',
		'tv96_long_limit',
		'tv96_short_limit',
		'tv96_sv_thresh',
		'tv96_nd_thresh',
		'nd_value',
		'nd_hysteresis',
		'sv96_max',
		'sv96_target',
		'meter_width_pct',
		'meter_height_pct',
		'meter_left_pct',
		'meter_top_pct',
		'meter_step',
		'meter_high_thresh',
		'meter_high_limit',
		'meter_high_limit_weight',
		'meter_low_thresh',
		'meter_low_limit',
		'meter_low_limit_weight',
		'over_margin_ev',
		'over_thresh_frac',
		'under_margin_ev',
		'under_thresh_frac',
		'over_weight_max',
		'under_weight_max',
		'over_prio',
		'under_prio',
		'histo_step',
		'do_draw',
		'draw_meter',
		'draw_gauge_y_pct',
		'smooth_factor',
		'smooth_limit_frac',
		'ev_chg_rev_limit_frac',
	} do
		if opts[name] == nil then
			error('exp missing opt '..name)
		end
		self[name] = opts[name]
		table.insert(logvals,string.format("%s=%s",name,tostring(opts[name])))
	end

	-- TODO special value from usec_to_tv96
	if self.tv96_nd_thresh == -10000 or self.tv96_nd_thresh > self.tv96_short_limit then
		self.tv96_nd_thresh = false
	end

	self.meter_width =  (self.meter_width_pct * rawop.get_active_width()) / 100
	self.meter_height = (self.meter_height_pct * rawop.get_active_height()) / 100

	-- not strictly required, truncate to multiples of 4 to keep bayer alignment consistent
	self.meter_width = bitand(0xFFFFFFFC,self.meter_width)
	self.meter_height = bitand(0xFFFFFFFC,self.meter_height)

	-- -1 = centered in active area
	if self.meter_left_pct == -1 then
		self.meter_left = rawop.get_active_left() + rawop.get_active_width()/2 - self.meter_width/2
	else
		self.meter_left = rawop.get_active_left() + (self.meter_left_pct * rawop.get_active_width()) / 100
		self.meter_left = bitand(0xFFFFFFFC,self.meter_left)
		if self.meter_left + self.meter_width >= rawop.get_active_width() then
			local meter_width_trunc = rawop.get_active_width() - self.meter_left
			meter_width_trunc = bitand(0xFFFFFFFC,meter_width_trunc)
			if meter_width_trunc < 4 then
				error('meter width too small')
			end
			log:log_desc('WARN:meter_width truncated:%d->%d',self.meter_width,meter_width_trunc)
			self.meter_width = meter_width_trunc
		end
	end
	self.meter_x_count = self.meter_width/self.meter_step

	-- -1 = centered in active area
	if self.meter_top_pct == -1 then
		self.meter_top = rawop.get_active_top() + rawop.get_active_height()/2 - self.meter_height/2
	else
		self.meter_top = rawop.get_active_top() + (self.meter_top_pct * rawop.get_active_height()) / 100
		self.meter_top = bitand(0xFFFFFFFC,self.meter_top)
		if self.meter_top + self.meter_height >= rawop.get_active_height() then
			local meter_height_trunc = rawop.get_active_height() - self.meter_top
			meter_heightl_trunc = bitand(0xFFFFFFFC,meter_height_trunc)
			if meter_height_trunc < 4 then
				error('meter height too small')
			end
			log:log_desc('WARN:meter_height truncated:%d->%d',self.meter_height,meter_height_trunc)
			self.meter_height = meter_height_trunc
		end
	end
	self.meter_y_count = self.meter_height/self.meter_step

	-- weight of meter in "normal range" hard coded for now
	self.meter_base_weight = 100
	-- max weight inputs are in aboslute values, make relative to base weight
	self.meter_high_limit_weight = self.meter_high_limit_weight - self.meter_base_weight
	self.meter_low_limit_weight = self.meter_low_limit_weight - self.meter_base_weight

	self.over_thresh_weight=100
	self.over_frac_max = imath.sqrt(self.over_thresh_weight*imath.scale)
							*imath.sqrt(self.over_weight_max*imath.scale)/imath.scale^2

	self.under_thresh_weight=100
	self.under_frac_max = imath.sqrt(self.under_thresh_weight*imath.scale)
							*imath.sqrt(self.under_weight_max*imath.scale)/imath.scale^2

	-- log some calculated values
	for i,name in ipairs{
		'meter_top', 'meter_left',
		'meter_width','meter_height',
		'meter_x_count','meter_y_count',
	} do
		table.insert(logvals,string.format("%s=%s",name,tostring(self[name])))
	end

	-- scale for histo:range(), hard coded for now
	-- TODO NOTE histo_frac_to_pct format needs to be adjusted to match
	self.histo_scale = 1000000

	local histo_samples = (rawop.get_jpeg_width()/self.histo_step)*(rawop.get_jpeg_height()/self.histo_step)
	-- approx total number of pixels read by histo
	table.insert(logvals,string.format("histo_samples=%d",histo_samples))

	log:log_desc("init:%s",table.concat(logvals,' '))

	-- warn if < 10 pixels in histogram would trigger threshold
	if self.over_thresh_frac > 0 and 10*self.histo_scale/self.over_thresh_frac > histo_samples then
		log:log_desc('WARN:over_thresh histo_samples')
	end
	if self.under_thresh_frac > 0 and 10*self.histo_scale/self.under_thresh_frac > histo_samples then
		log:log_desc('WARN:under_thresh histo_samples')
	end

	-- TODO should just auto adjust and warn in log, or use multiple meters
	if self.meter_x_count*self.meter_y_count > bitshru(0xFFFFFFFF,rawop.get_bits_per_pixel()) then
		error("meter step too small")
	end
	if self.tv96_sv_thresh < self.tv96_long_limit then
		log:log_desc('WARN:tv96_sv_thresh < tv96_long_limit')
		self.tv96_sv_thresh = self.tv96_long_limit
-- TODO could disable instead
--		self.sv96_max = self.sv96_target
	end
	if self.sv96_max < self.sv96_target then
		log:log_desc('WARN:sv96_max < sv96_target')
		self.sv96_max = self.sv96_target
	end

	self.histo = rawop.create_histogram()
end

-- initialize values that might change between frames (blacklevel/neutral dependent)
function exp:init_frame()
	local bl=rawop.get_black_level()
	-- blacklevel initialized and unchanged
	if bl == self.black_level then
		return
	end
	self.black_level=bl
	-- white level shouldn't ever change, but more consistent to do it here
	self.white_level=rawop.get_white_level()
	-- histo limits in shot histo units
	-- lowest value to count as over exp, as shot histo value
	-- = raw(ev(whitelevel) - margin_ev)/(2^(bpp - histo_bpp))
	self.over_histo_min = bitshru(rawop.ev_to_raw(rawop.raw_to_ev(self.white_level)-self.over_margin_ev),rawop.get_bits_per_pixel() - 10)
	-- highest value to count as under exp, as shot histo value
	-- = raw(-margin_ev)/(2^(bpp - histo_bpp))
	self.under_histo_max = bitshru(rawop.ev_to_raw(-self.under_margin_ev),rawop.get_bits_per_pixel() - 10)
	log:log_desc('init_frame:black_level=%d neutral=%d over_histo_min=%d under_histo_max=%d',
				self.black_level,
				rawop.get_raw_neutral(),
				self.over_histo_min,
				self.under_histo_max)
end


-- draw debug stuff on raw
function exp:draw_pct_bar(x, y, frac, max, width, dir, r, g, b)
	local w,h
	local len = (frac*width/max)
	if len < 0 then
		if dir == 'h' then
			x = x + len
		else
			y = y + len
		end
		len = -len
	end
	if dir == 'h' then
		w = len
		h = 8
	elseif dir == 'v' then
		h = len
		w = 8
	end
	if g then
		rawop.fill_rect_rgbg(x, y, w, h, r,g,b)
	else
		rawop.fill_rect(x, y, w, h, r)
	end
end

function exp:draw_ev_tick(left, top, tick_height, tick_width, width, bl_offset, max_ev, ev, r,g,b)
	if g then
		rawop.fill_rect_rgbg(left + (width*(bl_offset + ev))/max_ev,top,tick_width,tick_height,r,g,b)
	else
		rawop.fill_rect(left + (width*(bl_offset + ev))/max_ev,top,tick_width,tick_height,r)
	end
end

function exp:draw()
	local t0=get_tick_count()
	local drawval_high = self.white_level - self.black_level
	local drawval_low = self.black_level*2
	local drawval = drawval_high
	if self.mval > self.white_level - self.white_level/3 then
		drawval = drawval_low
	end
	local width = self.meter_x_count*self.meter_step
	local height = self.meter_y_count*self.meter_step

	-- box around meter area
	if self.draw_meter == 'box' then
		rawop.rect(self.meter_left,self.meter_top,width,height,2,drawval)
	elseif self.draw_meter == 'corners' then
		local len=64
		rawop.fill_rect(self.meter_left,self.meter_top,len,2,drawval)
		rawop.fill_rect(self.meter_left,self.meter_top+2,2,len-2,drawval)
		rawop.fill_rect(self.meter_left + width - len - 2,self.meter_top,len,2,drawval)
		rawop.fill_rect(self.meter_left + width - 2,self.meter_top+2,2,len-2,drawval)

		rawop.fill_rect(self.meter_left,self.meter_top+height - 2,len,2,drawval)
		rawop.fill_rect(self.meter_left,self.meter_top+height - len - 2,2,len-2,drawval)
		rawop.fill_rect(self.meter_left + width - len - 2,self.meter_top+height-2,len,2,drawval)
		rawop.fill_rect(self.meter_left + width - 2,self.meter_top+height-len-2,2,len-2,drawval)
	end

	-- debug display area
	local d_width = 800
	local d_top
	if self.draw_gauge_y_pct == 0 then
		d_top = rawop.get_jpeg_top() + 80 -- ensure min margin, < 1%
	else
	 	d_top = rawop.get_jpeg_top() + (self.draw_gauge_y_pct*rawop.get_jpeg_height())/100
	end
	local d_left = rawop.get_jpeg_left() + (rawop.get_jpeg_width() - d_width)/2
	-- meter level
	local bl_offset = -rawop.raw_to_ev(self.black_level+1)
	local max_ev = bl_offset + rawop.raw_to_ev(self.white_level)

	-- get appropriate drawval with a tiny meter
	local mv = rawop.meter(d_left + d_width/2 - 64,d_top,18,9, 7,7)
	if mv > self.white_level - self.white_level/3 then
		drawval = drawval_low
	else
		drawval = drawval_high
	end

	self:draw_pct_bar(d_left,
					d_top,
					bl_offset + self.mval96,
					max_ev,
					d_width,
					'h',
					drawval)
	-- meter ticks
	-- black level
	rawop.fill_rect(d_left,d_top-8,4,30,drawval)
	-- white level
	rawop.fill_rect(d_left+d_width-2,d_top-8,4,30,drawval)
	-- neutral (0 ev)
	self:draw_ev_tick(d_left,d_top-8,8,4,d_width,bl_offset,max_ev,0,drawval)
	self:draw_ev_tick(d_left,d_top+8,14,4,d_width,bl_offset,max_ev,0,drawval)
	-- draw generic stops before and after neutral
	local i = -96
	repeat
		self:draw_ev_tick(d_left,d_top+8,10,4,d_width,bl_offset,max_ev,i,drawval)
		i = i - 96
	until bl_offset + i <= 0

	i = 96
	repeat
		self:draw_ev_tick(d_left,d_top+8,10,4,d_width,bl_offset,max_ev,i,drawval)
		i = i + 96
	until i >= max_ev - bl_offset
	-- draw meter limits, thresh = yellow, limit = red
	self:draw_ev_tick(d_left,d_top-12,8,4,d_width,bl_offset,max_ev,self.ev_target_base + self.meter_low_thresh,drawval_high,drawval_high,drawval_low)
	self:draw_ev_tick(d_left,d_top-12,8,4,d_width,bl_offset,max_ev,self.ev_target_base + self.meter_low_limit,drawval_high,drawval_low,drawval_low)
	self:draw_ev_tick(d_left,d_top-12,8,4,d_width,bl_offset,max_ev,self.ev_target_base + self.meter_high_thresh,drawval_high,drawval_high,drawval_low)
	self:draw_ev_tick(d_left,d_top-12,8,4,d_width,bl_offset,max_ev,self.ev_target_base + self.meter_high_limit,drawval_high,drawval_low,drawval_low)

	-- if ev shift is in effect, draw tick on top of everything else
	if self.ev_target ~= 0 then
		self:draw_ev_tick(d_left,d_top-8,8,4,d_width,bl_offset,max_ev,self.ev_target,drawval_low,drawval_high,drawval_low)
		self:draw_ev_tick(d_left,d_top+8,14,4,d_width,bl_offset,max_ev,self.ev_target,drawval_low,drawval_high,drawval_low)
	end

	-- exposure change
	self:draw_pct_bar(d_left + d_width/2,
						d_top + 30,
						self.ev_change,
						self.ev_change_max,
						d_width/2,
						'h',
						drawval)
	-- ticks for left, mid, right
	rawop.fill_rect(d_left,d_top+38,4,16,drawval)
	rawop.fill_rect(d_left+d_width/2-2,d_top+38,4,16,drawval)
	rawop.fill_rect(d_left+d_width-4,d_top+38,4,16,drawval)

	-- TODO under/over fracs are absolute, relative to threshold would be useful
	-- under exposed fraction
	local r,g,b = drawval,drawval,drawval
	if self.under_frac >= self.under_thresh_frac then
		r = drawval_high
		g,b = drawval_low,drawval_low
	end
	-- left to right
	self:draw_pct_bar(d_left,d_top+54, self.under_frac, self.histo_scale, d_width/2, 'h', r, g, b)

	-- over exposured fraction
	if self.over_frac >= self.over_thresh_frac then
		r = drawval_high
		g,b = drawval_low,drawval_low
	else
		r,g,b = drawval,drawval,drawval
	end
	-- right to left
	self:draw_pct_bar(d_left + d_width, d_top+54, -self.over_frac, self.histo_scale, d_width/2, 'h', r, g, b)

	log:set{draw_time=get_tick_count()-t0}
end

function exp:clamp(v,min,max)
	-- single value, assume +/-
	if not max then
		max = min
		min = -max
	end
	if v > max then
		return max
	elseif v < min then
		return min
	end
	return v
end

function exp:calc_bv_ev_shift()
	if self.bv_ev_shift_pct == 0 then
		return 0
	end
	-- bv change from initial
	local bv_change = self.bv96 - self.bv96_init
	local bv_ev_shift = (bv_change*self.bv_ev_shift_pct)/100
	-- limit shift by meter limits (relative to ev_target_base)
	-- simple linear ramp
	if bv_ev_shift > self.meter_high_thresh then
		local over = bv_ev_shift - self.meter_high_thresh
		if over > 2*(self.meter_high_limit - self.meter_high_thresh) then
			--log:log_desc('bv ev limit:%d',bv_ev_shift)
			self:nextlog{bv_ev_l1=bv_ev_shift}
			bv_ev_shift = self.meter_high_limit
		else
			--log:log_desc('bv ev thresh:%d',bv_ev_shift)
			self:nextlog{bv_ev_l1=bv_ev_shift}
			bv_ev_shift = self.meter_high_thresh + over/2
		end
	elseif bv_ev_shift < self.meter_low_thresh then
		local under = bv_ev_shift - self.meter_low_thresh
		if under < 2*(self.meter_low_limit - self.meter_low_thresh) then
			-- log:log_desc('bv ev -limit:%d',bv_ev_shift)
			self:nextlog{bv_ev_l1=bv_ev_shift}
			bv_ev_shift = self.meter_low_limit
		else
			-- log:log_desc('bv ev -thresh:%d',bv_ev_shift)
			self:nextlog{bv_ev_l1=bv_ev_shift}
			bv_ev_shift = self.meter_low_thresh + under/2
		end
	end
	return bv_ev_shift
end

function exp:calc_ev_change()
	local last_ev_change

	-- handle first iteration
	-- TODO ugly
	if self.ev_change then
		last_ev_change = self.ev_change_im
	else
		if self.bv_ev_shift_base_bv then
			self.bv96_init = self.bv_ev_shift_base_bv
		else
			self.bv96_init = self.bv96
		end
		-- first time through
		last_ev_change = 0
		self.ev_target_base = self.ev_shift
		-- if using initial as target, add to ev_shift
		if self.ev_use_initial then
			log:log_desc('initial ev:%d+%d',self.mval96,self.ev_shift)
			self.ev_target_base = self.ev_target_base + self.mval96
		end
	end

	-- shift by % of over or under initial value
	local bv_ev_shift = self:calc_bv_ev_shift()

	self:nextlog{bv_ev_shift=bv_ev_shift}

	-- adjust target for this shot
	self.ev_target = self.ev_target_base + bv_ev_shift
	self:nextlog{meter96_tgt=self.ev_target}

	-- basic change: difference of last exposure from metered exposure
	-- plus exposure shift, clamped to per-frame limit
	local ev_change = self:clamp(self.ev_target - self.mval96,self.ev_change_max)

	-- convert limits that are relative to ev shift to meter values
	local meter_high_thresh	= self.ev_target_base + self.meter_high_thresh
	local meter_high_limit	= self.ev_target_base + self.meter_high_limit
	local meter_low_thresh	= self.ev_target_base + self.meter_low_thresh
	local meter_low_limit	= self.ev_target_base + self.meter_low_limit

	-- basic weight
	local meter_weight = self.meter_base_weight

	-- if over / under exposed beyond thresholds, increase meter weight
	-- high limit - driven above "ideal" value by underexp
	if self.mval96 > meter_high_thresh then
		local range = meter_high_limit - meter_high_thresh
		-- amount of range we have left
		local frac = meter_high_limit - self.mval96
		-- if above limit, clamp to limit
		if frac <= 0 then
			meter_weight = meter_weight + self.meter_high_limit_weight
		else
			-- otherwise, weight bonus = (max_bonus - margin_remaining)^2/max_bonus
			meter_weight = meter_weight + (self.meter_high_limit_weight - (self.meter_high_limit_weight*frac)/range)^2/self.meter_high_limit_weight
		end
	-- low limit - driven below "ideal" value by overexp
	-- TODO will also be hit if max shutter / iso reached
	elseif self.mval96 < meter_low_thresh then
		local range = meter_low_thresh - meter_low_limit
		local frac = self.mval96 - meter_low_limit
		if frac <= 0 then
			meter_weight = meter_weight + self.meter_low_limit_weight
		else
			meter_weight = meter_weight + (self.meter_low_limit_weight - (self.meter_low_limit_weight*frac)/range)^2/self.meter_low_limit_weight
		end
	end

	-- TODO
	-- to avoid flapping as limits approached over / under weights
	-- are calculated as (% of threshold)^2/(100)
	-- clamped to maximum weight
	-- this makes under / over start to have a slight effect as soon as there is any over/under
	-- and ramp up quickly as it exceeds the threshold
	local over_weight = 0
	local over_fw
	if self.over_thresh_frac > 0 then
		if self.over_frac > 0 then
			-- fraction threshold used by measured over exposure
			over_fw = self.over_frac*self.over_thresh_weight/self.over_thresh_frac
			-- if over by enough to hit weight limit, use max val
			if over_fw > self.over_frac_max then
				over_weight = self.over_weight_max
			else
				over_weight = over_fw^2/self.over_thresh_weight
			end
		end
	end

	local under_weight = 0
	local under_fw
	if self.under_thresh_frac > 0 then
		if self.under_frac > 0 then
			-- fraction threshold used by measured under exposure
			under_fw = (self.under_frac*self.under_thresh_weight)/self.under_thresh_frac
			-- if over by enough to hit weight limit, use max val
			if under_fw > self.under_frac_max then
				under_weight = self.under_weight_max
			else
				under_weight = under_fw^2/self.under_thresh_weight
			end
		end
	end

	-- priority adjustments
	if over_fw and self.over_prio > 0 then
		local prio_mod = self:clamp(over_fw * self.over_prio / self.over_thresh_weight,0,self.over_prio)
		-- meter in opposite direction?
		if ev_change > 0 then
			log:log_desc("over prio meter %d-%d",meter_weight,prio_mod)
			meter_weight = meter_weight - prio_mod
			if meter_weight < 0 then
				meter_weight = 0
			end
		end
		-- under exposure
		if under_fw then
			log:log_desc("over prio under %d-%d",under_weight,prio_mod)
			under_weight = under_weight - prio_mod
			if under_weight < 0 then
				under_weight = 0
			end
		end
	end

	if under_fw and self.under_prio > 0 then
		local prio_mod = self:clamp(under_fw * self.under_prio / self.under_thresh_weight,0,self.under_prio)
		-- meter in opposite direction?
		if ev_change < 0 then
			log:log_desc("under prio meter %d-%d",meter_weight,prio_mod)
			meter_weight = meter_weight - prio_mod
			if meter_weight < 0 then
				meter_weight = 0
			end
		end
		-- over exposure
		if over_fw then
			log:log_desc("under prio over %d-%d",over_weight,prio_mod)
			over_weight = over_weight - prio_mod
			if over_weight < 0 then
				over_weight = 0
			end
		end
	end

	log:set{
		meter_weight=meter_weight,
		over_weight=over_weight,
		under_weight=under_weight,
	}

	ev_change = imath.scale*(ev_change*meter_weight - self.ev_change_max*over_weight + self.ev_change_max*under_weight)/(meter_weight + over_weight + under_weight)

	-- everything above should already be in limits, but clamp to UI limits to be sure
	ev_change = self:clamp(ev_change,self.ev_change_max*imath.scale)

	log:set{d_ev_base=stru.imath2str(ev_change)}

	-- smooth out rapid changes with simple exponential smoothing
	-- https://en.wikipedia.org/wiki/Exponential_smoothing
	if self.smooth_factor > 0 then
		local ev_change_smooth = imath.mul(ev_change, (imath.scale - self.smooth_factor)) + imath.mul(last_ev_change, self.smooth_factor)
		log:set{d_ev_s1=stru.imath2str(ev_change_smooth)}
		-- additional limits to reduce smoothing triggering oscillation
		-- limit_frac = 0 means smoothed used as is, with no limiting
		if self.smooth_limit_frac > 0 then
			if ev_change*ev_change_smooth < 0 -- smoothed and unsmoothed have opposite signs
				or math.abs(ev_change) < math.abs(ev_change_smooth) then -- smoothed has larger magnitude than unsmoothed
				local ev_change_limited = imath.mul(ev_change, self.smooth_limit_frac) + imath.mul(ev_change_smooth, imath.scale - self.smooth_limit_frac)
				log:set{d_ev_s2=stru.imath2str(ev_change_limited)}
				ev_change = ev_change_limited
			else -- otherwise, use normal smoothing
				ev_change = ev_change_smooth
			end
		else
			ev_change = ev_change_smooth
		end
	end
	if self.ev_chg_rev_limit_frac > 0 then
		-- if direction of Ev change changed, reduce by ev_chg_rev_limit_frac
		if ev_change * last_ev_change < 0 then
			local ev_change_limited = imath.mul(ev_change,imath.scale - self.ev_chg_rev_limit_frac)
			log:set{d_ev_r1=stru.imath2str(ev_change_limited)}
			ev_change = ev_change_limited
		end
	end

	self.ev_change_im = ev_change -- imath value
	self.ev_change = imath.round(ev_change)/imath.scale -- integer apex96, rounded

	log:set{
		d_ev_f=stru.imath2str(ev_change),
		d_ev=self.ev_change,
	}
end

-- read meter values from frame buffer
function exp:do_meter()
	local t0=get_tick_count()
	self.mval = rawop.meter(self.meter_left,self.meter_top,
								self.meter_x_count,self.meter_y_count,
								self.meter_step,self.meter_step)

	log:set{meter_time=get_tick_count()-t0}

	self.mval96 = rawop.raw_to_ev(self.mval)

	t0=get_tick_count()
	-- parameters similar to shot_histogram
	-- use jpeg area to avoid dark borders
	self.histo:update(rawop.get_jpeg_left(),rawop.get_jpeg_top(),
						rawop.get_jpeg_width(),
						rawop.get_jpeg_height(),
						self.histo_step,self.histo_step,10)
	-- shot histo values always scaled to 10 bit, assume white=1023, black=31
	-- ignore much lower than black, typically bad pixels
	self.over_frac = self.histo:range(self.over_histo_min,1023,self.histo_scale)
	self.under_frac = self.histo:range(4,self.under_histo_max,self.histo_scale)
	log:set{histo_time=get_tick_count()-t0}
end

function exp:histo_frac_to_pct(v)
	return string.format("%d.%04d",v/(self.histo_scale/100),v%(self.histo_scale/100))
end

function exp:log_meter()
	-- log meter values
	log:set{
		meter=self.mval,
		meter96=self.mval96,
		over_frac=self:histo_frac_to_pct(self.over_frac),
		under_frac=self:histo_frac_to_pct(self.under_frac),
	}
end

--[[
some values related to calculating exposure make more sense logged with
the exposure that used those values. Buffer for later
]]
function exp:nextlog(vals)
	if not self.nextlog_vals then
		self.nextlog_vals = {}
	end
	for k,v in pairs(vals) do
		self.nextlog_vals[k] = v
	end
end

function exp:log_nextlog_vals()
	if self.nextlog_vals then
		log:set(self.nextlog_vals)
	end
	self.nextlog_vals = nil
end


function exp:nd96_for_state(nd_state)
	-- only used for cams with iris
	if get_nd_present() == 2 and nd_state then
		return self.nd_value
	end
	return 0
end

function exp:init_exposure_params_from_cam()
	self.tv96 = get_prop(props.TV)
	self.sv96 = get_prop(props.SV)
	self.av96 = get_prop(props.AV)
	self.bv96 = get_prop(props.BV)

	-- allow manual fine-tuning
	if self.nd_value == 0 then
		self.nd_value = get_nd_value_ev96()
		log:log_desc('fw nd_value:%d',self.nd_value)
	else
		log:log_desc('override nd_value:%d fw:%d',self.nd_value,get_nd_value_ev96())
	end
	self.nd_state = self:get_nd_state()

	self.nd96 = self:nd96_for_state(self.nd_state)
end

-- initialization after initial halfpress ready
function exp:init_preshoot()
	-- prevent any stale nextlog values from carrying over into a shooting sequence
	self.nextlog_vals = nil
	self:init_exposure_params_from_cam()
	self:log_exposure_params()
	log:set{bv96=self.bv96}
	-- shifts are currnetly not calculated or applied for the initial exposure
	-- does not account for Canon native EV shift
	self:nextlog{meter96_tgt=0,bv_ev_shift=0}
	-- TODO could try to use Bv and ev comp setting
	self.ev_change = 0

	-- turn EV change into updated exposure settings
	self:calc_exposure_params()

	-- set values for next exposure
	self:set_cam_exposure_params()
	-- TODO force initialization on first real shot
	self.ev_change = nil
end

--[[
check if cam used values match set values, can fail if ISO_BASE is wrong
]]
function exp:sanity_check_cam_exposure_params()
	local cam_tv96 = get_prop(props.TV)
	local cam_sv96 = get_prop(props.SV)
	local cam_av96 = get_prop(props.AV)
	if self.tv96 ~= cam_tv96 then
		log:log_desc('tv %s != cam %s',tostring(self.tv96),tostring(cam_tv96))
	end
	if self.sv96 ~= cam_sv96 then
		log:log_desc('sv %s != cam %s',tostring(self.sv96),tostring(cam_sv96))
	end
	if self.av96 ~= cam_av96 then
		log:log_desc('av %s != cam %s',tostring(self.av96),tostring(cam_av96))
	end
	local cam_nd = self:get_nd_state()
	if self.nd_state ~= cam_nd then
		log:log_desc('nd %s != cam %s',tostring(self.nd_state),tostring(cam_nd))
	end
end

--[[
return the hardware state of ND, false = out, or no ND, true = in
--]]
function exp:get_nd_state()
	if get_nd_present() == 0 then
		return false
	end
	return (get_nd_current_ev96() ~= 0)
end

function exp:set_nd()
	-- ND only
	if get_nd_present() ~= 0 then
		if self.nd_state then
			set_nd_filter(1)
		else
			set_nd_filter(2)
		end
	end
end

function exp:set_cam_exposure_params()
	set_tv96_direct(self.tv96)
	set_sv96(self.sv96)
	self:set_nd()
end

--[[
Some cams need ND state set in shoot hook, especially in quick mode
may want a way to disable
]]
function exp:on_hook_shoot_ready()
	if self.nd_state ~= self:get_nd_state() then
		self:set_nd()
		-- TODO spammy on cams that need it
		if self.nd_state == self:get_nd_state() then
			-- log:log_desc('hook ndfix')
			log:set{nd_hookfix=1}
		else
			log:set{nd_hookfix=0}
			-- log:log_desc('hook ndfix fail')
		end
	end
end

-- update exposure params from cam if needed, log
function exp:get_cam_exposure_params()
	-- on the first shot, get exposure values from cam
	if not self.tv96 then
		self:init_exposure_params_from_cam()
	else
	-- otherwise, compare cam values to last set values and log if different
		self:sanity_check_cam_exposure_params()
	end
end

function exp:log_exposure_params()
	-- log exposure values for shot we just metered
	local tvus=tv96_to_usec(self.tv96)
	local av1k=av96_to_aperture(self.av96)
	local nd
	if self.nd_state then
		nd=1
	else
		nd=0
	end
	log:set{
		sv=sv96_to_iso(sv96_real_to_market(self.sv96)),
		sv96=self.sv96,
		av=string.format("%d.%03d",av1k/1000,((av1k%1000))),
		av96=self.av96,
		tv=string.format("%d.%06d",tvus/1000000,((tvus%1000000))),
		tv96=self.tv96,
		nd=nd,
	}
end

-- calculate new exposure settings from EV change
function exp:calc_exposure_params()
	-- start with ev change on Tv
	local tv96_new = self.tv96 - self.ev_change

	local sv_extra = 0

	local sv96_new = self.sv96_target

	-- TODO initial may be over limits
	if self.sv96 > self.sv96_max then
		log:log_desc('sv prev > sv max')
	end
	if self.sv96 > sv96_new then
		sv_extra = self.sv96 - sv96_new
	end

	-- put anything over base ISO on Tv, will add back later if tv limits hit
	tv96_new = tv96_new - sv_extra

	local nd_state_new=false
	local av96_new = self.av96
	-- TODO doesn't handle cases where sv thresh overlaps with ND range
	if get_nd_present() > 0 then
		local nd_state_old = self.nd_state
		if self.nd_state then
			-- if ND was in for last shot, add value back to tv and clear
			tv96_new = tv96_new + self.nd_value
			-- if ND only, remove from av
			if get_nd_present() == 1 then
				av96_new = av96_new - self.nd_value
			end
			nd_state_new = false
		end
		if self.tv96_nd_thresh and tv96_new > self.tv96_nd_thresh then
			-- log:log_desc('tv over nd:%d',tv96_new - self.tv96_nd_thresh)
			self:nextlog{nd_tv_tr=tv96_new - self.tv96_nd_thresh}
			nd_state_new = true
		elseif self.tv96_nd_thresh and nd_state_old and tv96_new > self.tv96_nd_thresh - self.nd_hysteresis then
			-- log:log_desc('tv nd hyst:%d',tv96_new - self.tv96_nd_thresh)
			self:nextlog{nd_tv_tr=tv96_new - self.tv96_nd_thresh}
			nd_state_new = true
		end
		if nd_state_new then
			tv96_new = tv96_new - self.nd_value
			if get_nd_present() == 1 then
				av96_new = av96_new + self.nd_value
			end
		end
	end

	local tv_extra = 0

	-- only do ISO adjustment + messages if range defined
	if self.sv96_target < self.sv96_max then
		if tv96_new < self.tv96_sv_thresh then
			local over = self.tv96_sv_thresh - tv96_new
			if over > (self.tv96_sv_thresh - self.tv96_long_limit)*2 then
				tv_extra = tv96_new - self.tv96_long_limit
				tv96_new = self.tv96_long_limit
				-- log:log_desc('tv over long:%d',-tv_extra)
				self:nextlog{tv_l1=tv_extra}
			else
				tv_extra = -over/2
				tv96_new = tv96_new - tv_extra
				-- log:log_desc('tv iso adj:%d',-tv_extra)
				self:nextlog{tv_sv_tr=-tv_extra}
			end
		end

		if tv_extra < 0 then
			sv96_new = sv96_new - tv_extra
		end
		if sv96_new > self.sv96_max then
			local sv_over = sv96_new - self.sv96_max
			-- log:log_desc('iso over limit:%d',sv_over)
			self:nextlog{sv_l1=sv_over}
			-- if ISO range isn't past end of shutter range, put remainder back on shutter
			if tv96_new > self.tv96_long_limit then
				-- log:log_desc('iso over tv:%d',tv96_new - self.tv96_long_limit)
				self:nextlog{sv_tv_tr=tv96_new - self.tv96_long_limit}
				tv96_new = tv96_new - sv_over
				if tv96_new < self.tv96_long_limit then
					self:nextlog{tv_l1=tv96_new - self.tv96_long_limit}
					tv96_new = self.tv96_long_limit
				end
			end

			sv96_new = self.sv96_max
		end
	else
		if tv96_new < self.tv96_long_limit then
			-- log:log_desc('tv over long:%d',self.tv96_long_limit- tv96_new)
			self:nextlog{tv_l1=tv96_new - self.tv96_long_limit}
			tv96_new = self.tv96_long_limit
		end
	end

	if tv96_new > self.tv96_short_limit then
		-- log:log_desc('tv under short:%d',tv96_new)
		self:nextlog{tv_l1=tv96_new - self.tv96_short_limit}
		tv96_new = self.tv96_short_limit
	end


	self.tv96 = tv96_new
	self.sv96 = sv96_new
	self.av96 = av96_new
	self.nd_state = nd_state_new
	self.nd96 = self:nd96_for_state(self.nd_state)
end

--[[
force reset of values that are calculated from first exposure
]]
function exp:reset()
	-- force reset of last ev, shifted values
	self.ev_change=nil
	-- force refresh of exposure values from cam exposure
	self.tv96 = nil
end


-- meter and update exposure
function exp:run()
	-- initialize raw buffer related values that can change between frames
	self:init_frame()
	-- update / sanity check settings from previous exposure
	self:get_cam_exposure_params()
	-- log previous exposure
	self:log_exposure_params()
	-- log related items from previous exposure calc
	self:log_nextlog_vals()

	self:do_meter()
	self:log_meter()

	if self.mval == 0 then
		log:set{meter='fail'}
		return
	end

	-- if m96 == 0, bv = tv + av - sv
	-- nd96 is works like av, for cameras with both iris and ND
	self.bv96 = self.tv96 + self.av96 + self.nd96 - self.sv96 + self.mval96

	log:set{bv96=self.bv96}

	-- calculate required EV change
	self:calc_ev_change()

	-- turn EV change into updated exposure settings
	self:calc_exposure_params()

	-- set values for next exposure
	self:set_cam_exposure_params()

	if self.do_draw then
		self:draw()
	end
end
return exp

end)()
package.loaded['reylib/rawexp']=exp -- end inline reylib/rawexp

function restore()
	disp:enable(true)
	-- note for some cameras, canon raw is in RESOLUTION prop
	-- restore raw and size settings in reverse order of set to restore initial value
	if canon_img_fmt_save then
		set_canon_image_format(canon_img_fmt_save)
	end
	if image_size_save then
		set_prop(props.RESOLUTION,image_size_save)
	end
	if raw_enable_save then
		set_raw(raw_enable_save)
	end
	if usb_remote_enable_save then
		set_config_value(require'GEN/cnf_core'.remote_enable,usb_remote_enable_save)
	end
	log:close()
end

-- main script initialization
interval=ui_interval_s10*100

-- not all available on all cams
-- typical through propset 6
-- 0 = large (native), 1 = M1, 2=M2, 3=M3, 4=S (640x480), 8=Wide. 5=Canon raw on some cams
-- later propsets, crash if 1, 4 used
-- 0 = L, 2 = M1, 3 = M2, 5 = S

if get_propset() <= 6 then
	image_size=({false,0,1,2,3,4,8})[ui_image_size_e + 1]
else
	image_size=({false,0,2,3,3,5,0})[ui_image_size_e + 1]
end
-- need long to allow 100k, doesn't allow range
if ui_exp_over_thresh_frac < 0 or ui_exp_over_thresh_frac > 100000 then
	error('over frac must be 0-100000')
end
if ui_exp_under_thresh_frac < 0 or ui_exp_under_thresh_frac > 100000 then
	error('under frac must be 0-100000')
end

use_raw=({false,1,0})[ui_use_raw_e + 1]
canon_img_fmt=({false,1,2,3})[ui_canon_img_fmt + 1]

-- quarter stops ... 0 24 48 ...
ui_ev_shift=(ui_ev_shift_e-10)*24
ui_meter_high_thresh =  (ui_meter_high_thresh_e + 2)*24
ui_meter_high_limit =  (ui_meter_high_limit_e + 4)*24
ui_meter_low_thresh =  -(ui_meter_low_thresh_e + 2)*24
ui_meter_low_limit =  -(ui_meter_low_limit_e + 4)*24
ui_nd_hysteresis=(ui_nd_hysteresis_e)*24

ui_max_ev_change = ({96/16,96/8,96/4,96/3,96/2,96})[(ui_max_ev_change_e + 1)]
ui_exp_over_margin_ev = ({96/32,96/16,96/8,96/4,96/3,96/2,2*96/3,3*96/4,96})[(ui_exp_over_margin_e + 1)]
ui_exp_under_margin_ev = ({96*7, 96*6, 96*5 + 48, 96*5, 96*4 + 48, 96*4, 96*3 + 48, 96*3, 96*2 + 48, 96*2})[ui_exp_under_margin_e+1]

ui_histo_step=tonumber(ui_histo_step_t.value)

-- half stops, first is auto
if ui_bv_ev_shift_base_e==0 then
	ui_bv_ev_shift_base_bv=false
else
	ui_bv_ev_shift_base_bv=(ui_bv_ev_shift_base_e - 3)*48
end

if ui_meter_high_thresh >= ui_meter_high_limit or
	ui_meter_low_thresh <= ui_meter_low_limit then
	error('meter limit must be > than thresh')
end

if ui_interval_warn_led < 0 then
	ui_interval_warn_led=false
end


disp:init{
	-- show the first few shots
	start_delay = 15000,
	mode = string.lower(ui_display_mode_t.value),
}

log = xsvlog.new{
	name="A/rawopint.csv",
	append=(ui_log_mode.value=='Append'),
	dummy=(ui_log_mode.value=='None'),
--	buffer_mode='sync', -- for crash debugging, save every line
	-- column names
	cols={
		'date',
		'time',
		'exp',
		'start',
		'shoot_ready',
		'sleep',
		'exp_start',
		'raw_ready',
		'raw_done',
		'vbatt',
		'tsensor',
		'topt',
		'tbatt',
		'free_mem',
		'lua_mem',
		'sd_space',
		exp.log_columns,
		'desc',
	},
	-- columns automatically set at write time from functions
	funcs={
		exp=get_exp_count,
		vbatt=get_vbatt,
		tsensor=function()
			return get_temperature(1)
		end,
		topt=function()
			return get_temperature(0)
		end,
		tbatt=function()
			return get_temperature(2)
		end,
		free_mem=function()
			return get_meminfo().free_size
		end,
		lua_mem=function()
			return collectgarbage('count')
		end,
		sd_space=get_free_disk_space,
	},
	-- columns collected in a table, concatenated at write time
	tables={
		desc=' / ',
	},
	dt_loggers={
		'start',
	},
	text_loggers={
		'desc',
	},
}
-- log message and display on screen, for waiting stage
logecho=function(...)
	stru.printf(...)
	log:log_desc(...)
end

shutdown:init{
	finish=ui_shutdown_finish,
	lowbat=ui_shutdown_lowbat,
	lowspace=ui_shutdown_lowspace,
}

exp:init{
	meter_width_pct=ui_meter_width_pct,
	meter_height_pct=ui_meter_height_pct,
	meter_left_pct=ui_meter_left_pct,
	meter_top_pct=ui_meter_top_pct,
	meter_step=ui_meter_step,

	ev_change_max=ui_max_ev_change,
	ev_shift=ui_ev_shift, -- shift target ev by x APEX96
	ev_use_initial=ui_ev_use_initial, -- use initial EV as target ev, modified by ev_shift if specified
	bv_ev_shift_pct=ui_bv_ev_shift_pct, -- shift ev proportional to abosolute scene brightness
	bv_ev_shift_base_bv=ui_bv_ev_shift_base_bv, -- absolute scene brightness for initial target ev (direct sun = ~10)
	-- max (longest) shutter value
	tv96_long_limit=usec_to_tv96(ui_tv_max_s1k*1000),
	-- min (shortest) shutter value
	tv96_short_limit=usec_to_tv96(ui_tv_min_s100k*10),
	-- shutter value to start adjusting iso
	tv96_sv_thresh=usec_to_tv96(ui_tv_sv_adj_s1k*1000),

	-- shutter value to put in ND
	tv96_nd_thresh=usec_to_tv96(ui_tv_nd_thresh_s10k*100),

	nd_value=ui_nd_value,
	nd_hysteresis=ui_nd_hysteresis,
	-- max iso
	sv96_max=sv96_market_to_real(iso_to_sv96(ui_sv_max_mkt)),
	-- target iso
	sv96_target=sv96_market_to_real(iso_to_sv96(ui_sv_target_mkt)),

-- prefer low or high aperture
-- TODO not implemented
--av_target_low = (av_target.value == 0)


	-- point where high meter value starts increasing meter weight,
	meter_high_thresh = ui_meter_high_thresh,
	-- point where full weight increase is reached
	meter_high_limit = ui_meter_high_limit,
	-- weight at limit
	meter_high_limit_weight = ui_meter_high_limit_weight,

	-- point where low meter value starts increasing meter weight
	meter_low_thresh = ui_meter_low_thresh,
	-- point where full weight increase is reached
	meter_low_limit = ui_meter_low_limit,
	-- weight at limit
	meter_low_limit_weight = ui_meter_low_limit_weight,

    -- how close to max shot histo to count against over exp fraction
	over_margin_ev=ui_exp_over_margin_ev,

    -- under is defined in terms of EV under neutral, since there are a bunch of stops without useful DR near black level
	under_margin_ev=ui_exp_under_margin_ev,

	-- histo is measured in parts per million, inputs in parts per 100k
	over_thresh_frac=ui_exp_over_thresh_frac*10,
	under_thresh_frac=ui_exp_under_thresh_frac*10,

	over_weight_max=ui_exp_over_weight_max,
	over_prio=ui_exp_over_prio,

	under_weight_max=ui_exp_under_weight_max,
	under_prio=ui_exp_under_prio,

	histo_step=ui_histo_step,
	do_draw=ui_do_draw,
	draw_meter=string.lower(ui_draw_meter_t.value),
	draw_gauge_y_pct=ui_draw_gauge_y_pct,
	smooth_factor=ui_smooth_factor*imath.scale/10, -- input is 0-9, value is imath 0-0.9
	smooth_limit_frac=ui_smooth_limit_frac*imath.scale/10, -- imath 0-1
	ev_chg_rev_limit_frac=ui_ev_chg_rev_limit_frac*imath.scale/10, -- imath 0-1
}

function log_preshoot_values()
	local dof=get_dofinfo()
	log:log_desc('sd:%d af_ok:%s fl:%d efl:%d zoom_pos:%d',
			dof.focus,tostring(get_focus_ok()),dof.focal_length,dof.eff_focal_length,get_zoom())
end

function run()
	local bi=get_buildinfo()
	log:log_desc("rawopint v:%s",rawopint_version)
	log:log_desc("platform:%s-%s-%s-%s %s %s",
						bi.platform,bi.platsub,bi.build_number,bi.build_revision,
						bi.build_date,bi.build_time)
	log:log_desc('interval:%d',interval)

	clockstart:init{
		active=(ui_start_hour >= 0),
		hour=ui_start_hour,
		min=ui_start_min,
		sec=ui_start_sec,
	}
	-- aborted in main wait, return for cleanup / shutdown
	if not clockstart:main_wait() then
		return
	end

	local rec, vid = get_mode()
	if not rec then
		print("switching to rec")
		sleep(1000)
		set_record(true)
		repeat sleep(10) until get_mode()
		sleep(500)
		rec, vid = get_mode()
	end
	if vid then
		error('not in still mode')
	end
	log:log_desc('capmode:%s',capmode.get_name())

	if ui_raw_hook_sleep > 0 then
		log:log_desc('rawhooksleep:%d',ui_raw_hook_sleep)
	end

	local yield_save_count, yield_save_ms
	if ui_noyield then
		log:log_desc('noyield')
		yield_save_count, yield_save_ms = set_yield(-1,-1)
	end
	if image_size then
		image_size_save = get_prop(props.RESOLUTION)
		set_prop(props.RESOLUTION,image_size)
	end
	if use_raw then
		raw_enable_save = get_raw()
		set_raw(use_raw)
	end
	-- note for some cameras, canon raw is in RESOLUTION prop
	-- restore should preserve by restoring resolution last
	if canon_img_fmt then
		if get_canon_raw_support() then
			canon_img_fmt_save = get_canon_image_format()
			set_canon_image_format(canon_img_fmt)
			log:log_desc('set canon_img_fmt:%d',canon_img_fmt)
		elseif canon_img_fmt > 1 then
			error('Firmware does not support Canon RAW')
		end
	else
		log:log_desc('canon_img_fmt:%d',get_canon_image_format())
	end

	local cont = ui_use_cont and get_prop(props.DRIVE_MODE) == 1
	if cont then
		log:log_desc('cont_mode')
	end

	if rs_opts then
		log:log_desc('remoteshoot')
	end

	if ui_zoom_mode_t.value ~= 'Off' then
		local zoom_step
		if ui_zoom_mode_t.value == 'Pct' then
			if ui_zoom > 100 then
				log:log_desc('WARN zoom %d>100%%',ui_zoom)
				ui_zoom=100
			end
			zoom_step = (get_zoom_steps()*ui_zoom)/100
		else
			if ui_zoom >= get_zoom_steps() then
				log:log_desc('WARN zoom %d>max %d',ui_zoom,get_zoom_steps()-1)
				zoom_step = get_zoom_steps()-1
			else
				zoom_step = ui_zoom
			end
		end
		set_zoom(ui_zoom)
		sleep(250) -- small delay before setting focus
	end

	if ui_sd_mode_t.value ~= 'Off' then
		focus:init()
		focus:enable_override(ui_sd_mode_t.value)
		log:log_desc('uisd:%d pref:%s mode:%s',ui_sd,ui_sd_mode_t.value,focus:get_mode())
		focus:set(ui_sd)
	end

	-- set initial display state
	disp:update()

	-- set the hook just before shutter release for timing, for interval control
	-- must wait up to inverval - shooting overhead, add 2 sec just for safety
	hook_shoot.set(2000+interval)
	-- if using remote, make sure shoot hook will wait longer than timeout interval
	if ui_use_remote then
		log:log_desc("USB remote")
		usb_remote_enable_save = get_config_value(require'GEN/cnf_core'.remote_enable)
		set_config_value(require'GEN/cnf_core'.remote_enable,1)
		-- TODO set remote config values as needed
	end
	-- set hook in raw for exposure
	-- only needs to wait for metering, exposure calc etc
	hook_raw.set(10000)

	-- times for pre-shoot
	log:set{
		start=get_tick_count(),
		date=os.date('%m/%d/%Y'),
		time=os.date('%H:%M:%S'),
	}

	press('shoot_half')

	repeat sleep(10) until get_shooting()

	exp:init_preshoot()

	log_preshoot_values()

	log:write()

	-- collect all startup related garbage
	collectgarbage('collect')

	-- could start in shoot hook, but only second-ish resolution anyway
	clockstart:final_wait()

	-- 0 = no limit, end on space, power etc
	if ui_shots == 0 then
		ui_shots = 100000000
	end

	if cont then
		press('shoot_full_only')
	end
	local user_exit
	for shot=1,ui_shots do
		log:set{
			start=get_tick_count(),
			date=os.date('%m/%d/%Y'),
			time=os.date('%H:%M:%S'),
		}
		-- poll / reset click state
		-- camera will generally take while to be ready for next shot, so extra wait here shouldn't hurt
		wait_click(10)
		if is_key('menu') or read_usb_msg() == 'quit' then
			user_exit=true
		end
		if user_exit then
			-- prevent shutdown on finish if user abort
			shutdown.opts.finish = false
			log:log_desc('user exit')
			log:write()
			break
		end
		-- TODO CHDK osd doesn't seem to update in halfshoot, but you can check exposure
		if is_key('set') then
			log:log_desc('key_set')
			disp:toggle(30000)
		end
		if shutdown:check() then
			log:log_desc('shutdown:%s',shutdown:reason())
			log:write()
			break
		end

		if not cont then
			press('shoot_full_only')
		end
		-- wait until the hook is reached
		hook_shoot.wait_ready()
		log:dt_start('shoot_ready')
		if not cont then
			release('shoot_full_only')
		end
		-- in cont release shoot full as soon as the final shot starts
		-- to avoid extra shots and delays
		if cont and shot == ui_shots then
			release('shoot_full')
		end

		-- run anything that needs to run on shoot ready in exp hook
		exp:on_hook_shoot_ready()

		if ui_use_remote then
			-- using remote, wait for pulse or timeout if not already received
			local t0=get_tick_count()
			local timeout = t0+interval
			while get_usb_power(0) == 0 do
				-- allow menu to exit (will take one more shot)
				-- normal exit hard to hit, because remote pulse counts as key
				wait_click(10)
				if is_key('menu') then
					log:log_desc('remote quit')
					user_exit=true
					break
				end
				if get_tick_count() > timeout then
					log:log_desc('remote timeout')
					break
				end
			end
			log:set{sleep=get_tick_count()-t0} -- how long remote was waited for?
		else -- not remote
			-- if additional wait is needed to reach the desired interval, wait
			if shot_tick then
				-- local et = get_tick_count() - shot_tick
				local sleepms = interval - get_tick_count() + shot_tick
				if sleepms > 0 then
					sleep(sleepms)
				elseif interval > 0 then -- if specific interval set, warn if not achieved
					if ui_interval_warn_led then
						set_led(ui_interval_warn_led,1)
					end
					if ui_interval_warn_beep then
						play_sound(4)
					end
				end
				log:set{sleep=sleepms} -- negative == late
			end
		end
		-- record time
		shot_tick = get_tick_count()
		log:dt_start('exp_start') -- the moment the exposure started, because hey, why not?
		-- allow shooting to proceed
		hook_shoot.continue()

		disp:update()

		-- wait for the image to be captured
		hook_raw.wait_ready()
		log:dt_start('raw_ready')

		-- if warning LED specified, make sure it's turned off here
		if ui_interval_warn_led then
			set_led(ui_interval_warn_led,0)
		end

		exp:run()
		-- TODO D10 sometimes fails to open shutter if this is off and debug drawing is disabled, and set_yield is not used
		if ui_raw_hook_sleep > 0 then
			sleep(ui_raw_hook_sleep)
		end
		hook_raw.continue()
		log:dt_start('raw_done')
		log:write()
		-- if run through remoteshoot, honor the filedummy option to create dummy jpeg/cr2 files
		if rs_opts and rs_opts.filedummy then
			rlib_shoot_filedummy()
		end
		-- encourage garbage collection at a predictable point
		-- TODO should do full collect in sleep time if avail, otherwise step
		collectgarbage('step')
	end
	-- clear hooks
	hook_shoot.set(0)
	hook_raw.set(0)

	if yield_save_count then
		set_yield(yield_save_count,yield_save_ms)
	end
	release('shoot_full')

	-- allow final shot to end before restore + possible shutdown
	repeat sleep(10) until not get_shooting()
	sleep(1000)

	restore()
	shutdown:finish()
end

run()
