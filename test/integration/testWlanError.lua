require "credentials"
require "wlan"

local function printAbc() 
	print("Wlan Status on connect:", tostring(wlan))
    print("ABC", abc.xyz) -- nil operation 
end

wlan.setup(cred.ssid, cred.password)
wlan.execute(printAbc)
tmr.alarm(2, 5000, tmr.ALARM_AUTO, function() print("Wlan Status:", tostring(wlan)) end) 