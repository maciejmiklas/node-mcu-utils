require "dateformatEurope";
require "ntp";
require "ntpClock";

sapiClock = {utcOffset = 3600, debug = false}

-- read time is seconds since 1.1.1970
function scmd.CTS()
	uart.write(0, ntpc.current.."\n")
end

-- seconds since last sync with NTP server
function scmd.CLS()
	uart.write(0, ntpc.lastSyncSec.."\n")
end

-- return hours of local time in 24h format, e.g.: 23:11
function scmd.CH2()
	df.setEuropeTime(ntpc.current, sapiClock.utcOffset)
	uart.write(0, string.format("%02u:%02u:%02d\n", df.hour, df.min, df.sec))
end

-- return date in format: yyyy-mm-dd
function scmd.CDU()
	df.setEuropeTime(ntpc.current, sapiClock.utcOffset)
	uart.write(0, string.format("%04u-%02u-%02u\n", df.year, df.month, df.day))
end

-- return date and time (24h) in format: yyyy-mm-dd HHLmm:ss
function scmd.CF1()
	df.setEuropeTime(ntpc.current, sapiClock.utcOffset)
	uart.write(0, string.format("%04u-%02u-%02u %02u:%02u:%02d\n",
		df.year, df.month, df.day, df.hour, df.min, df.sec))
end

-- return day of week as int, range: 1 to 7 starting from monday
function scmd.CDI()
	df.setEuropeTime(ntpc.current, sapiClock.utcOffset)
	uart.write(0, df.dayOfWeek.."\n")
end

-- return day of week as 3 letter us text
function scmd.CDU()
	df.setEuropeTime(ntpc.current, sapiClock.utcOffset)
	uart.write(0, df.getDayOfWeekUp().."\n")
end