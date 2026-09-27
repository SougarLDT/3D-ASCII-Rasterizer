local ObjParser = {}
ObjParser.__index = ObjParser
--//Types//--
---@class ObjParser
---@field fileOutput string
---@field vertices Vector3[]
---@field triangles number[]
---@field getVertices fun()
---@field getTriangles fun()
---@field init fun() : ObjParser


--//Modules//--
local vector3 = require('Class.vector3')
--//Constants//--

--//Variables//--

--//Globals//--
ObjParser.MODEL_DIRECTORY = "Ressources"
--//Private Functions//--

--//Methods//--

---@param directory string
---@param path string
---@return boolean,string?
function ObjParser.validateObjPath(path,directory)
    if not path:match("%.obj$") then
        return false, "File must have a .obj extension, fallback to default"
    end
    directory = directory or ObjParser.MODEL_DIRECTORY
    local file = io.open(directory.."/"..path, "r")
    if not file then
        return false, "File not found, fallback to default"
    end
    file:close()
    return true
end

---@param filePath string
---@return ObjParser
function ObjParser.new(filePath)
    local self = setmetatable({},ObjParser)
    local handle = io.open(filePath)
    if not handle then
        error("Invalid file path : "..filePath)
    end
    self.fileOutput = handle:read("a")
    self.vertices = {}
    self.triangles = {}
    handle:close()
    return self
end

---@private
---@param self ObjParser
function ObjParser.init(self)
    self:getTriangles()
    self:getVertices()
    return self
end

---@private
---@param self ObjParser
function ObjParser.getVertices(self)
    local vertexPattern =
    "v%s+([%-]?%d*%.?%d+[eE]?[%-]?%d*)%s+([%-]?%d*%.?%d+[eE]?[%-]?%d*)%s+([%-]?%d*%.?%d+[eE]?[%-]?%d*)"
    local iterator = string.gmatch(self.fileOutput,vertexPattern)
    for x,y,z in iterator do
        table.insert(self.vertices,vector3.new(tonumber(x),tonumber(y),tonumber(z)))
    end
end

---@private
---@param self ObjParser
function ObjParser.getTriangles(self)
    local trianglePattern = "f%s+(%d+)/%S+%s+(%d+)/%S+%s+(%d+)/%S+"
    local iterator = string.gmatch(self.fileOutput,trianglePattern)
    for v1,v2,v3 in iterator do
        table.insert(self.triangles,{tonumber(v1),tonumber(v2),tonumber(v3)})
    end
    assert(#self.triangles > 0, "No faces found, unsupported .obj format?")
end

return ObjParser