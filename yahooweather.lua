-- http://query.yahooapis.com/v1/public/yql?q=select%20item.forecast%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20where%20text%3D%22munic%2C%20de%22)%20and%20u%3D%27c%27%20limit%203&format=json
yaw = {
	url1 = "GET /v1/public/yql?q=select%20item.forecast%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20where%20text%3D%22",
	url2 = "%2C%20",
	url3 = "%22)%20and%20u%3D%27c%27%20limit%203&format=json",
	city = "munic",
	country = "de",
	host = "query.yahooapis.com",
	debug = false,
	timerId = 2,
	
	-- weather tabel contains forecast for x days
	-- K: day number starting from 1, where 1 is today, 2 tomorrow, and so on.
	-- V: table containing following keys:
	--    low - min temp in celclus
	--    high - max temp in celclus
	--    day - 3 letter day code, like: Tue or Mon
	--    code - https://developer.yahoo.com/weather/documentation.html#codes
	--    date - date in form: 31 Aug 2016
	--    text - description, like: Partly Cloudy, Thunderstorms or Sunny
	weather = nil
}

local client

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

local function parseBody(body)
	local bodyStart = string.find(body, "\n\r", 1)
	local jsonStart = string.find(body, "{", bodyStart)
	local len = string.len(body)
	local jsonStr = string.sub(body, jsonStart, len)
	if yaw.debug then print("Json: ", jsonStr) end
	return jsonStr
end

local function onReceive(cn, body)
	cn:close()
	if yaw.debug then print("Weather response: ", body) end
	local jsonStr = parseBody(body)
	yaw.weather = parseWeather(jsonStr)
end

local function onConnection(sck, c)	
	local get = yaw.url1..yaw.city..yaw.url2..yaw.country..yaw.url3.."  HTTP/1.1\r\nHost: "..yaw.host.."\r\nAccept: */*\r\n\r\n"
	if yaw.debug then print("Weather request: ", get) end
	sck:send(get)
end

function yaw.start()
	client = net.createConnection(net.TCP, 0)
	client:on("receive", onReceive)
	client:on("connection", onConnection)
	client:connect(80, "98.137.200.255")	
end
