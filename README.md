This project contains a few utilities for NodeMcu based on ESP32. 

[Here you will find the branch for ESP8266](https://github.com/maciejmiklas/NodeMCUUtils/tree/esp8266)

# Logger
Different log levels can be specified in *log.lua*, including the UART Port.

# Serial Port
Serial port fol logger can be changed in *log.lua -> log.uart_id*. The port for communication is in *serial_api.lua -> sapi.uart_id*

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
It's a simple facade for connecting to WiFi. You have to provide connection credentials and a function that will be executed after the connection has been established.

*execute(...)* connects to WiFi, which can take some time. You can still call this method multiple times. In such cases, callbacks will be stored in the queue and executed after the WiFi connection has been established.

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
Wlan Status on init: WiFi ->nil,ST:1,ERR:0
Wlan Status on connect: WiFi ->172.20.10.6,ST:5,ERR:0
ABC
```

# NTP Time
This simple facade connects to a given NTP server, requests UTC time from it, and once a response has been received, it calls the given callback function. 

The example below executes the following chain: WiFi -> NTP -> Date Format. 
So in the first step, we create a WLAN connection and register a callback function that will be executed after a connection has been established. This callback function requests time from the NTP server (*ntp.requestTime*). 
On the *ntp* object, we are registering another function that will get called after the NTP response has been received: *printTime(ts)*.

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
This script provides functionality to run a clock with a precision of one second and to synchronize this clock every few hours with the NTP server. 

In the code below, we first configure WiFi access. Once the WiFi access has been established, it will call *ntpc.start()*. This function will start a clock synchronizing with the given NTP server every minute. Now you can access actual UTC time in seconds over *ntpc.current*. To show that it's working, we have a registered timer that will call *printTime()* every second. This function reads current time as *ntpc.current* and prints it as local time. 

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
This script provides access to [Open Weather](https://openweathermap.org). You have to register to get your application id. 
*owe.start()* will obtain weather immediately and keep refreshing it every *owe.sync_period_sec* second.

Open Weather delivers lots of info in the forecast. *open_weather_parser.lua* reduces it to 3 next days, without nights. 

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
Serial API exposes a simple interface that provides access to weather and date/time so that it can be accessed outside NodeMCU - for example, by Arduino.

Serial API is divided into a few Lua scripts. Loading of each script will automatically add new API commands:
- *serial_api.lua* - has to be always loaded. It initializes the serial interface with few diagnostics commands.
- *serial_api_clock.lua* - access to clock including date formatter.
- *serial_api_open_weather.lua* - API for Open Weather

Each script above registers a set of commands as keys of *scmd* table - inside each script, you will find further documentation.

The example below loads all available scripts:

```lua
require "serial_api_clock"
require "serial_api_open_weather"

cred = {ssid = 'free wlan', password = '12345678'}

ntpc.syncPeriodSec = 900 -- 15 min
owe.syncPeriodSec = 1020 -- 17 min

local gts_call = 0;

-- return status for all modules.
function scmd.SHI()
    gts_call = gts_call + 1;
    sapi.send("Hi There!")
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

# function from script above
>SHI
Hi There!

# free ram
>GFR
RAM: 144.076

# date
>CFD
2019-05-16 07:43:55

# hour of the day
>CHH
07

# minutes
>CMM
43

# day of month
>CDD
09

# day
>CD3
THU

# weather description for 3 days
>WFF
THU: min:9 max:16 overcast clouds,scattered clouds,few cloudsbroken clouds   FRI: min:11 max:20 overcast clouds,broken clouds,light rainclear sky  SAT: min:15 max:23 few clouds,clear sky
```

# Firmware
It's a good idea to compile firmware with a minimal module set, it will save lots of RAM. It is a minimal set that covers the whole functionality required by all scripts: file, mqtt, gpio, net, node, tmr, uart, WiFi, sjson, http. You can also use already precompiled firmware from *firmware* folder.:
```bash
cd firmware
esptool.py --chip esp32 --port /dev/ttyUSB0 --baud 115200 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 40m --flash_size detect 0x1000 bootloader.bin 0x10000 NodeMCU.bin 0x8000 partitions_singleapp.bin
```
