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

assert("TUE: -3.4 -2.3 clear sky, light snow  WED: -5.7 6.3 clear sky, light snow  THU: -6.6 1.0 clear sky" == owe_p.forecast_text, owe_p.forecast_text)
assert(owe_p.forecast[1].temp == -2.05)


print("END")
