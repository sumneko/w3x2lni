local mt = {}

mt.info = {
    name = '本地脚本',
    version = 1.0,
    author = '最萌小汐',
    description = '让obj格式的地图使用本地的lua脚本。'
}

local currentpath = [[
package.path = package.path .. ';%s\?.lua'
]]

local function inject_jass(w2l, name)
    local buf = w2l:file_load('map', name)
    if not buf then
        return
    end
    local _, pos = buf:find('function main takes nothing returns nothing', 1, true)
    local bufs = {}
    bufs[1] = buf:sub(1, pos)
    bufs[2] = '\r\n    call Cheat("exec-lua:lua.currentpath")'
    bufs[3] = buf:sub(pos+1)
    w2l:file_save('map', name, table.concat(bufs))
end

local function reduce_jass(w2l, name)
    local buf = w2l:file_load('map', name)
    if not buf then
        return
    end
    local a, b = buf:find('function main takes nothing returns nothing\r\n    call Cheat("exec-lua:lua.currentpath")', 1, true)
    if not a or not b then
        return
    end
    local bufs = {}
    bufs[1] = buf:sub(1, a-1)
    bufs[2] = 'function main takes nothing returns nothing'
    bufs[3] = buf:sub(b+1)
    w2l:file_save('map', name, table.concat(bufs))
end

function mt:on_complete_data(w2l)
    if w2l.config.mode == 'obj' then
        local file_save = w2l.file_save
        function w2l:file_save(type, name, buf)
            if type == 'scripts' and name ~= 'blizzard.j' and name ~= 'common.j' then
                return
            end
            return file_save(self, type, name, buf)
        end

        w2l:file_save('map', 'lua/currentpath.lua', currentpath:format((input / 'scripts'):string()):gsub('\\', '\\\\'))
        inject_jass(w2l, 'war3map.j')
        inject_jass(w2l, 'scripts/war3map.j')
    end
    
    if w2l.config.mode == 'lni' then
        w2l:file_remove('map', 'lua/currentpath.lua')
        reduce_jass(w2l, 'war3map.j')
        reduce_jass(w2l, 'scripts/war3map.j')
    end
end

return mt
