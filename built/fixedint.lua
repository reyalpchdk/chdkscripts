--[[
@title fixed exposure intervalometer
@chdk_version 1.5.1
#ui_shots=1 "Shots (0=unlimited)"
#ui_interval_s10=0 "Interval Sec/10 (0=max)"
#ui_use_raw_e=1 "Use CHDK raw" {Default Yes No}
#ui_canon_img_fmt=0 "Canon image format" {Default JPG RAW RAW+JPG}
#ui_disable_dfs=true "Disable Canon Dark Frame"
#ui_tv_e=3 "Tv" {0 256 128 64 32 16 8 4 2 1 1/2 1/4 1/8 1/16 1/32 1/64}
#ui_tv_s=0 "Tv + sec" [0 2000]
#ui_tv_s10000=0 "Tv + sec/10000" [0 10000]
#ui_start_delay=300 "Start delay (ms)"
#ui_start_hour=-1 "Start hour (-1 off)" [-1 23]
#ui_start_min=0 "Start minute" [0 59]
#ui_start_sec=0 "Start second" [0 59]
#ui_iso=0 "ISO (by CHDK, 0=not set)"
#ui_iso_mode_e=0 "ISO (by ISO mode)" {No 80 100 200 400 800 1600}
#ui_zoom_mode_t=1 "Zoom mode" {Off Pct Step} table
#ui_zoom=0 "Zoom value" [0 500]
#ui_sd_mode_t=1 "Focus override mode" {Off MF AFL AF} table
#ui_sd=0 "Focus dist (mm)" long
#ui_use_cont=true "Use cont. mode if set"
#ui_display_mode_t=1 "Display" {On Off Blt_Off} table
#ui_shutdown_finish=false "Shutdown on finish"
#ui_shutdown_lowbat=true "Shutdown on low battery"
#ui_shutdown_lowspace=true "Shutdown on low space"
#ui_darks=false "Make dark frames"
#ui_log_mode=2 "Log mode" {None Append Replace} table

License: GPL

Copyright 2015-2021 reyalp (at) gmail.com

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
fixedint_version="1.4-dev"

props=require'propcase'
require'hookutil'

interval=ui_interval_s10*100

if ui_iso_mode_e ~= 0 then
	iso_mode=({80,100,200,400,800,1600})[ui_iso_mode_e]
end
if ui_iso ~= 0 then
	sv96=sv96_market_to_real(iso_to_sv96(ui_iso))
end

use_raw=({false,1,0})[ui_use_raw_e + 1]
canon_img_fmt=({false,1,2,3})[ui_canon_img_fmt + 1]

;(function()
	local tv_us=ui_tv_s*1000000 + ui_tv_s10000*100

	if ui_tv_e == 0 then
		if tv_us == 0 then
			error('Tv options all zero!')
		end
		tv = usec_to_tv96(tv_us)
		return
	else
		-- first entry in table is 0, not used
		tv=({-8*96,-7*96,-6*96,-5*96,-4*96,-3*96,-2*96,-96,0,96,2*96,3*96,4*96,5*96,6*96})[ui_tv_e]
		if tv_us ~= 0 then
			tv = usec_to_tv96(tv_us + tv96_to_usec(tv))
		end
	end
end)()

save_nr=get_raw_nr()
save_raw=get_raw()

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

log=(function() -- inline reylib/csvlog
-- csv log module. License: GPL
local log={}

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

function log:init(opts)
	if not opts then
		error('missing opts')
	end
	if not opts.name then
		error('missing name')
	end
	if type(opts.cols) ~= 'table' or #opts.cols < 1 then
		error('bad or empty cols')
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
	if opts.buffer_mode then
		self.buffer_mode = opts.buffer_mode
	else
		self.buffer_mode = 'os'
	end
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
function log:prepare_write()
	if self.buffer_mode == 'os' then
		return
	end
	-- if self.buffer_mode == 'sync' or self.buffer_mode then
	self.fh = io.open(self.name,'ab')
	if not self.fh then
		error('failed to open log')
	end
end
function log:finish_write()
	if self.buffer_mode == 'os' then
		return
	end
	self.fh:close()
	self.fh=nil
end

function log:quote_csv_cell(cell)
	if self.quote_mode and ( self.quote_mode == 'always' or cell:match('[,"\r\n]') ) then
		return '"'..cell:gsub('"','""')..'"'
	end
	return cell
end
function log:write_csv(data)
	local quoted
	if self.quote_mode then
		quoted = {}
		for i, cell in ipairs(data) do
			table.insert(quoted,self:quote_csv_cell(cell))
		end
	else
		quoted = data
	end
	self.fh:write(string.format("%s\n",table.concat(quoted,',')))
end
function log:write_data(data)
	if self.buffer_mode == 'table' then
		table.insert(self.lines,data)
		return
	end
	self:prepare_write()
	self:write_csv(data)
	self:finish_write()
end

function log:flush()
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

function log:write()
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
function log:reset_vals()
	for i,name in ipairs(self.cols) do
		if self.tables[name] then
			self.vals[name] = {}
		else
			self.vals[name] = ''
		end
	end
end
function log:set(vals)
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
--[[
return a function that records time offset from col named base_name
if name is not provided, function expects target aname as arg
]]
function log:dt_logger(base_name,name)
	if not self.vals[base_name] then
		error('invalid base field name')
	end
	if self.dummy then
		return function() end
	end
	if not name then
		return function(name)
			if not self.vals[name] then
				error('invalid col name')
			end
			self.vals[name]=get_tick_count() - self.vals[base_name]
		end
	end
	if not self.vals[name] then
		error('invalid col name')
	end
	return function()
		self.vals[name]=get_tick_count() - self.vals[base_name]
	end
end

--[[
return a printf-like function that appends to table col
]]
function log:text_logger(name)
	if not self.vals[name] then
		error('invalid col name')
	end
	if not self.tables[name] then
		error('text logger must be table field '..tostring(name))
	end
	if self.dummy then
		return function() end
	end
	return function(fmt,...)
		table.insert(self.vals[name],string.format(fmt,...))
	end
end

function log:close()
	if self.buffer_mode == 'table' then
		self:flush()
	end
	if self.fh then
		self.fh:close()
	end
end
return log

end)()
package.loaded['reylib/csvlog']=log -- end inline reylib/csvlog

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
		logdesc('disp:toggle off')
		self.shutoff_time = false
		self:enable(false)
	else
		logdesc('disp:toggle on')
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

end)()
package.loaded['reylib/clkstrt']=clockstart -- end inline reylib/clkstrt

function init_shutter_procs()
	if ui_darks then
		local close_func_name
		-- will throw "native calls disabled" if not enabled, no need for additional check
		if call_event_proc('Mecha.Create') == -1 then
			if call_event_proc('MechaRegisterEventProcedure') == -1 then
				error('Failed to initialize Mecha failed')
			end
			close_func_name='CloseMechaShutterEvent'
		else
			close_func_name='CloseMechaShutter'
		end
		close_shutter=function()
			if call_event_proc(close_func_name) == -1 then
				error('Close Shutter failed')
			end
		end
	end
end

function restore()
	-- note for some cameras, canon raw is in RESOLUTION prop
	-- restore raw and size settings in reverse order of set to restore initial value
	if canon_img_fmt_save then
		set_canon_image_format(canon_img_fmt_save)
	end
	if image_size_save then
		set_prop(props.RESOLUTION,image_size_save)
	end

	set_raw_nr(save_nr)
	set_raw(save_raw)
	disp:enable(true)
	log:close()
end

function log_preshoot_values()
	local dof=get_dofinfo()
	logdesc('sd:%d af_ok:%s fl:%d efl:%d zoom_pos:%d',
			dof.focus,tostring(get_focus_ok()),dof.focal_length,dof.eff_focal_length,get_zoom())
	-- these shouldn't change, only log initial values
	logdesc('sv96:%d tv96:%d av96:%d',get_prop(props.SV), get_prop(props.TV), get_prop(props.AV))
end

function run()
	disp:init{
		mode = string.lower(ui_display_mode_t.value)
	}
	log:init{
		name="A/fixedint.csv",
		append=(ui_log_mode.value=='Append'),
		dummy=(ui_log_mode.value=='None'),
		-- column names
		cols={
			'date',
			'tick',
			'exp',
			'exp_start',
			'sleep',
			'vbatt',
			'tsensor',
			'topt',
			'free_mem',
			'lua_mem',
			'desc',
		},
		-- columns automatically set at write time from functions
		funcs={
			date=function()
				return os.date('%m/%d/%Y %H:%M:%S')
			end,
			tick=get_tick_count,
			exp=get_exp_count,
			vbatt=get_vbatt,
			tsensor=function()
				return get_temperature(1)
			end,
			topt=function()
				return get_temperature(0)
			end,
			free_mem=function()
				return get_meminfo().free_size
			end,
			lua_mem=function()
				return collectgarbage('count')
			end,
		},
		-- columns collected in a table, concatenated at write time
		tables={
			desc=' / ',
		},
	}
	logdesc=log:text_logger('desc')
	-- log message and display on screen, for waiting stage
	logecho=function(...)
		stru.printf(...)
		logdesc(...)
	end

	shutdown:init{
		finish=ui_shutdown_finish,
		lowbat=ui_shutdown_lowbat,
		lowspace=ui_shutdown_lowspace,
	}

	init_shutter_procs()

	logdesc('fixedint v:%s',fixedint_version)

	local bi=get_buildinfo()
	logdesc("platform:%s-%s-%s-%s %s %s",
						bi.platform,bi.platsub,bi.build_number,bi.build_revision,
						bi.build_date,bi.build_time)
	logdesc('interval:%d',interval)

	if ui_darks then
		logdesc('taking darks')
	end

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
		disp:enable(true)
		error('not in still mode')
	end
	if ui_zoom_mode_t.value ~= 'Off' then
		local zoom_step
		if ui_zoom_mode_t.value == 'Pct' then
			if ui_zoom > 100 then
				logdesc('WARN zoom %d>100%%',ui_zoom)
				ui_zoom=100
			end
			zoom_step = (get_zoom_steps()*ui_zoom)/100
		else
			if ui_zoom >= get_zoom_steps() then
				logdesc('WARN zoom %d>max %d',ui_zoom,get_zoom_steps()-1)
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
		logdesc('uisd:%d pref:%s mode:%s',ui_sd,ui_sd_mode_t.value,focus:get_mode())
		focus:set(ui_sd)
	end


	if use_raw then
		set_raw(use_raw)
	end
	if canon_img_fmt then
		if get_canon_raw_support() then
			-- note for some cameras, canon raw is in RESOLUTION prop
			-- save resolution value to restore later
			image_size_save = get_prop(props.RESOLUTION)
			canon_img_fmt_save = get_canon_image_format()
			set_canon_image_format(canon_img_fmt)
			logdesc('set canon_img_fmt:%d',canon_img_fmt)
		elseif canon_img_fmt > 1 then
			error('Firmware does not support Canon RAW')
		end
	else
		logdesc('canon_img_fmt:%d',get_canon_image_format())
	end

	if ui_disable_dfs then
		set_raw_nr(1)
	end

	if iso_mode then
		set_iso_mode(iso_mode)
	end
	if sv96 then
		set_sv96(sv96)
	end

	local cont = ui_use_cont and get_prop(props.DRIVE_MODE) == 1
	if cont then
		logdesc('cont_mode')
	end
	if ui_shots == 0 then
		ui_shots = 100000000
	end

	-- set initial display state
	disp:update()

	if not clockstart.ts_start then
		logdesc('start_delay:%d',ui_start_delay)
		sleep(ui_start_delay)
	end

	-- set the hook just before shutter release for timing, for interval control
	-- must wait up to interval - shooting overhead, add 2 sec just for safety
	hook_shoot.set(2000 + interval)
	-- set hook in raw for exposure
	hook_raw.set(10000)

	set_tv96_direct(tv)

	press('shoot_half')

	repeat sleep(10) until get_shooting() == true

	log_preshoot_values()

	-- could start in shoot hook, but only second-ish resolution anyway
	clockstart:final_wait()

	-- if canon power saving was active for initial wait, display could have turned on in initial half press
	-- despite name, this only takes effect if display mode is Off
	disp:enable(false)

	if cont then
		press'shoot_full_only'
	end
	for shot=1,ui_shots do
		print("shot ",shot,"/",ui_shots)
		-- poll / reset click state
		-- camera will generally take while to be ready for next shot, so extra wait here shouldn't hurt
		wait_click(10)
		if is_key('menu') then
			-- prevent shutdown on finish if user abort
			shutdown.opts.finish = false
			logdesc('user exit')
			log:write()
			break
		end
		if shutdown:check() then
			logdesc('shutdown:%s',shutdown:reason())
			log:write()
			break
		end

		if not cont then
			press('shoot_full_only')
		end
		hook_shoot.wait_ready()
		if ui_darks then
			close_shutter()
		end
		if not cont then
			release('shoot_full_only')
		end
		-- in cont release shoot full as soon as the final shot starts
		-- to avoid extra shots and delays
		if cont and shot == ui_shots then
			release('shoot_full')
		end
		-- if additional wait is needed to reach the desired interval, wait
		if shot_tick then
			local et = get_tick_count() - shot_tick
			if et < interval then
				sleep(interval - et)
			end
			log:set{sleep=interval-et} -- negative == late
		end
		-- record time
		shot_tick = get_tick_count()
		log:set{exp_start=shot_tick}
		hook_shoot.continue()
		if is_key('set') then
			disp:toggle(30000)
		end
		disp:update()
		-- wait for the image to be captured
		hook_raw.wait_ready()
		set_tv96_direct(tv)
		hook_raw.continue()
		log:write()
		-- if run through remoteshoot, honor the filedummy option to create dummy jpeg/cr2 files
		if rs_opts and rs_opts.filedummy then
			rlib_shoot_filedummy()
		end
		-- encourage garbage collection at a predictable point
		collectgarbage('step')
	end

	-- clear hooks
	hook_shoot.set(0)
	hook_raw.set(0)

	-- will release half and full as needed
	release('shoot_full')

	-- allow final shot to end before restore + possible shutdown
	repeat sleep(10) until not get_shooting()
	sleep(1000)
end

run()
restore()
shutdown:finish()
