wlan = {ssid="SSID not set"}
wlan.debug = false

function wlan.connect(ssid, password, callback)
	if wlan.debug then print("Configuring Wi-Fi on: ", ssid) end
	wlan.ssid = ssid
	wifi.setmode(wifi.STATION)
	wifi.sta.config(ssid, password)
	wifi.sta.autoconnect(1)
	wifi.sta.connect()

	tmr.alarm(0, 1000, tmr.ALARM_AUTO, function()
			local status = wifi.sta.status()
			if wlan.debug then print("status", status) end
			if(status == 5) then
				if wlan.debug then print("Got Wi-Fi connection: ", wifi.sta.getip()) end
				tmr.stop(0)
				callback()
			end
		end)
end

function wlan.listAPs()
	print("Wi-Fi list")
	wifi.sta.getap(function (t)
		for k,v in pairs(t) do
			print(k, v)
		end
	end)
end

local function tostring(wlan)
	return "SSID: "..wlan.ssid..", status: "..wifi.sta.status()
end

local mt = {
	__tostring = tostring
}
setmetatable(wlan, mt)