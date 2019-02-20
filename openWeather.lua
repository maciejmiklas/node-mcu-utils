-- http://api.openweathermap.org/data/2.5/forecast?id=3081368&appid=3afb55b99aafbe3310545e4ced598754&units=metric
require "wlan";
require "openWeatherParser"

owe_net = {
    url = "GET /data/2.5/forecast?id=3081368&appid=3afb55b99aafbe3310545e4ced598754&units=metric",
    server = "api.openweathermap.org",
    port = 80,
    syncPeriodSec = 1200, -- sync weather every 20 minutes
    weather = nil,
    responseCallback = nil,
    lastSyncSec = -1 -- Seconds since last response from weather server.
}
local con
local jp = JsonListParserFactory.create()
jp:onElementReady(owe_p.onData)

local function close()
    if con ~= nil then con:close() end
    con = nil
end

local function onReceive(cn, data)
    jp:data(data)
end

local function onConnection(sck, c)
    local get = owe_net.url ..
            "  HTTP/1.1\r\nHost: " .. owe_net.server .. "\r\nAccept: */*\r\n\r\n"
    sck:send(get)
end

local function requestWeather()
    close()
    con = net.createConnection(net.TCP)
    con:on("receive", onReceive)
    con:on("connection", onConnection)
    con:connect(owe_net.port, owe_net.server)
    owe_p.onDataStart()
end

local function onTimer()
    wlan.execute(requestWeather)
end

function owe_net.start()
    onTimer()

    local timer = tmr.create()
    timer:register(owe_net.syncPeriodSec * 1000, tmr.ALARM_AUTO, onTimer)
    timer:start()
end