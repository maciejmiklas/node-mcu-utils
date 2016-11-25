-- http://query.yahooapis.com/v1/public/yql?q=select%20item.forecast%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20where%20text%3D%22munic%2C%20de%22)%20and%20u%3D%27c%27%20limit%203&format=json
yaw = {
	url1 = "GET /v1/public/yql?q=select%20item.forecast%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20where%20text%3D%22",
	url2 = "%2C%20",
	url3 = "%22)%20and%20u%3D%27c%27%20limit%203&format=json",
	city = "munic",
	country = "de",
	server = "query.yahooapis.com",
	port = 80,
	timerId = 2,
	syncPeriodSec = 3600, -- sync weather every hour

	-- weather tabel contains forecast for x days
	-- K: day number starting from 1, where 1 is today, 2 tomorrow, and so on.
	-- V: table containing following keys:
	--    low - min temp in celclus
	--    high - max temp in celclus
	--    day - 3 letter day code, like: Tue or Mon
	--    code - https://developer.yahoo.com/weather/documentation.html#codes
	--    date - date in form: 31 Aug 2016
	--    text - description, like: Partly Cloudy, Thunderstorms or Sunny
	-- examples:
	--          - yaw.weather[1].low
	--          - yaw.weather[2].date
	weather = nil,
	responseCallback = nil
}
local con

local stats = {
	yahooReqTime = -1,-- time in sec of last response from DNS server and request to yahoo
	yahooRespTime = -1, -- time in sec of last response from yahoo
	dnsReqTime = -1, -- time in sec of last request to DNS server,
	ip = 0 -- ip of yahoo server
}

local function parseWeather(jsonStr)
	local json = cjson.decode(jsonStr)
	local weather = {}
	local day = 1
	for k,v in pairs(json.query.results.channel) do
		for _,forecast in pairs(v.item) do
			weather[day] = forecast;
			day = day + 1
		end
	end
	return weather;
end

local function findJsonEnd(body)
	local len = string.len(body)
	for idx = len, 1, -1 do
		local char = body:sub(idx, idx)
		if char == '}' then return idx end
	end
	return len
end

local function extraactJson(body)
	local bodyStart = string.find(body, "\n\r", 1)
	local jsonStart = string.find(body, "{", bodyStart)
	local jsonEnd = findJsonEnd(body);
	local jsonStr = string.sub(body, jsonStart, jsonEnd)
	return jsonStr
end

local function onReceive(cn, body)
	stats.yahooRespTime = tmr.time()
	cn:close()
	con = nil
	local jsonStr = extraactJson(body)
	yaw.weather = parseWeather(jsonStr)
	if yaw.responseCallback ~= nil then
		yaw.responseCallback()
	end
end

local function onConnection(sck, c)
	local get = yaw.url1..yaw.city..yaw.url2..yaw.country..yaw.url3..
		"  HTTP/1.1\r\nHost: "..yaw.server.."\r\nAccept: */*\r\n\r\n"
	sck:send(get)
end

local function onDNSResponse(con, ip)
	if ip == nil then
		stats.ip = 0;
		return
	end
	stats.ip = ip;
	stats.yahooReqTime = tmr.time()
	con:connect(yaw.port, ip)
end

local function requestWeather()
	if con ~= nil then con:close() end

	con = net.createConnection(net.TCP, 0)
	con:on("receive", onReceive)
	con:on("connection", onConnection)
	stats.dnsReqTime = tmr.time()
	con:dns(yaw.server, onDNSResponse)
end

local function onTimer()
	wlan.execute(requestWeather)
end

function yaw.start()
	onTimer()
	tmr.alarm(yaw.timerId, yaw.syncPeriodSec * 1000, tmr.ALARM_AUTO, onTimer)
end

local mt = {}

mt.__tostring = function(yaw)
	local lastSyncSec = -1
	if stats.yahooRespTime ~= -1 then
		lastSyncSec = tmr.time() - stats.yahooRespTime
	end
	return string.format("YAW->%d,%s,DNS_RQ:%d,Y_RQ:%d,Y_RS:%d", lastSyncSec, stats.ip, stats.dnsReqTime, stats.yahooReqTime, stats.yahooRespTime)
end

setmetatable(yaw, mt)
