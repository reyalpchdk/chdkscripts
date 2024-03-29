--[[
This is a template to generate glue scripts. Everything below --[!glue:start]
is copied to the template. See chdkptp lua/chdkscripthdr.lua for details
]]
--[!glue:start]
--[[
chdkptp "glue" script to use fixedint.lua with remoteshoot

This file must be on the host PC running chdkptp, NOT on the camera
The fixedint.lua script must be on the camera SD card, in CHDK/SCRIPTS

from chdkptp, use like
 rs -script=fixedint_chdkptp.lua -cont=100 -int=5

The following remoteshoot options are mapped to corresponding
script options and override any settings in the glue section if used
-shots (or number specified with -cont or -quick): ui_shots
-int: ui_interval_s10
-quick: forces ui_use_cont false
-sd, -sdmode: ui_sd, ui_sd_mode_t
-jpg, -craw, -raw, -dng: ui_use_raw_e, ui_canon_img_fmt

Other remoteshoot options for camera side values (exposure etc) are ignored

Edit the values below to change other settings

This script can also be used to run fixedint from chdkptp without remoteshoot,
like
 lua <fixedint_chdkptp.lua

]]

--[!glue:vars]

-- override shots and interval using remoteshoot opts
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
	-- pass through SD and SD mode
	if rs_opts.sd then
		ui_sd=rs_opts.sd
		if rs_opts.sdprefmode then
			ui_sd_mode_t.value = rs_opts.sdprefmode
		else
		-- in remoteshoot, prefmode may be unspecified, but rawop requires
		-- default to MF, focus lib will pick a different mode if not supported
			ui_sd_mode_t.value = 'MF'
		end
		-- index isn't currently used, but try to make it consistent
		ui_sd_mode_t.index = ({MF=2,AFL=3,AF=4})[ui_sd_mode_t.value]
	end
end

--[!glue:body]
