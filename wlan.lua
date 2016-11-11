wlan = {ssid="SSID not set", timerId = 0}

local timerBusy = false
local callbacks = {}
local stats = {callbackError = 0}
function wlan.setup(ssid, password)
	wlan.ssid = ssid
	wlan.password = password
	wifi.setmode(wifi.STATION)
	wifi.sta.config(wlan.ssid, wlan.password)
	wifi.sta.autoconnect(1)
end

-- this method can be executed multiple times. It will queue all callbacks untill it gets
-- WiFi connection
function wlan.execute(callback)
	if wifi.sta.status() == 5 and wifi.sta.getip() ~= nil then
		local _, err = pcall(callback)
		if err ~= nil then stats.callbackError = err end				
		return
	end

	table.insert(callbacks, callback)
	if timerBusy then
		return
	end
	timerBusy = true

	wifi.sta.connect()

	tmr.alarm(wlan.timerId, 1000, tmr.ALARM_AUTO, function()
		local status = wifi.sta.status()
		local ip = wifi.sta.getip();
		if status == 5 and ip ~= nil then
			tmr.stop(wlan.timerId)
			timerBusy = false
			local clb = table.remove(callbacks)
			while clb ~= nil do
				local _, err = pcall(clb)
				if err ~= nil then stats.callbackError = err end
				clb = table.remove(callbacks)
			end
		end
	end)
end

local mt = {}

mt.__tostring = function(wl)
	return string.format("WiFi->%s,ST:%u,ERR:%s", tostring(wifi.sta.getip()), wifi.sta.status(), stats.callbackError)
end

setmetatable(wlan, mt)
