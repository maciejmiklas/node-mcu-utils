wlan = {}
function wlan.connect(sid, password, callback)
	print("Configuring Wi-Fi")

	wifi.setmode(wifi.STATION)
	wifi.sta.config(sid, password)
	wifi.sta.autoconnect(1)
	wifi.sta.connect()

	tmr.alarm(0, 1000, tmr.ALARM_AUTO, function()
			local status = wifi.sta.status()
			print("Wi-Fi status: ", status)
			if(status == 5) then
				print("Got Wi-Fi connection: "..wifi.sta.getip())
				tmr.stop(0)
				callback()
			end
		end)
end

function wlan.APs()
	print("Wi-Fi list")
	wifi.sta.getap(function (t)
		for k,v in pairs(t) do
			print(k, v)
		end
	end)
end