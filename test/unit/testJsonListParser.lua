require "jsonListParser"

--https://github.com/rxi/json.lua
json = require("test/unit/json")
sjson = {}

local foundCnt = 1
local expectedData = {
    { "2019-01-29 18:00:00", -2.05 },
    { "2019-01-29 21:00:00", -2.27 },
    { "2019-01-30 00:00:00", -3.64 },
    { "2019-01-30 03:00:00", -5.3 },
    { "2019-01-30 06:00:00", -5.7 },
    { "2019-01-30 09:00:00", -3.75 },
    { "2019-01-30 12:00:00", -1.27 },
    { "2019-01-30 15:00:00", -1 },
    { "2019-01-30 18:00:00", -1.89 },
    { "2019-01-30 21:00:00", -2.32 },
    { "2019-01-31 00:00:00", -3.38 },
    { "2019-01-31 03:00:00", -5.03 },
    { "2019-01-31 06:00:00", -6.58 },
    { "2019-01-31 09:00:00", -3.51 },
    { "2019-01-31 12:00:00", 1 },
    { "2019-01-31 15:00:00", 0.58 },
    { "2019-01-31 18:00:00", -3.8 },
    { "2019-01-31 21:00:00", -6.02 },
    { "2019-02-01 00:00:00", -6.52 },
    { "2019-02-01 03:00:00", -7.47 },
    { "2019-02-01 06:00:00", -7.26 },
    { "2019-02-01 09:00:00", -3.44 },
    { "2019-02-01 12:00:00", 2.42 },
    { "2019-02-01 15:00:00", 3.43 },
    { "2019-02-01 18:00:00", 1.14 },
    { "2019-02-01 21:00:00", 2.21 },
    { "2019-02-02 00:00:00", 3.68 },
    { "2019-02-02 03:00:00", 4.72 },
    { "2019-02-02 06:00:00", 5.65 },
    { "2019-02-02 09:00:00", 8.11 },
    { "2019-02-02 12:00:00", 9.12 },
    { "2019-02-02 15:00:00", 8.8 },
    { "2019-02-02 18:00:00", 7.37 },
    { "2019-02-02 21:00:00", 4.26 },
    { "2019-02-03 00:00:00", 1.43 },
    { "2019-02-03 03:00:00", 0.78 },
    { "2019-02-03 06:00:00", 1.32 },
    { "2019-02-03 09:00:00", 2.69 },
    { "2019-02-03 12:00:00", 5.1 },
    { "2019-02-03 15:00:00", 4.05 }
}

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
    if not doc.dt_txt then return end
    local ev = expectedData[foundCnt]
    foundCnt = foundCnt + 1

    assert(doc.dt_txt == ev[1], "Error on " .. foundCnt .. " - " .. ev[1])
    assert(doc.main.temp == ev[2], "Error on " .. foundCnt .. " - " .. ev[2])
end

local function testParseWholeDocumentAtOnce()
    foundCnt = 1
    testCnt = testCnt + 1
    local data = readFile("test/unit/data/weather.json")
    local jp = JsonListParserFactory.create()
    jp:onElementReady(porcessWeatherPart)
    jp:data(data)

    assert(foundCnt == 41, "Found only: " .. foundCnt)
end

local function testParseChunks()
    foundCnt = 1
    testCnt = testCnt + 1
    local jp = JsonListParserFactory.create()
    jp:onElementReady(porcessWeatherPart)
    jp:data(readFile("test/unit/data/weather_001.json"))
    jp:data(readFile("test/unit/data/weather_002.json"))
    jp:data(readFile("test/unit/data/weather_003.json"))
    jp:data(readFile("test/unit/data/weather_004.json"))
    jp:data(readFile("test/unit/data/weather_005.json"))
    jp:data(readFile("test/unit/data/weather_006.json"))
    jp:data(readFile("test/unit/data/weather_007.json"))

    assert(foundCnt == 41, "Found only: " .. foundCnt)
end

testParseWholeDocumentAtOnce()
testParseChunks()
print("Done - Executed " .. testCnt .. " tests, all OK")
