require "jsonListParser"

--https://github.com/rxi/json.lua
json = require("test/unit/json")
sjson = {}
local testCnt = 0;

local sjson_mt = { __index = sjson }

function sjson.decoder()
    local obj = {}
    setmetatable(obj, sjson_mt)
    return obj
end

function sjson:decode(data)
    return json.decode(data)
end

local function readFile(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

local function porcessWeatherPart(doc)
    print("XXXX: ", doc)
end

local function testParseWholeDocumentAtOnce()
    testCnt = testCnt + 1
    local data = readFile("test/unit/data/weather.json")
    local jp = JsonListParserFactory.create("list")
    jp:onElementReady(porcessWeatherPart)
    jp:data(data)
end

local function testParseChunks()
    testCnt = testCnt + 1
    local jp = JsonListParserFactory.create("list")
    jp:onElementReady(porcessWeatherPart)
    jp:data(readFile("test/unit/data/weather_001.json"))
    jp:data(readFile("test/unit/data/weather_002.json"))
    jp:data(readFile("test/unit/data/weather_003.json"))
    jp:data(readFile("test/unit/data/weather_004.json"))
    jp:data(readFile("test/unit/data/weather_005.json"))
    jp:data(readFile("test/unit/data/weather_006.json"))
    jp:data(readFile("test/unit/data/weather_007.json"))
end

--testParseWholeDocumentAtOnce()
testParseChunks()
print("Done - Executed " .. testCnt .. " tests, all OK")
