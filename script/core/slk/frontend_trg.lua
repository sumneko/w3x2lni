return function (w2l)
    if not w2l.trg then
        local res, err = w2l:trigger_data()
        if not res then
            error(err)
        end
        w2l.trg = res
    end
    return w2l.trg
end
