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
chdkptp lua file to test xsvlog lib
run with
 chdkptp -e'exec require"xsvlogtest":do_test()'
or a single test like
 chdkptp -e'exec require"xsvlogtest":do_subtest("bad_init")'
]]
local inlinemods = require'extras/inlinemods'
local testlib = require'testlib'
local cam_script_name = 'xsvlogtest-cam.lua'
local cam_script = inlinemods.process_string(fsutil.readfile(cam_script_name),{
						modpath='../src',
						source_name=cam_script_name
					})

local cam_script_mini = inlinemods.process_string([[
local xsvlog=require'reylib/xsvlog' --[!inline]
]],{
						modpath='../src',
						source_name='cam_script_mini'
					})
local function cleanup_remove_local_csv(self,opts)
	if lfs.attributes('logtest.csv','mode') == 'file' and not opts.keep_files then
		os.remove('logtest.csv')
	end
end

local function cleanup_remove_both_csv(self,opts)
	if lfs.attributes('logtest.csv','mode') == 'file' and not opts.keep_files then
		os.remove('logtest.csv')
	end
	if con:is_connected() and con:stat('A/logtest.csv') then
		cli:print_status(cli:execute('rm logtest.csv'))
	end
end

local tests = testlib.new_test({
'xsvlog',{
{
	'bad_init',
	function()
		testlib.assert_thrown(function()
				con:execwait(cam_script_mini..[[
xsvlog.new()
]])
			end,{etype='exec_runtime',msg_match='missing opts'})
	end,
	setup=testlib.setup_ensure_connected,
},
{
	'bad_name',
	function()
		testlib.assert_thrown(function()
				con:execwait(cam_script_mini..[[
xsvlog.new{}
]])
			end,{etype='exec_runtime',msg_match='missing name'})
	end,
	setup=testlib.setup_ensure_connected,
},
{
	'bad_delim',
	function()
		testlib.assert_thrown(function()
				con:execwait(cam_script_mini..[[
xsvlog.new{
	name='A/logtest.csv',
	cols={
		'test',
	},
	delim='hi',
}
]])
			end,{etype='exec_runtime',msg_match='bad delimiter'})
	end,
	setup=testlib.setup_ensure_connected,
},
{
	'bad_cols',
	function()
		testlib.assert_thrown(function()
				con:execwait(cam_script_mini..[[
xsvlog.new{
	name='A/logtest.csv',
}
]])
			end,{etype='exec_runtime',msg_match='bad or empty cols'})
	end,
	setup=testlib.setup_ensure_connected,
},
{
	'bad_func',
	function()
		testlib.assert_thrown(function()
				con:execwait(cam_script_mini..[[
xsvlog.new{
	name='A/logtest.csv',
	cols={
		'test'
	},
	funcs={
		foo=function()
			return 'foo'
		end
	},
}
]])
			end,{etype='exec_runtime',msg_match='missing func col foo'})
	end,
	setup=testlib.setup_ensure_connected,
},
{
	'bad_table',
	function()
		testlib.assert_thrown(function()
				con:execwait(cam_script_mini..[[
xsvlog.new{
	name='A/logtest.csv',
	cols={
		'test'
	},
	tables={
		foo={' / '}
	},
}
]])
			end,{etype='exec_runtime',msg_match='missing table col foo'})
	end,
	setup=testlib.setup_ensure_connected,
},
{
	'bad_col',
	function()
		testlib.assert_thrown(function()
				con:execwait(cam_script_mini..[[
log=xsvlog.new{
	name='A/logtest.csv',
	cols={
		'test'
	},
}
log:set{foo='foo'}
]])
			end,{etype='exec_runtime',msg_match='unknown log col foo'})
		testlib.assert_cli_ok('d logtest.csv')
		local s=fsutil.readfile('logtest.csv')
		testlib.assert_eq(s,[[
test
]])
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_both_csv,
},
{
	'bad_textlogger1',
	function()
		testlib.assert_thrown(function()
				con:execwait(cam_script_mini..[[
log=xsvlog.new{
	name='A/logtest.csv',
	cols={
		'test'
	},
	text_loggers={
		'desc'
	}
}
]])
			end,{etype='exec_runtime',msg_match='invalid text_logger col desc'})
		testlib.assert_eq(con:stat('A/logtest.csv'),nil)
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_both_csv,
},
{
	'bad_textlogger2',
	function()
		testlib.assert_thrown(function()
				con:execwait(cam_script_mini..[[
log=xsvlog.new{
	name='A/logtest.csv',
	cols={
		'desc'
	},
	text_loggers={
		'desc',
		'desc'
	}
}
]])
			end,{etype='exec_runtime',msg_match='conflicting text_logger log_desc'})
		testlib.assert_eq(con:stat('A/logtest.csv'),nil)
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_both_csv,
},
{
	'quote_bad_mode',
	function()
		testlib.assert_thrown(function()
				con:execwait([[
opt_name='A/logtest.csv'
opt_append=false
opt_quote_mode='bogus'
]]..cam_script)
			end,{etype='exec_runtime',msg_match='invalid quote mode bogus'})
	end,
	setup=testlib.setup_ensure_connected,
},
{
	'buffer_bad_mode',
	function()
		testlib.assert_thrown(function()
				con:execwait([[
opt_name='A/logtest.csv'
opt_append=false
opt_buffer_mode='bogus'
]]..cam_script)
			end,{etype='exec_runtime',msg_match='invalid buffer mode bogus'})
	end,
	setup=testlib.setup_ensure_connected,
},
{
	'quote_default',
	function()
		con:execwait([[
opt_name='A/logtest.csv'
opt_append=false
]]..cam_script)
		testlib.assert_cli_ok('d logtest.csv')
		local s=fsutil.readfile('logtest.csv')
		testlib.assert_eq(s,[[
func1,test_1,test_2,desc
1,,,this is the first data row
2,1,two,"this is the second data row, it has a comma / and a second item"
3,"hello, world","goodbye ""world""",
4,"new
line", boring ,
]])
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_both_csv,
},
{
	'quote_always',
	function()
		con:execwait([[
opt_name='A/logtest.csv'
opt_append=false
opt_quote_mode='always'
]]..cam_script)
		testlib.assert_cli_ok('d logtest.csv')
		local s=fsutil.readfile('logtest.csv')
		testlib.assert_eq(s,[[
"func1","test_1","test_2","desc"
"1","","","this is the first data row"
"2","1","two","this is the second data row, it has a comma / and a second item"
"3","hello, world","goodbye ""world""",""
"4","new
line"," boring ",""
]])
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_both_csv,
},
{
	'quote_never',
	function()
		con:execwait([[
opt_name='A/logtest.csv'
opt_append=false
opt_quote_mode='never'
]]..cam_script)
		testlib.assert_cli_ok('d logtest.csv')
		local s=fsutil.readfile('logtest.csv')
		testlib.assert_eq(s,[[
func1,test_1,test_2,desc
1,,,this is the first data row
2,1,two,this is the second data row, it has a comma / and a second item
3,hello, world,goodbye "world",
4,new
line, boring ,
]])
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_both_csv,
},
{
	'tsv',
	function()
		con:execwait([[
opt_name='A/logtest.csv'
opt_append=false
opt_delim='\t'
]]..cam_script)
		testlib.assert_cli_ok('d logtest.csv')
		local s=fsutil.readfile('logtest.csv')
		testlib.assert_eq(s,
'func1\ttest_1\ttest_2\tdesc\n'..
'1\t\t\tthis is the first data row\n'..
'2\t1\ttwo\tthis is the second data row, it has a comma / and a second item\n'..
'3\thello, world\t"goodbye ""world"""\t\n'..
'4\t"new\n'..
'line"\t boring \t\n'
)
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_both_csv,
},
{
	'append',
	function()
		con:execwait(cam_script_mini..[[
log=xsvlog.new{
	name='A/logtest.csv',
	cols={
		'col1',
		'col2',
	},
}
log:set{col1='one',col2=2}
log:write()
log:close()
]])
		testlib.assert_cli_ok('d logtest.csv')
		local s=fsutil.readfile('logtest.csv')
		testlib.assert_eq(s,[[
col1,col2
one,2
]])
		con:execwait(cam_script_mini..[[
log=xsvlog.new{
	name='A/logtest.csv',
	append=true,
	cols={
		'col1',
		'col2',
	},
}
log:set{col1=true,col2='four'}
log:write()
log:close()
]])
		testlib.assert_cli_ok('d logtest.csv')
		s=fsutil.readfile('logtest.csv')
		testlib.assert_eq(s,[[
col1,col2
one,2
col1,col2
true,four
]])
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_both_csv,
},
{
	'overwrite',
	function()
		con:execwait(cam_script_mini..[[
log=xsvlog.new{
	name='A/logtest.csv',
	cols={
		'col1',
		'col2',
	},
}
log:set{col1='one',col2='two'}
log:write()
log:close()
]])
		testlib.assert_cli_ok('d logtest.csv')
		local s=fsutil.readfile('logtest.csv')
		testlib.assert_eq(s,[[
col1,col2
one,two
]])
		con:execwait(cam_script_mini..[[
log=xsvlog.new{
	name='A/logtest.csv',
	cols={
		'col1',
		'col2',
	},
}
log:set{col1='three',col2='four'}
log:write()
log:close()
]])
		testlib.assert_cli_ok('d logtest.csv')
		s=fsutil.readfile('logtest.csv')
		testlib.assert_eq(s,[[
col1,col2
three,four
]])
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_both_csv,
},
{
	'dtlogger',
	function()
		con:execwait(cam_script_mini..[[
-- override get_tick_count so values are predictable
local fake_tick = 1000
function get_tick_count()
	fake_tick = fake_tick + 10
	return fake_tick
end

log=xsvlog.new{
	name='A/logtest.csv',
	cols={
		'start',
		't1',
		't2',
	},
	dt_loggers={
		'start',
	},
}
log:set{start=get_tick_count()}
log:dt_start('t1')
log:dt_start('t2')
log:write()
log:close()
]])
		testlib.assert_cli_ok('d logtest.csv')
		local s=fsutil.readfile('logtest.csv')
		testlib.assert_eq(s,[[
start,t1,t2
1010,10,20
]])
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_both_csv,
},
{
	'bad_dtlogger1',
	function()
		testlib.assert_thrown(function()
				con:execwait(cam_script_mini..[[
log=xsvlog.new{
	name='A/logtest.csv',
	cols={
		'start',
		't1',
		't2',
	},
	dt_loggers={
		'startle',
	},
}
]])
			end,{etype='exec_runtime',msg_match='invalid dt_logger base col startle'})
	end,
	setup=testlib.setup_ensure_connected,
},
{
	'bad_dtlogger2',
	function()
		testlib.assert_thrown(function()
				con:execwait(cam_script_mini..[[
log=xsvlog.new{
	name='A/logtest.csv',
	cols={
		'start',
		't1',
		't2',
	},
	dt_loggers={
		'start',
		'start',
	},
}
]])
			end,{etype='exec_runtime',msg_match='conflicting dt_logger dt_start'})
	end,
	setup=testlib.setup_ensure_connected,
},
{
	'bad_dtlogger3',
	function()
		testlib.assert_thrown(function()
				con:execwait(cam_script_mini..[[
-- override get_tick_count so values are predictable
local fake_tick = 1000
function get_tick_count()
	fake_tick = fake_tick + 10
	return fake_tick
end

log=xsvlog.new{
	name='A/logtest.csv',
	cols={
		'start',
		't1',
		't2',
	},
	dt_loggers={
		'start',
	},
}
log:set{start=get_tick_count()}
log:dt_start('bad')
log:dt_start('t2')
log:write()
log:close()
]])
			end,{etype='exec_runtime',msg_match='invalid dt_logger col name bad'})
		testlib.assert_cli_ok('d logtest.csv')
		local s=fsutil.readfile('logtest.csv')
		testlib.assert_eq(s,[[
start,t1,t2
]])
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_both_csv,
},
}})

return tests
