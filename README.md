This project contains a few utilities for NodeMcu based on ESP8266.

# Date Format
Provides functionality to get local date and time from timestamp given in seconds since 1970.01.01

For such code:
``` lua
collectgarbage() print("heap before", node.heap())

require "dateformat"
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

# WiFi Access
It's simple facade for connecting to WiFi. You have to provide connection credentials and function that will be executed after the connection has been established.

*execute(...)* connects to WiFi and this can take some time. You can still call this method multiple times. In such case callbacks will be stored in the queue and executed after WiFi connection has been established.

``` lua
require "wlan"

local function printAbc() 
    print("Wlan Status on connect:", tostring(wlan))
    print("ABC")
end

wlan.setup("fred", "123456789")
print("Wlan Status on init:", tostring(wlan))
wlan.execute(printAbc)
```

``` bash
Wlan Status on init:    WiFi->nil,ST:1,ERR:0
Wlan Status on connect:   WiFi->172.20.10.6,ST:5,ERR:0
ABC
```

## Wifi Error Handling
There is a possibility that callback function executed by *wlan* module will cause an error. In this case status message will contain last error log. The example below is similar to one above but we have modified *printAbc()* so that it causes nil exception. Additionally there is a timer that will output status of *wlan* module every 5 seconds.
```lua
require "wlan"

local function printAbc() 
    print("Wlan Status on connect:", tostring(wlan))
    print("ABC", abc.xyz) -- nil operation 
end

wlan.setup("free wlan", "12345678")
wlan.execute(printAbc)
tmr.alarm(2, 5000, tmr.ALARM_AUTO, function() print("Wlan Status:", tostring(wlan)) end) 
```

```bash
Wlan Status:  WiFi->nil,ST:1,ERR:0
Wlan Status on connect: WiFi->172.20.10.6,ST:5,ERR:0
Wlan Status:    WiFi->172.20.10.6,ST:5,ERR:testWlanError.lua:5: attempt to index global 'abc' (a nil value)
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

wlan.setup("fred", "123456789")

ntp = NtpFactory:fromDefaultServer()

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

wlan.execute(function() ntp:requestTime() end)

tmr.alarm(2, 5000, tmr.ALARM_AUTO, function() print("NTP Status:", tostring(ntp), tostring(wlan)) end) 

collectgarbage() print("RAM callbacks", node.heap())
```

and console output:

``` bash
RAM init    42520
RAM after require   28936
RAM callbacks   28544
> RAM before printTime  29208
NTP Local Time: 2016-11-08 10:10:49
Summer Time:    false
Day of Week:    3
RAM after printTime 29016
NTP Status: NTP->09:10:49,131.188.3.222,DNS_RQ:7,NTP_RQ:8,NTP_RS:9  WiFi->172.20.10.6,ST:5,ERR:0
```

## NTP Error Handling 
*ntp* module has *tostring* function that should help you to find out what went wrong. 
Lets analyze this output: 
```bash
NTP Status: NTP->09:10:49,131.188.3.222,DNS_RQ:7,NTP_RQ:8,NTP_RS:9  WiFi->172.20.10.6,ST:5,ERR:0
```
We can see following info: NTP time, IP address of NTP server, time of DNS request, time of NTP request and finally time of NTP response.

Now lest modify last example and provide incorrect DNS server. This will result in following status:

```bash
> NTP Status:   NTP->23:59:59,-1,DNS_RQ:5,NTP_RQ:-1,NTP_RS:-1   WiFi->172.20.10.6,ST:5,ERR:0
```

You can see that DNS request has been issued (5 seconds after system start) but there is no response, because NTP request did not take place and it should be executed right after DNS response. You can also see that IP is *-1* - meaning that DNS resolution did not take place.

# Ntp Clock (ntpClock.lua)
This script provides functionality to run a clock with precision of one second and to synchronize this clock every few hours with NTP server. 

In the code below we first configure WiFi access. Once the WiFi access has been established it will call *ntpc.start()*. This function will start clock that will get synchronized with given NTP server every minute. Now you can access actual UTC time in seconds over *ntpc.current*. In order to show that it's working we have registered timer that will call *printTime()* every second. This function reads current time as *ntpc.current* and prints it as local time. 

```lua
collectgarbage() print("RAM init", node.heap())

