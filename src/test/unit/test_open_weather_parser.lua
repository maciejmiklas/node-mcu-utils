require "date_format_europe"
require "open_weather_parser"


local function read_file(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

local jlp = JsonListParser.new()
jlp:register_element_ready(owe_p.on_next_document)
local data = read_file("test/unit/data/weather.json")
owe_p.on_data_start()
assert(owe_p.has_weather == false)
jlp:on_next_chunk(data)
assert(owe_p.has_weather == true)

assert("TUE:-3.0 -2.0 clear sky,light snow  WED:-6.0 6.0 clear sky3,clear sky4,clear sky5,clear sky6,clear sky7,light snow  THU:-7.0 1.0 clear sky" == owe_p.forecast_text, owe_p.forecast_text)
assert(owe_p.forecast[1].temp == -2.05)
assert(owe_p.forecast[1].codes[1] == 9)
assert(owe_p.forecast[1].codes[2] == 2)

assert(owe_p.forecast[2].codes[1] == 3)
assert(owe_p.forecast[2].codes[2] == 2)
assert(owe_p.forecast[2].codes[3] == 1)
assert(owe_p.forecast[2].codes[4] == 3)
assert(owe_p.forecast[2].codes[5] == 6)

assert(owe_p.forecast[3].codes[1] == 9)

assert(owe_p.current.icons == "9,2", tostring(owe_p.current.icons))
assert(owe_p.current.temp == -2, tostring(owe_p.current.temp))

print("END")

