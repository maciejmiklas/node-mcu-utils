wlan = {ssid="SSID not set", debug = false, timerId = 0}

function wlan.setup(ssid, password)
	wlan.ssid = ssid
	wlan.password = password
	wifi.setmode(wifi.STATION)
	wifi.sta.config(wlan.ssid, wlan.password)
	wifi.sta.autoconnect(1)
end

function wlan.execute(callback)
	if wifi.sta.status() == 5 and wifi.sta.getip() ~= nil then
		if wlan.debug then print("WiFi already connected") end
		callback()
		return
	end

	if wlan.debug then print("Connecting to WiFi...") end
	wifi.sta.connect()

	tmr.alarm(wlan.timerId, 1000, tmr.ALARM_AUTO, function()
		local status = wifi.sta.status()
		local ip = wifi.sta.getip();
		if wlan.debug then print("WiFi status:", status, "IP:", ip) end
		if status == 5 and ip ~= nil then
			tmr.stop(wlan.timerId)
			callback()
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
