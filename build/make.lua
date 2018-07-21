require 'filesystem'
local process = require 'process'
local sleep = require 'ffi.sleep'
local uni = require 'unicode'
local minizip = require 'minizip'

local root = fs.absolute(fs.path '..')
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
    local chg = require 'share.changelog'
    return chg[1].version
end

local function create_directory()
    print('正在清空目录：', release_path)
    if fs.exists(release_path) then
        if not task(fs.remove_all, release_path) then
            error(('清空目录失败：%s'):format(release_path))
        end
    end
    fs.create_directories(release_path)
end

local function filter(name)
    name = name:string()
    if name == 'bin\\nuklear.dll' then
        print('屏蔽文件:', name)
        return false
    end
    if name:sub(1, 14) == 'script\\gui\\old' then
        print('屏蔽文件:', name)
        return false
    end
    return true
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
                if filter(name) then
                    f(name / new:filename())
                end
            end
        else
            fs.create_directories((release_path / name):parent_path())
            if filter(name) then
                local suc, err = pcall(fs.copy_file, root / name, release_path / name, true)
                if not suc then
                    error(('复制文件失败：[%s] -> [%s]\n%s'):format(root / name, release_path / name, err))
                end
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
    local application = release_path / 'bin' / 'w3x2lni-lua.exe'
    local entry = release_path / 'test' / 'unit_test.lua'
    local currentdir = release_path / 'script'
    local command_line = ('"%s" "%s"'):format(application:string(), entry:string())
    local p = process()
    p:hide_window()
    copy_files('test')
	local stdout, stderr = p:std_output(), p:std_error()
	if not p:create(application, command_line, currentdir) then
		error('运行失败：\n'..command_line)
    end
    print('正在单元测试...')
    local err = stderr:read 'a'
    local exit_code = p:wait()
    p:close()
    if err ~= '' then
        print(err)
        os.exit(false)
    else
        print('单位测试完成')
    end
    remove_files('test')
end

local function command(...)
    local commands = {...}
    table.insert(commands, 1, (release_path / 'w2l'):string())
    for i, c in ipairs(commands) do
        commands[i] = ('%s'):format(c)
    end
    local command = table.concat(commands, ' ')
    print('正在执行命令:', command)
    io.popen(command):close()
end

local function for_directory(path, func, leaf)
	for file in (leaf and (path / leaf) or path):list_directory() do
		local leaf = (leaf and (leaf / file:filename()) or file:filename())
		if fs.is_directory(file) then
			for_directory(path, func, leaf)
		else
			func(leaf)
		end
	end
end

local function loadfile(filename)
	local f, e = io.open(filename:string(), 'rb')
	if not f then error(e) end
	local content = f:read 'a'
	f:close()
	return content
end

local function zip(dir, zip, filter)
	local z = minizip(zip:string(), 'w')
	for_directory(dir, function(file)
		if not filter or filter(file) then
			z:archive(uni.u2a((dir:filename() / file):string()), loadfile(dir / file))
		end
	end)
	z:close()
end

local function zippack()
    local zip_path = release_path:parent_path() / (release_path:filename():string() .. '.zip')
    fs.remove(zip_path)
    print('正在打包：', zip_path)
    zip(release_path, zip_path)
end

local function make_zhCN()
    print('生成中文版，目录为：', release_path:string())
    create_directory()
    copy_files('bin')
    copy_files('data/zhCN-1.24.4')
    copy_files('script')
    copy_files('config.ini')
    copy_files('w3x2lni.exe')
    copy_files('w2l.exe')
    command('config', 'global.data=zhCN-1.24.4')
    command('config', 'global.data_ui=${YDWE}')
    command('config', 'global.data_meta=${DEFAULT}')
    command('config', 'global.data_wes=${DEFAULT}')
    command('template')
end

local function make_enUS()
    print('生成英文版，目录为：', release_path:string())
    create_directory()
    copy_files('bin')
    copy_files('data/enUS-1.27.1')
    copy_files('script')
    copy_files('config.ini')
    copy_files('w3x2lni.exe')
    copy_files('w2l.exe')
    command('config', 'global.data=enUS-1.27.1')
    command('config', 'global.data_ui=${DATA}')
    command('config', 'global.data_meta=${DATA}')
    command('config', 'global.data_wes=${DATA}')
    command('config', 'slk.slk_doodad=false')
    command('template')
end

local gitlog = require 'gitlog'
gitlog((root / 'script' / 'share' / 'gitlog.lua'):string())

if arg[1] == 'zhCN' then
    release_path = root / 'build' / arg[1] / ('w3x2lni_' .. arg[1] .. '_v'..read_version())
    make_zhCN()
    unit_test()
    zippack()
elseif arg[1] == 'enUS' then
    release_path = root / 'build' / arg[1] / ('w3x2lni_' .. arg[1] .. '_v'..read_version())
    make_enUS()
    unit_test()
    zippack()
    command('config', 'global.lang=enUS')
elseif arg[1] == 'ci' then
    release_path = root / 'build' / 'ci' / 'zhCN'
    make_zhCN()
    unit_test()
    release_path = root / 'build' / 'ci' / 'enUS'
    make_enUS()
    unit_test()
end

print('完成')
