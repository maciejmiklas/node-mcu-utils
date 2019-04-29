require "credentials"
require "wlan"

local function printAbc() 
	print("Wlan Status on execute:", tostring(wifi.sta.IP))
  print("ABC")
end

wlan.setup(cred.ssid, cred.password)
print("Wlan Status on init:", tostring(wifi.sta.IP))
wlan.execute(printAbc)