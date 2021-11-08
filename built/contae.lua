--[[
@title continuous auto exposure
@chdk_version 1.4.1
#ui_meter_width_pct=60 "Meter width %" [1 100]
#ui_meter_height_pct=60 "Meter height %" [1 100]
#ui_meter_step=13 "Meter step"
#ui_max_ev_change_e=5 "Max Ev change" {1/4 1/3 1/2 2/3 3/4 1 1.1/4 1.1/3 1.1/2 1.2/3 1.3/4 2}
#ui_smooth_factor=0 "Ev smooth factor/10"[0 9]
#ui_smooth_limit_frac=7 "Ev smooth limit frac/10" [0 10]
#ui_ev_change_rev_frac=5 "Ev change reverse frac/10" [0 10]
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

Copyright 2014-2021 reyalp (at) gmail.com

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
contae_version="0.13-dev"

require'hookutil'
require'rawoplib'
props=require'propcase'

log=(function() -- inline reylib/csvlog
-- csv log module. License: GPL
local log={}
function log:init(opts)
	if not opts then
		error('missing opts')
	end
	self.cols={unpack(opts.cols)}
	self.vals={}
	self.funcs={}
	self.tables={}
	if opts.funcs then
		for n,f in pairs(opts.funcs) do
			if type(f) ~= 'function' then
				error('expected function')
			end
			self.funcs[n] = f
		end
	end
	self.name = opts.name
	self.dummy = opts.dummy
	if opts.buffer_mode then
		self.buffer_mode = opts.buffer_mode
	else
		self.buffer_mode = 'os'
	end
	if self.buffer_mode == 'table' then
		self.lines={}
	elseif self.buffer_mode ~= 'os' and self.buffer_mode ~= 'sync' then
		error('invalid buffer mode '..tostring(self.buffer_mode))
	end
	-- TODO may accept other options than sep later
	if opts.tables then
		for n,sep in pairs(opts.tables) do
			self.tables[n] = {sep=sep}
		end
	end
	self:reset_vals()
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
	if self.dummy then
		local nop =function() return end
		self.write=nop
		self.write_data=nop
		self.flush=nop
		self.set=nop
	else
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
		self:write_data(self.cols)
		self:flush()
	end
end
function log:prepare_write()
	if self.buffer_mode == 'os' then
		return
	end
	-- if self.buffer_mode == 'sync' or self.buffer_mode then
	self.fh = io.open(self.name,'ab')
	if not self.fh then
		error('failed to open log')
	end
end
function log:finish_write()
	if self.buffer_mode == 'os' then
		return
	end
	self.fh:close()
	self.fh=nil
end

function log:write_csv(data)
	-- TODO should handle CSV quoting
	self.fh:write(string.format("%s\n",table.concat(data,',')))
end
function log:write_data(data)
	if self.buffer_mode == 'table' then
		table.insert(self.lines,data)
		return
	end
	self:prepare_write()
	self:write_csv(data)
	self:finish_write()
end

function log:flush()
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
			self:write_csv(data)
		end
		self:finish_write()
		self.lines={}
	end
	-- 'sync' is flushed every line
end

function log:write()
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
function log:reset_vals()
	for i,name in ipairs(self.cols) do
		if self.tables[name] then
			self.vals[name] = {}
		else
			self.vals[name] = ''
		end
	end
end
function log:set(vals)
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
--[[
return a function that records time offset from col named base_name
if name is not provided, function expects target aname as arg
]]
function log:dt_logger(base_name,name)
	if not self.vals[base_name] then
		error('invalid base field name')
	end
	if self.dummy then
		return function() end
	end
	if not name then
		return function(name)
			if not self.vals[name] then
				error('invalid col name')
			end
			self.vals[name]=get_tick_count() - self.vals[base_name]
		end
	end
	if not self.vals[name] then
		error('invalid col name')
	end
	return function()
		self.vals[name]=get_tick_count() - self.vals[base_name]
	end
end

--[[
return a printf-like function that appends to table col
]]
function log:text_logger(name)
	if not self.vals[name] then
		error('invalid col name')
	end
	if not self.tables[name] then
		error('text logger must be table field '..tostring(name))
	end
	if self.dummy then
		return function() end
	end
	return function(fmt,...)
		table.insert(self.vals[name],string.format(fmt,...))
	end
end

function log:close()
	if self.buffer_mode == 'table' then
		self:flush()
	end
	if self.fh then
		self.fh:close()
	end
end
return log

end)()
package.loaded['reylib/csvlog']=log -- end inline reylib/csvlog

exp=(function() -- inline reylib/rawexp
-- exposure module. License: GPL
local stru=(function() -- inline reylib/strutil
-- general string utilities. License: GPL
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
		'ev_change_rev_frac',
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

	-- meter rectangle, centered in active area
	self.meter_left = rawop.get_active_left() + rawop.get_active_width()/2 - self.meter_width/2
	self.meter_x_count = self.meter_width/self.meter_step
	self.meter_top = rawop.get_active_top() + rawop.get_active_height()/2 - self.meter_height/2
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

	logdesc("init:%s",table.concat(logvals,' '))

	-- warn if < 10 pixels in histogram would trigger threshold
	if self.over_thresh_frac > 0 and 10*self.histo_scale/self.over_thresh_frac > histo_samples then
		logdesc('WARN:over_thresh histo_samples')
	end
	if self.under_thresh_frac > 0 and 10*self.histo_scale/self.under_thresh_frac > histo_samples then
		logdesc('WARN:under_thresh histo_samples')
	end

	-- TODO should just auto adjust and warn in log, or use multiple meters
	if self.meter_x_count*self.meter_y_count > bitshru(0xFFFFFFFF,rawop.get_bits_per_pixel()) then
		error("meter step too small")
	end
	if self.tv96_sv_thresh < self.tv96_long_limit then
		logdesc('WARN:tv96_sv_thresh < tv96_long_limit')
		self.tv96_sv_thresh = self.tv96_long_limit
-- TODO could disable instead
--		self.sv96_max = self.sv96_target
	end
	if self.sv96_max < self.sv96_target then
		logdesc('WARN:sv96_max < sv96_target')
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
	logdesc('init_frame:black_level=%d neutral=%d over_histo_min=%d under_histo_max=%d',
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
			logdesc('bv ev limit:%d',bv_ev_shift)
			bv_ev_shift = self.meter_high_limit
		else
			logdesc('bv ev thresh:%d',bv_ev_shift)
			bv_ev_shift = self.meter_high_thresh + over/2
		end
	elseif bv_ev_shift < self.meter_low_thresh then
		local under = bv_ev_shift - self.meter_low_thresh
		if under < 2*(self.meter_low_limit - self.meter_low_thresh) then
			logdesc('bv ev -limit:%d',bv_ev_shift)
			bv_ev_shift = self.meter_low_limit
		else
			logdesc('bv ev -thresh:%d',bv_ev_shift)
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
			logdesc('initial ev:%d+%d',self.mval96,self.ev_shift)
			self.ev_target_base = self.ev_target_base + self.mval96
		end
	end

	-- shift by % of over or under initial value
	local bv_ev_shift = self:calc_bv_ev_shift()

	log:set{bv_ev_shift=bv_ev_shift}

	-- adjust target for this shot
	self.ev_target = self.ev_target_base + bv_ev_shift
	log:set{meter96_tgt=self.ev_target}

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
			logdesc("over prio meter %d-%d",meter_weight,prio_mod)
			meter_weight = meter_weight - prio_mod
			if meter_weight < 0 then
				meter_weight = 0
			end
		end
		-- under exposure
		if under_fw then
			logdesc("over prio under %d-%d",under_weight,prio_mod)
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
			logdesc("under prio meter %d-%d",meter_weight,prio_mod)
			meter_weight = meter_weight - prio_mod
			if meter_weight < 0 then
				meter_weight = 0
			end
		end
		-- over exposure
		if over_fw then
			logdesc("under prio over %d-%d",over_weight,prio_mod)
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

	local d_ev_str = stru.imath2str(ev_change)
	log:set{
		d_ev_base=d_ev_str,
		d_ev_s1=d_ev_str, -- set to base, will be overridden if smoothing active
		d_ev_s2=d_ev_str,
		limit_s=0,
		limit_r=0,
	}

	-- smooth out rapid changes with simple exponential smoothing
	-- https://en.wikipedia.org/wiki/Exponential_smoothing
	if self.smooth_factor > 0 then
		local ev_change_smooth = imath.mul(ev_change, (imath.scale - self.smooth_factor)) + imath.mul(last_ev_change, self.smooth_factor)
		log:set{d_ev_s1=stru.imath2str(ev_change_smooth)}
		-- additional limits to reduce smoothing triggering. limit_frac = 1 means smoothed always used
		if self.smooth_limit_frac > 0 then
			if ev_change*ev_change_smooth < 0 -- smoothed and unsmoothed have opposite signs
				or math.abs(ev_change) < math.abs(ev_change_smooth) then -- smoothed has larger magnitude than unsmoothed
				local ev_change_limited = imath.mul(ev_change, self.smooth_limit_frac) + imath.mul(ev_change_smooth, imath.scale - self.smooth_limit_frac)
				--logdesc('smooth limit:%s %s %s',stru.imath2str(ev_change_smooth),stru.imath2str(ev_change),stru.imath2str(ev_change_limited))
				ev_change = ev_change_limited
				log:set{limit_s=1}
			else -- otherwise, use normal smoothing
				ev_change = ev_change_smooth
			end
		else
			ev_change = ev_change_smooth
		end
		log:set{d_ev_s2=stru.imath2str(ev_change)}
	end
	if self.ev_change_rev_frac < imath.scale then
		-- if direction of Ev change changed, reduce by ev_change_rev_frac
		if ev_change * last_ev_change < 0 then
			local ev_change_limited = imath.mul(ev_change,self.ev_change_rev_frac)
			-- logdesc('sign switch: %s %s %s',stru.imath2str(last_ev_change),stru.imath2str(ev_change),stru.imath2str(ev_change_limited))
			log:set{limit_r=1}
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
		logdesc('fw nd_value:%d',self.nd_value)
	else
		logdesc('override nd_value:%d fw:%d',self.nd_value,get_nd_value_ev96())
	end
	self.nd_state = self:get_nd_state()

	self.nd96 = self:nd96_for_state(self.nd_state)
end

-- initialization after initial halfpress ready
function exp:init_preshoot()
	self:init_exposure_params_from_cam()
	self:log_exposure_params()
	log:set{bv96=self.bv96}
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
		logdesc('tv %s != cam %s',tostring(self.tv96),tostring(cam_tv96))
	end
	if self.sv96 ~= cam_sv96 then
		logdesc('sv %s != cam %s',tostring(self.sv96),tostring(cam_sv96))
	end
	if self.av96 ~= cam_av96 then
		logdesc('av %s != cam %s',tostring(self.av96),tostring(cam_av96))
	end
	local cam_nd = self:get_nd_state()
	if self.nd_state ~= cam_nd then
		logdesc('nd %s != cam %s',tostring(self.nd_state),tostring(cam_nd))
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
			logdesc('hook ndfix')
		else
			logdesc('hook ndfix fail')
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
		logdesc('sv prev > sv max')
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
			logdesc('tv over nd:%d',tv96_new - self.tv96_nd_thresh)
			nd_state_new = true
		elseif self.tv96_nd_thresh and nd_state_old and tv96_new > self.tv96_nd_thresh - self.nd_hysteresis then
			logdesc('tv nd hyst:%d',tv96_new - self.tv96_nd_thresh)
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
				logdesc('tv over long:%d',-tv_extra)
			else
				tv_extra = -over/2
				tv96_new = tv96_new - tv_extra
				logdesc('tv iso adj:%d',-tv_extra)
			end
		end

		if tv_extra < 0 then
			sv96_new = sv96_new - tv_extra
		end
		if sv96_new > self.sv96_max then
			local sv_over = sv96_new - self.sv96_max
			logdesc('iso over limit:%d',sv_over)
			-- if ISO range isn't past end of shutter range, put remainder back on shutter
			if tv96_new > self.tv96_long_limit then
				logdesc('iso over tv:%d',tv96_new - self.tv96_long_limit)
				tv96_new = tv96_new - sv_over
				if tv96_new < self.tv96_long_limit then
					tv96_new = self.tv96_long_limit
				end
			end

			sv96_new = self.sv96_max
		end
	else
		if tv96_new < self.tv96_long_limit then
			logdesc('tv over long:%d',self.tv96_long_limit- tv96_new)
			tv96_new = self.tv96_long_limit
		end
	end

	if tv96_new > self.tv96_short_limit then
		logdesc('tv under short:%d',tv96_new)
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
	logdesc('burst start')

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
	log:close()
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

log:init{
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
		'meter_time',
		'histo_time',
		'draw_time',
		'free_mem',
		'lua_mem',
		'sv',
		'sv96',
		'sv96_new',
		'tv',
		'tv96',
		'tv96_new',
		'av',
		'av96',
		'nd',
		'bv96',
		'meter',
		'meter96',
		'meter96_tgt',
		'meter_weight',
		'over_frac',
		'over_weight',
		'under_frac',
		'under_weight',
		'bv_ev_shift',
		'd_ev_base',
		'd_ev_s1',
		'limit_s',
		'd_ev_s2',
		'limit_r',
		'd_ev_f',
		'd_ev',
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
}
--logtime=log:dt_logger('start')
logdesc=log:text_logger('desc')

exp:init{
	meter_width_pct=ui_meter_width_pct,
	meter_height_pct=ui_meter_height_pct,
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
	ev_change_rev_frac=ui_ev_change_rev_frac*imath.scale/10, -- imath 0-1
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
logdesc("contae v:%s",contae_version);
logdesc("platform:%s-%s-%s-%s %s %s",
					bi.platform,bi.platsub,bi.build_number,bi.build_revision,
					bi.build_date,bi.build_time)

-- TODO might want to handle in script
set_exit_key("menu")

kb:handle_startup_shoot()
while true do
	kb:update()
	shootctl:update_drive_mode()
	shootctl:run()
	sleep(10)
end
