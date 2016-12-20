local progress = require 'progress'
local w2l = require 'w3x2lni'
local archive = require 'archive'
w2l:initialize()

return function (input)
    message('正在打开地图...')
    local slk = {}
    local input_ar = archive(input)
    if not input_ar then
        message('地图打开失败')
        return false
    end
    message('正在读取物编...')
	w2l:frontend(input_ar, slk)
    message('正在转换...')
    w2l:backend_processing(slk)
    w2l:backend(input_ar, slk)

    local output
    if w2l.config.target_storage == 'dir' then
        message('正在导出文件...')
        output = input:parent_path() / input:stem()
    elseif w2l.config.target_storage == 'map' then
        message('正在打包地图...')
        output = input:parent_path() / (input:stem():string() .. '_slk.w3x')
    end
    local output_ar = archive(output, 'w')
    for name, buf in pairs(input_ar) do
        output_ar:set(name, buf)
    end
    progress:target(100)
    output_ar:save(w2l.info, slk)
    output_ar:close()
    input_ar:close()
    progress:target(100)
    return true
end
