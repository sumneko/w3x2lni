local fs = require 'bee.filesystem'
local msvc = require 'msvc'

return function (platform, target)
    fs.create_directories(target)
    fs.copy_file(msvc.crtpath(platform) / 'msvcp140.dll', target / 'msvcp140.dll', true)
    fs.copy_file(msvc.crtpath(platform) / 'concrt140.dll', target / 'concrt140.dll', true)
    fs.copy_file(msvc.crtpath(platform) / 'vcruntime140.dll', target / 'vcruntime140.dll', true)
    for dll in msvc.ucrtpath(platform):list_directory() do
        fs.copy_file(dll, target / dll:filename(), true)
    end
end
