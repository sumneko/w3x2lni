require 'filesystem'
local command = require 'tool.command'
local messager = require 'tool.messager'
local maketemplate = require 'prebuilt.maketemplate'
local core = require 'backend.sandbox_core'
local w2l = core()
local root = fs.current_path()

w2l:set_messager(messager)

function w2l:mpq_load(filename)
    local mpq_path = root:parent_path() / 'data' / 'mpq'
    return self.mpq_path:each_path(function(path)
        return io.load(mpq_path / path / filename)
    end)
end

return function ()
    local mpq = command[2]
    local version = command[3]

    w2l.messager.text(('正在生成template[%s][%s]'):format(mpq, version))
    
    maketemplate(w2l, mpq, version)
end
