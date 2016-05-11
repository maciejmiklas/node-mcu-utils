require("wlan")

ntp = {}

function ntp.getTime()
	local cn = net.createConnection(net.UDP, 0)
	cn:dns("pool.ntp.org", ntp.request)
	cn:on("receive", ntp.response)
end

function ntp.request(cn, ip)
	print("Connecting to: ", ip)
	cn:connect(123, ip)
	local request = string.char(0x1B) .. string.rep(0x0,47)
	cn:send(request)
end

function ntp.response(cn, data)
	cn:close()
	print("Got response:", data)
end

wlan.connect("Maciej Miklas’s iPhone", "mysia2pysia", ntp.getTime)

