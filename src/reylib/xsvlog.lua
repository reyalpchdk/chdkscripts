--[[
License: GPL

Copyright 2014-2024 reyalp (at) gmail.com

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
	if not opts.name then
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
function log_methods:write_xsv(data)
	local quoted
	if self.quote_mode then
		quoted = {}
		for i, cell in ipairs(data) do
			table.insert(quoted,self:quote_xsv_cell(cell))
		end
	else
		quoted = data
	end
	self.fh:write(string.format("%s\n",table.concat(quoted,self.delim)))
end
function log_methods:write_data(data)
	if self.buffer_mode == 'table' then
		table.insert(self.lines,data)
		return
	end
	self:prepare_write()
	self:write_xsv(data)
	self:finish_write()
end

function log_methods:flush()
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
			self:write_xsv(data)
		end
		self:finish_write()
		self.lines={}
	end
	-- 'sync' is flushed every line
end

function log_methods:write()
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
--[!inline:module_end]

