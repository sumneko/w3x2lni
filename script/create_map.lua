local stormlib = require 'ffi.stormlib'
local progress = require 'progress'

local mt = {}
mt.__index = mt

function mt:add(name, buf)
    if self.info.pack.packignore[name] then
        return
    end
    self.files[#self.files+1] = {name, buf}
    if not self.info.pack.impignore[name] then
        self.imp[#self.imp+1] = name
    end
end

function mt:save(map_path)
    local hexs = {}

    hexs[#hexs+1] = ('c4'):pack('HM3W')
    hexs[#hexs+1] = ('c4'):pack('\0\0\0\0')
    hexs[#hexs+1] = ('z'):pack(w3i and w3i.map_name or '未命名地图')
    hexs[#hexs+1] = ('l'):pack(w3i and w3i.map_flag or 0)
    hexs[#hexs+1] = ('l'):pack(w3i and w3i.player_count or 233)

    io.save(map_path, table.concat(hexs))
    local map = stormlib.create(map_path, #self.files + 8)

    progress:target(100)
    local clock = os.clock()
    for i, data in ipairs(self.files) do
        map:save_file(data[1], data[2])
		if os.clock() - clock >= 0.1 then
            clock = os.clock()
            progress(i / #self.files)
            message(('正在打包文件... (%d/%d)'):format(i, #self.files))
		end
    end

    local imp = {}
    imp[#imp+1] = ('ll'):pack(1, #self.imp)
    for _, name in ipairs(self.imp) do
        imp[#imp+1] = ('z'):pack(name)
    end
    
    map:save_file('war3map.imp', table.concat(imp, '\r'))
    map:close()
end

return function(w3i, info)
    return setmetatable({ info = info, imp = {}, files = {} }, mt)
end
