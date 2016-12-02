require 'sys'

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

function mt:update()
	self:update_out()
	self:update_err()
	if not self.process:is_running() then
		self.process:close()
		return true
	end
	return false
end

function sys.popen(commandline)		
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

function sys.async_popen(commandline)
	local process, out_rd, err_rd, in_wr = sys.popen(commandline)
	in_wr:close()
	return setmetatable({
		process = process,
		out_rd = out_rd, 
		err_rd = err_rd,
		output = '',
		error = ''
	}, mt)
end
