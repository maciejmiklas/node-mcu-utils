This project contains a few utilities for NodeMcu based on ESP32.

# Logger
Different log levels can be specified in *log.lua*, including the UART Port.

# Date Format
Provides functionality to get local date and time from timestamp given in seconds since 1970.01.01

For such code:
``` lua
require "date_format_europe"; -- there is also US version

df = DateFormat.new()
df.set_time(1463145687, 3600) -- function requires GMT offset for your location

print(string.format("%04u-%02u-%02u %02u:%02u:%02d", 
    df.year, df.month, df.day, df.hour, df.min, df.sec))
print("Day of week: ", df.dayOfWeek)
```

you will get this output:
``` bash
2016-05-13 15:21:27
Day of week:  6
```

# WiFi Access
It's simple facade for connecting to WiFi. You have to provide connection credentials and function that will be executed after the connection has been established.

*execute(...)* connects to WiFi and this can take some time. You can still call this method multiple times. In such case callbacks will be stored in the queue and executed after WiFi connection has been established.

``` lua
require "wlan"

local function print_abc() 
    print("Wlan Status on connect:", tostring(wlan))
    print("ABC")
end

wlan.setup("fred", "123456789")
print("Wlan Status on init:", tostring(wlan))
wlan.execute(print_abc)
```

``` bash
Wlan Status on init:    WiFi->nil,ST:1,ERR:0
Wlan Status on connect:   WiFi->172.20.10.6,ST:5,ERR:0
ABC
```

# NTP Time
This simple facade connects to given NTP server, request UTC time from it and once response has been received it calls given callback function. 

Example below executes following chain: WiFi -> NTP -> Date Format. 
So in the fist step we are creating WLAN connection and registering callback function that will be executed after connection has been established. This callback function requests time from NTP server (*ntp.requestTime*). 
On the *ntp* object we are registering another function that will get called after NTP response has been received: *printTime(ts)*.

``` lua
require "wlan"
require "ntp"
require "date_format_europe"

df = DateFormat.new()
wlan.setup("fred", "123456789")

ntp = NtpFactory:from_default_server()

local function print_time(ts) 
    df.set_time(ts, 3600)
    
    print("NTP Local Time:", string.format("%04u-%02u-%02u %02u:%02u:%02d", 
        df.year, df.month, df.day, df.hour, df.min, df.sec))
    print("Summer time:", df.summerTime)
    print("Day of week:", df.dayOfWeek)
    
end

ntp:on_response(print_time)
wlan.execute(function() ntp:request_time() end)
```

and console output:

``` bash
NTP Local Time: 2016-11-08 10:10:49
Summer Time:    false
Day of Week:    3
```

# Ntp Clock
This script provides functionality to run a clock with precision of one second and to synchronize this clock every few hours with NTP server. 

In the code below we first configure WiFi access. Once the WiFi access has been established it will call *ntpc.start()*. This function will start clock that will get synchronized with given NTP server every minute. Now you can access actual UTC time in seconds over *ntpc.current*. In order to show that it's working we have registered timer that will call *printTime()* every second. This function reads current time as *ntpc.current* and prints it as local time. 

```lua
collectgarbage() print("RAM init", node.heap())

require "date_format_europe"
require "ntp_clock";
require "wlan";

wlan.setup("fred", "1234567890")

wlan.execute(function() ntpc.start("pool.ntp.org", 3600) end)

local function print_time()
    collectgarbage() print("\nRAM in printTime", node.heap())

    df.setEuropeTime(ntpc.current, 3600)

    print("Time:", string.format("%04u-%02u-%02u %02u:%02u:%02d",
        df.year, df.month, df.day, df.hour, df.min, df.sec))
    print("Summer Time:", df.summerTime)
    print("Day of Week:", df.dayOfWeek)
    print("\n")
end

tmrObj = tmr.create()
tmrObj:register(5000, tmr.ALARM_AUTO, print_time)
tmrObj:start()
```

so this is the output:

```bash

Time:   2018-11-09 08:02:41
Summer Time:    false
Day of Week:    4

Time:   2018-11-09 08:02:46
Summer Time:    false
Day of Week:    4

Time:   2018-11-09 08:02:51
Summer Time:    false
Day of Week:    4
```

# Open Weather
This script provides access to [Open Weather](https://openweathermap.org), you have to register to get your application id. 
*owe.start()* will obtain weather immediately and keep refreshing it every *owe.sync_period_sec* seconds. 

```lua
require "open_weather.lua"
require "wlan"


owe.appid = 'YOUR APP ID'
    
wlan.setup("free wlan", "12345678")

-- update weather every 17 minutes
owe.sync_period_sec = 1020

owe.response_callback = function()
    print("Current temp:", owe.current('temp'))     

    local fc = owe.forecast(2)
    print("Weather for tomorrow:", fc.day, fc.temp_min, fc.temp_max, fc.description)     
end

-- start weather update timer
owe.start()
```

and output:
```
Current temp:  21
Weather for tomorrow: MON 16 25  Partly Cloudy
```

# Serial API
Serial API exposes simple interface that provides access to weather and date so that it can be accessed outside NodeMCU - for example by Arduino.

Serial API is divided into few Lua scripts. Loading of each script will automatically add new API commands:
- *serial_api.lua* - has to be always loaded. It initializes serial interface with few diagnostics commands.
- *serial_api_clock.lua* - access to clock including date formatter.
- *serial_api_open_weather.lua* - API for Open Weather

Each script above registers set of commands as keys of *scmd* table - inside of each script you will find further documentation.

Example below loads all available scripts:

```lua
require "serial_api_clock"
require "serial_api_open_weather"

cred = {ssid = 'free wlan', password = '12345678'}

ntpc.syncPeriodSec = 900 -- 15 min
owe.syncPeriodSec = 1020 -- 17 min

local gts_call = 0;

-- return status for all modules.
function scmd.GST()
    gts_call = gts_call + 1;
    uart.write(0, string.format("NOW:%u;CNT:%u;RAM:%u;%s;%s;%s", tmr.time(),
        gts_call, node.heap(), tostring(wlan), tostring(ntpc), tostring(yaw)))
end

-- setup wlan required by NTP clokc
wlan.setup("fred", "1234567890")

-- start serial API by enabling gpio and uart
sapi.start()

-- start NTP synchronization
ntpc.start("pool.ntp.org")

-- start yahoo weather with serial API
owe.start()
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
It's a good idea to compile firmware with minimal module set, it will save lots of RAM. Those modules are required: file, mqtt, gpio, net, node, tmr, uart, wifi. You can also use already precompiled firmware from 'firmware' folder.:
```bash
cd firmware
esptool.py --chip esp32 --port /dev/ttyUSB0 --baud 115200 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 40m --flash_size detect 0x1000 bootloader.bin 0x10000 NodeMCU.bin 0x8000 partitions_singleapp.bin
```
