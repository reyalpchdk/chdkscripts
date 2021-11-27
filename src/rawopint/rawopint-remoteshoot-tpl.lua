--[[
chdkptp "glue" script to use rawopint.lua with remoteshoot

This file must be on the host PC running chdkptp, NOT on the camera

remoteshoot -shots and -int options automatically set the corresponding
rawopint.lua options ui_shots and ui_interval_s10

from chdkptp, use like
rs -script=rawopint_chdkptp.lua -shots=100 -int=5

remoteshoot file format selection with -jpg, -raw works as normal

Other remote shoot options are ignored

Edit the values below to change other settings

Note:
rawop histogram and meter may interfere with USB communication if they run too long
]]

--[!glue]

-- override shots and interval using remoteshoot opts
if rs_opts then
	ui_shots=rs_opts.shots
	-- use config default if not set in remoteshoot opts
	if rs_opts.int then
		ui_interval_s10=rs_opts.int/100
	end
end

loadfile("A/CHDK/SCRIPTS/rawopint.lua")()
