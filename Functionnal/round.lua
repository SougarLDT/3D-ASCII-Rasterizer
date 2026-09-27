---@param number number
---@return integer
return function (number)
    local rounded = math.floor(number + 0.5)
    return math.tointeger(rounded)
end