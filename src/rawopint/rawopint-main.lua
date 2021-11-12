--[[
@title raw meter intervalometer
@chdk_version 1.5.1
#ui_shots=0 "Shots (0 = unlimited)"
#ui_interval_s10=20 "Interval Sec/10"
#ui_use_remote=false "USB remote interval control"
#ui_meter_width_pct=90 "Meter width %" [1 100]
#ui_meter_height_pct=90 "Meter height %" [1 100]
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

stru=require'reylib/strutil' --[!inline]

log = require'reylib/csvlog' --[!inline]

disp = require'reylib/disp' --[!inline]

shutdown = require'reylib/shutdown' --[!inline]

focus = require'reylib/focus' --[!inline]

clockstart = require'reylib/clkstrt' --[!inline]

exp = require'reylib/rawexp' --[!inline]

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

log:init{
	name="A/rawopint.csv",
	append=(ui_log_mode.value=='Append'),
	dummy=(ui_log_mode.value=='None'),
--	buffer_mode='sync', -- for crash debugging, save every line
	-- column names
	cols={
		'date',
		'time',
		'tick',
		'exp',
		'start',
		'shoot_ready',
		'sleep',
		'exp_start',
		'raw_ready',
		'meter_time',
		'histo_time',
		'draw_time',
		'raw_done',
		'vbatt',
		'tsensor',
		'topt',
		'tbatt',
		'free_mem',
		'lua_mem',
		'sd_space',
		'sv',
		'sv96',
		'tv',
		'tv96',
		'av',
		'av96',
		'nd',
		'bv96',
		'meter',
		'meter96',
		'meter96_tgt',
		'meter_weight',
		'over_frac',
		'over_weight',
		'under_frac',
		'under_weight',
		'bv_ev_shift',
		'd_ev_base',
		'd_ev_s1',
		'd_ev_s2',
		'd_ev_r1',
		'd_ev_f',
		'd_ev',
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
}
logtime=log:dt_logger('start')
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

exp:init{
	meter_width_pct=ui_meter_width_pct,
	meter_height_pct=ui_meter_height_pct,
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
	logdesc('sd:%d af_ok:%s fl:%d efl:%d zoom_pos:%d',
			dof.focus,tostring(get_focus_ok()),dof.focal_length,dof.eff_focal_length,get_zoom())
end

function run()
	local bi=get_buildinfo()
	logdesc("rawopint v:%s",rawopint_version)
	logdesc("platform:%s-%s-%s-%s %s %s",
						bi.platform,bi.platsub,bi.build_number,bi.build_revision,
						bi.build_date,bi.build_time)
	logdesc('interval:%d',interval)

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
	logdesc('capmode:%s',capmode.get_name())

	if ui_raw_hook_sleep > 0 then
		logdesc('rawhooksleep:%d',ui_raw_hook_sleep)
	end

	local yield_save_count, yield_save_ms
	if ui_noyield then
		logdesc('noyield')
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
			logdesc('set canon_img_fmt:%d',canon_img_fmt)
		elseif canon_img_fmt > 1 then
			error('Firmware does not support Canon RAW')
		end
	else
		logdesc('canon_img_fmt:%d',get_canon_image_format())
	end

	local cont = ui_use_cont and get_prop(props.DRIVE_MODE) == 1
	if cont then
		logdesc('cont_mode')
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

	-- set initial display state
	disp:update()

	-- set the hook just before shutter release for timing, for interval control
	-- must wait up to inverval - shooting overhead, add 2 sec just for safety
	hook_shoot.set(2000+interval)
	-- if using remote, make sure shoot hook will wait longer than timeout interval
	if ui_use_remote then
		logdesc("USB remote")
		usb_remote_enable_save = get_config_value(require'GEN/cnf_core'.remote_enable)
		set_config_value(require'GEN/cnf_core'.remote_enable,1)
		-- TODO set remote config values as needed
	end
	-- set hook in raw for exposure
	-- only needs to wait for metering, exposure calc etc
	hook_raw.set(10000)

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
		-- poll / reset click state
		-- camera will generally take while to be ready for next shot, so extra wait here shouldn't hurt
		wait_click(10)
		if is_key('menu') then
			user_exit=true
		end
		if user_exit then
			-- prevent shutdown on finish if user abort
			shutdown.opts.finish = false
			logdesc('user exit')
			log:write()
			break
		end
		-- TODO CHDK osd doesn't seem to update in halfshoot, but you can check exposure
		if is_key('set') then
			logdesc('key_set')
			disp:toggle(30000)
		end
		if shutdown:check() then
			logdesc('shutdown:%s',shutdown:reason())
			log:write()
			break
		end

		if not cont then
			press('shoot_full_only')
		end
		local t_start=get_tick_count()
		log:set{start=t_start}
		-- wait until the hook is reached
		hook_shoot.wait_ready()
		logtime('shoot_ready')
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
					logdesc('remote quit')
					user_exit=true
					break
				end
				if get_tick_count() > timeout then
					logdesc('remote timeout')
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
		logtime('exp_start') -- the moment the exposure started, because hey, why not?
		-- allow shooting to proceed
		hook_shoot.continue()

		disp:update()

		-- wait for the image to be captured
		hook_raw.wait_ready()
		logtime('raw_ready')

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
		logtime('raw_done')
		log:write()
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
