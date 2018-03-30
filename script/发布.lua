package.path = package.path .. ';script\\?.lua'

require 'filesystem'
local sleep = require 'ffi.sleep'

local root = fs.path(arg[1])

local function task(f, ...)
    for i = 1, 99 do
        if pcall(f, ...) then
            return true
        end
        sleep(10)
    end
    return false
end

local function read_version()
    local chg = require 'script.gui.changelog'
    return chg[1].version
end

local function create_directory(path)
    if fs.exists(path) then
        task(fs.remove_all, path)
    end
    fs.create_directory(path)
end

local function copy_files(path, input)
    local function f (name)
        if fs.is_directory(root / name) then
            for new in (root / name):list_directory() do
                f(name / new:filename())
            end
        else
            fs.create_directories((path / name):parent_path())
            local suc, err = pcall(fs.copy_file, root / name, path / name, true)
            if not suc then
                error(('复制文件失败：[%s] -> [%s]\n'):format(root / name, path / name))
            end
        end
    end
    f(fs.path(input))
end

local version = read_version()
local release_path = root / ('w3x2lni_'..version)
create_directory(release_path)
copy_files(release_path, 'bin')
copy_files(release_path, 'data')
copy_files(release_path, 'plugin/本地脚本.lua')
copy_files(release_path, 'plugin/模型加密.lua')
copy_files(release_path, 'plugin/示例.lua')
copy_files(release_path, 'plugin/资源保护.lua')
copy_files(release_path, 'script/core')
copy_files(release_path, 'script/ffi')
copy_files(release_path, 'script/gui')
copy_files(release_path, 'script/map-builder')
copy_files(release_path, 'script/tool')
copy_files(release_path, 'script/ui-builder')
copy_files(release_path, 'script/main.lua')
copy_files(release_path, 'script/map.lua')
copy_files(release_path, 'script/utility.lua')
copy_files(release_path, 'template')
copy_files(release_path, 'config.ini')
copy_files(release_path, 'w3x2lni.exe')

print('完成')
