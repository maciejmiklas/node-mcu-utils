require "yahooWeather";

sapiYaw = {debug = false}

-- 1 if clock has been synched at least once, 0 otherwise 
function scmd.YIE()
	if yaw.weather == nil then
		uart.write(0, "0\n")
	else 	
		uart.write(0, "1\n")
	end
end

-- seconds since last sync with NTP server
function scmd.YLS()
	uart.write(0, yaw.getLastSyncSec().."\n")
end

-- "scmd.YFx" returns forecast for given param, where x is day: 1 - today, 2 - tommorow, and so on. 
-- Possible params can be found at: yahooWeather.lua -> yaw.weather
function scmd.YF1(param)
	uart.write(0, yaw.weather[1][param].."\n")
end
function scmd.YF2(param)
	uart.write(0, yaw.weather[2][param].."\n")
end
function scmd.YF3(param)
	uart.write(0, yaw.weather[3][param].."\n")
end