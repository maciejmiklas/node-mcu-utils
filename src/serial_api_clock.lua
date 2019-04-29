require "serial_api"
require "ntp";
require "ntp_clock";

sapiClock = { utc_offset = 3600 }
local df = DateFormat.new()

-- return hours as local time in 24h format, range: 00-23
function scmd.CHH()
    df:set_time(ntpc.current, sapiClock.utc_offset)
    uart.write(sapi.uart_id, string.format("%02u\n", df.hour))
end

-- return minutes of actual minute as local time, range: 01 to 60
function scmd.CMI()
    df:set_time(ntpc.current, sapiClock.utc_offset)
    uart.write(sapi.uart_id, string.format("%02u\n", df.min))
end

-- HH:MM
function scmd.CHM()
    df:set_time(ntpc.current, sapiClock.utc_offset)
    uart.write(sapi.uart_id, string.format("%02u:%02u\n", df.hour, df.min))
end

-- DD-MM
function scmd.CDM()
    df:set_time(ntpc.current, sapiClock.utc_offset)
    uart.write(sapi.uart_id, string.format("%02u-%02u\n", df.day, df.month))
end

-- return day of the month, range: 01-31
function scmd.CDD()
    df:set_time(ntpc.current, sapiClock.utc_offset)
    uart.write(sapi.uart_id, string.format("%02u\n", df.day))
end

-- return day of week as 3 letter US text in format 'DDD'
function scmd.CD3()
    df:set_time(ntpc.current, sapiClock.utc_offset)
    uart.write(sapi.uart_id, df.get_day_of_week_up() .. '\n')
end

function scmd.CFD()
    df:set_time(ntpc.current, sapiClock.utc_offset)
    local full = string.format("%04u-%02u-%02u %02u:%02u:%02d\n", df.year, df.month, df.day, df.hour, df.min, df.sec)
    uart.write(sapi.uart_id, full)
end