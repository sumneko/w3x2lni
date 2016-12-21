require 'sys'
local uni = require 'ffi.unicode'

local srv = {}
srv.message = ''
srv.progress = nil
srv.report = {}

local mt = {}
mt.__index = mt

function mt:update_out()
	if not self.out_rd then
		return
	end
	local n = sys.peek_pipe(self.out_rd)
	if n == 0 then
		return
	end
	local r = self.out_rd:read(n)
	if r then
		self.output = self.output .. r
		return
	end
	self.out_rd:close()
	self.out_rd = nil
end

function mt:update_err()
	if not self.err_rd then
		return
	end
	local n = sys.peek_pipe(self.err_rd)
	if n == 0 then
		return
	end
	local r = self.err_rd:read(n)
	if r then
		self.error = self.error .. r
		return
	end
	self.err_rd:close()
	self.err_rd = nil
end

function mt:update_pipe()
	self:update_out()
	self:update_err()
	if not self.process:is_running() then
		self.output = self.output .. self.out_rd:read '*a'
		self.error = self.error .. self.err_rd:read '*a'
		self.process:close()
		return true
	end
	return false
end

function mt:update_message(pos)
	local msg = self.output:sub(1, pos):gsub("^%s*(.-)%s*$", "%1"):gsub('[^\r\n]+[\r\n]*', function(str)
		if str:sub(1, 1) == '-' then
			local key, value = str:match('%-(%S+)%s(.+)')
			if key then
				if key == 'progress' then
					srv.progress = value
				elseif key == 'report' then
					table.insert(srv.report, value)
				end
				return ''
			end
		end
	end)
	if #msg > 0 then
		srv.message = msg
		if debug then
			io.stdout:write(uni.u2a(msg) .. '\n')
			io.stdout:flush()
		end
	end
	self.output = self.output:sub(pos+1)
end

function mt:update()
	if not self.closed then
		self.closed = self:update_pipe()
	end
	if #self.output > 0 then
		local pos = self.output:find('\n')
		if pos then
			self:update_message(pos)
		end
	end
	if #self.error > 0 then
		io.stdout:write(self.error)
		io.stdout:flush()
		self.error = ''
	end
	if self.closed then
		while true do
			local pos = self.output:find('\n')
			if not pos then
				break
			end
			self:update_message(pos)
		end
		self:update_message(-1)
		return true
	end
	return false
end

function srv.popen(commandline)		
	local in_rd,  in_wr  = sys.open_pipe()
	local out_rd, out_wr = sys.open_pipe()
	local err_rd, err_wr = sys.open_pipe()
	local p = sys.process()
	p:hide_window()
	p:redirect(in_rd, out_wr, err_wr)
	if not p:create(nil, commandline, nil) then
		return nil
	end	
	in_rd:close()
	out_wr:close()
	err_wr:close()
	return p, out_rd, err_rd, in_wr
end

function srv.async_popen(commandline)
	local process, out_rd, err_rd, in_wr = srv.popen(commandline)
	in_wr:close()
	return setmetatable({
		process = process,
		out_rd = out_rd, 
		err_rd = err_rd,
		output = '',
		error = '',
	}, mt)
end

return srv