require "dateformatEurope";
require "ntpClock";
require "wlan";

collectgarbage() print("RAM after require", node.heap())

wlan.setup("fred", "1234567890")

wlan.execute(function() ntpc.start("pool.ntp.org", 3600) end)

local function printTime()
    collectgarbage() print("\nRAM in printTime", node.heap())

    df.setEuropeTime(ntpc.current, 3600)

    print("Time:", string.format("%04u-%02u-%02u %02u:%02u:%02d",
        df.year, df.month, df.day, df.hour, df.min, df.sec))
    print("Summer Time:", df.summerTime)
    print("Day of Week:", df.dayOfWeek)
    print("Status:",tostring(wlan), tostring(ntpc))
    print("\n")
end

tmr.alarm(2, 5000, tmr.ALARM_AUTO, printTime)
```

so this is the output:

```bash
RAM init    42864
RAM after require   26896

RAM in printTime    27384
Time:   1970-01-01 01:00:00
Summer Time:    false
Day of Week:    5
Status: WiFi->172.20.10.6,ST:5,ERR:0    NTPC->-1,NTP->23:59:59,-1,DNS_RQ:6,NTP_RQ:-1,NTP_RS:-1

RAM in printTime    27472
Time:   2016-11-09 08:02:41
Summer Time:    false
Day of Week:    4
Status: WiFi->172.20.10.6,ST:5,ERR:0    NTPC->5,NTP->07:02:36,176.9.253.76,DNS_RQ:6,NTP_RQ:6,NTP_RS:6

RAM in printTime    26704
Time:   2016-11-09 08:02:46
Summer Time:    false
Day of Week:    4
Status: WiFi->172.20.10.6,ST:5,ERR:0    NTPC->10,NTP->07:02:36,176.9.253.76,DNS_RQ:6,NTP_RQ:6,NTP_RS:6

RAM in printTime    26704
Time:   2016-11-09 08:02:51
Summer Time:    false
Day of Week:    4
Status: WiFi->172.20.10.6,ST:5,ERR:0    NTPC->15,NTP->07:02:36,176.9.253.76,DNS_RQ:6,NTP_RQ:6,NTP_RS:6
```

# Yahoo Weather (yahooWeather.lua)
This script provides access to Yahoo weather. *yaw.start()* will obtain weather immediately and keep refreshing it every *yaw.syncPeriodSec* seconds. Weather data itself is stored in *yahooWeather.lua -> yaw.weather*, you will find there further documentation. 

```lua
require "yahooWeather"
require "wlan"

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

local gtsCall = 0;

-- return status for all modules.
function scmd.GST()
    gtsCall = gtsCall + 1;
    uart.write(0, string.format("NOW:%u;CNT:%u;RAM:%u;%s;%s;%s", tmr.time(),
        gtsCall, node.heap(), tostring(wlan), tostring(ntpc), tostring(yaw)))
end

-- setup wlan required by NTP clokc
wlan.setup("fred", "1234567890")

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

# function from script above
GST
NOW:30;CNT:1;RAM:12264;WiFi->172.20.10.6,ST:5,ERR:0;NTPC->18,NTP->
07:08:03,129.70.132.35,DNS_RQ:12,NTP_RQ:12,NTP_RS:12;YAW->
76.13.28.196,DNS_RQ:12,Y_RQ:13,Y_RS:13

# hour of the day
CHH
08

# minutes
CMM
11

# day of month
CDD
09

# day
CD3
WED

# weather description for today
YF1 text
Rain And Snow

# weather description for tomorrow
>YF2 text
Showers

# not existing command
YF1 min
ERR:serialAPIYahooWeather.lua:6: attempt to concatenate field '?' (a nil value)

# max temp for tomorrow 
YF2 low
1

# weather date for today
YF1 date
09 Nov 2016
```

# Firmware
Executing multiple scripts can lead to out of memory issues. One possibility to solve it is to build custom firmware containing only minimal set of node-mcu modules: cjson, file, gpio, net, node, tmr, uart, wifi. This blog provides detailed upgrade procedure: http://maciej-miklas.blogspot.de/2016/08/installing-nodemcu-v15-on-eps8266-esp.html

