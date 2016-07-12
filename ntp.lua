NtpFactory = {}

local ntp = {
	responseCallback = nil,
	lastTs = nil,
	debug = false,
	server = nil
}

local mt = {__index = ntp}

function NtpFactory:fromDefaultServer()
	return self:fromServer("pool.ntp.org")
end

-- enables debug for all NTP instances
function ntp:withDebug()
	ntp.debug = true
	return self
end

-- creates NTP instance from DNS server name
function NtpFactory:fromServer(server)
	obj = {}
	setmetatable(obj, mt)
	obj.server = server
	return obj
end

local function request(cn, ip)
	if ntp.debug then print("NTP request: ", ip) end
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
	self.lastTs = ustamp
	
	if ntp.debug then print("NTP response: ", self) end
	
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
	if ntp.debug then print("NTP request: ", self.server) end

	local cn = net.createConnection(net.UDP, 0)
	cn:dns(self.server, request)
	cn:on("receive", function(cn, data) self:response(cn, data) end)
end

mt.__tostring = function(ntp)
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