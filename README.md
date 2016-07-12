This project contains a few utilities for NodeMcu based on ESP8266.

# Date Format
Provides functionality to get local date and time from timestamp given in seconds since 1970.01.01

For such code:
``` lua
collectgarbage() print("heap before", node.heap())

require "dateformatEurope";
local ts = 1463145687
df.setEuropeTime(ts, 3600) -- function requires GMT offset for your city

print(string.format("%04u-%02u-%02u %02u:%02u:%02d", 
    df.year, df.month, df.day, df.hour, df.min, df.sec))
print("DayOfWeek: ", df.dayOfWeek)

collectgarbage() print("heap after", node.heap())
```

you will get this output:
``` bash
heap before 44704
2016-05-13 15:21:27
DayOfWeek:  6
heap after  39280
```

# Wi-FI access
It's simple facade for connecting to Wi-Fi. You have to provide connection credentials and function that will be executed after the connection has been established.

``` lua
require "wlan"

wlan.debug = true

local function printAbc() 
    print("ABC")
end

wlan.connect("free wlan", "12345678", printAbc)
```

``` bash
Configuring Wi-Fi on:   free wlan
status  1
status  1
status  5
Got Wi-Fi connection:   172.20.10.6 255.255.255.240 172.20.10.1
ABC
```

# NTP Time
This simple facade connects to given NTP server, request UTC time from it and once response has been received it calls given function. 

Example below executes following chain: WLAN -> NTP -> Date Format. 
So in the fist step we are creating WLAN connection and registering callback function that will be executed after connection has been established. This callback function requests time from NTP server (*ntp.requestTime*). 
On the *ntp* object we are registering another function that will get called after NTP response has been received: *printTime(ts)*.

``` lua
collectgarbage() print("RAM init", node.heap())

require "wlan"
require "ntp"
require "dateformatEurope";

collectgarbage() print("RAM after require", node.heap())

ntp = NtpFactory:fromDefaultServer():withDebug()
wlan.debug = true

local function printTime(ts) 
    collectgarbage() print("RAM before printTime", node.heap())
    
    df.setEuropeTime(ts, 3600)
    
    print("NTP Local Time:", string.format("%04u-%02u-%02u %02u:%02u:%02d", 
        df.year, df.month, df.day, df.hour, df.min, df.sec))
    print("Summer Time:", df.summerTime)
    print("Day of Week:", df.dayOfWeek)
    
    collectgarbage() print("RAM after printTime", node.heap())
end

ntp:registerResponseCallback(printTime)

wlan.connect("free wlan", "12345678", function() ntp:requestTime() end)

collectgarbage() print("RAM callbacks", node.heap())
```

and console output:

``` bash
RAM init    43328
RAM after require   30920
Configuring Wi-Fi on:   free wlan
RAM callbacks   30688
status  1
status  1
status  5
Got Wi-Fi connection:   172.20.10.6 255.255.255.240 172.20.10.1
NTP request:    pool.ntp.org
NTP request:    194.29.130.252
NTP response:   11:59:34
RAM before printTime    31120
NTP Local Time: 2016-07-12 13:59:34
Summer Time:    true
Day of Week:    3
RAM after printTime 30928
```
