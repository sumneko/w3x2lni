return (require 'sandbox')('.\\core\\', io.open, { 
    ['w3xparser'] = require 'w3xparser',
    ['lni-c']     = require 'lni-c',
    ['lpeg']      = require 'lpeg',
    ['lml']       = require 'lml'
})
