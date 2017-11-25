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
    self.root = root or get_exepath()
    core:initialize(self.root)
end

return mt
