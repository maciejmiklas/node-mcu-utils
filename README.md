This project contains a few utilities for NodeMcu based on ESP8266.

# Date Format (dateformat.lua, dateformatAmerica.lua, dateformatEurope.lua)
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

# WiFi access (wlan.lua)
It's simple facade for connecting to WiFi. You have to provide connection credentials and function that will be executed after the connection has been established.

*execute(...)* connects to WiFi and this can take some time. You can still call this method multiple times. In such case callbacks will be stored in the queue and executed after WiFi connection has been established.

``` lua
require "wlan"

wlan.debug = true

local function printAbc() 
    print("ABC")
end

wlan.setup("free wlan", "12345678")
wlan.execute(printAbc)
```

``` bash
Configuring WiFi on:   free wlan
status  1
status  1
status  5
Got WiFi connection:   172.20.10.6 255.255.255.240 172.20.10.1
ABC
```

# NTP Time (ntp.lua)
This simple facade connects to given NTP server, request UTC time from it and once response has been received it calls given callback function. 

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

wlan.setup("free wlan", "12345678")
wlan.execute(function() ntp:requestTime() end)

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

# Ntp Clock (ntpClock.lua)
This script provides functionality to run a clock with precision of one second and to synchronize this clock every few hours with NTP server. 

In the code below we first configure WiFi access. Once the WiFi access has been established it will call *ntpc.start()*. This function will start clock that will get synchronized with given NTP server every minute. Now you can access actual UTC time in seconds over this variable *ntpc.current*. In order to show that it's working we have registered timer that will call *printTime()* every second. This function reads current time as *ntpc.current* and prints it as local time. 

```lua
collectgarbage() print("RAM init", node.heap())

require "dateformatEurope";
require "ntpClock";
require "wlan";

collectgarbage() print("RAM after require", node.heap())

ntpc.debug = true
wlan.debug = true

wlan.setup("free wlan", "12345678")
wlan.execute(function() ntpc.start("pool.ntp.org", 60) end)

local function printTime() 
    collectgarbage() print("RAM in printTime", node.heap())
    
    df.setEuropeTime(ntpc.current, 3600)
    
    print("Time:", string.format("%04u-%02u-%02u %02u:%02u:%02d", 
        df.year, df.month, df.day, df.hour, df.min, df.sec))
    print("Summer Time:", df.summerTime)
    print("Day of Week:", df.dayOfWeek)
end

tmr.alarm(2, 30000, tmr.ALARM_AUTO, printTime)
```

so this is the output:

```bash
RAM init    43784
RAM after require   29408
Configuring WiFi on:    free wlan
status  1
status  5
Got WiFi connection:    192.168.2.113   255.255.255.0   192.168.2.1

NTP request:    pool.ntp.org
NTP request:    195.50.171.101
NTP response:   17:09:46

RAM in printTime    29664
Time:   2016-08-08 19:10:08
Summer Time:    true
Day of Week:    2

RAM in printTime    29808
Time:   2016-08-08 19:10:38
Summer Time:    true
Day of Week:    2

NTP request:    pool.ntp.org
NTP request:    195.50.171.101
NTP response:   17:10:46

RAM in printTime    29680
Time:   2016-08-08 19:11:08
Summer Time:    true
Day of Week:    2

RAM in printTime    29808
Time:   2016-08-08 19:11:38
Summer Time:    true
Day of Week:    2

NTP request:    pool.ntp.org
NTP request:    131.188.3.221
NTP response:   17:11:46

RAM in printTime    29680
Time:   2016-08-08 19:12:08
Summer Time:    true
Day of Week:    2

RAM in printTime    29808
Time:   2016-08-08 19:12:38
Summer Time:    true
Day of Week:    2
```

# Yahoo Weather (yahooWeather.lua)
This script provides access to Yahoo weather. *yaw.start()* will obtain weather immediately and keep refreshing it every *yaw.syncPeriodSec* seconds. Weather data itself is stored in *yahooWeather.lua -> yaw.weather*, you will find there further documentation. 

```lua
require "yahooWeather"
require "wlan"

wlan.debug = false
yaw.debug = false
yaw.trace = false

yaw.city = "munic"
yaw.country = "de"
    
wlan.setup("free wlan", "12345678")

-- update weather every 17 minutes
yaw.syncPeriodSec = 1020

yaw.responseCallback = function()
    print("Weather for today:", yaw.weather[1].date) 
    print(yaw.weather[1].low, yaw.weather[1].high, yaw.weather[1].text)

    print("Weather for tomorrow:", yaw.weather[2].date) 
    print(yaw.weather[2].low, yaw.weather[2].high, yaw.weather[2].text)
end

-- start weather update timer
yaw.start()
```

and output:
```
Weather for today:  01 Sep 2016
18  25  Partly Cloudy
Weather for tomorrow:   02 Sep 2016
16  25  Partly Cloudy
```

# Serial API
Serial API exposes simple interface that provides access to weather and date so that it can be accessed outside NodeMCU - for example by Arduino.

Serial API is divided into few Lua scripts. Loading of each script will automatically add new API commands:
- *serialAPI.lua* - has to be always loaded. It initializes serial interface with few diagnostics commands.
- *serialAPIClock.lua* - access to clock including date formatter.
- *serialAPIYahooWeather.lua* - API for Yahoo Weather

Each script above registers set of commands as keys of *scmd* table - inside of each script you will find further documentation.

Example below loads all available scripts:

```lua
require "credentials"
require "serialAPI"
require "serialAPIClock"
require "serialAPIYahooWeather"
require "yahooWeather"

ntpc.syncPeriodSec = 900 -- 15 min
yaw.syncPeriodSec = 1020 -- 17 min
sapi.baud = 115200

-- setup wlan required by NTP clock and weather
wlan.setup("free wlan", "12345678")

-- start serial API by enabling gpio and uart
sapi.start()

-- start NTP synchronization
ntpc.start("pool.ntp.org")

-- start yahoo weather with serial API
yaw.start()
```

Here are few Serial API commands and their responses.
```bash
# free ram
>GFR
10664

# WiFi status
>GWS
5

# date and time (24h) in format: yyyy-mm-dd HHLmm:ss
>CF1
2016-09-16 10:45:25

# date in format: yyyy-mm-dd
>CH2
10:45:59

# weather description for today
>YF1 text
Scattered Showers

# weather description for tomorrow
>YF2 text
Showers

# max temp for today
>YF1 high
22

# max temp for tomorrow
>YF2 high
16

# weather date for today
>YF1 date
16 Sep 2016

# weather date for tomorrow
>YF2 date
17 Sep 2016

```


# Firmware
Executing multiple scripts can lead to out of memory issues. One possibility to solve it is to build custom firmware containing only minimal set of node-mcu modules: cjson, file, gpio, net, node, tmr, uart, wifi. This blog provides detailed upgrade procedure: http://maciej-miklas.blogspot.de/2016/08/installing-nodemcu-v15-on-eps8266-esp.html

