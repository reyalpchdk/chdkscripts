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

Other remoteshoot options for camera side values (exposure etc) are ignored

Edit the values below to change other settings

This script can also be used to run fixedint from chdkptp without remoteshoot,
like
 lua <fixedint_chdkptp.lua

]]

--[!glue]

-- override shots and interval using remoteshoot opts
if rs_opts then
	ui_shots=rs_opts.shots
	-- use config default if not set in remoteshoot opts
	if rs_opts.int then
		ui_interval_s10=rs_opts.int/100
	end
	-- for convenience, respect -cont
	ui_use_cont=rs_opts.cont
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
