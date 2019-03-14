NtpFactory = {}

local ntp = {
    responseCallback = nil,
    server = nil,
    cn = nil
}

local mt = { __index = ntp }

function NtpFactory:fromDefaultServer()
    return self:fromServer("pool.ntp.org")
end

-- creates NTP instance from DNS server name
function NtpFactory:fromServer(server)
    local obj = {}
    setmetatable(obj, mt)
    obj.server = server
    return obj
end

function ntp:dnsResponse(_, ip)
    if ip == nil then
        return
    end
    local request = string.char(0x1B) .. string.rep(0x0, 47)
    self.cn:send(123, ip, request)
end

function ntp:response(_, data)
    self.cn = nil
    local highw = data:byte(41) * 256 + data:byte(42)
    local loww = data:byte(43) * 256 + data:byte(44)
    local timezone = 1
    local ntpstamp = (highw * 65536 + loww) + (timezone * 3600) - 3600 -- seconds since 1.1.1900
    local ustamp = ntpstamp - 1104494400 - 1104494400 -- seconds since 1.1.1970

    if self.responseCallback ~= nill then
        self.responseCallback(ustamp)
    end
    if log.isInfo then log.info("Got time") end
end

-- Registers function that will get called after NTP response has been received.
-- Registered function should take one parameter - it's timestamp since 1970 in seconds.
function ntp:onResponse(responseCallback)
    self.responseCallback = responseCallback;
end

function ntp:requestTime()
    self.cn = net.createConnection(net.UDP)
    self.cn:on("receive", function(cn, data) self:response(cn, data) end)
    self.cn:dns(self.server, function(cn, ip) self:dnsResponse(cn, ip) end)
end
