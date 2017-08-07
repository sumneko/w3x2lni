(function()
    local exepath = package.cpath:sub(1, (package.cpath:find(';') or 0)-6)
    package.path = package.path .. ';' .. exepath .. '..\\script\\?.lua'
end)()

require 'filesystem'
require 'utility'
local w2l  = require 'w3x2lni'
local uni      = require 'ffi.unicode'
local stormlib = require 'ffi.stormlib'
local sleep = require 'ffi.sleep'

w2l:initialize()

function message(...)
    if select(1, ...) == '-progress' then
        return
    end
    local tbl = {...}
    local count = select('#', ...)
    for i = 1, count do
        tbl[i] = uni.u2a(tostring(tbl[i]))
    end
    print(table.concat(tbl, ' '))
end

local function task(f, ...)
    for i = 1, 99 do
        if pcall(f, ...) then
            return
        end
        sleep(10)
    end
    f(...)
end

local mpq_names = {
    'War3.mpq',
    'War3x.mpq',
    'War3xLocal.mpq',
}

local function open_mpq(dir)
    local mpqs = {}

    for i, name in ipairs(mpq_names) do
        mpqs[i] = stormlib.open(dir / name, true)
        if mpqs[i] == nil then
            message('文件打开失败：', (dir / name):string())
            return nil
        end
    end

    return mpqs
end

local result = {} 

local function extract_file(mpq, name, dir)
    if not dir then
        dir = w2l.custom
    end
    local path = dir / name
    if fs.exists(path) then
        return
    end
    fs.create_directories(path:parent_path())
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
        message('文件导出失败：', name)
    end
end

local function extract_mpq(mpqs)
    for i = 3, 1, -1 do
        local mpq = mpqs[i]
        extract_file(mpq, 'Scripts\\Common.j')
        extract_file(mpq, 'Scripts\\Blizzard.j')
        
        extract_file(mpq, 'UI\\MiscData.txt')
        extract_file(mpq, 'UI\\UnitEditorData.txt')
        extract_file(mpq, 'UI\\WorldEditStrings.txt')

        extract_file(mpq, 'Doodads\\Doodads.slk')

        extract_file(mpq, 'units\\MiscGame.txt')
        extract_file(mpq, 'units\\MiscData.txt')
        if i == 1 then
            extract_file(mpq, 'units\\MiscGame.txt', w2l.custom / 'Custom_V1')
            extract_file(mpq, 'units\\MiscData.txt', w2l.custom / 'Custom_V1')
        else
            extract_file(mpq, 'Custom_V1\\units\\MiscGame.txt')
            extract_file(mpq, 'Custom_V1\\units\\MiscData.txt')
        end

        for type, slks in pairs(w2l.info.slk) do
            if type ~= 'doodad' then
                for _, name in ipairs(slks) do
                    extract_file(mpq, name)
                    if i == 1 then
                        extract_file(mpq, name, w2l.custom / 'Custom_V1')
                    else
                        extract_file(mpq, 'Custom_V1\\' .. name)
                    end
                end
            end
        end

        for _, name in ipairs(w2l.info.txt) do
            extract_file(mpq, name)
            if i == 1 then
                extract_file(mpq, name, w2l.custom / 'Custom_V1')
            else
                extract_file(mpq, 'Custom_V1\\' .. name)
            end
        end
    end
end

local function main()
    if not arg[1] then
        message('没有指定目录')
        arg[1] = uni.u2a 'D:\\魔兽争霸III正版镜像'
        --return
    end

    local dir = fs.path(uni.a2u(arg[1]))
    if not fs.is_directory(dir) then
        dir:remove_filename()
    end

    local mpqs = open_mpq(dir)
    if not mpqs then
        return
    end

    if fs.exists(w2l.custom) then
        task(fs.remove_all, w2l.custom)
    end
    task(fs.create_directories, w2l.custom)

    extract_mpq(mpqs)
    report_fail()

    message('[完毕]: 用时 ' .. os.clock() .. ' 秒') 
end

main()
