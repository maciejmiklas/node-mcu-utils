require "dateformatEurope";
require "ntp";
require "ntpClock";

sapiClock = {utcOffset = 3600}

-- return hours as local time in 24h format, range: 00-23
function scmd.CHH()
	df.setEuropeTime(ntpc.current, sapiClock.utcOffset)
	uart.write(0, string.format("%02u\n", df.hour))
end

-- return minutes of actual minute as local time, range: 01 to 60
function scmd.CMI()
	df.setEuropeTime(ntpc.current, sapiClock.utcOffset)
	uart.write(0, string.format("%02u\n", df.min))
end

-- return day of the month, range: 01-31
function scmd.CDD()
	df.setEuropeTime(ntpc.current, sapiClock.utcOffset)
	uart.write(0, string.format("%02u\n", df.day))
end

-- return month, range: 01 to 12
function scmd.CMM()
	df.setEuropeTime(ntpc.current, sapiClock.utcOffset)
	uart.write(0, string.format("%02u\n", df.month))
end

-- return day of week as 3 letter US text in format 'DDD'
function scmd.CD3()
	df.setEuropeTime(ntpc.current, sapiClock.utcOffset)
	uart.write(0, df.getDayOfWeekUp()..'\n')
end