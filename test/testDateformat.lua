require "dateformat";

function testGMT()
	for line in io.lines("test/datesGMT.csv") do
		local _, _, tsStr, expDate = string.find(line, "(%d+),(.*)")
		local ts = tonumber(tsStr)
		
		local _, _, expYearStr, expMonthStr, expDayStr, expHourStr, expMinStr, expSecStr = 
			string.find(expDate, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
		local expYear, expMonth, expDay = tonumber(expYearStr), tonumber(expMonthStr), tonumber(expDayStr)
		local expHour, expMin, expSec = tonumber(expHourStr), tonumber(expMinStr), tonumber(expSecStr)
		
		local df = DateFormatFactory:fromGMT(ts)
		local fromated = df:format()
		
		local msg =  tsStr.."->"..fromated.." ~= "..expDate
		assert(fromated == expDate, msg)
		assert(ts == df.timestampGMT, msg)
		assert(zone == nil, msg)
		assert(df.gmtOffset == 0, msg)
		assert(df.year == expYear, msg)
		assert(df.month == expMonth, msg)
		assert(df.day == expDay, msg)
		assert(df.hour == expHour, msg)
		assert(df.min == expMin, msg)
		assert(df.sec == expSec, msg)
	end
end

print("Executing tests....")
testGMT()
print("Done - no errors :)")