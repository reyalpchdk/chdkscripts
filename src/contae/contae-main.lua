--[[
@title continuous auto exposure
@chdk_version 1.5.1
#ui_meter_width_pct=60 "Meter width %" [1 100]
#ui_meter_height_pct=60 "Meter height %" [1 100]
#ui_meter_left_pct=-1 "Meter left % (-1 center)" [-1 99]
#ui_meter_top_pct=-1 "Meter top % (-1 center)" [-1 99]
#ui_meter_step=13 "Meter step"
#ui_max_ev_change_e=5 "Max Ev change" {1/4 1/3 1/2 2/3 3/4 1 1.1/4 1.1/3 1.1/2 1.2/3 1.3/4 2}
#ui_smooth_factor=0 "Ev chg smooth factor/10"[0 9]
#ui_smooth_limit_frac=7 "Ev chg smooth limit frac/10" [0 10]
#ui_ev_chg_rev_limit_frac=0 "Ev chg reverse limit frac/10" [0 10]
#ui_ev_use_initial=false "Use initial Ev as target"
#ui_ev_shift_e=10 "Ev shift" {-2.1/2 -2.1/4 -2 -1.3/4  -1.1/2 -1.1/4 -1 -3/4 -1/2 -1/4 0 1/4 1/2 3/4 1 1.1/4 1.1/2 1.3/4 2 2.1/4 2.1/2}
#ui_tv_max_s1k=1000 "Max Tv Sec/1000"
#ui_tv_min_s100k=10 "Min Tv Sec/100K" [1 99999]
#ui_sv_target_mkt=80 "Target ISO"
#ui_tv_sv_adj_s1k=25 "ISO adj Tv Sec/1000"
#ui_sv_max_mkt=800 "Max ISO"
#ui_tv_nd_thresh_s10k=1 "ND Tv Sec/10000"
#ui_nd_hysteresis_e=2 "ND hysteresis Ev" {none 1/4 1/2 3/4 1}
#ui_nd_value=0 "ND value APEX*96 (0=firmware)" [0 1000]
#ui_meter_high_thresh_e=2 "Meter high thresh Ev" {1/2 3/4 1 1.1/4 1.1/2 1.3/4}
#ui_meter_high_limit_e=3 "Meter high limit Ev" {1 1.1/4 1.1/2 1.3/4 2 2.1/4}
#ui_meter_high_limit_weight=200 "Meter high max weight" [100 300]
#ui_meter_low_thresh_e=5 "Meter low thresh -Ev" {1/2 3/4 1 1.1/4 1.1/2 1.3/4 2 2.1/4 2.1/2 2.3/4 3}
#ui_meter_low_limit_e=7 "Meter low limit -Ev" {1 1.1/4 1.1/2 1.3/4 2 2.1/4 2.1/2 2.3/4 3 3.1/4 3.1/2 3.3/4 4}
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
#ui_do_draw=false "Draw debug info"
#ui_draw_meter_t=1 " Meter area" {None Corners Box} table
#ui_draw_gauge_y_pct=0 " Gauge Y offset %" [0 94]
#ui_log_mode=2 "Log mode" {None Append Replace} table
#ui_raw_hook_sleep=0 "Raw hook sleep ms (0=off)" [0 100]

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
contae_version="0.13-dev"

require'hookutil'
require'rawoplib'
props=require'propcase'

log = require'reylib/csvlog' --[!inline]

exp = require'reylib/rawexp' --[!inline]

-- quarter stops ... 0 24 48 ...
ui_ev_shift=(ui_ev_shift_e-10)*24
ui_meter_high_thresh =  (ui_meter_high_thresh_e + 2)*24
ui_meter_high_limit =  (ui_meter_high_limit_e + 4)*24
ui_meter_low_thresh =  -(ui_meter_low_thresh_e + 2)*24
ui_meter_low_limit =  -(ui_meter_low_limit_e + 4)*24
ui_nd_hysteresis=(ui_nd_hysteresis_e)*24

ui_histo_step=tonumber(ui_histo_step_t.value)

ui_max_ev_change = ({
	96/4,
	96/3,
	96/2,
	2*96/3,
	3*96/4,
	96,
	96+96/4,
	96+96/3,
	96+96/2,
	96+2*96/3,
	96+3*96/4,
	2*96})[(ui_max_ev_change_e + 1)]
ui_exp_over_margin_ev = ({96/32,96/16,96/8,96/4,96/3,96/2,2*96/3,3*96/4,96})[(ui_exp_over_margin_e + 1)]
ui_exp_under_margin_ev = ({96*7, 96*6, 96*5 + 48, 96*5, 96*4 + 48, 96*4, 96*3 + 48, 96*3, 96*2 + 48, 96*2})[ui_exp_under_margin_e+1]

if ui_meter_high_thresh >= ui_meter_high_limit or
	ui_meter_low_thresh <= ui_meter_low_limit then
	error('meter limit must be > than thresh')
end

-- need long to allow 100k, doesn't allow range
if ui_exp_over_thresh_frac < 0 or ui_exp_over_thresh_frac > 100000 then
	error('over frac must be 0-100000')
end
if ui_exp_under_thresh_frac < 0 or ui_exp_under_thresh_frac > 100000 then
	error('under frac must be 0-100000')
end

-- keyboard module
kb={
	handle_keys={
		'up',
		'down',
		'left',
		'right',
		'set',
		'shoot_half',
--		'shoot_full',
		'shoot_full_only',
		'erase',
		'zoom_in',
		'zoom_out',
--		'menu',  -- used for exit
		'display',
		'print',
		'erase',
		'iso',
		'flash',
		'mf',
		'macro',
		'video',
		'timer',
		'expo_corr',
		'fe',
		'face',
		'zoom_assist',
		'ae_lock',
		'metering_mode',
		'playback',
		'help',
		'mode',
	},
	handlers={},
	state={},
}
function kb.default_handler(name,state)
	if state then
		press(name)
	else
		release(name)
	end
end

function kb:init(opts)
	for i, name in ipairs(self.handle_keys) do
		self.state[name]=false
		if opts.handlers[name] then
			self.handlers[name] = opts.handlers[name]
		else
			self.handlers[name] = self.default_handler
		end
	end
	for name,fn in ipairs(opts.handlers) do
		if self.state[name]==nil then
			error("handler for unknown key "..tostring(name))
		end
	end
end

function kb:handle_startup_shoot()
	-- shoot full on startup - may be left over from starting the script, or may want to start shooting
	-- full press will include half
	if is_pressed('shoot_half') then
		local t0=get_tick_count()
		-- start getting pre-shoot ready
		press('shoot_half')
		repeat sleep(10) until get_shooting() or not is_pressed('shoot_half')
		local dt=get_tick_count() - t0
		-- if pre-shoot took less than 100ms, may still be seeing the startup click
		if get_tick_count() - t0 < 100 then
			sleep(100-dt)
		end

		-- if shoot_half released, abort
		if not is_pressed('shoot_half') then
			release('shoot_half')
		end
		-- otherwise, continue to the normal shooting loop, shoot full will be detected immediately if held
	end
end
function kb:update()
	-- TODO would be nice to mirror any unhandled key by default, but don't have a way of getting key names
	for i, name in ipairs(self.handle_keys) do
		local new_state = is_pressed(name)
		if new_state ~= self.state[name] then
			self.state[name] = new_state
			self.handlers[name](name,new_state)
		end
	end
end
-- end keyboard module

-- shoot control module
shootctl={
	raw_hook_sleep=ui_raw_hook_sleep
}
function shootctl:update_drive_mode()
	local new_prop = get_prop(props.DRIVE_MODE)
	if new_prop == self.prop then
		return
	end
	self.prop = new_prop
	-- TODO there might be other continous-type values
	self.cont = (new_prop == 1)
	if self.cont then
		hook_shoot.set(0)
	else
		hook_shoot.set(10000)
	end
end
function shootctl:burst_start()
	logdesc('burst start')

	exp:init_preshoot()
	log:write()

	self.burst = true
	if self.cont then
		press('shoot_full_only')
	end
	-- set hook in raw for exposure
	hook_raw.set(10000)
end
function shootctl:burst_end()
	self.burst = false
	-- clear raw hook to ensure capt seq doesn't stay wait after burst
	hook_raw.set(0)
	if self.cont then
		release('shoot_full_only')
	end
	-- flush log when burst is done
	log:flush()
end
function shootctl:run()
	if not self.burst then
		return
	end
	-- if not in cont, simulate by clicking shoot full
	if not self.cont then
		press('shoot_full_only')
		-- wait until the hook is reached
		hook_shoot.wait_ready()
		release('shoot_full_only')
		hook_shoot.continue()
	end
	hook_raw.wait_ready()
	exp:run()
	-- TODO D10 sometimes fails to open shutter if this is off and debug drawing is disabled, and set_yield is not used
	if self.raw_hook_sleep > 0 then
		sleep(self.raw_hook_sleep)
	end

	hook_raw.continue()
	log:write()
end
-- end shoot control

function restore()
	log:close()
end

-- main script initialization
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

log:init{
	name="A/contae.csv",
	append=(ui_log_mode.value=='Append'),
	dummy=(ui_log_mode.value=='None'),
	buffer_mode='table',
	-- column names
	cols={
		'date',
		'time',
		'tick',
		'exp',
		'free_mem',
		'lua_mem',
		exp.log_columns,
		'desc',
	},
	-- columns automatically set at write time from functions
	funcs={
		date=function()
			return os.date('%m/%d/%Y')
		end,
		time=function()
			return os.date('%H:%M:%S')
		end,
		tick=get_tick_count,
		exp=get_exp_count,
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
--logtime=log:dt_logger('start')
logdesc=log:text_logger('desc')

exp:init{
	meter_width_pct=ui_meter_width_pct,
	meter_height_pct=ui_meter_height_pct,
	meter_left_pct=ui_meter_left_pct,
	meter_top_pct=ui_meter_top_pct,
	meter_step=ui_meter_step,

	ev_change_max=ui_max_ev_change,
	ev_shift=ui_ev_shift, -- shift target ev by x APEX96
	ev_use_initial=ui_ev_use_initial, -- use initial EV as target ev, modified by ev_shift if specified

	bv_ev_shift_pct=0, -- not implemented for contae, not clear if it makes sense for contae
	bv_ev_shift_base_bv=false,

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

	-- point where high meter value starts increasing meter weight
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

	-- histo is measured in parts per 100k, inputs in parts per 10k
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

kb:init{
	handlers={
		shoot_full_only=function(name,state)
			-- new press
			if state then
				shootctl:burst_start()
			else
				shootctl:burst_end()
			end
		end,
	}
}

local bi=get_buildinfo()
logdesc("contae v:%s",contae_version);
logdesc("platform:%s-%s-%s-%s %s %s",
					bi.platform,bi.platsub,bi.build_number,bi.build_revision,
					bi.build_date,bi.build_time)

-- TODO might want to handle in script
set_exit_key("menu")

kb:handle_startup_shoot()
shootctl:update_drive_mode() -- ensure drive mode initialized
while true do
	kb:update()
	shootctl:update_drive_mode()
	shootctl:run()
	sleep(10)
end
