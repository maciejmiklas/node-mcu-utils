-- http://api.openweathermap.org/data/2.5/forecast?id=3081368&appid=3afb55b99aafbe3310545e4ced598754&units=metric
require "wlan";
owe = {
    url = "GET /data/2.5/forecast?id=3081368&appid=3afb55b99aafbe3310545e4ced598754&units=metric",
    server = "api.openweathermap.org",
    port = 80,
    syncPeriodSec = 1200, -- sync weather every 20 minutes
    weather = nil,
    responseCallback = nil,
    lastSyncSec = -1 -- Seconds since last response from weather server.
}
local con
local buf

local function parseWeather(jsonStr)
    local json = cjson.decode(jsonStr)
    local weather = {}
    local day = 1
    local j_channel = json.query.results.channel

    weather[0] = j_channel[1].item.condition

    for _, chel in pairs(j_channel) do
        for _, item in pairs(chel) do
            weather[day] = item.forecast;
            day = day + 1
        end
    end
    return weather;
end

local function findJsonEnd(body)
    local eidx = string.find(body, "}}")
    if eidx == nil then
        return -1
    else
        return eidx
    end
end

local function findtJsonStart(body)
    local jsonStart = string.find(body, "{", 1)
    if jsonStart == nil then return null end

    local jsonEnd = findJsonEnd(body);
    local jsonStr = string.sub(body, jsonStart, jsonEnd)
    return jsonStr, jsonEnd
end

local function close()
    if con ~= nil then con:close() end
    con = nil
    buf = nil
end

local function processWeatherJson(jsonStr)
    -- owe.weather = parseWeather(jsonStr)
    --if owe.responseCallback ~= nil then
    --   owe.responseCallback()
    -- end
    print("####: ", jsonStr)
    print("RAM after", node.heap())
end

local function onReceive(cn, body)

    -- first TCP frame
    if buf == nil then
        local jsonStr, jsonEnd = findtJsonStart(body)
        if jsonStr == nil then
            return
        end
        print("#### A", jsonStr, " - ", jsonEnd)
        -- weather has been received in first TPC frame
        if jsonEnd ~= -1 then
            close()
            processWeatherJson(jsonStr)
        else
            buf = jsonStr;
        end
    else -- buf ~= nil -> followig TCP frame(s)
        local jsonEnd = findJsonEnd(body);
        if jsonEnd == -1 then
            buf = buf .. body;
        else
            print("#### END", body)
            local jsonEndStr = string.sub(body, 1, jsonEnd)
            local jsonStr = buf .. jsonEndStr;
            close()
            processWeatherJson(jsonStr)
        end
    end
end

local function onConnection(sck, c)
    local get = owe.url ..
            "  HTTP/1.1\r\nHost: " .. owe.server .. "\r\nAccept: */*\r\n\r\n"
    sck:send(get)
end

local function onDNSResponse(con, ip)
    if ip == nil then
        return
    end
    con:connect(owe.port, ip)
end

local function requestWeather()
    close()
    con = net.createConnection(net.TCP)
    con:on("receive", onReceive)
    con:on("connection", onConnection)
    --con:dns(owe.server, onDNSResponse)
    con:connect(owe.port, owe.server)
end

local function onTimer()
    wlan.execute(requestWeather)
end

function owe.start()
    onTimer()

    local timer = tmr.create()
    timer:register(owe.syncPeriodSec * 1000, tmr.ALARM_AUTO, onTimer)
    timer:start()
end


-- ############ parser ############
local parser = {
    callback = nil
}

function parser.onReady(callback)
end

function parser.data(data)
end

-- ############ parser ############