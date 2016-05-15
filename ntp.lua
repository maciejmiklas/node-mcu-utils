ntp = {}
ntp.responseCallback = nil

local function request(cn, ip)
	print("NTP to: ", ip)
	cn:connect(123, ip)
	local request = string.char(0x1B) .. string.rep(0x0,47)
	cn:send(request)
end

local function msTostring(ustamp) 
	local hour = ustamp % 86400 / 3600
	local minute = ustamp % 3600 / 60
	local second = ustamp % 60
	return string.format("%02u:%02u:%02u", hour, minute, second)
end

local function response(cn, data)
	cn:close()
	print("Got response with "..data:len().." bytes")
	local highw = data:byte(41) * 256 + data:byte(42)
	local loww = data:byte(43) * 256 + data:byte(44)
	local timezone = 1
	local ntpstamp = ( highw * 65536 + loww ) + ( timezone * 3600) -- seconds since 1.1.1900
	local ustamp = ntpstamp - 1104494400 - 1104494400 -- seconds since 1.1.1970
	
	if ntp.responseCallback ~= nill then
		ntp.responseCallback(ustamp)
	else
		print("No callback, NTP resp: "..msTostring(ustamp))
	end	
end

function ntp:registerResponseCallback(responseCallback)
	self.responseCallback = responseCallback;
end

function ntp:requestTime()
	local cn = net.createConnection(net.UDP, 0)
	cn:dns("pool.ntp.org", request)
	cn:on("receive", response)
end