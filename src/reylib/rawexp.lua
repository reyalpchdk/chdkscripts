--[[
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

--[!inline_start]
-- exposure module. License: GPL
local stru=require'reylib/strutil' --[!inline]
local exp={}

--[[
log columns used with log:set
note logdesc function is also assumed to exist and accept printf text
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
			--logdesc('bv ev limit:%d',bv_ev_shift)
			self:nextlog{bv_ev_l1=bv_ev_shift}
			bv_ev_shift = self.meter_high_limit
		else
			--logdesc('bv ev thresh:%d',bv_ev_shift)
			self:nextlog{bv_ev_l1=bv_ev_shift}
			bv_ev_shift = self.meter_high_thresh + over/2
		end
	elseif bv_ev_shift < self.meter_low_thresh then
		local under = bv_ev_shift - self.meter_low_thresh
		if under < 2*(self.meter_low_limit - self.meter_low_thresh) then
			-- logdesc('bv ev -limit:%d',bv_ev_shift)
			self:nextlog{bv_ev_l1=bv_ev_shift}
			bv_ev_shift = self.meter_low_limit
		else
			-- logdesc('bv ev -thresh:%d',bv_ev_shift)
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
			logdesc('initial ev:%d+%d',self.mval96,self.ev_shift)
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
		logdesc('fw nd_value:%d',self.nd_value)
	else
		logdesc('override nd_value:%d fw:%d',self.nd_value,get_nd_value_ev96())
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
			-- logdesc('hook ndfix')
			log:set{nd_hookfix=1}
		else
			log:set{nd_hookfix=0}
			-- logdesc('hook ndfix fail')
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
			-- logdesc('tv over nd:%d',tv96_new - self.tv96_nd_thresh)
			self:nextlog{nd_tv_tr=tv96_new - self.tv96_nd_thresh}
			nd_state_new = true
		elseif self.tv96_nd_thresh and nd_state_old and tv96_new > self.tv96_nd_thresh - self.nd_hysteresis then
			-- logdesc('tv nd hyst:%d',tv96_new - self.tv96_nd_thresh)
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
				-- logdesc('tv over long:%d',-tv_extra)
				self:nextlog{tv_l1=tv_extra}
			else
				tv_extra = -over/2
				tv96_new = tv96_new - tv_extra
				-- logdesc('tv iso adj:%d',-tv_extra)
				self:nextlog{tv_sv_tr=-tv_extra}
			end
		end

		if tv_extra < 0 then
			sv96_new = sv96_new - tv_extra
		end
		if sv96_new > self.sv96_max then
			local sv_over = sv96_new - self.sv96_max
			-- logdesc('iso over limit:%d',sv_over)
			self:nextlog{sv_l1=sv_over}
			-- if ISO range isn't past end of shutter range, put remainder back on shutter
			if tv96_new > self.tv96_long_limit then
				-- logdesc('iso over tv:%d',tv96_new - self.tv96_long_limit)
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
			-- logdesc('tv over long:%d',self.tv96_long_limit- tv96_new)
			self:nextlog{tv_l1=tv96_new - self.tv96_long_limit}
			tv96_new = self.tv96_long_limit
		end
	end

	if tv96_new > self.tv96_short_limit then
		-- logdesc('tv under short:%d',tv96_new)
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
