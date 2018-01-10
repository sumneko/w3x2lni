require 'utility'
local uni = require 'ffi.unicode'
local sandbox = require 'sandbox'
local lni = require 'lni-c'

local core = sandbox('core', { 
    ['w3xparser'] = require 'w3xparser',
    ['lni-c']     = require 'lni-c',
    ['lpeg']      = require 'lpeg',
})()

local function get_exepath()
    return fs.path(uni.a2u(package.cpath:sub(1, (package.cpath:find(';') or 0)-6))):remove_filename():remove_filename()
end

local mt = {}

function mt:__index(key)
    local value = mt[key]
    if value then
        return value
    end
    local value = core[key]
    if type(value) == 'function' then
        return function (obj, ...)
            if obj == self then
                obj = core
            end
            return value(obj, ...)
        end
    end
    return value
end

function mt:__newindex(key, value)
    if key == 'mpq_load' or key == 'map_load' or key == 'map_save' or key == 'map_remove' then
        core[key] = value
    else
        rawset(self, key, value)
    end
end

local function initialize(self, root)
    if self.initialized then
        return
    end
    self.initialized = true
    if not root then
        root = get_exepath()
    end
    self.root = root
    self.core     = self.root / 'script' / 'core'
    self.template = self.root / 'template'
    self.meta     = self.root / 'script' / 'meta'
    self.defined  = self.core / 'defined'
    self.info     = lni(assert(io.load(self.core / 'info.ini')), 'info')

    local config = lni(assert(io.load(self.root / 'config.ini')), 'config')
    local fmt = config.target_format
    for k, v in pairs(config[fmt]) do
        config[k] = v
    end
    self:set_config(config)

    function core:mpq_load(filename)
        return core.mpq_path:each_path(function(path)
            return io.load(root / 'data' / 'mpq' / path / filename)
        end)
    end

    function core:prebuilt_load(filename)
        return core.mpq_path:each_path(function(path)
            return io.load(root / 'data' / 'prebuilt' / path / filename)
        end)
    end
end

return function (root)
    local self = setmetatable({}, mt)
    initialize(self, root)
    return self
end
