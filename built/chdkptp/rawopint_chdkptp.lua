--[[
chdkptp "glue" script to use rawopint.lua with remoteshoot
This file must be on the host PC running chdkptp, NOT on the camera
from chdkptp, use like
 rs -script=rawopint_chdkptp.lua -cont=100 -int=5
The following remoteshoot options are mapped to corresponding
script options and override any settings in the glue section if used
-shots (or number specified with -cont or -quick): ui_shots
-int: ui_interval_s10
-quick: forces ui_use_cont false
-sd, -sdmode: ui_sd, ui_sd_mode_t
-jpg, -craw, -raw, -dng: ui_use_raw_e, ui_canon_img_fmt
Other remoteshoot options for camera side values (exposure etc) are ignored
Edit the values below to change other settings
This script can also be used to run rawopint from chdkptp without remoteshoot,
like
 lua <rawopint_chdkptp.lua
In this case, shots and interval must be set in the glue section
Note:
rawop histogram and meter may interfere with USB communication if they run too long
]]
-- BEGIN menu glue
-- @title raw meter intervalometer
-- @chdk_version 1.5.1
-- #ui_shots=0 "Shots (0 = unlimited)"
ui_shots=0
-- #ui_interval_s10=20 "Interval Sec/10"
ui_interval_s10=20
-- #ui_use_remote=false "USB remote interval control"
ui_use_remote=false
-- #ui_meter_width_pct=90 "Meter width %" [1 100]
ui_meter_width_pct=90
-- #ui_meter_height_pct=90 "Meter height %" [1 100]
ui_meter_height_pct=90
-- #ui_meter_left_pct=-1 "Meter left % (-1 center)" [-1 99]
ui_meter_left_pct=-1
-- #ui_meter_top_pct=-1 "Meter top % (-1 center)" [-1 99]
ui_meter_top_pct=-1
-- #ui_meter_step=15 "Meter step"
ui_meter_step=15
-- #ui_max_ev_change_e=3 "Max Ev change" {1/16 1/8 1/4 1/3 1/2 1}
ui_max_ev_change_e=3
-- #ui_smooth_factor=5 "Ev chg smooth factor/10"[0 9]
ui_smooth_factor=5
-- #ui_smooth_limit_frac=7 "Ev chg smooth limit frac/10" [0 10]
ui_smooth_limit_frac=7
-- #ui_ev_chg_rev_limit_frac=5 "Ev chg reverse limit frac/10" [0 10]
ui_ev_chg_rev_limit_frac=5
-- #ui_ev_use_initial=false "Use initial Ev as target"
ui_ev_use_initial=false
-- #ui_ev_shift_e=10 "Ev shift" {-2.1/2 -2.1/4 -2 -1.3/4  -1.1/2 -1.1/4 -1 -3/4 -1/2 -1/4 0 1/4 1/2 3/4 1 1.1/4 1.1/2 1.3/4 2 2.1/4 2.1/2}
ui_ev_shift_e=10
-- #ui_bv_ev_shift_pct=0 "Bv Ev shift %" [0 100]
ui_bv_ev_shift_pct=0
-- #ui_bv_ev_shift_base_e=0 "Bv Ev shift base Bv" {First -1 -1/2 0 1/2 1 1.1/2 2 2.1/2 3 3.1/2 4 4.1/2 5 5.1/2 6 6.1/2 7 7.1/2 8 8.1/2 9 9.1/2 10 10.1/2 11 11.1/2 12 12.1/2 13}
ui_bv_ev_shift_base_e=0
-- #ui_tv_max_s1k=1000 "Max Tv Sec/1000"
ui_tv_max_s1k=1000
-- #ui_tv_min_s100k=10 "Min Tv Sec/100K" [1 99999]
ui_tv_min_s100k=10
-- #ui_sv_target_mkt=80 "Target ISO"
ui_sv_target_mkt=80
-- #ui_tv_sv_adj_s1k=250 "ISO adj Tv Sec/1000"
ui_tv_sv_adj_s1k=250
-- #ui_sv_max_mkt=800 "Max ISO"
ui_sv_max_mkt=800
-- #ui_tv_nd_thresh_s10k=1 "ND Tv Sec/10000"
ui_tv_nd_thresh_s10k=1
-- #ui_nd_hysteresis_e=2 "ND hysteresis Ev" {none 1/4 1/2 3/4 1}
ui_nd_hysteresis_e=2
-- #ui_nd_value=0 "ND value APEX*96 (0=firmware)" [0 1000]
ui_nd_value=0
-- #ui_meter_high_thresh_e=2 "Meter high thresh Ev" {1/2 3/4 1 1.1/4 1.1/2 1.3/4}
ui_meter_high_thresh_e=2
-- #ui_meter_high_limit_e=3 "Meter high limit Ev" {1 1.1/4 1.1/2 1.3/4 2 2.1/4}
ui_meter_high_limit_e=3
-- #ui_meter_high_limit_weight=200 "Meter high max weight" [100 300]
ui_meter_high_limit_weight=200
-- #ui_meter_low_thresh_e=5 "Meter low thresh -Ev" {1/2 3/4 1 1.1/4 1.1/2 1.3/4 2 2.1/4 2.1/2 2.3/4 3 3.1/4 3.1/2 3.3/4 4 4.1/4 4.1/2 4.3/4 5}
ui_meter_low_thresh_e=5
-- #ui_meter_low_limit_e=7 "Meter low limit -Ev" {1 1.1/4 1.1/2 1.3/4 2 2.1/4 2.1/2 2.3/4 3 3.1/4 3.1/2 3.3/4 4 4.1/4 4.1/2 4.3/4 5 5.1/4 5.1/2 5.3/4 6}
ui_meter_low_limit_e=7
-- #ui_meter_low_limit_weight=200 "Meter low max weight" [100 300]
ui_meter_low_limit_weight=200
-- #ui_exp_over_thresh_frac=3000 "Overexp thresh x/100k (0=Off)" long
ui_exp_over_thresh_frac=3000
-- #ui_exp_over_margin_e=3 "Overexp Ev range" {1/32 1/16 1/8 1/4 1/3 1/2 2/3 3/4 1}
ui_exp_over_margin_e=3
-- #ui_exp_over_weight_max=200 "Overexp max weight" [100 300]
ui_exp_over_weight_max=200
-- #ui_exp_over_prio=0 "Overexp prio" [0 200]
ui_exp_over_prio=0
-- #ui_exp_under_thresh_frac=10000 "Underexp thresh x/100k (0=Off)" long
ui_exp_under_thresh_frac=10000
-- #ui_exp_under_margin_e=5 "Underexp -Ev" {7 6 5.1/2 5 4.1/2 4 3.1/2 3 2.1/2 2}
ui_exp_under_margin_e=5
-- #ui_exp_under_weight_max=200 "Underexp max weight" [100 300]
ui_exp_under_weight_max=200
-- #ui_exp_under_prio=0 "Underexp prio" [0 200]
ui_exp_under_prio=0
-- #ui_histo_step_t=5 "Histogram step (pixels)" {5 7 9 11 15 19 23 27 31} table
ui_histo_step_t={
 index=5,
 value="15"
}
-- #ui_zoom_mode_t=1 "Zoom mode" {Off Pct Step} table
ui_zoom_mode_t={
 index=1,
 value="Off"
}
-- #ui_zoom=0 "Zoom value" [0 500]
ui_zoom=0
-- #ui_sd_mode_t=1 "Focus override mode" {Off MF AFL AF} table
ui_sd_mode_t={
 index=1,
 value="Off"
}
-- #ui_sd=0 "Focus dist (mm)" long
ui_sd=0
-- #ui_image_size_e=0 "Image size" {Default L M1 M2 M3 S W}
ui_image_size_e=0
-- #ui_use_raw_e=0 "Use CHDK raw" {Default Yes No}
ui_use_raw_e=0
-- #ui_canon_img_fmt=0 "Canon image format" {Default JPG RAW RAW+JPG}
ui_canon_img_fmt=0
-- #ui_use_cont=true "Use cont. mode if set"
ui_use_cont=true
-- #ui_start_hour=-1 "Start hour (-1 off)" [-1 23]
ui_start_hour=-1
-- #ui_start_min=0 "Start minute" [0 59]
ui_start_min=0
-- #ui_start_sec=0 "Start second" [0 59]
ui_start_sec=0
-- #ui_display_mode_t=1 "Display" {On Off Blt_Off} table
ui_display_mode_t={
 index=1,
 value="On"
}
-- #ui_shutdown_finish=false "Shutdown on finish"
ui_shutdown_finish=false
-- #ui_shutdown_lowbat=true "Shutdown on low battery"
ui_shutdown_lowbat=true
-- #ui_shutdown_lowspace=true "Shutdown on low space"
ui_shutdown_lowspace=true
-- #ui_interval_warn_led=-1 "Interval warn LED (-1=off)"
ui_interval_warn_led=-1
-- #ui_interval_warn_beep=false "Interval warn beep"
ui_interval_warn_beep=false
-- #ui_do_draw=false "Draw debug info"
ui_do_draw=false
-- #ui_draw_meter_t=1 " Meter area" {None Corners Box} table
ui_draw_meter_t={
 index=1,
 value="None"
}
-- #ui_draw_gauge_y_pct=0 " Gauge Y offset %" [0 94]
ui_draw_gauge_y_pct=0
-- #ui_log_mode=2 "Log mode" {None Append Replace} table
ui_log_mode={
 index=2,
 value="Append"
}
-- #ui_raw_hook_sleep=0 "Raw hook sleep ms (0=off)" [0 100]
ui_raw_hook_sleep=0
-- #ui_noyield=false "Disable script yield"
ui_noyield=false
-- END menu glue
-- if invoked from remoteshoot, override menu options from remoteshoot
-- options where required or reasonable mappings exist
if rs_opts then
	ui_shots=rs_opts.shots
	-- use config default if not set in remoteshoot opts
	if rs_opts.int then
		ui_interval_s10=rs_opts.int/100
	end
	-- if -quick used, override cont off
	if rs_opts.quick then
		ui_use_cont=false
	end
	-- image format must match what remoteshoot expects, override to "Default"
	-- required for canon formats, not strictly required for CHDK raw
	ui_use_raw_e=0
	ui_canon_img_fmt=0
	-- pass through SD and sd mode
	if rs_opts.sd then
		ui_sd=rs_opts.sd
		if rs_opts.sdprefmode then
			ui_sd_mode_t.value = rs_opts.sdprefmode
		else
		-- in remoteshoot, prefmode may be unspecified, but rawop requires
		-- default to MF, focus lib will pick a different mode if not supported
			ui_sd_mode_t.value = 'MF'
		end
		-- index isn't current used, but try to make it consistent
		ui_sd_mode_t.index = ({MF=2,AFL=3,AF=4})[ui_sd_mode_t.value]
	end
end
-- BEGIN glued script
loadfile("A/CHDK/SCRIPTS/rawopint.lua")()
-- END glued script
