local DEFAULT_DIMENSION = {
    width = 165,
    height = 40
}
return function()
    local handle, err = io.popen("powershell -NoProfile (Get-Host).UI.RawUI.WindowSize")
    if not handle then
        warn("Failed to retrieve console window dimensions: " .. tostring(err))
        return DEFAULT_DIMENSION
    end
    local dimension = {}
    local result = handle:read("a")
    for measure in string.gmatch(result, "%d+") do
        table.insert(dimension, measure)
    end
    handle:close()
    return {
        width = tonumber(dimension[1]),
        height = tonumber(dimension[2])
    }
end
