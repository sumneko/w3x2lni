local progress = require 'progress'
local w2l = require 'w3x2lni'
local archive = require 'archive'
w2l:initialize()

local mt = {}
mt.__index = mt

function mt:save_map(output_path)
    local map = archive(output_path, 'w')
    for name, buf in pairs(self.archive) do
        map:set(name, buf)
    end

    progress:target(100)
    map:save(w2l.info, self.slk)
    map:close()
end

function mt:load_file(input)
    self.archive = archive(input)
    if not self.archive then
        return false
    end
    return true
end

function mt:save(input)
    message('正在打开地图...')
    if not self:load_file(input) then
        message('地图打开失败')
        return false
    end
    message('正在读取物编...')
    self.slk = {}
	w2l:frontend(self.archive, self.slk)
    message('正在转换...')
    w2l:backend_processing(self.slk)
    w2l:backend(self.archive, self.slk)

    local output = input:parent_path() / input:stem()
    if w2l.config.target_storage == 'dir' then
        message('正在导出文件...')
        self:save_map(output)
    elseif w2l.config.target_storage == 'map' then
        message('正在打包地图...')
        self:save_map(output:parent_path() / (output:filename():string() .. '_slk.w3x'))
    end
    self.archive:close()
    progress:target(100)
    return true
end

return function ()
    local self = setmetatable({}, mt)
    self.slk = {}
    return self
end
