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
--[!inline_end]

