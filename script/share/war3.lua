local file_version = require 'ffi.file_version'
local stormlib = require 'ffi.stormlib'
local casclib = require 'ffi.casclib'
local config = require 'share.config'
local fs = require 'bee.filesystem'

local language_map = {
    [0x00000409] = 'enUS',
    [0x00000809] = 'enGB',
    [0x0000040c] = 'frFR',
    [0x00000407] = 'deDE',
    [0x0000040a] = 'esES',
    [0x00000410] = 'itIT',
    [0x00000405] = 'csCZ',
    [0x00000419] = 'ruRU',
    [0x00000415] = 'plPL',
    [0x00000416] = 'ptBR',
    [0x00000816] = 'ptPT',
    [0x0000041f] = 'tkTK',
    [0x00000411] = 'jaJA',
    [0x00000412] = 'koKR',
    [0x00000404] = 'zhTW',
    [0x00000804] = 'zhCN',
    [0x0000041e] = 'thTH',
}

local function mpq_language(config)
    if not config then
        return nil
    end
    local id = config:match 'LANGID=(0x[%x]+)'
    if not id then
        return nil
    end
    return language_map[tonumber(id)]
end

local function casc_language(casc)
    local lgs = {}
    for _, lg in pairs(language_map) do
        if casc:has_file('war3.w3mod:_locales\\'..lg..'.w3mod:config.txt') then
            lgs[#lgs+1] = lg
        end
    end
    -- 如果客户端同时支持多个语言，则使用config.ini中定义的语言
    for _, lg in ipairs(lgs) do
        if lg == config.global.lang then
            return lg
        end
    end
    -- 否则随便返回一个语言
    return lgs[1]
end

local function war3_ver (input)
    if not input then
        return nil
    end
    if not fs.is_directory(input) then
        return nil
    end
    local exe_path = input / 'War3.exe'
    if fs.exists(exe_path) then
        local ver = file_version(exe_path:string())
        if ver.major > 1 or ver.minor >= 29 then
            return ('%d.%d.%d'):format(ver.major, ver.minor, ver.revision), ver
        end
    end
    local exe_path = input / 'Warcraft III.exe'
    if fs.exists(exe_path) then
        local ver = file_version(exe_path:string())
        if ver.major > 1 or ver.minor >= 29 then
            return ('%d.%d.%d'):format(ver.major, ver.minor, ver.revision), ver
        end
    end
    local exe_path = input / 'x86_64' / 'Warcraft III.exe'
    if fs.exists(exe_path) then
        local ver = file_version(exe_path:string())
        if ver.major > 1 or ver.minor >= 29 then
            return ('%d.%d.%d'):format(ver.major, ver.minor, ver.revision), ver
        end
    end
    local exe_path = input / '_retail_' / 'x86_64' / 'Warcraft III.exe'
    if fs.exists(exe_path) then
        local ver = file_version(exe_path:string())
        if ver.major > 1 or ver.minor >= 29 then
            return ('%d.%d.%d'):format(ver.major, ver.minor, ver.revision), ver
        end
    end
    local dll_path = input / 'Game.dll'
    if fs.exists(dll_path) then
        local ver = file_version(dll_path:string())
        return ('%d.%d.%d'):format(ver.major, ver.minor, ver.revision), ver
    end
    return nil
end

local m = {}

function m:open(path)
    local verStr, ver = war3_ver(path)
    if not verStr then
        return false
    end
    if ver.major > 1 or ver.minor >= 29 then
        self.casc = casclib.open(path:string())
        local lg = casc_language(self.casc)
        if lg then
            self.casc_paths = {
                'war3.w3mod:_locales\\'..lg..'.w3mod:',
                'war3.w3mod:',
            }
            self.name = lg .. '-' .. verStr
        end
    else
        self.mpqs = {}
        for _, mpqname in ipairs {
            'War3Patch.mpq',
            'War3xLocal.mpq',
            'War3x.mpq',
            'War3Local.mpq',
            'War3.mpq',
        } do
            self.mpqs[#self.mpqs+1] = stormlib.open(path / mpqname, true)
        end
        local lg = mpq_language(self:readfile('config.txt'))
        if lg then
            self.name = lg .. '-' .. verStr
        end
    end
    if ver.major > 1 or ver.minor >= 32 then
        self.reforge = true
    end
    self.ver = ver
    return true
end

function m:close()
    for _, mpq in ipairs(self.mpqs) do
        mpq:close()
    end
    self.mpqs = {}
end

function m:readfile(filename)
    if self.mpqs then
        for _, mpq in ipairs(self.mpqs) do
            if mpq:has_file(filename) then
                return mpq:load_file(filename)
            end
        end
    elseif self.casc then
        for _, path in ipairs(self.casc_paths) do
            local content = self.casc:load_file(path .. filename)
            if content then
                return content
            end
        end
    end
end

function m:extractfile(filename, targetpath)
    if self.mpqs then
        for _, mpq in ipairs(self.mpqs) do
            if mpq:has_file(filename) then
                return mpq:extract(filename, targetpath)
            end
        end
    elseif self.casc then
        for _, path in ipairs(self.casc_paths) do
            local suc = self.casc:extract(path .. filename, targetpath)
            if suc then
                return suc
            end
        end
    end
end


return m
