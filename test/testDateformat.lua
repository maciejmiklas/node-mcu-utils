require "dateformat";

testCnt = 0;
local function parseDate(expDate)
	local _, _, expYearStr, expMonthStr, expDayStr, expHourStr, expMinStr, expSecStr =
		string.find(expDate, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
	local expYear, expMonth, expDay = tonumber(expYearStr), tonumber(expMonthStr), tonumber(expDayStr)
	local expHour, expMin, expSec = tonumber(expHourStr), tonumber(expMinStr), tonumber(expSecStr)
	return 	expYear, expMonth, expDay, expHour, expMin, expSec
end

function testUTC()
	for line in io.lines("test/data/datesUTC.csv") do
		testCnt = testCnt + 1
		local _, _, tsStr, expDate = string.find(line, "(%d+),(.*)")
		local ts = tonumber(tsStr)
		local expYear, expMonth, expDay, expHour, expMin, expSec = parseDate(expDate);
		local df = DateFormatFactory:asUTC(ts)
		local fromated = df:format()

		local msg =  tsStr.." -> "..expDate.." ~= "..fromated
		assert(fromated == expDate, msg)
		assert(ts == df.timestampUTC, msg)
		assert(df.lt.zone == nil, msg)
		assert(df.year == expYear, msg)
		assert(df.month == expMonth, msg)
		assert(df.day == expDay, msg)
		assert(df.hour == expHour, msg)
		assert(df.min == expMin, msg)
		assert(df.sec == expSec, msg)
	end
end

function testEurope(city, utcOffset)
	for line in io.lines("test/data/datesEurope_"..city..".csv") do
		testCnt = testCnt + 1
		local _, _, tsStr, expDate, expDls = string.find(line, "(%d+),(.*),(%d)")
		local ts = tonumber(tsStr)
		local expYear, expMonth, expDay, expHour, expMin, expSec = parseDate(expDate);
		local df = DateFormatFactory:asEurope(ts, utcOffset)
		local fromated = df:format()
		local summer = (df.lt.summerTime and "Summer" or "Winter")
		local expSummer = (expDls == "1" and "Summer" or "Winter")
		local msg =  tsStr.." -> "..expDate.."("..expSummer..") ~= "..fromated.."("..summer..")"..", Debug: "..df.dd
		--assert(fromated == expDate, msg)
		if(fromated ~= expDate) then
			print("ERR", msg)
		end
	end
end

print("Executing tests....")
testUTC()
testEurope("London", 0)
testEurope("Warsaw", 3600)
print("Done - Executed "..testCnt.." tests without error :)")
