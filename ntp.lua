ntp = {}
ntp.responseCallback = nil
ntp.lastTs = nil

local function request(cn, ip)
	print("NTP request: ", ip)
	cn:connect(123, ip)
	local request = string.char(0x1B) .. string.rep(0x0,47)
	cn:send(request)
end

local function response(cn, data)
	cn:close()
	local highw = data:byte(41) * 256 + data:byte(42)
	local loww = data:byte(43) * 256 + data:byte(44)
	local timezone = 1
	local ntpstamp = ( highw * 65536 + loww ) + ( timezone * 3600) -- seconds since 1.1.1900
	local ustamp = ntpstamp - 1104494400 - 1104494400 -- seconds since 1.1.1970
	ntp.lastTs = ustamp
	
	print("NTP response: ", ntp)
	
	if ntp.responseCallback ~= nill then
		ntp.responseCallback(ustamp)
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

local function tostring(ntp)
	if ntp.lastTs == nil then
		return "NTP not requested"
	else
		ustamp = ntp.lastTs
		local hour = ustamp % 86400 / 3600
		local minute = ustamp % 3600 / 60
		local second = ustamp % 60
		return string.format("%02u:%02u:%02u", hour, minute, second)
	end
end

local mt = {
	__tostring = tostring
}
setmetatable(ntp, mt)