local function send(type, args)
    local content = ('{type=%q,args=%s}'):format(type, args)
    io.stdout:write(('Content-Length:%d\r\n%s'):format(#content, content))
end

local function recv(s, bytes)
    s.bytes = s.bytes or s.bytes .. bytes and bytes
    if s.length then
        if s.length >= #s.bytes then
            local res = s.bytes:sub(1, s.length)
            s.bytes:sub(s.length + 1)
            s.length = nil
            return res
        end
        return
    end
    local pos = s.bytes:find('\r\n', 1, true)
    if not pos then
        return
    end
    if pos <= 15 or s.bytes:sub(1, 15) ~= 'Content-Length:' then
        return error('Invalid protocol.')
    end
    local length = tonumber(s.bytes:sub(16, pos))
    if not length then
        return error('Invalid protocol.')
    end
    s.length = length + 2
end

return {
    send = send,
    recv = recv,
}
