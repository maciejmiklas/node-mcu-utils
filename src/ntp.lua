NtpFactory = {}

local ntp = {
    response_callback = nil,
    server = nil,
    cn = nil
}

local mt = { __index = ntp }

function NtpFactory:from_default_server()
    return self:from_server("pool.ntp.org")
end

-- creates NTP instance from DNS server name
function NtpFactory:from_server(server)
    local obj = {}
    setmetatable(obj, mt)
    obj.server = server
    return obj
end

function ntp:dns_response(ip)
    if log.is_debug then log.debug("NTP DNS response") end
    if ip == nil then
        return
    end
    local request = string.char(0x1B) .. string.rep(0x0, 47)
    self.cn:send(123, ip, request)
end

function ntp:response(data)
    local highw = data:byte(41) * 256 + data:byte(42)
    local loww = data:byte(43) * 256 + data:byte(44)
    local timezone = 1
    local ntpstamp = (highw * 65536 + loww) + (timezone * 3600) - 3600 -- seconds since 1.1.1900
    local ustamp = ntpstamp - 1104494400 - 1104494400 -- seconds since 1.1.1970

    if log.is_info then log.info("NTP time:", ustamp) end

    if self.response_callback ~= nill then
        self.response_callback(ustamp)
    end
end

-- Registers function that will get called after NTP response has been received.
-- Registered function should take one parameter - it's timestamp since 1970 in seconds.
function ntp:register_response_callback(response_callback)
    self.response_callback = response_callback;
end

function ntp:request_time()
    if self.cn == nil then
        self.cn = net.createConnection(net.UDP)
        self.cn:on("receive", function(cn, data) self:response(data) end)
    end
    self.cn:dns(self.server, function(cn, ip) self:dns_response(ip) end)
end
