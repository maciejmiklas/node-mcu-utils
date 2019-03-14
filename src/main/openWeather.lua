-- http://api.openweathermap.org/data/2.5/forecast?id=3081368&appid=3afb55b99aafbe3310545e4ced598754&units=metric
require "wlan";
require "openWeatherParser"
require "log"
require "scheduler"

owe_net = {
    url = "GET /data/2.5/forecast?id=3081368&appid=3afb55b99aafbe3310545e4ced598754&units=metric",
    server = "api.openweathermap.org",
    port = 80,
    syncPeriodSec = 60, -- sync weather every 20 minutes
    syncOnErrorPauseSec = 20,
    weather = nil,
    responseCallback = nil,
    lastSyncSec = -1, -- Seconds since last response from weather server.
    syncToleranceSec = 10
}
local con
local jlp = JsonListParser.new()
jlp:registerElementReady(owe_p.onNextDocument)

function owe_net.status()
    local status = nil
    if owe_net.lastSyncSec == -1 or owe_p.hasWeather == false or owe_p.forecastText == nil then
        status = "WEATHER ERROR"
    elseif owe_net.lastSyncSec - owe_net.syncToleranceSec > owe_net.syncPeriodSec then
        status = "WEATHER OLD"
    end
    return status;
end

local function close()
    if con ~= nil then pcall(function() con:close() end) end
    con = nil
end

local function onReceive(sck, data)
    if log.isDebug then log.debug("OWE frame " .. (string.len(data) / 1000) .. "kb, RAM: " .. (node.heap() / 1000) .. "kb") end
    local status, err = pcall(function() jlp:onNextChunk(data) end)
    if not status then
        log.error("OWE receive: " .. err .. "->" .. tostring(data))
        close()
    end
end

local function onConnection(sck, c)
    local get = owe_net.url ..
            "  HTTP/1.1\r\nHost: " .. owe_net.server .. "\r\nAccept: */*\r\n\r\n"
    jlp:reset()
    owe_p.onDataStart()
    sck:send(get)
end

local function requestWeather()
    close()
    con = net.createConnection(net.TCP)
    con:on("receive", onReceive)
    con:on("connection", onConnection)
    con:connect(owe_net.port, owe_net.server)
end

local function onScheduler()
    wlan.execute(requestWeather)
    owe_net.lastSyncSec = scheduler.uptimeSec()
end

function owe_net.start()
    scheduler.register(onScheduler, "weather", owe_net.syncPeriodSec, owe_net.syncOnErrorPauseSec)
end