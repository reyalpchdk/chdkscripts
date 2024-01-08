--[[
  Copyright (C) 2021 - 2024 <reyalp (at) gmail dot com>
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

NOTE: may require svn version of chdkptp
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

local function cleanup_remove_cam_csv(self,opts)
	if con:is_connected() and con:stat('A/logtest.csv') then
		cli:print_status(cli:execute('rm logtest.csv'))
	end
end

local function get_free_print_log_num()
	return con:execwait([[
local st = os.stat('A/CHDK/LOGS')
if not st then
	if not mkdir_m('A/CHDK/LOGS') then
		error('failed to create missing A/CHDK/LOGS')
	end
	return 1230
end
if not st.is_dir then
	error('A/CHDK/LOGS not a directory')
end
for i=1230, 1250 do
	local fn=('A/CHDK/LOGS/LOG_%4d.TXT'):format(i)
	if not os.stat(fn) then
		return i
	end
end
error('failed to find unused print log name')
]],{libs='mkdir_m'})
end

local function setup_get_free_print_log(self,opts)
	if not self._data then
		self._data = {}
	end
	self:ensure_connected(opts)
	self._data.prnlog_num = get_free_print_log_num()
	self._data.prnlog = ('A/CHDK/LOGS/LOG_%04d.txt'):format(self._data.prnlog_num)
end

local function cleanup_remove_print_log(self,opts)
	if con:is_connected() and self._data.prnlog then
		cli:print_status(cli:execute(('rm %s'):format(self._data.prnlog)))
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
		testlib.assert_eq(con:readfile('A/logtest.csv'),[[
test
]])
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_cam_csv,
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
	cleanup=cleanup_remove_cam_csv,
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
	cleanup=cleanup_remove_cam_csv,
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
		testlib.assert_eq(con:readfile('A/logtest.csv'),[[
func1,test_1,test_2,desc
1,,,this is the first data row
2,1,two,"this is the second data row, it has a comma / and a second item"
3,"hello, world","goodbye ""world""",
4,"new
line", boring ,
]])
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_cam_csv,
},
{
	'quote_always',
	function()
		con:execwait([[
opt_name='A/logtest.csv'
opt_append=false
opt_quote_mode='always'
]]..cam_script)
		testlib.assert_eq(con:readfile('A/logtest.csv'),[[
"func1","test_1","test_2","desc"
"1","","","this is the first data row"
"2","1","two","this is the second data row, it has a comma / and a second item"
"3","hello, world","goodbye ""world""",""
"4","new
line"," boring ",""
]])
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_cam_csv,
},
{
	'quote_never',
	function()
		con:execwait([[
opt_name='A/logtest.csv'
opt_append=false
opt_quote_mode='never'
]]..cam_script)
		testlib.assert_eq(con:readfile('A/logtest.csv'),[[
func1,test_1,test_2,desc
1,,,this is the first data row
2,1,two,this is the second data row, it has a comma / and a second item
3,hello, world,goodbye "world",
4,new
line, boring ,
]])
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_cam_csv,
},
{
	'tsv',
	function()
		con:execwait([[
opt_name='A/logtest.csv'
opt_append=false
opt_delim='\t'
]]..cam_script)
		testlib.assert_eq(con:readfile('A/logtest.csv'),
'func1\ttest_1\ttest_2\tdesc\n'..
'1\t\t\tthis is the first data row\n'..
'2\t1\ttwo\tthis is the second data row, it has a comma / and a second item\n'..
'3\thello, world\t"goodbye ""world"""\t\n'..
'4\t"new\n'..
'line"\t boring \t\n'
)
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_cam_csv,
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
		testlib.assert_eq(con:readfile('A/logtest.csv'),[[
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
		testlib.assert_eq(con:readfile('A/logtest.csv'),[[
col1,col2
one,2
col1,col2
true,four
]])
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_cam_csv,
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
		testlib.assert_eq(con:readfile('A/logtest.csv'),[[
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
		testlib.assert_eq(con:readfile('A/logtest.csv'),[[
col1,col2
three,four
]])
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_cam_csv,
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
		testlib.assert_eq(con:readfile('A/logtest.csv'),[[
start,t1,t2
1010,10,20
]])
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_cam_csv,
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
		testlib.assert_eq(con:readfile('A/logtest.csv'),[[
start,t1,t2
]])
	end,
	setup=testlib.setup_ensure_connected,
	cleanup=cleanup_remove_cam_csv,
},
{
	'ptplog', {
	{
		'nofile',
		function()
			local msgs={}
			local handle_msg=chdku.msg_handler_value(msgs,{unserialize=true})
			con:execwait(cam_script_mini..[[
log=xsvlog.new{
	name='A/logtest.csv',
	nofile=true,
	ptplog=true,
	cols={
		'col1',
		'col2',
	},
}
log:set{col1='one',col2='two'}
log:write()
log:close()
]],{libs='serialize_msgs',msgs=handle_msg})
			testlib.assert_eq(con:stat('A/logtest.csv'),nil)
			testlib.assert_teq(msgs,{
				{xsvlog={'col1','col2'}},
				{xsvlog={'one','two'}}
			})
		end,
		setup=function(self,opts)
			self:ensure_connected(opts)
			if con:stat('A/logtest.csv') then
				if not cli:print_status(cli:execute('rm logtest.csv')) then
					return false
				end
			end
		end,
	},
	{
		'file',
		function()
			local msgs={}
			local handle_msg=chdku.msg_handler_value(msgs,{unserialize=true})
			con:execwait(cam_script_mini..[[
log=xsvlog.new{
	name='A/logtest.csv',
	ptplog='string',
	ptplog_key='boo',
	cols={
		'col1',
		'col2',
	},
}
log:set{col1='one',col2='two, and more'}
log:write()
log:close()
]],{libs='serialize_msgs',msgs=handle_msg})
			testlib.assert_eq(con:readfile('A/logtest.csv'),[[
col1,col2
one,"two, and more"
]])

			testlib.assert_teq(msgs,{
				{boo='col1,col2'},
				{boo='one,"two, and more"'}
			})
		end,
		setup=testlib.setup_ensure_connected,
		cleanup=cleanup_remove_cam_csv,
	},
	{
		'nokey_str',
		function()
			local msgs={}
			local handle_msg=chdku.msg_handler_value(msgs,{unserialize=true})
			con:execwait(cam_script_mini..[[
log=xsvlog.new{
	name='A/logtest.csv',
	nofile=true,
	ptplog='string',
	ptplog_key=false,
	cols={
		'col1',
		'col2',
	},
}
log:set{col1='one',col2='two, and more'}
log:write()
log:close()
]],{libs='serialize_msgs',msgs=handle_msg})
			testlib.assert_teq(msgs,{
				'col1,col2',
				'one,"two, and more"',
			})
		end,
		setup=testlib.setup_ensure_connected,
	},
	{
		'nokey_table',
		function()
			local msgs={}
			local handle_msg=chdku.msg_handler_value(msgs,{unserialize=true})
			con:execwait(cam_script_mini..[[
log=xsvlog.new{
	nofile=true,
	ptplog='table',
	ptplog_key=false,
	cols={
		'col1',
		'col2',
	},
}
log:set{col1='one',col2='two, and more'}
log:write()
log:close()
]],{libs='serialize_msgs',msgs=handle_msg})
			testlib.assert_teq(msgs,{
				{'col1','col2'},
				{'one','"two, and more"'},
			})
		end,
		setup=testlib.setup_ensure_connected,
	},
	{
		'timeout1', -- check default timeout behavior
		function(self)
			local msgs={}
			local handle_msg=chdku.msg_handler_value(msgs,{unserialize=true})
			con:exec(([[
%s
print_screen(%d)
log=xsvlog.new{
	name='A/logtest.csv',
	ptplog='table',
	ptplog_key=false,
	cols={
		'it',
	},
}
for i=1,17 do
	log:set{it=i}
	log:write()
end
log:close()
]]):format(cam_script_mini,self._data.prnlog_num),{libs='serialize_msgs'})
			con:wait_status{run=false}
			con:read_all_msgs{user=handle_msg}
			testlib.assert_teq(msgs,{
				{'it'},
				{'1'},
				{'2'},
				{'3'},
				{'4'},
				{'5'},
				{'6'},
				{'7'},
				{'8'},
				{'9'},
				{'10'},
				{'11'},
				{'12'},
				{'13'},
				{'14'},
			})
			testlib.assert_eq(con:readfile(self._data.prnlog),[[
msg queue full 15
msg timeout 15
]])
			testlib.assert_eq(con:readfile('A/logtest.csv'),[[
it
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
]])

		end,
		setup=setup_get_free_print_log,
		cleanup={
			cleanup_remove_print_log,
			cleanup_remove_cam_csv,
		},
	},
	{
		'timeout2', -- check handling if messages read after timeout
		function(self)
			local msgs={}
			local handle_msg=chdku.msg_handler_value(msgs,{unserialize=true})
			con:exec(([[
%s
print_screen(%d)
log=xsvlog.new{
	nofile=true,
	ptplog='table',
	ptplog_key=false,
	ptplog_timeout=500,
	cols={
		'it',
	},
}
for i=1,17 do
	log:set{it=i}
	log:write()
end
log:close()
]]):format(cam_script_mini,self._data.prnlog_num),{libs='serialize_msgs'})
			-- wait for queue to fill up
			chdku.sleep(200)
			-- read two messages, should get queue full but not timeout
			handle_msg(con:read_msg())
			handle_msg(con:read_msg())
			-- wait for script to finish, final message should get new queue full and timeout
			con:wait_status{run=false}
			con:read_all_msgs{user=handle_msg}
			testlib.assert_teq(msgs,{
				{'it'},
				{'1'},
				{'2'},
				{'3'},
				{'4'},
				{'5'},
				{'6'},
				{'7'},
				{'8'},
				{'9'},
				{'10'},
				{'11'},
				{'12'},
				{'13'},
				{'14'},
				{'15'},
				{'16'},
			})
			testlib.assert_eq(con:readfile(self._data.prnlog),[[
msg queue full 15
msg queue full 17
msg timeout 17
]])
		end,
		setup=setup_get_free_print_log,
		cleanup=cleanup_remove_print_log,
	},
	{
		'timeout3', -- check drop_on_timeout disabled
		function(self)
			local msgs={}
			local handle_msg=chdku.msg_handler_value(msgs,{unserialize=true})
			con:exec(([[
%s
print_screen(%d)
log=xsvlog.new{
	nofile=true,
	ptplog='table',
	ptplog_key=false,
	ptplog_timeout=100,
	ptplog_drop_on_timeout=false,
	cols={
		'it',
	},
}
for i=1,17 do
	log:set{it=i}
	log:write()
end
log:close()
]]):format(cam_script_mini,self._data.prnlog_num),{libs='serialize_msgs'})
			con:wait_status{run=false}
			con:read_all_msgs{user=handle_msg}
			testlib.assert_teq(msgs,{
				{'it'},
				{'1'},
				{'2'},
				{'3'},
				{'4'},
				{'5'},
				{'6'},
				{'7'},
				{'8'},
				{'9'},
				{'10'},
				{'11'},
				{'12'},
				{'13'},
				{'14'},
			})
			testlib.assert_eq(con:readfile(self._data.prnlog),[[
msg queue full 15
msg timeout 15
msg timeout 16
msg timeout 17
]])
		end,
		setup=setup_get_free_print_log,
		cleanup=cleanup_remove_print_log,
	},
	{
		'timeout4', -- check warn_print can be turned off
		function(self)
			local msgs={}
			local handle_msg=chdku.msg_handler_value(msgs,{unserialize=true})
			con:exec(([[
%s
print_screen(%d)
log=xsvlog.new{
	nofile=true,
	ptplog='table',
	ptplog_key=false,
	ptplog_timeout=50,
	ptplog_warn_print=false,
	cols={
		'it',
	},
}
for i=1,16 do
	log:set{it=i}
	log:write()
end
log:close()
]]):format(cam_script_mini,self._data.prnlog_num),{libs='serialize_msgs'})
			con:wait_status{run=false}
			con:read_all_msgs{user=handle_msg}
			testlib.assert_teq(msgs,{
				{'it'},
				{'1'},
				{'2'},
				{'3'},
				{'4'},
				{'5'},
				{'6'},
				{'7'},
				{'8'},
				{'9'},
				{'10'},
				{'11'},
				{'12'},
				{'13'},
				{'14'},
			})
			testlib.assert_eq(con:readfile(self._data.prnlog),'')
		end,
		setup=setup_get_free_print_log,
		cleanup=cleanup_remove_print_log,
	},
	{
		'bad_mode',
		function()
			testlib.assert_thrown(function()
				con:execwait(cam_script_mini..[[
log=xsvlog.new{
	nofile=true,
	ptplog='bogus',
	cols={
		'col1',
		'col2',
	},
}
]])
			end,{etype='exec_runtime',msg_match='invalid ptplog mode'})
		end,
	},
	{
		'bad_key',
		function()
			testlib.assert_thrown(function()
				con:execwait(cam_script_mini..[[
log=xsvlog.new{
	nofile=true,
	ptplog=true,
	ptplog_key={'what'},
	cols={
		'col1',
		'col2',
	},
}
]])
			end,{etype='exec_runtime',msg_match='invalid ptplog_key'})
		end,
	},
	{
		'bad_timeout',
		function()
			testlib.assert_thrown(function()
				con:execwait(cam_script_mini..[[
log=xsvlog.new{
	nofile=true,
	ptplog=true,
	ptplog_timeout='no',
	cols={
		'col1',
		'col2',
	},
}
]])
			end,{etype='exec_runtime',msg_match='invalid ptplog_timeout'})
		end,
	}},
}
}})

return tests
