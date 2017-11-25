require 'utility'
local uni = require 'ffi.unicode'
local core = require 'core'
local lni = require 'lni-c'

local function get_exepath()
    return fs.path(uni.a2u(package.cpath:sub(1, (package.cpath:find(';') or 0)-6))):remove_filename():remove_filename()
end

local mt = {}

setmetatable(mt, { __index = core })

function mt:initialize(root)
    if self.initialized then
        return
    end
    self.initialized = true
    if not root then
        root = get_exepath()
    end
    self.root = root
    self.template = self.root / 'template'
    self.core = self.root / 'script' / 'core'
    self.meta = self.root / 'script' / 'meta'

    local function loader(path)
        return io.load(self.core / path)
    end
    core:initialize(loader, config)

    local config = lni(assert(io.load(self.root / 'config.ini')), 'config')
    local fmt = config.target_format
    for k, v in pairs(config[fmt]) do
        config[k] = v
    end
    core:set_config(config)
end

return mt
