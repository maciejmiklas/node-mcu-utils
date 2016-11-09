require "credentials"
require "wlan"

local function printAbc() 
	print("Wlan Status on connect:", tostring(wlan))
    print("ABC")
end

wlan.setup(cred.ssid, cred.password)

print("Wlan Status on init:", tostring(wlan))
wlan.execute(printAbc)