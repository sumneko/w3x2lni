local parser    = require 'parser'
local converter = require 'parser.converter'
local simplify  = require 'parser.simplify'

return function (w2l, archive)
    local common   = archive:get 'common.j'   or archive:get 'scripts\\common.j'   or io.load(w2l.mpq / 'scripts' / 'common.j')
    local blizzard = archive:get 'blizzard.j' or archive:get 'scripts\\blizzard.j' or io.load(w2l.mpq / 'scripts' / 'blizzard.j')
    local war3map  = archive:get 'war3map.j'  or archive:get 'scripts\\war3map.j'
    local ast
    ast = parser(common,   'common.j',   ast)
    ast = parser(blizzard, 'blizzard.j', ast)
    ast = parser(war3map,  'war3map.j',  ast)
    simplify(ast)
    local buf = converter(ast)

    archive:set('scripts\\war3map.j', false)
    archive:set('war3map.j', buf)

    io.save(w2l.root / 'war3map.j', buf)
end
