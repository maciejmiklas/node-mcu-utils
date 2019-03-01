require "openWeatherParser"

local function readFile(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

local jlp = JsonListParserFactory.create()
jlp:registerElementReady(owe_p.onNextDocument)
local data = readFile("test/unit/data/weather.json")
owe_p.onDataStart()
assert(owe_p.hasWeather == false)
jlp:onNextChunk(data)
assert(owe_p.hasWeather == true)

assert("01-29: ^-3.4 !-2.3 clear sky, light snow >> 01-30: ^-5.7 !6.3 clear sky, light snow >> 01-31: ^-6.6 !1.0 clear sky" == owe_p.forecastText)
assert(owe_p.forecast[1].temp == -2.05)


print("END")
