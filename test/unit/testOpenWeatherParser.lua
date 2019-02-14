require "openWeatherParser"
require "test/unit/sjsonWrapper"

local function readFile(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

local jp = JsonListParserFactory.create()
jp:onElementReady(owe_p.onData)
local data = readFile("test/unit/data/weather.json")

owe_p.onDataStart()
jp:data(data)
owe_p.onDataEnd()

print("END")
