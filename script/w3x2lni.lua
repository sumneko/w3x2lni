require 'utility'
local uni = require 'ffi.unicode'
local core = require 'core'

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
    self.template = 'template'
    self.defined = 'script\\core\\meta\\defined'

    local function loader(path)
        return io.load(root / path)
    end

    core:initialize(loader)
end

return mt
