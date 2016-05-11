function wifiConnect()
    print("Connecting to Wi-Fi")
    local status = wifi.sta.status()
    for retry = 1, 20 do
        status = wifi.sta.status()
        if status == 5 then
          print("Already connected")
          return
        end
        tmr.delay(100000)        
    end 
    
    wifi.setmode(wifi.STATION)
    wifi.sta.config("Maciej Miklas’s iPhone","mysia2pysia")
    wifi.sta.connect()
   
    for retry = 1, 20 do
        status = wifi.sta.status()
        if status == 5 then
            break
        end
        tmr.delay(500000)        
    end 
    
    assert(status == 5, "Could not connect: "..status)
    local ip = wifi.sta.getip()
    print("Got Wi-Fi connection:"..ip)
end

function listAPs()
    print("Wi-Fi list")
    wifi.sta.getap(function (t) 
            for k,v in pairs(t) do
                print(k.." : "..v)
            end
        end)
end

function parseTime(conn, data)
   print("Time Response: "..data)
   conn:close()
end

wifiConnect()

--http.get("https://www.vowstar.com/nodemcu/", nil, function(code, data)
--    if (code < 0) then
--      print("HTTP request failed")
--    else
--      print(code, data)
--    end
--  end)

