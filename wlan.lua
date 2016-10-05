wlan = {ssid="SSID not set", timerId = 0}

local timerBusy = false
local callbacks = {}

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
		callback()
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
				local status, err = pcall(clb)
				clb = table.remove(callbacks)
			end
		end
	end)
end
