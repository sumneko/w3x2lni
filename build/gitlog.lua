return function()
    local root = fs.current_path() / '..'

    local f = io.popen('git log -n 1', 'r')
    local lines = {}
    for l in f:lines() do
        lines[#lines+1] = l
    end
    local commit = lines[1]:match 'commit[ ]+([0-9|a-f]*)'
    local date = lines[4]:match 'Date:[ ]+([0-9|a-z|A-Z|%+|%:| ]*)'

    local f = io.open((root / 'script' / 'gui' / 'gitlog.lua'):string(), 'w')
    f:write(([[
    return {
        commit = '%s',
        date = '%s',
    }
    ]]):format(commit, date))
    f:close()
end
