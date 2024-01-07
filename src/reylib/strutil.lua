--[[
License: GPL

Copyright 2021-2024 reyalp (at) gmail.com

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

--[!inline:module_start]
-- General string utilities. Author: reyalp (at) gmail.com. License: GPL.
-- Source: https://github.com/reyalpchdk/chdkscripts
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
