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

Copyright 2015-2025 reyalp (at) gmail.com

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

stru=require'reylib/strutil' --[!inline]

xsvlog = require'reylib/xsvlog' --[!inline]

disp = require'reylib/disp' --[!inline]

shutdown = require'reylib/shutdown' --[!inline]

focus = require'reylib/focus' --[!inline]

clockstart = require'reylib/clkstrt' --[!inline]

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

function cleanup()
	if focus_mode_save then
		focus:set_mode(focus_mode_save)
	end
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
	if log then
		log:close()
	end
end

function restore()
	-- record that script was interrupted
	if log then
		log:log_desc('interrupted')
		log:write()
	end
	cleanup()
end

function log_preshoot_values()
	local dof=get_dofinfo()
	log:log_desc('sd:%d af_ok:%s fl:%d efl:%d zoom_pos:%d',
			dof.focus,tostring(get_focus_ok()),dof.focal_length,dof.eff_focal_length,get_zoom())
	-- these shouldn't change, only log initial values
	log:log_desc('sv96:%d tv96:%d av96:%d',get_prop(props.SV), get_prop(props.TV), get_prop(props.AV))
end

function run()
	disp:init{
		mode = string.lower(ui_display_mode_t.value)
	}
	log = xsvlog.new{
		name="A/fixedint.csv",
		append=(ui_log_mode.value=='Append'),
		dummy=(ui_log_mode.value=='None'),
		-- PTP logging options, set assumed to be set externally when running via PTP
		ptplog=ptplog,
		ptplog_key=ptplog_key,
		ptplog_timeout=ptplog_timeout,
		ptplog_drop_on_timeout=ptplog_drop_on_timeout,
		ptplog_warn_print=ptplog_warn_print,
		-- column names
		cols={
			'date',
			'time',
			'exp',
			'start',
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

	init_shutter_procs()

	log:log_desc('fixedint v:%s',fixedint_version)

	local bi=get_buildinfo()
	log:log_desc("platform:%s-%s-%s-%s %s %s",
						bi.platform,bi.platsub,bi.build_number,bi.build_revision,
						bi.build_date,bi.build_time)
	log:log_desc('interval:%d shots:%d',interval,ui_shots)

	if ui_darks then
		log:log_desc('taking darks')
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
		focus_mode_save = focus:get_mode()
		focus:enable_override(ui_sd_mode_t.value)
		log:log_desc('uisd:%d pref:%s mode:%s',ui_sd,ui_sd_mode_t.value,focus:get_mode())
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
			log:log_desc('set canon_img_fmt:%d',canon_img_fmt)
		elseif canon_img_fmt > 1 then
			error('Firmware does not support Canon RAW')
		end
	else
		log:log_desc('canon_img_fmt:%d',get_canon_image_format())
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
		log:log_desc('cont_mode')
	end

	if rs_opts then
		log:log_desc('remoteshoot')
	end

	if ptplog then
		log:log_desc('ptplog')
	end

	if ui_shots == 0 then
		ui_shots = 100000000
	end

	-- set initial display state
	disp:update()

	if not clockstart.ts_start then
		log:log_desc('start_delay:%d',ui_start_delay)
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
	local user_exit
	for shot=1,ui_shots do
		print("shot ",shot,"/",ui_shots)
		log:set{
			start=get_tick_count(),
			date=os.date('%m/%d/%Y'),
			time=os.date('%H:%M:%S'),
		}

		-- poll / reset click state
		-- camera will generally take while to be ready for next shot, so extra wait here shouldn't hurt
		wait_click(10)
		if is_key('menu') then
			user_exit = true
		end
		if read_usb_msg() == 'quit' then
			log:log_desc('ptp quit')
			user_exit = true
		end
		if user_exit then
			-- prevent shutdown on finish if user abort
			shutdown.opts.finish = false
			log:log_desc('user exit')
			log:write()
			break
		end
		if shutdown:check() then
			log:log_desc('shutdown:%s',shutdown:reason())
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
cleanup()
shutdown:finish()
