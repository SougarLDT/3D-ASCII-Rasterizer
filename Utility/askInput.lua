local askInput = {}
--//Types//--

--//Constants//--

--//Variables//--

--//Methods//--

---@param label string
---@param default number
---@param minimum number?
---@param onFallback fun(default:number)?
---@return number
function askInput.askNumber(label, default, minimum, onFallback)
    io.write(("%s (default : %s) : "):format(label, tostring(default)))
    local value = tonumber(io.read())
    if not value then
        return default
    end
    if minimum and value < minimum then
        if onFallback then onFallback(default) end
        return default
    end
    return value
end

---@param label string
---@param default string?
---@param validator fun(value:string) : boolean, string?
---@return string?
function askInput.askString(label, default, validator)
    io.write(("%s%s : "):format(label, default and (" (default : "..default..")") or ""))
    local value = io.read()
    if value == "" or value == nil then
        return default
    end
    if validator then
        local ok, err = validator(value)
        if not ok then
            print(err or "Invalid value, fallback to default")
            return default
        end
    end
    return value
end


return askInput

