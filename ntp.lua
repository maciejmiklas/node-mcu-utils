NtpFactory = {}

local ntp = {
	responseCallback = nil,
	server = nil,
	status = {lastTs = -1, ip = -1, dnsReqTime = -1, ntpReqTime = -1, ntpRespTime = -1}
}

local mt = {__index = ntp}
local cn

function NtpFactory:fromDefaultServer()
	return self:fromServer("pool.ntp.org")
end

-- creates NTP instance from DNS server name
function NtpFactory:fromServer(server)
	obj = {}
	setmetatable(obj, mt)
	obj.server = server
	return obj
end

function ntp:request(cn, ip)
	if ip == nil then
		self.status.ip = 0;
		return
	end
	self.status.ip = ip
	self.status.ntpReqTime = tmr.time()
	cn:connect(123, ip)
	local request = string.char(0x1B) .. string.rep(0x0,47)
	cn:send(request)
end

function ntp:response(cn, data)
	self.status.ntpRespTime = tmr.time()
	cn:close()
	local highw = data:byte(41) * 256 + data:byte(42)
	local loww = data:byte(43) * 256 + data:byte(44)
	local timezone = 1
	local ntpstamp = ( highw * 65536 + loww ) + ( timezone * 3600) - 3600 -- seconds since 1.1.1900
	local ustamp = ntpstamp - 1104494400 - 1104494400 -- seconds since 1.1.1970
	self.status.lastTs = ustamp

	if self.responseCallback ~= nill then
		self.responseCallback(ustamp)
	end
end

-- Registers function that will get called after NTP response has been received.
-- Registered function should take one parameter - it's timestamp since 1970 in seconds.
function ntp:registerResponseCallback(responseCallback)
	self.responseCallback = responseCallback;
end

function ntp:requestTime()
	if cn ~= nil then cn:close() end
	cn = net.createConnection(net.UDP, 0)
	cn:on("receive", function(cn, data) self:response(cn, data) end)
	
	self.status.dnsReqTime = tmr.time()
	cn:dns(self.server, function(cn, ip) self:request(cn, ip) end)
end

--[[
mt.__tostring = function(ntp)
	local ustamp = ntp.status.lastTs
	local hour = ustamp % 86400 / 3600
	local minute = ustamp % 3600 / 60
	local second = ustamp % 60
	return string.format("NTP->%02u:%02u:%02u,%s,DNS_RQ:%d,NTP_RQ:%d,NTP_RS:%d", 
		hour, minute, second, ntp.status.ip, ntp.status.dnsReqTime, ntp.status.ntpReqTime, ntp.status.ntpRespTime)
end
--]]