ntp = {}

function ntp.getTime()
	local cn = net.createConnection(net.UDP, 0)
	cn:dns("pool.ntp.org", ntp.request)
	cn:on("receive", ntp.response)
end

function ntp.request(cn, ip)
	print("NTP to: ", ip)
	cn:connect(123, ip)
	local request = string.char(0x1B) .. string.rep(0x0,47)
	cn:send(request)
end

function ntp.response(cn, data)
	cn:close()
	print("Got response with "..data:len().." bytes")
	local highw = data:byte(41) * 256 + data:byte(42)
	local loww = data:byte(43) * 256 + data:byte(44)
	local timezone = 1
	local ntpstamp = ( highw * 65536 + loww ) + ( timezone * 3600) -- seconds since 1.1.1900
	local ustamp = ntpstamp - 1104494400 - 1104494400 -- seconds since 1.1.1970
	print(ntp.tsToString(ustamp))
end

function ntp.tsToString(ustamp) 
	local hour = ustamp % 86400 / 3600
	local minute = ustamp % 3600 / 60
	local second = ustamp % 60
	return string.format("%02u:%02u:%02u",hour, minute, second)
end

