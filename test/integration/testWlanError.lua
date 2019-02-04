require "credentials"
require "wlan"

local function printAbc() 
  print("ABC", abc.xyz) -- nil operation 
end

wlan.setup(cred.ssid, cred.password)
wlan.execute(printAbc)