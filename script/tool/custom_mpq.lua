require 'filesystem'
require 'utility'
local stormlib = require 'ffi.stormlib'
local sleep = require 'ffi.sleep'
local makefile = require 'prebuilt.makefile'
local config = require 'tool.config'
local proto = require 'tool.protocol'
local w2l
local mpq_name
local root = fs.current_path()

local function print(...)
    w2l.messager.text(...)
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
        if mpqs[i] == nil then
            print('文件打开失败：', (dir / name):string())
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
        print('文件导出失败：', name)
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
    if not fs.is_directory(input) then
        print('请使用魔兽目录')
        return
    end

    local mpqs = open_mpq(input)
    if not mpqs then
        return
    end
    w2l = _w2l
    mpq_name = input:filename()
    
    function w2l:mpq_load(filename)
        local mpq_path = root:parent_path() / 'data' / 'mpq'
        return self.mpq_path:each_path(function(path)
            return io.load(mpq_path / path / filename)
        end)
    end

    w2l.progress:start(0.1)
    print('清理目录...')
    local mpq_path = fs.current_path():parent_path() / 'data' / 'mpq' / mpq_name
    if fs.exists(mpq_path) then
        if not task(fs.remove_all, mpq_path) then
            print(('无法清空目录[%s]，请检查目录是否被占用。'):format(mpq_path:string()))
            return
        end
    end
    if not fs.exists(mpq_path) then
        if not task(fs.create_directories, mpq_path) then
            print(('无法创建目录[%s]，请检查目录是否被占用。'):format(mpq_path:string()))
            return
        end
    end
    w2l.progress:finish()

    w2l.progress:start(0.2)
    print('导出mpq...')
    extract_mpq(mpqs)
    report_fail()
    w2l.progress:finish()

    w2l.progress:start(0.6)
    makefile(w2l, mpq_name:string(), 'Melee', 'Melee')
    w2l.progress:finish()
    w2l.progress:start(1.0)
    makefile(w2l, mpq_name:string(), 'Custom', 'Custom')
    w2l.progress:finish()

    config.mpq = mpq_name:string()

    print('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end
