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
assert(owe_p.hasWeather == false)
jp:data(data)
assert(owe_p.hasWeather == true)


assert("01-29: v-3.4 ˆ-2.3 clear sky, light snow >> 01-30: v-5.7 ˆ6.3 clear sky, light snow >> 01-31: v-6.6 ˆ1.0 clear sky" == owe_p.forecastText)
assert(owe_p.forecast[1].temp == -2.05)


print("END")
