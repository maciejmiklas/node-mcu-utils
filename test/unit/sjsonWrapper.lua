--https://github.com/rxi/json.lua
json = require("test/unit/json")
sjson = {}
local sjson_mt = { __index = sjson }

function sjson.decoder()
    local obj = {}
    setmetatable(obj, sjson_mt)
    return obj
end

function sjson:decode(data)
    return json.decode(data)
end

