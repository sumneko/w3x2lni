local w3xparser = require 'w3xparser'

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
    
    for _, name in pairs(w2l.info.pack.packignore) do
        w2l:file_remove('map', name)
    end
    w2l:map_remove('builder.w3x')
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

    for name, buf in pairs(input_ar) do
        if not buf then
            goto CONTINUE
        end
        if w2l.config.mdx_squf and name:sub(-4) == '.mdx' then
            buf = w3xparser.mdxopt(buf)
        end
        local type
        if name:sub(-4) == '.mdx' or name:sub(-4) == '.mdl' or name:sub(-4) == '.blp' then
            type = 'resource'
        elseif name:sub(-2) == '.j' then
            type = 'jass'
        elseif name:sub(-4) == '.lua' then
            type = 'lua'
        elseif name:sub(-4) == '.mp3' or name:sub(-4) == '.wav' then
            type = 'sound'
        else
            type = 'map'
        end
        if w2l.input_mode == 'lni' then
            name = name:sub(#type + 2)
        end
        w2l:file_save(type, name, buf)
        ::CONTINUE::
    end

    input_ar:close()
    if not output_ar:save(w3i, w2l.progress, w2l.config.remove_we_only) then
        print('创建新地图失败,可能文件被占用了')
    end
    output_ar:close()
end
