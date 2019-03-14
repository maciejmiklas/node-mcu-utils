require "dateformatAmerica";

local testCnt = 0;
local function parseDate(expDate)
	local _, _, expYearStr, expMonthStr, expDayStr, expHourStr, expMinStr, expSecStr =
		string.find(expDate, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
	local expYear, expMonth, expDay = tonumber(expYearStr), tonumber(expMonthStr), tonumber(expDayStr)
	local expHour, expMin, expSec = tonumber(expHourStr), tonumber(expMinStr), tonumber(expSecStr)
	return 	expYear, expMonth, expDay, expHour, expMin, expSec
end

function format(df)
	return string.format("%04u-%02u-%02u %02u:%02u:%02d", df.year, df.month, 
		df.day, df.hour, df.min, df.sec)
end

function testUTC(df)
	for line in io.lines("test/unit/data/datesUTC.csv") do
		testCnt = testCnt + 1
		local _, _, tsStr, expDate = string.find(line, "(%d+),(.*)")
		local ts = tonumber(tsStr)
		local expYear, expMonth, expDay, expHour, expMin, expSec = parseDate(expDate);
		df:setTimeStamp(ts)
		local fromated = format(df)

		local msg =  tsStr.." -> "..expDate.." ~= "..fromated
		assert(fromated == expDate, msg)
		assert(df.summerTime == nil, msg)
		assert(df.year == expYear, msg)
		assert(df.month == expMonth, msg)
		assert(df.day == expDay, msg)
		assert(df.hour == expHour, msg)
		assert(df.min == expMin, msg)
		assert(df.sec == expSec, msg)
	end
end

function testLocal(df, location, utcOffset, timeFunction)
	for line in io.lines("test/unit/data/dates"..location..".csv") do
		testCnt = testCnt + 1
		local _, _, utcSecTxt, expDate, expDls = string.find(line, "(%d+),(.*),(%d)")
		local utcSec = tonumber(utcSecTxt)
		timeFunction(df, utcSec, utcOffset)
		local fromated = format(df)
		local summer = (df.summerTime and "Summer" or "Winter")
		local expSummer = (expDls == "1" and "Summer" or "Winter")
		local msg =  location.." -> "..utcSecTxt.." -> "..expDate.."("..expSummer..") ~= "..fromated.."("..summer..")"
		assert(fromated == expDate, msg)
	end
end

function testAmerica(df, city, utcOffset)
	local location = "America_"..city
	local dateFactory = function(df, ts, utcOffset) return df:setTime(ts, utcOffset) end
	testLocal(df, location, utcOffset, dateFactory)
end

print("Executing tests....")
df = DateFormat.new()
testUTC(df)
testAmerica(df, "Los_Angeles", -28800)

print("Done - Executed "..testCnt.." tests, all OK")
