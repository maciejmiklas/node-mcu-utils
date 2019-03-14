require "ntp";
require "ntpClock";

sapiClock = { utcOffset = 3600 }
local df = DateFormat.new()

-- return hours as local time in 24h format, range: 00-23
function scmd.CHH()
    df:setTime(ntpc.current, sapiClock.utcOffset)
    uart.write(sapi.uratId, string.format("%02u\n", df.hour))
end

-- return minutes of actual minute as local time, range: 01 to 60
function scmd.CMI()
    df:setTime(ntpc.current, sapiClock.utcOffset)
    uart.write(sapi.uratId, string.format("%02u\n", df.min))
end

-- return day of the month, range: 01-31
function scmd.CDD()
    df:setTime(ntpc.current, sapiClock.utcOffset)
    uart.write(sapi.uratId, string.format("%02u\n", df.day))
end

-- return month, range: 01 to 12
function scmd.CMM()
    df:setTime(ntpc.current, sapiClock.utcOffset)
    uart.write(sapi.uratId, string.format("%02u\n", df.month))
end

-- return day of week as 3 letter US text in format 'DDD'
function scmd.CD3()
    df:setTime(ntpc.current, sapiClock.utcOffset)
    uart.write(sapi.uratId, df.getDayOfWeekUp() .. '\n')
end

function scmd.CFD()
    df:setTime(ntpc.current, sapiClock.utcOffset)
    local full = string.format("%04u-%02u-%02u %02u:%02u:%02d\n", df.year, df.month, df.day, df.hour, df.min, df.sec)
    uart.write(sapi.uratId, full)
end