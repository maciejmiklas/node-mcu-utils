-- http://api.openweathermap.org/data/2.5/forecast?id=3081368&appid=3afb55b99aafbe3310545e4ced598754&units=metric
require "wlan";
owe = {
  url = "GET /data/2.5/weather?id=3081368&appid=3afb55b99aafbe3310545e4ced598754&units=metric",
  server = "api.openweathermap.org",
  port = 80,
  timerId = 2,
  syncPeriodSec = 1200, -- sync weather every 20 minutes
  weather = nil,
  responseCallback = nil
}
local con
local buf

local stats = {
  yahooReqTime = -1,-- time in sec of last response from DNS server and request to yahoo
  yahooRespTime = -1, -- time in sec of last response from yahoo
  dnsReqTime = -1, -- time in sec of last request to DNS server
  ip = 0 -- ip of yahoo server
}

local function parseWeather(jsonStr)
  local json = cjson.decode(jsonStr)
  local weather = {}
  local day = 1
  local j_channel = json.query.results.channel

  weather[0] = j_channel[1].item.condition

  for _,chel in pairs(j_channel) do
    for _,item in pairs(chel) do
      weather[day] = item.forecast;
      day = day + 1
    end
  end
  return weather;
end

local function findJsonEnd(body)
  local len = string.len(body)
  local sb = string.byte('}')

  -- search for } from end of body, but reduce it to 100 steps
  local steps = len - 100;
  for idx = len, steps, -1 do
    if body:byte(idx) == sb then return idx end
  end
  return -1
end

local function extraactJsonStart(body)
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
  owe.weather = parseWeather(jsonStr)
  if owe.responseCallback ~= nil then
    owe.responseCallback()
  end
end

local function onReceive(cn, body)
  stats.yahooRespTime = tmr.time()

  -- first TCP frame
  if buf == nil then
    local jsonStr, jsonEnd = extraactJsonStart(body)
    if jsonStr == nil then
      return
    end

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
      local jsonEndStr = string.sub(body, 1, jsonEnd)
      local jsonStr = buf .. jsonEndStr;
      close()
      processWeatherJson(jsonStr)
    end
  end
end

local function onConnection(sck, c)
  local get = owe.url1..owe.city..owe.url2..owe.country..owe.url3..
    "  HTTP/1.1\r\nHost: "..owe.server.."\r\nAccept: */*\r\n\r\n"
  sck:send(get)
end

local function onDNSResponse(con, ip)
  if ip == nil then
    stats.ip = 0;
    return
  end
  stats.ip = ip;
  stats.yahooReqTime = tmr.time()
  con:connect(owe.port, ip)
end

local function requestWeather()
  close()
  con = net.createConnection(net.TCP, 0)
  con:on("receive", onReceive)
  con:on("connection", onConnection)
  stats.dnsReqTime = tmr.time()
  con:dns(owe.server, onDNSResponse)
end

local function onTimer()  
  wlan.execute(requestWeather)
end

function owe.start()
  onTimer()
  tmr.alarm(owe.timerId, owe.syncPeriodSec * 1000, tmr.ALARM_AUTO, onTimer)
end

function owe.lastSyncSec()
  local lastSyncSec = -1
  if stats.yahooRespTime ~= -1 then
    lastSyncSec = tmr.time() - stats.yahooRespTime
  end
  return lastSyncSec;
end

--[[
local mt = {}
mt.__tostring = function(owe)
	return string.format("owe->%d,%s,DNS_RQ:%d,Y_RQ:%d,Y_RS:%d", owe.lastSyncSec(), stats.ip, stats.dnsReqTime, 
	   stats.yahooReqTime, stats.yahooRespTime)
end
setmetatable(owe, mt)
--]]
