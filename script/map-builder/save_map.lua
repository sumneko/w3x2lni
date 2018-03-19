local w3xparser = require 'w3xparser'

local function search_staticfile(map, files, searched)
    for _, name in ipairs {'(listfile)', '(signature)', '(attributes)'} do
        searched[name] = map:has(name)
        files[name] = map:get(name)
    end
end

local function search_listfile(map, files, searched)
    local buf = map:get '(listfile)'
    if buf then
        for name in buf:gmatch '[^\r\n]+' do
            files[name] = map:get(name)
            searched[name] = map:has(name)
        end
    end
end

local function search_imp(map, files, searched)
    local buf = map:get 'war3map.imp'
    if buf then
        local _, count, index = ('ll'):unpack(buf)
        local name
        for i = 1, count do
            _, name, index = ('c1z'):unpack(buf, index)
            files[name] = map:get(name)
            searched[name] = map:has(name)
            if not map:has(name) then
                local name = 'war3mapimported\\' .. name
                files[name] = map:get(name)
                searched[name] = map:has(name)
            end
        end
    end
end

local searchers = {
    search_listfile,
    search_staticfile,
    search_imp,
}

local function search_mpq(files, map, progress)
    local total = map:number_of_files()
    local count = 0
    local clock = os.clock()
    local mark = {}
    local searched = setmetatable({}, {
        __newindex = function (self, name, v)
            if not v then
                return
            end
            name = name:lower():gsub('/', '\\')
            if mark[name] then
                return
            end
            mark[name] = true
            count = count + 1
            if os.clock() - clock > 0.1 then
                clock = os.clock()
                print(('正在搜索文件... (%d/%d)'):format(count, total))
                progress(count / total)
            end
        end
    })
    setmetatable(files, {
        __newindex = function (self, name, v)
            if not v then
                return
            end
            name = name:lower():gsub('/', '\\')
            if mark[name] then
                return
            end
            rawset(self, name, v)
        end
    })
    for i, searcher in ipairs(searchers) do
        pcall(searcher, map, files, searched)
    end

    if count ~= total then
        print('-report|1严重错误', ('还有%d个文件没有读取'):format(total - count))
        print('-tip', '这些文件被丢弃了,请包含完整(listfile)')
        print('-report|1严重错误', ('读取(%d/%d)个文件'):format(count, total))
    end
end

local function scan_dir(dir, callback)
    for path in dir:list_directory() do
        if fs.is_directory(path) then
            scan_dir(path, callback)
        else
            callback(path)
        end
    end
end

local function search_dir(paths, path)
    local len = #path:string()
    scan_dir(path, function(path)
        local name = path:string():sub(len+2):lower()
        paths[name] = path
    end)
end

local function load_files(files, paths, progress)
    local total = 0
    for _ in pairs(paths) do
        total = total + 1
    end
    local clock = os.clock()
    local count = 0
    for name, path in pairs(paths) do
        files[name] = io.load(path)
        count = count + 1
        if os.clock() - clock > 0.1 then
            clock = os.clock()
            print(('正在搜索文件... (%d/%d)'):format(count, total))
            progress(count / total)
        end
    end
end

local function build_imp(w2l, output_ar, imp_buf)
    local impignore = {}
    for _, name in ipairs(w2l.info.pack.impignore) do
        impignore[name] = true
    end
    for _, name in pairs(w2l.info.obj) do
        impignore[name] = true
    end
    for _, name in pairs(w2l.info.lni) do
        impignore[name] = true
    end
    for _, slks in pairs(w2l.info.slk) do
        for _, name in ipairs(slks) do
            impignore[name] = true
        end
    end
    for _, name in ipairs(w2l.info.txt) do
        impignore[name] = true
    end
    local imp = {}
    for name, buf in pairs(output_ar) do
        if buf and not impignore[name] then
            imp[#imp+1] = name
        end
    end
    if imp_buf then
        local imp_lni = w2l:parse_lni(imp_buf, filename)
        for _, name in ipairs(imp_lni.import) do
            local name = name:lower()
            if impignore[name] then
                imp[#imp+1] = name
            end
        end
    end
    table.sort(imp)
    local hex = {}
    hex[1] = ('ll'):pack(1, #imp)
    for _, name in ipairs(imp) do
        hex[#hex+1] = ('z'):pack(name)
    end
    return table.concat(hex, '\r')
end

return function (w2l, output_ar, w3i, input_ar)
    local files = {}
    w2l.progress:start(0.5)
    if input_ar:get_type() == 'mpq' then
        search_mpq(files, input_ar, w2l.progress)
    else
        local paths = {}
        if w2l.input_mode == 'lni' then
            search_dir(paths, input_ar.path / 'map')
            search_dir(paths, input_ar.path / 'resource')
            search_dir(paths, input_ar.path / 'jass')
            search_dir(paths, input_ar.path / 'lua')
            search_dir(paths, input_ar.path / 'sound')
        else
            search_dir(paths, input_ar.path)
        end
        load_files(files, paths, w2l.progress)
    end
    w2l.progress:finish()
    if w2l.config.remove_we_only then
        w2l:file_remove('map', 'war3map.wtg')
        w2l:file_remove('map', 'war3map.wct')
        w2l:file_remove('map', 'war3map.imp')
        w2l:file_remove('map', 'war3map.w3s')
        w2l:file_remove('map', 'war3map.w3r')
        w2l:file_remove('map', 'war3map.w3c')
        w2l:file_remove('map', 'war3mapunits.doo')
    else
        if not w2l:file_load('map', 'war3mapunits.doo') then
            w2l:file_save('map', 'war3mapunits.doo', w2l:create_unitsdoo())
        end
    end
    for name, buf in pairs(files) do
        if not buf then
            goto CONTINUE
        end
        if w2l.config.mdx_squf and name:sub(-4) == '.mdx' then
            buf = w3xparser.mdxopt(buf)
        end
        if name:sub(-4) == '.mdx' or name:sub(-4) == '.mdl' or name:sub(-4) == '.blp' then
            w2l:file_save('resource', name, buf)
        elseif name:sub(-2) == '.j' then
            w2l:file_save('jass', name, buf)
        elseif name:sub(-4) == '.lua' then
            w2l:file_save('lua', name, buf)
        elseif name:sub(-4) == '.mp3' or name:sub(-4) == '.wav' then
            w2l:file_save('sound', name, buf)
        else
            w2l:file_save('map', name, buf)
        end
        ::CONTINUE::
    end
    for _, name in pairs(w2l.info.pack.packignore) do
        w2l:file_remove('map', name)
    end

    if w2l.config.mode == 'lni' then
        if not w2l:file_load('lni', 'imp') and w2l:file_load('map', 'war3map.imp') then
            w2l:file_save('lni', 'imp', w2l:backend_imp(w2l:file_load('map', 'war3map.imp')))
        end
        w2l:file_remove('map', 'war3map.imp')
    else
        if w2l.config.remove_we_only then
            w2l:file_remove('map', 'war3map.imp')
        elseif w2l:file_load('lni', 'imp') then
            w2l:file_save('map', 'war3map.imp', build_imp(w2l, output_ar, w2l:file_load('lni', 'imp')))
        end
    end

    for name, buf in pairs(output_ar) do
        output_ar:set(name, buf)
    end

    input_ar:close()
    w2l.progress:start(1)
    if not output_ar:save(w3i, w2l.progress, w2l.config.remove_we_only) then
        print('创建新地图失败,可能文件被占用了')
    end
    w2l.progress:finish()
    output_ar:close()
end
