--[[
  Copyright (C) 2021 <reyalp (at) gmail dot com>
  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License version 2 as
  published by the Free Software Foundation.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  with this program. If not, see <http://www.gnu.org/licenses/>.
]]


--[[
camera side file to test csvlog lib
chdkptp script expected to prepend with assigned opt values or leave nil for defaults
]]
local csvlog=require'reylib/csvlog' --[!inline]

local row_num=0
log = csvlog.new{
	name=opt_name,
	append=opt_append,
    dummy=opt_dummy,
	quote_mode=opt_quote_mode,
	buffer_mode=opt_buffer_mode,
	delim=opt_delim,
	-- column names
	cols={
		'func1',
		'test_1',
		'test_2',
		'desc',
	},
	-- columns automatically set at write time from functions
	funcs={
		func1=function()
			row_num = row_num + 1
			return row_num
		end,
	},
	-- columns collected in a table, concatenated at write time
	tables={
		desc=' / ',
	},
}
local logdesc=log:text_logger('desc')
local bi=get_buildinfo()
logdesc("this is the first data row")
log:write()
log:set{test_1=1,test_2='two'}
logdesc("this is the second data row, it has a comma")
logdesc("and a second item")
log:write()
log:set{test_1='hello, world',test_2='goodbye "world"'}
log:write()
log:set{test_1='new\nline',test_2=' boring '}
log:write()
log:close()
