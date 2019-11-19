//TESH.scrollpos=0
//TESH.alwaysfold=0
function Magic takes nothing returns real
    return 0
endfunction

function Test takes nothing returns nothing
    call BJDebugMsg(R2S(Magic()))
endfunction
