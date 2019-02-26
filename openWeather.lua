-- http://api.openweathermap.org/data/2.5/forecast?id=3081368&appid=3afb55b99aafbe3310545e4ced598754&units=metric
require "wlan";
require "openWeatherParser"
require "log"

owe_net = {
    url = "GET /data/2.5/forecast?id=3081368&appid=3afb55b99aafbe3310545e4ced598754&units=metric",
    server = "api.openweathermap.org",
    port = 80,
    syncPeriodSec = 1200, -- sync weather every 20 minutes
    syncOnErrorPauseSec = 60,
    weather = nil,
    responseCallback = nil,
    lastSyncSec = -1 -- Seconds since last response from weather server.
}
local con
local jlp = JsonListParserFactory.create()
jlp:onElementReady(owe_p.onData)

local function close()
    if con ~= nil then pcall(function() con:close() end) end
    con = nil
end

local function onReceive(cn, data)
    local status, err = pcall(function() jlp:onData(data) end)
    if not status then
        log.error("Receive weather: " .. err .. "->" .. tostring(data))
        owe_net.lastSyncSec = owe_net.syncPeriodSec - owe_net.syncOnErrorPauseSec
        close()
    end
end

local function onConnection(sck, c)
    local get = owe_net.url ..
            "  HTTP/1.1\r\nHost: " .. owe_net.server .. "\r\nAccept: */*\r\n\r\n"

    jlp:reset()
    owe_p.reset()
    sck:send(get)
end

local function requestWeather()
    if log.isInfo then log.info("Request Weather") end
    close()
    con = net.createConnection(net.TCP)
    con:on("receive", onReceive)
    con:on("connection", onConnection)
    con:connect(owe_net.port, owe_net.server)
end

local function onTimer()
    if owe_net.lastSyncSec == -1 or owe_net.lastSyncSec >= owe_net.syncPeriodSec then
        owe_net.lastSyncSec = 0
        wlan.execute(requestWeather)
    end
    owe_net.lastSyncSec = owe_net.lastSyncSec + 1
end

function owe_net.start()
    onTimer()
    local timer = tmr.create()
    timer:register(1000, tmr.ALARM_AUTO, onTimer)
    timer:start()
end