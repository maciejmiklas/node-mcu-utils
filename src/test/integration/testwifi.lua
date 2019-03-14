wifi.mode(wifi.STATION)
wifi.start()
wifi.sta.config({ ssid = 'SOL', pwd = 'lamiglowka' })

local function test()
    con = net.createConnection(net.TCP)
    con:on("receive", function(cn, data)
        print(">> " .. (string.len(data) / 1000) .. "kb, RAM: " .. (node.heap() / 1000) .. "kb")
    end)

    con:on("connection", function(sck, c)
        sck:send("GET /data/2.5/forecast?id=3081368&appid=3afb55b99aafbe3310545e4ced598754&units=metric" ..
                "  HTTP/1.1\r\nHost: api.openweathermap.org\r\nAccept: */*\r\n\r\n")
    end)
    con:connect(80, "api.openweathermap.org")
end

wifi.sta.on("got_ip", test)

