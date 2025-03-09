--[[
@title continuous auto exposure
@chdk_version 1.5.1
#ui_meter_width_pct=60 "Meter width %" [1 100]
#ui_meter_height_pct=60 "Meter height %" [1 100]
#ui_meter_left_pct=-1 "Meter left % (-1 center)" [-1 99]
#ui_meter_top_pct=-1 "Meter top % (-1 center)" [-1 99]
#ui_meter_step=13 "Meter step"
#ui_max_ev_change_e=5 "Max Ev change" {1/4 1/3 1/2 2/3 3/4 1 1.1/4 1.1/3 1.1/2 1.2/3 1.3/4 2}
#ui_smooth_factor=0 "Ev chg smooth factor/10"[0 9]
#ui_smooth_limit_frac=7 "Ev chg smooth limit frac/10" [0 10]
#ui_ev_chg_rev_limit_frac=0 "Ev chg reverse limit frac/10" [0 10]
#ui_ev_use_initial=false "Use initial Ev as target"
#ui_ev_shift_e=10 "Ev shift" {-2.1/2 -2.1/4 -2 -1.3/4  -1.1/2 -1.1/4 -1 -3/4 -1/2 -1/4 0 1/4 1/2 3/4 1 1.1/4 1.1/2 1.3/4 2 2.1/4 2.1/2}
#ui_tv_max_s1k=1000 "Max Tv Sec/1000"
#ui_tv_min_s100k=10 "Min Tv Sec/100K" [1 99999]
#ui_sv_target_mkt=80 "Target ISO"
#ui_tv_sv_adj_s1k=25 "ISO adj Tv Sec/1000"
#ui_sv_max_mkt=800 "Max ISO"
#ui_tv_nd_thresh_s10k=1 "ND Tv Sec/10000"
#ui_nd_hysteresis_e=2 "ND hysteresis Ev" {none 1/4 1/2 3/4 1}
#ui_nd_value=0 "ND value APEX*96 (0=firmware)" [0 1000]
#ui_meter_high_thresh_e=2 "Meter high thresh Ev" {1/2 3/4 1 1.1/4 1.1/2 1.3/4}
#ui_meter_high_limit_e=3 "Meter high limit Ev" {1 1.1/4 1.1/2 1.3/4 2 2.1/4}
#ui_meter_high_limit_weight=200 "Meter high max weight" [100 300]
#ui_meter_low_thresh_e=5 "Meter low thresh -Ev" {1/2 3/4 1 1.1/4 1.1/2 1.3/4 2 2.1/4 2.1/2 2.3/4 3}
#ui_meter_low_limit_e=7 "Meter low limit -Ev" {1 1.1/4 1.1/2 1.3/4 2 2.1/4 2.1/2 2.3/4 3 3.1/4 3.1/2 3.3/4 4}
#ui_meter_low_limit_weight=200 "Meter low max weight" [100 300]
#ui_exp_over_thresh_frac=3000 "Overexp thresh x/100k (0=Off)" long
#ui_exp_over_margin_e=3 "Overexp Ev range" {1/32 1/16 1/8 1/4 1/3 1/2 2/3 3/4 1}
#ui_exp_over_weight_max=200 "Overexp max weight" [100 300]
#ui_exp_over_prio=0 "Overexp prio" [0 200]
#ui_exp_under_thresh_frac=10000 "Underexp thresh x/100k (0=Off)" long
#ui_exp_under_margin_e=5 "Underexp -Ev" {7 6 5.1/2 5 4.1/2 4 3.1/2 3 2.1/2 2}
#ui_exp_under_weight_max=200 "Underexp max weight" [100 300]
#ui_exp_under_prio=0 "Underexp prio" [0 200]
#ui_histo_step_t=5 "Histogram step (pixels)" {5 7 9 11 15 19 23 27 31} table
#ui_do_draw=false "Draw debug info"
#ui_draw_meter_t=1 " Meter area" {None Corners Box} table
#ui_draw_gauge_y_pct=0 " Gauge Y offset %" [0 94]
#ui_log_mode=2 "Log mode" {None Append Replace} table
#ui_raw_hook_sleep=0 "Raw hook sleep ms (0=off)" [0 100]

License: GPL

Copyright 2014-2025 reyalp (at) gmail.com

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
contae_version="0.13"

require'hookutil'
require'rawoplib'
props=require'propcase'

xsvlog=(function() -- inline reylib/xsvlog
-- CSV/TSV/*SV log module. Author: reyalp (at) gmail.com. License: GPL.
-- Source: https://github.com/reyalpchdk/chdkscripts
local xsvlog={}
local log_methods={}

-- 'cols' can be either a simple array of names, or include sub-arrays
-- to allow modules to export their own list of columns
local function unpack_cols(cols_init, cols, depth)
	if not depth then
		depth=0
	elseif depth > 10 then
		error('too many nested column specs')
	end
	if not cols then
		cols = {}
	end
	for i,v in ipairs(cols_init) do
		if type(v) == 'table' then
			unpack_cols(v,cols,depth+1)
		elseif type(v) == 'string' then
			table.insert(cols,v)
		else
			error('invalid column spec '..type(v))
		end
	end
	return cols
end

function log_methods:init(opts)
	if not opts then
		error('missing opts')
	end
	if not opts.name and not opts.nofile then
		error('missing name')
	end
	if type(opts.cols) ~= 'table' or #opts.cols < 1 then
		error('bad or empty cols')
	end
	self.delim = opts.delim or ','
	if self.delim:match('["\r\n]') or self.delim:len() ~= 1 then
		error('bad delimiter')
	end
	if self.delim:match('[%a%d]') then
		self.delim_pat = self.delim
	else
		self.delim_pat = '%'..self.delim
	end

	self.cols=unpack_cols(opts.cols)
	self.vals={}
	self.funcs={}
	self.tables={}
	self.write_count=0
	if opts.funcs then
		for n,f in pairs(opts.funcs) do
			if type(f) ~= 'function' then
				error('expected function')
			end
			self.funcs[n] = f
		end
	end
	self.name = opts.name
	-- nofile previously called dummy before ptp support
	self.nofile = opts.nofile or opts.dummy
	self.buffer_mode = opts.buffer_mode or 'os'
	if self.buffer_mode == 'table' then
		self.lines={}
	elseif self.buffer_mode ~= 'os' and self.buffer_mode ~= 'sync' then
		error('invalid buffer mode '..tostring(self.buffer_mode))
	end
	if opts.quote_mode ~= nil then
		if opts.quote_mode == 'never' then
			self.quote_mode = false
		else
			self.quote_mode = opts.quote_mode
		end
	else
		self.quote_mode = 'auto'
	end
	if self.quote_mode ~= 'auto' and self.quote_mode ~= 'always' and self.quote_mode ~= false then
		error('invalid quote mode '..tostring(self.quote_mode))
	end

	-- log using write_usb_msg, mode may be be 'table' for array of values, or string for xsv line
	self.ptplog = opts.ptplog
	if self.ptplog == true then
		self.ptplog = 'table'
	elseif self.ptplog ~= 'string' and self.ptplog ~= 'table' and self.ptplog then
		error('invalid ptplog mode '..tostring(self.ptplog))
	end
	-- key for log messages. If false, sent directly as message value
	if opts.ptplog_key == nil then
		self.ptplog_key = 'xsvlog'
	elseif type(opts.ptplog_key) == 'string' then
		self.ptplog_key = opts.ptplog_key
	elseif opts.ptplog_key ~= false then
		error('invalid ptplog_key '..tostring(opts.ptplog_key))
	end
	-- print is on by default
	if opts.ptplog_warn_print ~= false then
		self.ptplog_warn_print = true
	end
	-- timeout for messages, if messsage system queue of 15 is full
	self.ptplog_timeout = opts.ptplog_timeout or 250
	if type(self.ptplog_timeout) ~= 'number' or self.ptplog_timeout < 0 then
		error('invalid ptplog_timeout '..tostring(opts.ptplog_timeout))
	end

	-- if drop_on_timeout is true, and timeout is exceeded once
	-- timeout is not retried until queue is not full, to avoid slowdowns
	-- if connection goes away
	if opts.ptplog_drop_on_timeout ~= false then
		self.ptplog_drop_on_timeout = true
	end

	-- TODO may accept other options than sep later
	if opts.tables then
		for n,sep in pairs(opts.tables) do
			self.tables[n] = {sep=sep}
		end
	end
	self:reset_vals()

	if opts.text_loggers then
		for n,col in pairs(opts.text_loggers) do
			if not self.vals[col] then
				error('invalid text_logger col '..col)
			end
			local name = 'log_'..col
			if self[name] ~= nil then
				error('conflicting text_logger '..name)
			end
			self[name]=function(self,fmt,...)
				self:set{[col]=string.format(fmt,...)}
			end
		end
	end
	if opts.dt_loggers then
		for n,base_col in pairs(opts.dt_loggers) do
			if not self.vals[base_col] then
				error('invalid dt_logger base col '..base_col)
			end
			local name = 'dt_'..base_col
			if self[name] ~= nil then
				error('conflicting dt_logger '..name)
			end
			self[name]=function(self,col)
				if not self.vals[col] then
					error('invalid dt_logger col name '..tostring(col))
				end
				self:set{[col]=tostring(get_tick_count() - self.vals[base_col])}
			end
		end
	end

	-- checks after vals initialized
	for n, v in pairs(self.funcs) do
		if not self.vals[n] then
			error('missing func col '.. tostring(n))
		end
	end
	for n, v in pairs(self.tables) do
		if not self.vals[n] then
			error('missing table col '.. tostring(n))
		end
	end

	if self.nofile and not opts.ptplog then
		local nop =function() return end
		self.write=nop
		self.write_data=nop
		self.flush=nop
		self.set=nop
	else
		if not self.nofile then
			-- TODO name should accept autonumber or date based options
			if not opts.append then
				os.remove(self.name)
			end
			if self.buffer_mode == 'os' then
				self.fh = io.open(self.name,'ab')
				if not self.fh then
					error('failed to open log')
				end
			end
		end
		self:write_data(self.cols)
		self:flush()
	end
end
function log_methods:prepare_write()
	if self.buffer_mode == 'os' then
		return
	end
	-- if self.buffer_mode == 'sync' or self.buffer_mode then
	self.fh = io.open(self.name,'ab')
	if not self.fh then
		error('failed to open log')
	end
end
function log_methods:finish_write()
	if self.buffer_mode == 'os' then
		return
	end
	self.fh:close()
	self.fh=nil
end

function log_methods:quote_xsv_cell(cell)
	if not self.quote_mode then
		return cell
	end
	-- ensure string
	cell = tostring(cell)
	if self.quote_mode == 'always' or cell:match('['..self.delim_pat..'"\r\n]') then
		return '"'..cell:gsub('"','""')..'"'
	end
	return cell
end

function log_methods:quote_data(data)
	if not self.quote_mode then
		return data
	end
	local quoted = {}
	for i, cell in ipairs(data) do
		table.insert(quoted,self:quote_xsv_cell(cell))
	end
	return quoted
end

function log_methods:data_to_string(data)
	return table.concat(self:quote_data(data),self.delim)
end

function log_methods:write_xsv_file(data)
	self.fh:write(self:data_to_string(data)..'\n')
end

--[[
allow timeouts etc to be printed if enabled
can't easily send to file log from middle of log:write()
]]
function log_methods:ptplog_warn(fmt,...)
	if self.ptplog_warn_print then
		print(fmt:format(...))
	end
end

function log_methods:write_usb_msg(msg)
	-- always try without timeout, since with non-zero yields even if not needed
	if write_usb_msg(msg) then
		self.ptplog_timedout = false
	else
		if not self.ptplog_timedout then
			self:ptplog_warn('msg queue full %d',self.write_count)
		end
		if not self.ptplog_drop_on_timeout or not self.ptplog_timedout then
			if write_usb_msg(msg,self.ptplog_timeout) then
				self.ptplog_timedout = false
			else
				self:ptplog_warn('msg timeout %d',self.write_count)
				self.ptplog_timedout = true
			end
		end
	end
end

function log_methods:write_xsv_ptp(data)
	local val
	if self.ptplog == 'string' then
		val = self:data_to_string(data)
	else -- table
		-- TODO should quoting be optional?
		val = self:quote_data(data)
	end
	if self.ptplog_key then
		val = {[self.ptplog_key]=val}
	end
	self:write_usb_msg(val)
end

function log_methods:write_data(data)
	if self.ptplog then
		self:write_xsv_ptp(data)
	end
	if self.nofile then
		return
	end
	if self.buffer_mode == 'table' then
		table.insert(self.lines,data)
		return
	end
	self:prepare_write()
	self:write_xsv_file(data)
	self:finish_write()
end

function log_methods:flush()
	-- 'sync' is flushed every line, nothing to do here
	if self.nofile or self.buffer_mode == 'sync' then
		return
	end
	if self.buffer_mode == 'os' then
		if self.fh then
			self.fh:flush()
		end
	elseif self.buffer_mode == 'table' then
		if #self.lines == 0 then
			return
		end
		self:prepare_write()
		for i,data in ipairs(self.lines) do
			self:write_xsv_file(data)
		end
		self:finish_write()
		self.lines={}
	end
end

function log_methods:write()
	self.write_count = self.write_count + 1
	local data={}
	for i,name in ipairs(self.cols) do
		local v
		if self.funcs[name] then
			v=tostring(self.funcs[name]())
		elseif self.tables[name] then
			v=table.concat(self.vals[name],self.tables[name].sep)
		else
			v=self.vals[name]
		end
		table.insert(data,v)
	end
	self:write_data(data)
	self:reset_vals()
end
function log_methods:reset_vals()
	for i,name in ipairs(self.cols) do
		if self.tables[name] then
			self.vals[name] = {}
		else
			self.vals[name] = ''
		end
	end
end
function log_methods:set(vals)
	for name,v in pairs(vals) do
		if not self.vals[name] then
			error("unknown log col "..tostring(name))
		end
		if self.funcs[name] then
			error("tried to set func col "..tostring(name))
		end
		if self.tables[name] then
			table.insert(self.vals[name],v)
		else
			self.vals[name] = tostring(v)
		end
	end
end

function log_methods:close()
	if self.buffer_mode == 'table' then
		self:flush()
	end
	if self.fh then
		self.fh:close()
	end
end

function xsvlog.new(opts)
	local t={}
	for k,v in pairs(log_methods) do
		t[k] = v
	end
	t:init(opts)
	return t
end
return xsvlog

end)()
package.loaded['reylib/xsvlog']=xsvlog -- end inline reylib/xsvlog

exp=(function() -- inline reylib/rawexp
-- Exposure module. Author: reyalp (at) gmail.com. License: GPL.
-- Source: https://github.com/reyalpchdk/chdkscripts
local stru=(function() -- inline reylib/strutil
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

end)()
package.loaded['reylib/strutil']=stru -- end inline reylib/strutil
local exp={}

--[[
log columns used with log:set
note log must also provide a method log_desc, for free-form messages
typically using the xsvlog text_logger option
]]
exp.log_columns={
	'meter_time', -- milliseconds spent measuring meter area
	'histo_time', -- milliseconds spent measuring histogram
	'draw_time',  -- time to draw debug info on raw, if enabled
	'sv', -- "market" ISO
	'sv96', -- APEX*96 "real" ISO
	'sv_l1',   -- amount calculated sv is over sv96_max
	'sv_tv_tr', -- amount of sv over limit put back on tv
	'tv', -- shutter speed in seconds
	'tv96', -- APEX*96 shutter speed
	'tv_l1', -- amount calculated tv is over tv96_short_limit or under tv96_long_limit
	'tv_sv_tr', -- amount of calculated tv moved to ISO due to being over tv96_sv_thresh
	'av', -- aperture as F number. Includes ND value on ND-only cameras
	'av96', -- APEX*96 aperture
	'nd', -- 1 ND active, 0 ND not active
	'nd_tv_tr', -- when nd active, amount over ND trigger threshold, negative if if hysteresis active
	'nd_hookfix', -- nd was activated in shoot hook. 1 succeeded, 0 failed. Blank if ND not active
	'bv96', -- brightness value calculated from meter and exposure settings
	'meter', -- average pixel value of meter area
	'meter96', -- meter value as APEX*96 exposure, where 0 is an aribtrary chosen "correct" exposure
	'meter96_tgt', -- target meter value for calculated for this exposure
	'meter_weight',
	'over_frac', -- fraction of pixels over (whitelevel - over_margin_ev)
	'over_weight',
	'under_frac', -- fraction of pixels under under_margin_ev
	'under_weight',
	'bv_ev_shift', -- bv ev shift applied to this exposure
	'bv_ev_l1', -- original calculated bv/ev shift value if over threshold or limit
	-- all of the following are the calculated change for the *next* exposure
	'd_ev_base', -- calculated ev change for next exposure, with over, under and ev change limit applied
	'd_ev_s1', -- ev change after smoothing
	'd_ev_s2', -- ev change after smooth overshoot logic
	'd_ev_r1', -- ev change after reverse limit logic
	'd_ev_f', -- final ev change with whichever of the preceding applied
	'd_ev', -- used ev change, as integer
}

function exp:init(opts)
	local logvals={}
	for i,name in ipairs{
		'ev_change_max',
		'ev_shift',
		'ev_use_initial',
		'bv_ev_shift_pct',
		'bv_ev_shift_base_bv',
		'tv96_long_limit',
		'tv96_short_limit',
		'tv96_sv_thresh',
		'tv96_nd_thresh',
		'nd_value',
		'nd_hysteresis',
		'sv96_max',
		'sv96_target',
		'meter_width_pct',
		'meter_height_pct',
		'meter_left_pct',
		'meter_top_pct',
		'meter_step',
		'meter_high_thresh',
		'meter_high_limit',
		'meter_high_limit_weight',
		'meter_low_thresh',
		'meter_low_limit',
		'meter_low_limit_weight',
		'over_margin_ev',
		'over_thresh_frac',
		'under_margin_ev',
		'under_thresh_frac',
		'over_weight_max',
		'under_weight_max',
		'over_prio',
		'under_prio',
		'histo_step',
		'do_draw',
		'draw_meter',
		'draw_gauge_y_pct',
		'smooth_factor',
		'smooth_limit_frac',
		'ev_chg_rev_limit_frac',
	} do
		if opts[name] == nil then
			error('exp missing opt '..name)
		end
		self[name] = opts[name]
		table.insert(logvals,string.format("%s=%s",name,tostring(opts[name])))
	end

	-- TODO special value from usec_to_tv96
	if self.tv96_nd_thresh == -10000 or self.tv96_nd_thresh > self.tv96_short_limit then
		self.tv96_nd_thresh = false
	end

	self.meter_width =  (self.meter_width_pct * rawop.get_active_width()) / 100
	self.meter_height = (self.meter_height_pct * rawop.get_active_height()) / 100

	-- not strictly required, truncate to multiples of 4 to keep bayer alignment consistent
	self.meter_width = bitand(0xFFFFFFFC,self.meter_width)
	self.meter_height = bitand(0xFFFFFFFC,self.meter_height)

	-- -1 = centered in active area
	if self.meter_left_pct == -1 then
		self.meter_left = rawop.get_active_left() + rawop.get_active_width()/2 - self.meter_width/2
	else
		self.meter_left = rawop.get_active_left() + (self.meter_left_pct * rawop.get_active_width()) / 100
		self.meter_left = bitand(0xFFFFFFFC,self.meter_left)
		if self.meter_left + self.meter_width >= rawop.get_active_width() then
			local meter_width_trunc = rawop.get_active_width() - self.meter_left
			meter_width_trunc = bitand(0xFFFFFFFC,meter_width_trunc)
			if meter_width_trunc < 4 then
				error('meter width too small')
			end
			log:log_desc('WARN:meter_width truncated:%d->%d',self.meter_width,meter_width_trunc)
			self.meter_width = meter_width_trunc
		end
	end
	self.meter_x_count = self.meter_width/self.meter_step

	-- -1 = centered in active area
	if self.meter_top_pct == -1 then
		self.meter_top = rawop.get_active_top() + rawop.get_active_height()/2 - self.meter_height/2
	else
		self.meter_top = rawop.get_active_top() + (self.meter_top_pct * rawop.get_active_height()) / 100
		self.meter_top = bitand(0xFFFFFFFC,self.meter_top)
		if self.meter_top + self.meter_height >= rawop.get_active_height() then
			local meter_height_trunc = rawop.get_active_height() - self.meter_top
			meter_heightl_trunc = bitand(0xFFFFFFFC,meter_height_trunc)
			if meter_height_trunc < 4 then
				error('meter height too small')
			end
			log:log_desc('WARN:meter_height truncated:%d->%d',self.meter_height,meter_height_trunc)
			self.meter_height = meter_height_trunc
		end
	end
	self.meter_y_count = self.meter_height/self.meter_step

	-- weight of meter in "normal range" hard coded for now
	self.meter_base_weight = 100
	-- max weight inputs are in aboslute values, make relative to base weight
	self.meter_high_limit_weight = self.meter_high_limit_weight - self.meter_base_weight
	self.meter_low_limit_weight = self.meter_low_limit_weight - self.meter_base_weight

	self.over_thresh_weight=100
	self.over_frac_max = imath.sqrt(self.over_thresh_weight*imath.scale)
							*imath.sqrt(self.over_weight_max*imath.scale)/imath.scale^2

	self.under_thresh_weight=100
	self.under_frac_max = imath.sqrt(self.under_thresh_weight*imath.scale)
							*imath.sqrt(self.under_weight_max*imath.scale)/imath.scale^2

	-- log some calculated values
	for i,name in ipairs{
		'meter_top', 'meter_left',
		'meter_width','meter_height',
		'meter_x_count','meter_y_count',
	} do
		table.insert(logvals,string.format("%s=%s",name,tostring(self[name])))
	end

	-- scale for histo:range(), hard coded for now
	-- TODO NOTE histo_frac_to_pct format needs to be adjusted to match
	self.histo_scale = 1000000

	local histo_samples = (rawop.get_jpeg_width()/self.histo_step)*(rawop.get_jpeg_height()/self.histo_step)
	-- approx total number of pixels read by histo
	table.insert(logvals,string.format("histo_samples=%d",histo_samples))

	log:log_desc("init:%s",table.concat(logvals,' '))

	-- warn if < 10 pixels in histogram would trigger threshold
	if self.over_thresh_frac > 0 and 10*self.histo_scale/self.over_thresh_frac > histo_samples then
		log:log_desc('WARN:over_thresh histo_samples')
	end
	if self.under_thresh_frac > 0 and 10*self.histo_scale/self.under_thresh_frac > histo_samples then
		log:log_desc('WARN:under_thresh histo_samples')
	end

	-- TODO should just auto adjust and warn in log, or use multiple meters
	if self.meter_x_count*self.meter_y_count > bitshru(0xFFFFFFFF,rawop.get_bits_per_pixel()) then
		error("meter step too small")
	end
	if self.tv96_sv_thresh < self.tv96_long_limit then
		log:log_desc('WARN:tv96_sv_thresh < tv96_long_limit')
		self.tv96_sv_thresh = self.tv96_long_limit
-- TODO could disable instead
--		self.sv96_max = self.sv96_target
	end
	if self.sv96_max < self.sv96_target then
		log:log_desc('WARN:sv96_max < sv96_target')
		self.sv96_max = self.sv96_target
	end

	self.histo = rawop.create_histogram()
end

-- initialize values that might change between frames (blacklevel/neutral dependent)
function exp:init_frame()
	local bl=rawop.get_black_level()
	-- blacklevel initialized and unchanged
	if bl == self.black_level then
		return
	end
	self.black_level=bl
	-- white level shouldn't ever change, but more consistent to do it here
	self.white_level=rawop.get_white_level()
	-- histo limits in shot histo units
	-- lowest value to count as over exp, as shot histo value
	-- = raw(ev(whitelevel) - margin_ev)/(2^(bpp - histo_bpp))
	self.over_histo_min = bitshru(rawop.ev_to_raw(rawop.raw_to_ev(self.white_level)-self.over_margin_ev),rawop.get_bits_per_pixel() - 10)
	-- highest value to count as under exp, as shot histo value
	-- = raw(-margin_ev)/(2^(bpp - histo_bpp))
	self.under_histo_max = bitshru(rawop.ev_to_raw(-self.under_margin_ev),rawop.get_bits_per_pixel() - 10)
	log:log_desc('init_frame:black_level=%d neutral=%d over_histo_min=%d under_histo_max=%d',
				self.black_level,
				rawop.get_raw_neutral(),
				self.over_histo_min,
				self.under_histo_max)
end


-- draw debug stuff on raw
function exp:draw_pct_bar(x, y, frac, max, width, dir, r, g, b)
	local w,h
	local len = (frac*width/max)
	if len < 0 then
		if dir == 'h' then
			x = x + len
		else
			y = y + len
		end
		len = -len
	end
	if dir == 'h' then
		w = len
		h = 8
	elseif dir == 'v' then
		h = len
		w = 8
	end
	if g then
		rawop.fill_rect_rgbg(x, y, w, h, r,g,b)
	else
		rawop.fill_rect(x, y, w, h, r)
	end
end

function exp:draw_ev_tick(left, top, tick_height, tick_width, width, bl_offset, max_ev, ev, r,g,b)
	if g then
		rawop.fill_rect_rgbg(left + (width*(bl_offset + ev))/max_ev,top,tick_width,tick_height,r,g,b)
	else
		rawop.fill_rect(left + (width*(bl_offset + ev))/max_ev,top,tick_width,tick_height,r)
	end
end

function exp:draw()
	local t0=get_tick_count()
	local drawval_high = self.white_level - self.black_level
	local drawval_low = self.black_level*2
	local drawval = drawval_high
	if self.mval > self.white_level - self.white_level/3 then
		drawval = drawval_low
	end
	local width = self.meter_x_count*self.meter_step
	local height = self.meter_y_count*self.meter_step

	-- box around meter area
	if self.draw_meter == 'box' then
		rawop.rect(self.meter_left,self.meter_top,width,height,2,drawval)
	elseif self.draw_meter == 'corners' then
		local len=64
		rawop.fill_rect(self.meter_left,self.meter_top,len,2,drawval)
		rawop.fill_rect(self.meter_left,self.meter_top+2,2,len-2,drawval)
		rawop.fill_rect(self.meter_left + width - len - 2,self.meter_top,len,2,drawval)
		rawop.fill_rect(self.meter_left + width - 2,self.meter_top+2,2,len-2,drawval)

		rawop.fill_rect(self.meter_left,self.meter_top+height - 2,len,2,drawval)
		rawop.fill_rect(self.meter_left,self.meter_top+height - len - 2,2,len-2,drawval)
		rawop.fill_rect(self.meter_left + width - len - 2,self.meter_top+height-2,len,2,drawval)
		rawop.fill_rect(self.meter_left + width - 2,self.meter_top+height-len-2,2,len-2,drawval)
	end

	-- debug display area
	local d_width = 800
	local d_top
	if self.draw_gauge_y_pct == 0 then
		d_top = rawop.get_jpeg_top() + 80 -- ensure min margin, < 1%
	else
	 	d_top = rawop.get_jpeg_top() + (self.draw_gauge_y_pct*rawop.get_jpeg_height())/100
	end
	local d_left = rawop.get_jpeg_left() + (rawop.get_jpeg_width() - d_width)/2
	-- meter level
	local bl_offset = -rawop.raw_to_ev(self.black_level+1)
	local max_ev = bl_offset + rawop.raw_to_ev(self.white_level)

	-- get appropriate drawval with a tiny meter
	local mv = rawop.meter(d_left + d_width/2 - 64,d_top,18,9, 7,7)
	if mv > self.white_level - self.white_level/3 then
		drawval = drawval_low
	else
		drawval = drawval_high
	end

	self:draw_pct_bar(d_left,
					d_top,
					bl_offset + self.mval96,
					max_ev,
					d_width,
					'h',
					drawval)
	-- meter ticks
	-- black level
	rawop.fill_rect(d_left,d_top-8,4,30,drawval)
	-- white level
	rawop.fill_rect(d_left+d_width-2,d_top-8,4,30,drawval)
	-- neutral (0 ev)
	self:draw_ev_tick(d_left,d_top-8,8,4,d_width,bl_offset,max_ev,0,drawval)
	self:draw_ev_tick(d_left,d_top+8,14,4,d_width,bl_offset,max_ev,0,drawval)
	-- draw generic stops before and after neutral
	local i = -96
	repeat
		self:draw_ev_tick(d_left,d_top+8,10,4,d_width,bl_offset,max_ev,i,drawval)
		i = i - 96
	until bl_offset + i <= 0

	i = 96
	repeat
		self:draw_ev_tick(d_left,d_top+8,10,4,d_width,bl_offset,max_ev,i,drawval)
		i = i + 96
	until i >= max_ev - bl_offset
	-- draw meter limits, thresh = yellow, limit = red
	self:draw_ev_tick(d_left,d_top-12,8,4,d_width,bl_offset,max_ev,self.ev_target_base + self.meter_low_thresh,drawval_high,drawval_high,drawval_low)
	self:draw_ev_tick(d_left,d_top-12,8,4,d_width,bl_offset,max_ev,self.ev_target_base + self.meter_low_limit,drawval_high,drawval_low,drawval_low)
	self:draw_ev_tick(d_left,d_top-12,8,4,d_width,bl_offset,max_ev,self.ev_target_base + self.meter_high_thresh,drawval_high,drawval_high,drawval_low)
	self:draw_ev_tick(d_left,d_top-12,8,4,d_width,bl_offset,max_ev,self.ev_target_base + self.meter_high_limit,drawval_high,drawval_low,drawval_low)

	-- if ev shift is in effect, draw tick on top of everything else
	if self.ev_target ~= 0 then
		self:draw_ev_tick(d_left,d_top-8,8,4,d_width,bl_offset,max_ev,self.ev_target,drawval_low,drawval_high,drawval_low)
		self:draw_ev_tick(d_left,d_top+8,14,4,d_width,bl_offset,max_ev,self.ev_target,drawval_low,drawval_high,drawval_low)
	end

	-- exposure change
	self:draw_pct_bar(d_left + d_width/2,
						d_top + 30,
						self.ev_change,
						self.ev_change_max,
						d_width/2,
						'h',
						drawval)
	-- ticks for left, mid, right
	rawop.fill_rect(d_left,d_top+38,4,16,drawval)
	rawop.fill_rect(d_left+d_width/2-2,d_top+38,4,16,drawval)
	rawop.fill_rect(d_left+d_width-4,d_top+38,4,16,drawval)

	-- TODO under/over fracs are absolute, relative to threshold would be useful
	-- under exposed fraction
	local r,g,b = drawval,drawval,drawval
	if self.under_frac >= self.under_thresh_frac then
		r = drawval_high
		g,b = drawval_low,drawval_low
	end
	-- left to right
	self:draw_pct_bar(d_left,d_top+54, self.under_frac, self.histo_scale, d_width/2, 'h', r, g, b)

	-- over exposured fraction
	if self.over_frac >= self.over_thresh_frac then
		r = drawval_high
		g,b = drawval_low,drawval_low
	else
		r,g,b = drawval,drawval,drawval
	end
	-- right to left
	self:draw_pct_bar(d_left + d_width, d_top+54, -self.over_frac, self.histo_scale, d_width/2, 'h', r, g, b)

	log:set{draw_time=get_tick_count()-t0}
end

function exp:clamp(v,min,max)
	-- single value, assume +/-
	if not max then
		max = min
		min = -max
	end
	if v > max then
		return max
	elseif v < min then
		return min
	end
	return v
end

function exp:calc_bv_ev_shift()
	if self.bv_ev_shift_pct == 0 then
		return 0
	end
	-- bv change from initial
	local bv_change = self.bv96 - self.bv96_init
	local bv_ev_shift = (bv_change*self.bv_ev_shift_pct)/100
	-- limit shift by meter limits (relative to ev_target_base)
	-- simple linear ramp
	if bv_ev_shift > self.meter_high_thresh then
		local over = bv_ev_shift - self.meter_high_thresh
		if over > 2*(self.meter_high_limit - self.meter_high_thresh) then
			--log:log_desc('bv ev limit:%d',bv_ev_shift)
			self:nextlog{bv_ev_l1=bv_ev_shift}
			bv_ev_shift = self.meter_high_limit
		else
			--log:log_desc('bv ev thresh:%d',bv_ev_shift)
			self:nextlog{bv_ev_l1=bv_ev_shift}
			bv_ev_shift = self.meter_high_thresh + over/2
		end
	elseif bv_ev_shift < self.meter_low_thresh then
		local under = bv_ev_shift - self.meter_low_thresh
		if under < 2*(self.meter_low_limit - self.meter_low_thresh) then
			-- log:log_desc('bv ev -limit:%d',bv_ev_shift)
			self:nextlog{bv_ev_l1=bv_ev_shift}
			bv_ev_shift = self.meter_low_limit
		else
			-- log:log_desc('bv ev -thresh:%d',bv_ev_shift)
			self:nextlog{bv_ev_l1=bv_ev_shift}
			bv_ev_shift = self.meter_low_thresh + under/2
		end
	end
	return bv_ev_shift
end

function exp:calc_ev_change()
	local last_ev_change

	-- handle first iteration
	-- TODO ugly
	if self.ev_change then
		last_ev_change = self.ev_change_im
	else
		if self.bv_ev_shift_base_bv then
			self.bv96_init = self.bv_ev_shift_base_bv
		else
			self.bv96_init = self.bv96
		end
		-- first time through
		last_ev_change = 0
		self.ev_target_base = self.ev_shift
		-- if using initial as target, add to ev_shift
		if self.ev_use_initial then
			log:log_desc('initial ev:%d+%d',self.mval96,self.ev_shift)
			self.ev_target_base = self.ev_target_base + self.mval96
		end
	end

	-- shift by % of over or under initial value
	local bv_ev_shift = self:calc_bv_ev_shift()

	self:nextlog{bv_ev_shift=bv_ev_shift}

	-- adjust target for this shot
	self.ev_target = self.ev_target_base + bv_ev_shift
	self:nextlog{meter96_tgt=self.ev_target}

	-- basic change: difference of last exposure from metered exposure
	-- plus exposure shift, clamped to per-frame limit
	local ev_change = self:clamp(self.ev_target - self.mval96,self.ev_change_max)

	-- convert limits that are relative to ev shift to meter values
	local meter_high_thresh	= self.ev_target_base + self.meter_high_thresh
	local meter_high_limit	= self.ev_target_base + self.meter_high_limit
	local meter_low_thresh	= self.ev_target_base + self.meter_low_thresh
	local meter_low_limit	= self.ev_target_base + self.meter_low_limit

	-- basic weight
	local meter_weight = self.meter_base_weight

	-- if over / under exposed beyond thresholds, increase meter weight
	-- high limit - driven above "ideal" value by underexp
	if self.mval96 > meter_high_thresh then
		local range = meter_high_limit - meter_high_thresh
		-- amount of range we have left
		local frac = meter_high_limit - self.mval96
		-- if above limit, clamp to limit
		if frac <= 0 then
			meter_weight = meter_weight + self.meter_high_limit_weight
		else
			-- otherwise, weight bonus = (max_bonus - margin_remaining)^2/max_bonus
			meter_weight = meter_weight + (self.meter_high_limit_weight - (self.meter_high_limit_weight*frac)/range)^2/self.meter_high_limit_weight
		end
	-- low limit - driven below "ideal" value by overexp
	-- TODO will also be hit if max shutter / iso reached
	elseif self.mval96 < meter_low_thresh then
		local range = meter_low_thresh - meter_low_limit
		local frac = self.mval96 - meter_low_limit
		if frac <= 0 then
			meter_weight = meter_weight + self.meter_low_limit_weight
		else
			meter_weight = meter_weight + (self.meter_low_limit_weight - (self.meter_low_limit_weight*frac)/range)^2/self.meter_low_limit_weight
		end
	end

	-- TODO
	-- to avoid flapping as limits approached over / under weights
	-- are calculated as (% of threshold)^2/(100)
	-- clamped to maximum weight
	-- this makes under / over start to have a slight effect as soon as there is any over/under
	-- and ramp up quickly as it exceeds the threshold
	local over_weight = 0
	local over_fw
	if self.over_thresh_frac > 0 then
		if self.over_frac > 0 then
			-- fraction threshold used by measured over exposure
			over_fw = self.over_frac*self.over_thresh_weight/self.over_thresh_frac
			-- if over by enough to hit weight limit, use max val
			if over_fw > self.over_frac_max then
				over_weight = self.over_weight_max
			else
				over_weight = over_fw^2/self.over_thresh_weight
			end
		end
	end

	local under_weight = 0
	local under_fw
	if self.under_thresh_frac > 0 then
		if self.under_frac > 0 then
			-- fraction threshold used by measured under exposure
			under_fw = (self.under_frac*self.under_thresh_weight)/self.under_thresh_frac
			-- if over by enough to hit weight limit, use max val
			if under_fw > self.under_frac_max then
				under_weight = self.under_weight_max
			else
				under_weight = under_fw^2/self.under_thresh_weight
			end
		end
	end

	-- priority adjustments
	if over_fw and self.over_prio > 0 then
		local prio_mod = self:clamp(over_fw * self.over_prio / self.over_thresh_weight,0,self.over_prio)
		-- meter in opposite direction?
		if ev_change > 0 then
			log:log_desc("over prio meter %d-%d",meter_weight,prio_mod)
			meter_weight = meter_weight - prio_mod
			if meter_weight < 0 then
				meter_weight = 0
			end
		end
		-- under exposure
		if under_fw then
			log:log_desc("over prio under %d-%d",under_weight,prio_mod)
			under_weight = under_weight - prio_mod
			if under_weight < 0 then
				under_weight = 0
			end
		end
	end

	if under_fw and self.under_prio > 0 then
		local prio_mod = self:clamp(under_fw * self.under_prio / self.under_thresh_weight,0,self.under_prio)
		-- meter in opposite direction?
		if ev_change < 0 then
			log:log_desc("under prio meter %d-%d",meter_weight,prio_mod)
			meter_weight = meter_weight - prio_mod
			if meter_weight < 0 then
				meter_weight = 0
			end
		end
		-- over exposure
		if over_fw then
			log:log_desc("under prio over %d-%d",over_weight,prio_mod)
			over_weight = over_weight - prio_mod
			if over_weight < 0 then
				over_weight = 0
			end
		end
	end

	log:set{
		meter_weight=meter_weight,
		over_weight=over_weight,
		under_weight=under_weight,
	}

	ev_change = imath.scale*(ev_change*meter_weight - self.ev_change_max*over_weight + self.ev_change_max*under_weight)/(meter_weight + over_weight + under_weight)

	-- everything above should already be in limits, but clamp to UI limits to be sure
	ev_change = self:clamp(ev_change,self.ev_change_max*imath.scale)

	log:set{d_ev_base=stru.imath2str(ev_change)}

	-- smooth out rapid changes with simple exponential smoothing
	-- https://en.wikipedia.org/wiki/Exponential_smoothing
	if self.smooth_factor > 0 then
		local ev_change_smooth = imath.mul(ev_change, (imath.scale - self.smooth_factor)) + imath.mul(last_ev_change, self.smooth_factor)
		log:set{d_ev_s1=stru.imath2str(ev_change_smooth)}
		-- additional limits to reduce smoothing triggering oscillation
		-- limit_frac = 0 means smoothed used as is, with no limiting
		if self.smooth_limit_frac > 0 then
			if ev_change*ev_change_smooth < 0 -- smoothed and unsmoothed have opposite signs
				or math.abs(ev_change) < math.abs(ev_change_smooth) then -- smoothed has larger magnitude than unsmoothed
				local ev_change_limited = imath.mul(ev_change, self.smooth_limit_frac) + imath.mul(ev_change_smooth, imath.scale - self.smooth_limit_frac)
				log:set{d_ev_s2=stru.imath2str(ev_change_limited)}
				ev_change = ev_change_limited
			else -- otherwise, use normal smoothing
				ev_change = ev_change_smooth
			end
		else
			ev_change = ev_change_smooth
		end
	end
	if self.ev_chg_rev_limit_frac > 0 then
		-- if direction of Ev change changed, reduce by ev_chg_rev_limit_frac
		if ev_change * last_ev_change < 0 then
			local ev_change_limited = imath.mul(ev_change,imath.scale - self.ev_chg_rev_limit_frac)
			log:set{d_ev_r1=stru.imath2str(ev_change_limited)}
			ev_change = ev_change_limited
		end
	end

	self.ev_change_im = ev_change -- imath value
	self.ev_change = imath.round(ev_change)/imath.scale -- integer apex96, rounded

	log:set{
		d_ev_f=stru.imath2str(ev_change),
		d_ev=self.ev_change,
	}
end

-- read meter values from frame buffer
function exp:do_meter()
	local t0=get_tick_count()
	self.mval = rawop.meter(self.meter_left,self.meter_top,
								self.meter_x_count,self.meter_y_count,
								self.meter_step,self.meter_step)

	log:set{meter_time=get_tick_count()-t0}

	self.mval96 = rawop.raw_to_ev(self.mval)

	t0=get_tick_count()
	-- parameters similar to shot_histogram
	-- use jpeg area to avoid dark borders
	self.histo:update(rawop.get_jpeg_left(),rawop.get_jpeg_top(),
						rawop.get_jpeg_width(),
						rawop.get_jpeg_height(),
						self.histo_step,self.histo_step,10)
	-- shot histo values always scaled to 10 bit, assume white=1023, black=31
	-- ignore much lower than black, typically bad pixels
	self.over_frac = self.histo:range(self.over_histo_min,1023,self.histo_scale)
	self.under_frac = self.histo:range(4,self.under_histo_max,self.histo_scale)
	log:set{histo_time=get_tick_count()-t0}
end

function exp:histo_frac_to_pct(v)
	return string.format("%d.%04d",v/(self.histo_scale/100),v%(self.histo_scale/100))
end

function exp:log_meter()
	-- log meter values
	log:set{
		meter=self.mval,
		meter96=self.mval96,
		over_frac=self:histo_frac_to_pct(self.over_frac),
		under_frac=self:histo_frac_to_pct(self.under_frac),
	}
end

--[[
some values related to calculating exposure make more sense logged with
the exposure that used those values. Buffer for later
]]
function exp:nextlog(vals)
	if not self.nextlog_vals then
		self.nextlog_vals = {}
	end
	for k,v in pairs(vals) do
		self.nextlog_vals[k] = v
	end
end

function exp:log_nextlog_vals()
	if self.nextlog_vals then
		log:set(self.nextlog_vals)
	end
	self.nextlog_vals = nil
end


function exp:nd96_for_state(nd_state)
	-- only used for cams with iris
	if get_nd_present() == 2 and nd_state then
		return self.nd_value
	end
	return 0
end

function exp:init_exposure_params_from_cam()
	self.tv96 = get_prop(props.TV)
	self.sv96 = get_prop(props.SV)
	self.av96 = get_prop(props.AV)
	self.bv96 = get_prop(props.BV)

	-- allow manual fine-tuning
	if self.nd_value == 0 then
		self.nd_value = get_nd_value_ev96()
		log:log_desc('fw nd_value:%d',self.nd_value)
	else
		log:log_desc('override nd_value:%d fw:%d',self.nd_value,get_nd_value_ev96())
	end
	self.nd_state = self:get_nd_state()

	self.nd96 = self:nd96_for_state(self.nd_state)
end

-- initialization after initial halfpress ready
function exp:init_preshoot()
	-- prevent any stale nextlog values from carrying over into a shooting sequence
	self.nextlog_vals = nil
	self:init_exposure_params_from_cam()
	self:log_exposure_params()
	log:set{bv96=self.bv96}
	-- shifts are currnetly not calculated or applied for the initial exposure
	-- does not account for Canon native EV shift
	self:nextlog{meter96_tgt=0,bv_ev_shift=0}
	-- TODO could try to use Bv and ev comp setting
	self.ev_change = 0

	-- turn EV change into updated exposure settings
	self:calc_exposure_params()

	-- set values for next exposure
	self:set_cam_exposure_params()
	-- TODO force initialization on first real shot
	self.ev_change = nil
end

--[[
check if cam used values match set values, can fail if ISO_BASE is wrong
]]
function exp:sanity_check_cam_exposure_params()
	local cam_tv96 = get_prop(props.TV)
	local cam_sv96 = get_prop(props.SV)
	local cam_av96 = get_prop(props.AV)
	if self.tv96 ~= cam_tv96 then
		log:log_desc('tv %s != cam %s',tostring(self.tv96),tostring(cam_tv96))
	end
	if self.sv96 ~= cam_sv96 then
		log:log_desc('sv %s != cam %s',tostring(self.sv96),tostring(cam_sv96))
	end
	if self.av96 ~= cam_av96 then
		log:log_desc('av %s != cam %s',tostring(self.av96),tostring(cam_av96))
	end
	local cam_nd = self:get_nd_state()
	if self.nd_state ~= cam_nd then
		log:log_desc('nd %s != cam %s',tostring(self.nd_state),tostring(cam_nd))
	end
end

--[[
return the hardware state of ND, false = out, or no ND, true = in
--]]
function exp:get_nd_state()
	if get_nd_present() == 0 then
		return false
	end
	return (get_nd_current_ev96() ~= 0)
end

function exp:set_nd()
	-- ND only
	if get_nd_present() ~= 0 then
		if self.nd_state then
			set_nd_filter(1)
		else
			set_nd_filter(2)
		end
	end
end

function exp:set_cam_exposure_params()
	set_tv96_direct(self.tv96)
	set_sv96(self.sv96)
	self:set_nd()
end

--[[
Some cams need ND state set in shoot hook, especially in quick mode
may want a way to disable
]]
function exp:on_hook_shoot_ready()
	if self.nd_state ~= self:get_nd_state() then
		self:set_nd()
		-- TODO spammy on cams that need it
		if self.nd_state == self:get_nd_state() then
			-- log:log_desc('hook ndfix')
			log:set{nd_hookfix=1}
		else
			log:set{nd_hookfix=0}
			-- log:log_desc('hook ndfix fail')
		end
	end
end

-- update exposure params from cam if needed, log
function exp:get_cam_exposure_params()
	-- on the first shot, get exposure values from cam
	if not self.tv96 then
		self:init_exposure_params_from_cam()
	else
	-- otherwise, compare cam values to last set values and log if different
		self:sanity_check_cam_exposure_params()
	end
end

function exp:log_exposure_params()
	-- log exposure values for shot we just metered
	local tvus=tv96_to_usec(self.tv96)
	local av1k=av96_to_aperture(self.av96)
	local nd
	if self.nd_state then
		nd=1
	else
		nd=0
	end
	log:set{
		sv=sv96_to_iso(sv96_real_to_market(self.sv96)),
		sv96=self.sv96,
		av=string.format("%d.%03d",av1k/1000,((av1k%1000))),
		av96=self.av96,
		tv=string.format("%d.%06d",tvus/1000000,((tvus%1000000))),
		tv96=self.tv96,
		nd=nd,
	}
end

-- calculate new exposure settings from EV change
function exp:calc_exposure_params()
	-- start with ev change on Tv
	local tv96_new = self.tv96 - self.ev_change

	local sv_extra = 0

	local sv96_new = self.sv96_target

	-- TODO initial may be over limits
	if self.sv96 > self.sv96_max then
		log:log_desc('sv prev > sv max')
	end
	if self.sv96 > sv96_new then
		sv_extra = self.sv96 - sv96_new
	end

	-- put anything over base ISO on Tv, will add back later if tv limits hit
	tv96_new = tv96_new - sv_extra

	local nd_state_new=false
	local av96_new = self.av96
	-- TODO doesn't handle cases where sv thresh overlaps with ND range
	if get_nd_present() > 0 then
		local nd_state_old = self.nd_state
		if self.nd_state then
			-- if ND was in for last shot, add value back to tv and clear
			tv96_new = tv96_new + self.nd_value
			-- if ND only, remove from av
			if get_nd_present() == 1 then
				av96_new = av96_new - self.nd_value
			end
			nd_state_new = false
		end
		if self.tv96_nd_thresh and tv96_new > self.tv96_nd_thresh then
			-- log:log_desc('tv over nd:%d',tv96_new - self.tv96_nd_thresh)
			self:nextlog{nd_tv_tr=tv96_new - self.tv96_nd_thresh}
			nd_state_new = true
		elseif self.tv96_nd_thresh and nd_state_old and tv96_new > self.tv96_nd_thresh - self.nd_hysteresis then
			-- log:log_desc('tv nd hyst:%d',tv96_new - self.tv96_nd_thresh)
			self:nextlog{nd_tv_tr=tv96_new - self.tv96_nd_thresh}
			nd_state_new = true
		end
		if nd_state_new then
			tv96_new = tv96_new - self.nd_value
			if get_nd_present() == 1 then
				av96_new = av96_new + self.nd_value
			end
		end
	end

	local tv_extra = 0

	-- only do ISO adjustment + messages if range defined
	if self.sv96_target < self.sv96_max then
		if tv96_new < self.tv96_sv_thresh then
			local over = self.tv96_sv_thresh - tv96_new
			if over > (self.tv96_sv_thresh - self.tv96_long_limit)*2 then
				tv_extra = tv96_new - self.tv96_long_limit
				tv96_new = self.tv96_long_limit
				-- log:log_desc('tv over long:%d',-tv_extra)
				self:nextlog{tv_l1=tv_extra}
			else
				tv_extra = -over/2
				tv96_new = tv96_new - tv_extra
				-- log:log_desc('tv iso adj:%d',-tv_extra)
				self:nextlog{tv_sv_tr=-tv_extra}
			end
		end

		if tv_extra < 0 then
			sv96_new = sv96_new - tv_extra
		end
		if sv96_new > self.sv96_max then
			local sv_over = sv96_new - self.sv96_max
			-- log:log_desc('iso over limit:%d',sv_over)
			self:nextlog{sv_l1=sv_over}
			-- if ISO range isn't past end of shutter range, put remainder back on shutter
			if tv96_new > self.tv96_long_limit then
				-- log:log_desc('iso over tv:%d',tv96_new - self.tv96_long_limit)
				self:nextlog{sv_tv_tr=tv96_new - self.tv96_long_limit}
				tv96_new = tv96_new - sv_over
				if tv96_new < self.tv96_long_limit then
					self:nextlog{tv_l1=tv96_new - self.tv96_long_limit}
					tv96_new = self.tv96_long_limit
				end
			end

			sv96_new = self.sv96_max
		end
	else
		if tv96_new < self.tv96_long_limit then
			-- log:log_desc('tv over long:%d',self.tv96_long_limit- tv96_new)
			self:nextlog{tv_l1=tv96_new - self.tv96_long_limit}
			tv96_new = self.tv96_long_limit
		end
	end

	if tv96_new > self.tv96_short_limit then
		-- log:log_desc('tv under short:%d',tv96_new)
		self:nextlog{tv_l1=tv96_new - self.tv96_short_limit}
		tv96_new = self.tv96_short_limit
	end


	self.tv96 = tv96_new
	self.sv96 = sv96_new
	self.av96 = av96_new
	self.nd_state = nd_state_new
	self.nd96 = self:nd96_for_state(self.nd_state)
end

--[[
force reset of values that are calculated from first exposure
]]
function exp:reset()
	-- force reset of last ev, shifted values
	self.ev_change=nil
	-- force refresh of exposure values from cam exposure
	self.tv96 = nil
end


-- meter and update exposure
function exp:run()
	-- initialize raw buffer related values that can change between frames
	self:init_frame()
	-- update / sanity check settings from previous exposure
	self:get_cam_exposure_params()
	-- log previous exposure
	self:log_exposure_params()
	-- log related items from previous exposure calc
	self:log_nextlog_vals()

	self:do_meter()
	self:log_meter()

	if self.mval == 0 then
		log:set{meter='fail'}
		return
	end

	-- if m96 == 0, bv = tv + av - sv
	-- nd96 is works like av, for cameras with both iris and ND
	self.bv96 = self.tv96 + self.av96 + self.nd96 - self.sv96 + self.mval96

	log:set{bv96=self.bv96}

	-- calculate required EV change
	self:calc_ev_change()

	-- turn EV change into updated exposure settings
	self:calc_exposure_params()

	-- set values for next exposure
	self:set_cam_exposure_params()

	if self.do_draw then
		self:draw()
	end
end
return exp

end)()
package.loaded['reylib/rawexp']=exp -- end inline reylib/rawexp

-- quarter stops ... 0 24 48 ...
ui_ev_shift=(ui_ev_shift_e-10)*24
ui_meter_high_thresh =  (ui_meter_high_thresh_e + 2)*24
ui_meter_high_limit =  (ui_meter_high_limit_e + 4)*24
ui_meter_low_thresh =  -(ui_meter_low_thresh_e + 2)*24
ui_meter_low_limit =  -(ui_meter_low_limit_e + 4)*24
ui_nd_hysteresis=(ui_nd_hysteresis_e)*24

ui_histo_step=tonumber(ui_histo_step_t.value)

ui_max_ev_change = ({
	96/4,
	96/3,
	96/2,
	2*96/3,
	3*96/4,
	96,
	96+96/4,
	96+96/3,
	96+96/2,
	96+2*96/3,
	96+3*96/4,
	2*96})[(ui_max_ev_change_e + 1)]
ui_exp_over_margin_ev = ({96/32,96/16,96/8,96/4,96/3,96/2,2*96/3,3*96/4,96})[(ui_exp_over_margin_e + 1)]
ui_exp_under_margin_ev = ({96*7, 96*6, 96*5 + 48, 96*5, 96*4 + 48, 96*4, 96*3 + 48, 96*3, 96*2 + 48, 96*2})[ui_exp_under_margin_e+1]

if ui_meter_high_thresh >= ui_meter_high_limit or
	ui_meter_low_thresh <= ui_meter_low_limit then
	error('meter limit must be > than thresh')
end

-- need long to allow 100k, doesn't allow range
if ui_exp_over_thresh_frac < 0 or ui_exp_over_thresh_frac > 100000 then
	error('over frac must be 0-100000')
end
if ui_exp_under_thresh_frac < 0 or ui_exp_under_thresh_frac > 100000 then
	error('under frac must be 0-100000')
end

-- keyboard module
kb={
	handle_keys={
		'up',
		'down',
		'left',
		'right',
		'set',
		'shoot_half',
--		'shoot_full',
		'shoot_full_only',
		'erase',
		'zoom_in',
		'zoom_out',
--		'menu',  -- used for exit
		'display',
		'print',
		'erase',
		'iso',
		'flash',
		'mf',
		'macro',
		'video',
		'timer',
		'expo_corr',
		'fe',
		'face',
		'zoom_assist',
		'ae_lock',
		'metering_mode',
		'playback',
		'help',
		'mode',
	},
	handlers={},
	state={},
}
function kb.default_handler(name,state)
	if state then
		press(name)
	else
		release(name)
	end
end

function kb:init(opts)
	for i, name in ipairs(self.handle_keys) do
		self.state[name]=false
		if opts.handlers[name] then
			self.handlers[name] = opts.handlers[name]
		else
			self.handlers[name] = self.default_handler
		end
	end
	for name,fn in ipairs(opts.handlers) do
		if self.state[name]==nil then
			error("handler for unknown key "..tostring(name))
		end
	end
end

function kb:handle_startup_shoot()
	-- shoot full on startup - may be left over from starting the script, or may want to start shooting
	-- full press will include half
	if is_pressed('shoot_half') then
		local t0=get_tick_count()
		-- start getting pre-shoot ready
		press('shoot_half')
		repeat sleep(10) until get_shooting() or not is_pressed('shoot_half')
		local dt=get_tick_count() - t0
		-- if pre-shoot took less than 100ms, may still be seeing the startup click
		if get_tick_count() - t0 < 100 then
			sleep(100-dt)
		end

		-- if shoot_half released, abort
		if not is_pressed('shoot_half') then
			release('shoot_half')
		end
		-- otherwise, continue to the normal shooting loop, shoot full will be detected immediately if held
	end
end
function kb:update()
	-- TODO would be nice to mirror any unhandled key by default, but don't have a way of getting key names
	for i, name in ipairs(self.handle_keys) do
		local new_state = is_pressed(name)
		if new_state ~= self.state[name] then
			self.state[name] = new_state
			self.handlers[name](name,new_state)
		end
	end
end
-- end keyboard module

-- shoot control module
shootctl={
	raw_hook_sleep=ui_raw_hook_sleep
}
function shootctl:update_drive_mode()
	local new_prop = get_prop(props.DRIVE_MODE)
	if new_prop == self.prop then
		return
	end
	self.prop = new_prop
	-- TODO there might be other continous-type values
	self.cont = (new_prop == 1)
	if self.cont then
		hook_shoot.set(0)
	else
		hook_shoot.set(10000)
	end
end
function shootctl:burst_start()
	log:log_desc('burst start')

	exp:init_preshoot()
	log:write()

	self.burst = true
	if self.cont then
		press('shoot_full_only')
	end
	-- set hook in raw for exposure
	hook_raw.set(10000)
end
function shootctl:burst_end()
	self.burst = false
	-- clear raw hook to ensure capt seq doesn't stay wait after burst
	hook_raw.set(0)
	if self.cont then
		release('shoot_full_only')
	end
	-- flush log when burst is done
	log:flush()
end
function shootctl:run()
	if not self.burst then
		return
	end
	-- if not in cont, simulate by clicking shoot full
	if not self.cont then
		press('shoot_full_only')
		-- wait until the hook is reached
		hook_shoot.wait_ready()
		release('shoot_full_only')
		hook_shoot.continue()
	end
	hook_raw.wait_ready()
	exp:run()
	-- TODO D10 sometimes fails to open shutter if this is off and debug drawing is disabled, and set_yield is not used
	if self.raw_hook_sleep > 0 then
		sleep(self.raw_hook_sleep)
	end

	hook_raw.continue()
	log:write()
end
-- end shoot control

function restore()
	if log then
		log:close()
	end
end

-- main script initialization
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
	error('not in still mode')
end

log = xsvlog.new{
	name="A/contae.csv",
	append=(ui_log_mode.value=='Append'),
	dummy=(ui_log_mode.value=='None'),
	buffer_mode='table',
	-- column names
	cols={
		'date',
		'time',
		'tick',
		'exp',
		'free_mem',
		'lua_mem',
		exp.log_columns,
		'desc',
	},
	-- columns automatically set at write time from functions
	funcs={
		date=function()
			return os.date('%m/%d/%Y')
		end,
		time=function()
			return os.date('%H:%M:%S')
		end,
		tick=get_tick_count,
		exp=get_exp_count,
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

exp:init{
	meter_width_pct=ui_meter_width_pct,
	meter_height_pct=ui_meter_height_pct,
	meter_left_pct=ui_meter_left_pct,
	meter_top_pct=ui_meter_top_pct,
	meter_step=ui_meter_step,

	ev_change_max=ui_max_ev_change,
	ev_shift=ui_ev_shift, -- shift target ev by x APEX96
	ev_use_initial=ui_ev_use_initial, -- use initial EV as target ev, modified by ev_shift if specified

	bv_ev_shift_pct=0, -- not implemented for contae, not clear if it makes sense for contae
	bv_ev_shift_base_bv=false,

	-- max (longest) shutter value
	tv96_long_limit=usec_to_tv96(ui_tv_max_s1k*1000),
	-- min (shortest) shutter value
	tv96_short_limit=usec_to_tv96(ui_tv_min_s100k*10),
	-- shutter value to start adjusting iso
	tv96_sv_thresh=usec_to_tv96(ui_tv_sv_adj_s1k*1000),

	-- shutter value to put in ND
	tv96_nd_thresh=usec_to_tv96(ui_tv_nd_thresh_s10k*100),

	nd_value=ui_nd_value,
	nd_hysteresis=ui_nd_hysteresis,

	-- max iso
	sv96_max=sv96_market_to_real(iso_to_sv96(ui_sv_max_mkt)),
	-- target iso
	sv96_target=sv96_market_to_real(iso_to_sv96(ui_sv_target_mkt)),

	-- point where high meter value starts increasing meter weight
	meter_high_thresh = ui_meter_high_thresh,
	-- point where full weight increase is reached
	meter_high_limit = ui_meter_high_limit,
	-- weight at limit
	meter_high_limit_weight = ui_meter_high_limit_weight,

	-- point where low meter value starts increasing meter weight
	meter_low_thresh = ui_meter_low_thresh,
	-- point where full weight increase is reached
	meter_low_limit = ui_meter_low_limit,
	-- weight at limit
	meter_low_limit_weight = ui_meter_low_limit_weight,

	-- how close to max shot histo to count against over exp fraction
	over_margin_ev=ui_exp_over_margin_ev,

	-- under is defined in terms of EV under neutral, since there are a bunch of stops without useful DR near black level
	under_margin_ev=ui_exp_under_margin_ev,

	-- histo is measured in parts per 100k, inputs in parts per 10k
	over_thresh_frac=ui_exp_over_thresh_frac*10,
	under_thresh_frac=ui_exp_under_thresh_frac*10,

	over_weight_max=ui_exp_over_weight_max,
	over_prio=ui_exp_over_prio,

	under_weight_max=ui_exp_under_weight_max,
	under_prio=ui_exp_under_prio,

	histo_step=ui_histo_step,
	do_draw=ui_do_draw,
	draw_meter=string.lower(ui_draw_meter_t.value),
	draw_gauge_y_pct=ui_draw_gauge_y_pct,
	smooth_factor=ui_smooth_factor*imath.scale/10, -- input is 0-9, value is imath 0-0.9
	smooth_limit_frac=ui_smooth_limit_frac*imath.scale/10, -- imath 0-1
	ev_chg_rev_limit_frac=ui_ev_chg_rev_limit_frac*imath.scale/10, -- imath 0-1
}

kb:init{
	handlers={
		shoot_full_only=function(name,state)
			-- new press
			if state then
				shootctl:burst_start()
			else
				shootctl:burst_end()
			end
		end,
	}
}

local bi=get_buildinfo()
log:log_desc("contae v:%s",contae_version);
log:log_desc("platform:%s-%s-%s-%s %s %s",
					bi.platform,bi.platsub,bi.build_number,bi.build_revision,
					bi.build_date,bi.build_time)

-- TODO might want to handle in script
set_exit_key("menu")

kb:handle_startup_shoot()
shootctl:update_drive_mode() -- ensure drive mode initialized
while true do
	kb:update()
	shootctl:update_drive_mode()
	shootctl:run()
	sleep(10)
end
