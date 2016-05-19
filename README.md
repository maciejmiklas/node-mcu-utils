This project contains a few utilities for NodeMcu based on ESP8266.

# Date
Provides functionality to get date from timestamp given in seconds since 1970.01.01

For such code:
``` lua
print("RAM", collectgarbage("count")*1024)

require "date";

date:setTime(1463145687)

print("Date 1: ", date)
print("Date 2:", date.year, date.month, date.day, date.hour, date.min, date.sec)
print("DayOfYear: ", date:getDayOfYear())
print("DayOfWeek: ", date:getDayOfWeek())

print("RAM", collectgarbage("count")*1024)
```

you will get this console output:
``` bash
RAM 37808
Date 1:     2016-05-13 13:21:27
Date 2: 2016    5   13  13  21  27
DayOfYear:  134
DayOfWeek:  6
RAM 48301
```

Date is based on: https://github.com/daurnimator/luatz

# Wi-FI access
It's simple facade for connecting to Wi-Fi. You have to provide connection credentials and function that will be executed after the connection has been established.

``` lua
require "wlan"

wlan.debug = true

local function printAbc() 
    print("ABC")
end

wlan:connect("free wlan", "12345678", printAbc)
```

``` bash
Configuring Wi-Fi on:   free wlan
status  1
status  1
status  5
Got Wi-Fi connection:   172.20.10.6 255.255.255.240 172.20.10.1
ABC
```

# NTP time
Simple facade for getting NTP time.

First you have to connect to wlan and register callback that will be executed after the connection has been established, in our case we will use NTP script to request time: *ntp.requestTime*. Finally you have to register another callback that will get executed after NTP response has been received: *printTime(ts)*:

``` lua
require "wlan"
require "ntp"
require "date";

ntp.debug = true
wlan.debug = true

-- ts is time in seconds since 1970.01.01
local function printTime(ts) 
    date:setTime(ts) 
    print("NTP time:", date)
end

ntp:registerResponseCallback(printTime)

wlan:connect("free wlan", "12345678", ntp.requestTime)
```

and console output:

``` bash
Configuring Wi-Fi on:   free wlan
status  1
status  1
status  5
Got Wi-Fi connection:   172.20.10.6 255.255.255.240 172.20.10.1
NTP request:    89.163.209.233
NTP response:   06:53:31
NTP Time:   2016-05-19 06:53:31
```
