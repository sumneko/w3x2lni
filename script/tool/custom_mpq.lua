require 'filesystem'
require 'utility'
local stormlib = require 'ffi.stormlib'
local sleep = require 'ffi.sleep'
local makefile = require 'prebuilt.makefile'
local config = require 'tool.config'
local proto = require 'tool.protocol'
local lang = require 'tool.lang'
local file_version = require 'ffi.file_version'
local w2l
local mpq_name
local root = fs.current_path()

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

local function mpq_language(mpq)
    local config = mpq:load_file 'config.txt'
    if not config then
        return nil
    end
    local id = config:match 'LANGID=(0x[%x]+)'
    if not id then
        return nil
    end
    return language_map[tonumber(id)]
end

local function war3_ver(input)
    local exe_path = input / 'War3.exe'
    if fs.exists(exe_path) then
        local ver = file_version(exe_path:string())
        if ver.major > 1 or ver.minor >= 29 then
            return ('%d.%d.%d'):format(ver.major, ver.minor, ver.revision)
        end
    end
    local dll_path = input / 'Game.dll'
    if fs.exists(dll_path) then
        local ver = file_version(dll_path:string())
        return ('%d.%d.%d'):format(ver.major, ver.minor, ver.revision)
    end
    return nil
end

local function task(f, ...)
    for i = 1, 99 do
        if pcall(f, ...) then
            return true
        end
        sleep(10)
    end
    return false
end

local mpq_names = {
    'War3.mpq',
    'War3x.mpq',
    'War3xLocal.mpq',
    'War3Patch.mpq',
}

local function open_mpq(dir)
    local mpqs = {}

    for i, name in ipairs(mpq_names) do
        mpqs[i] = stormlib.open(dir / name, true)
        mpqs[name] = mpqs[i]
        if mpqs[i] == nil then
            w2l.messager.text(lang.script.OPEN_FILE_FAILED .. (dir / name):string())
            return nil
        end
    end

    return mpqs
end

local result = {} 

local function extract_file(mpq, name)
    local path = fs.current_path():parent_path() / 'data' / 'mpq' / mpq_name / name
    if fs.exists(path) then
        return
    end
    if not mpq:has_file(name) then
        return
    end
    if not fs.exists(path:parent_path()) then
        fs.create_directories(path:parent_path())
    end
    local res = mpq:extract(name, path)
    result[path:string()] = res
end

local function report_fail()
    local tbl = {}
    for name, res in pairs(result) do
        if res == false then
            table.insert(tbl, name)
        end
    end
    table.sort(tbl)
    for _, name in ipairs(tbl) do
        w2l.messager.text(lang.script.EXPORT_FILE_FAILED .. name)
    end
end

local function extract_mpq(mpqs)
    local info = w2l:parse_lni(assert(io.load(fs.current_path() / 'core' / 'info.ini')))
    for i = 4, 1, -1 do
        local mpq = mpqs[i]
        for _, root in ipairs {'', 'Custom_V1\\'} do
            extract_file(mpq, root .. 'Scripts\\Common.j')
            extract_file(mpq, root .. 'Scripts\\Blizzard.j')
            
            extract_file(mpq, root .. 'UI\\MiscData.txt')
            extract_file(mpq, root .. 'UI\\WorldEditStrings.txt')

            extract_file(mpq, root .. 'units\\MiscGame.txt')
            extract_file(mpq, root .. 'units\\MiscData.txt')

            for type, slks in pairs(info.slk) do
                for _, name in ipairs(slks) do
                    extract_file(mpq, root .. name)
                end
            end

            for _, name in ipairs(info.txt) do
                extract_file(mpq, root .. name)
            end
        end
    end
end

return function (_w2l, input)
    w2l = _w2l
    if not fs.is_directory(input) then
        w2l.messager.text(lang.script.NEED_WAR3_DIR)
        return
    end
    local ver = war3_ver(input)
    if not ver then
        w2l.messager.text(lang.script.NEED_WAR3_DIR)
        return
    end
    local mpqs = open_mpq(input)
    if not mpqs then
        return
    end
    local lg = mpq_language(mpqs['War3.mpq'])
    if lg then
        mpq_name = ver .. '-' .. lg
    else
        mpq_name = input:filename():string()
    end
    
    function w2l:mpq_load(filename)
        local mpq_path = root:parent_path() / 'data' / 'mpq'
        return self.mpq_path:each_path(function(path)
            return io.load(mpq_path / path / filename)
        end)
    end

    w2l.progress:start(0.1)
    w2l.messager.text(lang.script.CLEAN_DIR)
    local mpq_path = fs.current_path():parent_path() / 'data' / 'mpq' / mpq_name
    if fs.exists(mpq_path) then
        if not task(fs.remove_all, mpq_path) then
            w2l.messager.text(lang.script.CREATE_DIR_FAILED:format(mpq_path:string()))
            return
        end
    end
    if not fs.exists(mpq_path) then
        if not task(fs.create_directories, mpq_path) then
            w2l.messager.text(lang.script.CREATE_DIR_FAILED:format(mpq_path:string()))
            return
        end
    end
    w2l.progress:finish()

    w2l.progress:start(0.2)
    w2l.messager.text(lang.script.EXPORT_MPQ)
    extract_mpq(mpqs)
    report_fail()
    w2l.progress:finish()

    w2l.progress:start(0.6)
    makefile(w2l, mpq_name, 'Melee', 'Melee')
    w2l.progress:finish()
    w2l.progress:start(1.0)
    makefile(w2l, mpq_name, 'Custom', 'Custom')
    w2l.progress:finish()

    config.mpq = mpq_name

    w2l.messager.text((lang.script.FINISH):format(os.clock())) 
end
