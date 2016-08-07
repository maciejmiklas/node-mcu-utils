This project contains a few utilities for NodeMcu based on ESP8266.

# Date Format
Provides functionality to get local date and time from timestamp given in seconds since 1970.01.01

For such code:
``` lua
collectgarbage() print("heap before", node.heap())

require "dateformatEurope"
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

# WiFi access
It's simple facade for connecting to WiFi. You have to provide connection credentials and function that will be executed after the connection has been established.

``` lua
require "wlan"

wlan.debug = true

local function printAbc() 
    print("ABC")
end

wlan.connect("free wlan", "12345678", printAbc)
```

``` bash
Configuring WiFi on:   free wlan
status  1
status  1
status  5
Got WiFi connection:   172.20.10.6 255.255.255.240 172.20.10.1
ABC
```

# NTP Time
This simple facade connects to given NTP server, request UTC time from it and once response has been received it calls given function. 

Example below executes following chain: WiFi -> NTP -> Date Format. 
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
Configuring WiFi on:   free wlan
RAM callbacks   30688
status  1
status  1
status  5
Got WiFi connection:   172.20.10.6 255.255.255.240 172.20.10.1
NTP request:    pool.ntp.org
NTP request:    194.29.130.252
NTP response:   11:59:34
RAM before printTime    31120
NTP Local Time: 2016-07-12 13:59:34
Summer Time:    true
Day of Week:    3
RAM after printTime 30928
```

# Ntp Clock
This script provides functionality to run a clock with precision of one second and to synchronize this clock every few hours with NTP server. 

In the code below we first configure WiFi access. Once the WiFi access has been established it will call *nc.start()*. This function will start Clock that will get synchronized with given NTP server every minute. Now you can access actual UTC time in seconds over this variable *nc.current*. In order to show that it's working we have registered timer that will call *printTime()* every second. This function reads current time as *nc.current* and prints it as local time. 

```lua
collectgarbage() print("RAM init", node.heap())

require "dateformatEurope";
require "ntpClock";
require "wlan";

collectgarbage() print("RAM after require", node.heap())

nc.debug = true
wlan.debug = true

wlan.connect("free wlan", "12345678", function() nc.start("pool.ntp.org", 60) end)

local function printTime() 
    collectgarbage() print("RAM in printTime", node.heap())
    
    df.setEuropeTime(nc.current, 3600)
    
    print("Time:", string.format("%04u-%02u-%02u %02u:%02u:%02d", 
        df.year, df.month, df.day, df.hour, df.min, df.sec))
    print("Summer Time:", df.summerTime)
    print("Day of Week:", df.dayOfWeek)
end

tmr.alarm(2, 30000, tmr.ALARM_AUTO, printTime)
```

so this is the output:

```bash
```

# Firmware
Executing multiple scripts can lead to out of memory issues. One possibility to solve it is to build custom firmware containing only minimal set of node-mcu modules. 
In order to build custom firmware go to http://nodemcu-build.com . Below you will find list of lua scripts and modules that they use. Additionally you always need 'node' and 'file'.

| Module | Date Format | WiFi access | NTP Clock | Serial API |
|--------|-------------|--------------|-----------|------------|
|   net  |             |       x      |     x     |            |
|  timer |             |       x      |     x     |            |
|  urat  |             |              |           |            |
|  WiFi  |             |       x      |     x     |      x     |
