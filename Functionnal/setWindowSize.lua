return function(width,height)
    local handle,err = os.execute(("mode con: cols=%d lines=%d"):format(width,height))
    if not handle then
        warn("Failed to set console window dimensions: " .. tostring(err))
        return
    end
end
