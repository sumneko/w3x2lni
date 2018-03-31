package.path = package.path .. ';script\\?.lua'

require 'filesystem'
local process = require 'process'
local sleep = require 'ffi.sleep'
local uni = require 'ffi.unicode'

local root = fs.path(arg[1])
local release_path

local function task(f, ...)
    for i = 1, 99 do
        if pcall(f, ...) then
            return true
        end
        sleep(10)
    end
    return false
end

local ignore = {}
for _, name in ipairs {'.vscode', '.git', '.svn', '.gitignore', '.gitmodules'} do
    ignore[name] = true
end

local function read_version()
    local chg = require 'script.gui.changelog'
    return chg[1].version
end

local function create_directory()
    print('正在清空目录：', release_path)
    if fs.exists(release_path) then
        if not task(fs.remove_all, release_path) then
            error(('清空目录失败：%s'):format(release_path))
        end
    end
    fs.create_directory(release_path)
end

local function copy_files(input)
    print('正在复制文件：', input)
    local function f (name)
        local filename = (root / name):filename():string()
        if ignore[filename] then
            return
        end
        if fs.is_directory(root / name) then
            for new in (root / name):list_directory() do
                f(name / new:filename())
            end
        else
            fs.create_directories((release_path / name):parent_path())
            local suc, err = pcall(fs.copy_file, root / name, release_path / name, true)
            if not suc then
                error(('复制文件失败：[%s] -> [%s]\n%s'):format(root / name, release_path / name, err))
            end
        end
    end
    f(fs.path(input))
end

local function remove_files(input)
    print('正在删除文件：', input)
    if fs.exists(release_path / input) then
        if not task(fs.remove_all, release_path / input) then
            error(('清空目录失败：%s'):format(release_path / input))
        end
    end
end

local function unit_test()
    local application = release_path / 'bin' / 'w2l-worker.exe'
    local entry = release_path / 'test' / 'unit_test.lua'
    local currentdir = release_path / 'script'
    local command_line = ('"%s" "%s"'):format(application:string(), entry:string())
    local p = process()
	p:hide_window()
	local stdout, stderr = p:std_output(), p:std_error()
	if not p:create(application, command_line, currentdir) then
		error('运行失败：\n'..command_line)
    end
    while true do
        local out = stdout:read 'l'
        if out then
            print(uni.a2u(out))
        else
            break
        end
    end
    local err = stderr:read 'a'
    local exit_code = p:wait()
    p:close()
    if err ~= '' then
        print(err)
    end
end

local version = read_version()
release_path = root / ('w3x2lni_v'..version)
create_directory()
copy_files('bin')
copy_files('data')
copy_files('script')
copy_files('template')
copy_files('config.ini')
copy_files('w3x2lni.exe')

copy_files('test')
unit_test()
remove_files('test')

print('完成')
