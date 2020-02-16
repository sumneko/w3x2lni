local ffi = require 'ffi'
local loaddll = require 'ffi.loaddll'

ffi.cdef[[
    typedef UINT HWND;
    typedef int BOOL;
    
    BOOL ChangeWindowMessageFilterEx( HWND hwnd, UINT message, DWORD action, int pChangeFilterStruct);    
]]

loaddll 'user32.dll'
local user32 = ffi.load('user32')

local wmsg = {}
wmsg.__index = wmsg

function wmsg:send_drop_message(hwnd)
    user32.ChangeWindowMessageFilterEx(hwnd,563,1,0)
    user32.ChangeWindowMessageFilterEx(hwnd,73,1,0)
end