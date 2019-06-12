require "date_format_europe"
require "open_weather_parser"


local jlp = JsonListParser.new()
jlp:register_element_ready(owe_p.on_next_document)

for i = 1, 2000 do
    jlp:reset()
    owe_p.on_data_start()
    local src = file.open("weather.json", "r")
    local chunk
    local chunks = 0
    repeat
        chunk = src:read()
        if chunk then
            chunks = chunks + 1
            jlp:on_next_chunk(chunk)
        end
    until chunk == nil
    src:close();

    assert("TUE:-3 -2 clear sky,light snow  WED:-6 6 clear sky3,clear sky4,clear sky5,clear sky6,clear sky7,light snow  THU:-7 1 clear sky" == owe_p.forecast_text, owe_p.forecast_text)
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

    collectgarbage()
    print("RAM(" .. i .. "/" .. chunks .. "): " .. tostring(node.heap() / 1000))
end
print("#### Done ####")
