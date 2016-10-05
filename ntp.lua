NtpFactory = {}

local ntp = {
	responseCallback = nil,
	server = nil,
	status = {lastTs = nil, ip = nil}
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
		return
	end
	cn:connect(123, ip)
	local request = string.char(0x1B) .. string.rep(0x0,47)
	cn:send(request)
end

function ntp:response(cn, data)
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
	cn = net.createConnection(net.UDP, 0)
	cn:dns(self.server, function(cn, ip) self:request(cn, ip) end)
	cn:on("receive", function(cn, data) self:response(cn, data) end)
end

mt.__tostring = function(ntp)
	if ntp.lastTs == nil then
		return "..."
	else
		ustamp = ntp.lastTs
		local hour = ustamp % 86400 / 3600
		local minute = ustamp % 3600 / 60
		local second = ustamp % 60
		return string.format("%02u:%02u:%02u", hour, minute, second)
	end
end
