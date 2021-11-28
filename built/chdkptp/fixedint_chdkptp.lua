--[[
chdkptp "glue" script to use fixedint.lua with remoteshoot

This file must be on the host PC running chdkptp, NOT on the camera

from chdkptp, use like
 rs -script=fixedint_chdkptp.lua -cont=100 -int=5

The following remoteshoot options are mapped to corresponding
script options and override any settings in the glue section if used
-shots: ui_shots
-int: ui_interval_s10
-cont: ui_use_cont
-sd, -sdmode: ui_sd, ui_sd_mode_t
-jpg, -craw, -raw, -dng: ui_use_raw_e, ui_canon_img_fmt

Other remoteshoot options for camera side values (exposure etc) are ignored

Edit the values below to change other settings

This script can also be used to run fixedint from chdkptp without remoteshoot,
like
 lua <fixedint_chdkptp.lua

]]

-- @title fixed exposure intervalometer
-- @chdk_version 1.5.1
-- #ui_shots=1 "Shots (0=unlimited)"
ui_shots=1
-- #ui_interval_s10=0 "Interval Sec/10 (0=max)"
ui_interval_s10=0
-- #ui_use_raw_e=1 "Use CHDK raw" {Default Yes No}
ui_use_raw_e=1
-- #ui_canon_img_fmt=0 "Canon image format" {Default JPG RAW RAW+JPG}
ui_canon_img_fmt=0
-- #ui_disable_dfs=true "Disable Canon Dark Frame"
ui_disable_dfs=true
-- #ui_tv_e=3 "Tv" {0 256 128 64 32 16 8 4 2 1 1/2 1/4 1/8 1/16 1/32 1/64}
ui_tv_e=3
-- #ui_tv_s=0 "Tv + sec" [0 2000]
ui_tv_s=0
-- #ui_tv_s10000=0 "Tv + sec/10000" [0 10000]
ui_tv_s10000=0
-- #ui_start_delay=300 "Start delay (ms)"
ui_start_delay=300
-- #ui_start_hour=-1 "Start hour (-1 off)" [-1 23]
ui_start_hour=-1
-- #ui_start_min=0 "Start minute" [0 59]
ui_start_min=0
-- #ui_start_sec=0 "Start second" [0 59]
ui_start_sec=0
-- #ui_iso=0 "ISO (by CHDK, 0=not set)"
ui_iso=0
-- #ui_iso_mode_e=0 "ISO (by ISO mode)" {No 80 100 200 400 800 1600}
ui_iso_mode_e=0
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
-- #ui_use_cont=true "Use cont. mode if set"
ui_use_cont=true
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
-- #ui_darks=false "Make dark frames"
ui_darks=false
-- #ui_log_mode=2 "Log mode" {None Append Replace} table
ui_log_mode={
 index=2,
 value="Append"
}


-- override shots and interval using remoteshoot opts
if rs_opts then
	ui_shots=rs_opts.shots
	-- use config default if not set in remoteshoot opts
	if rs_opts.int then
		ui_interval_s10=rs_opts.int/100
	end
	-- for convenience, respect -cont
	ui_use_cont=rs_opts.cont
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

loadfile("A/CHDK/SCRIPTS/fixedint.lua")()
