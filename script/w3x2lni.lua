require 'utility'
local uni = require 'ffi.unicode'
local sandbox = require 'sandbox'
local lni = require 'lni-c'
local core = sandbox 'core'

local function get_exepath()
    return fs.path(uni.a2u(package.cpath:sub(1, (package.cpath:find(';') or 0)-6))):remove_filename():remove_filename()
end

local mt = {}
setmetatable(mt, mt)

function mt:__index(key)
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

function mt:initialize(root)
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

    local function loader(path)
        return io.load(self.core / path)
    end
    core:initialize(loader, config)

    self.defined  = self.core / core.defined
    self.info     = lni(assert(io.load(self.core / 'info.ini')), 'info')

    local config = lni(assert(io.load(self.root / 'config.ini')), 'config')
    local fmt = config.target_format
    for k, v in pairs(config[fmt]) do
        config[k] = v
    end
    self:set_config(config)
end

function mt:set_config(config)
    core:set_config(config)
    self.mpq = self.core / core.mpq
    self.agent = self.core / core.agent
    self.default = self.core / core.default
end

function mt:__newindex(key, value)
    if type(value) == 'function' and type(core[key]) == 'function' then
        core[key] = value
        return
    end
    rawset(self, key, value)
end

return mt
