require "dateformatEurope";

local testCnt = 0;
local function parseDate(expDate)
    local _, _, expYearStr, expMonthStr, expDayStr, expHourStr, expMinStr, expSecStr =
    string.find(expDate, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    local expYear, expMonth, expDay = tonumber(expYearStr), tonumber(expMonthStr), tonumber(expDayStr)
    local expHour, expMin, expSec = tonumber(expHourStr), tonumber(expMinStr), tonumber(expSecStr)
    return expYear, expMonth, expDay, expHour, expMin, expSec
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

        local msg = tsStr .. " -> " .. expDate .. " ~= " .. fromated
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
    for line in io.lines("test/unit/data/dates" .. location .. ".csv") do
        testCnt = testCnt + 1
        local _, _, utcSecTxt, expDate, expDls = string.find(line, "(%d+),(.*),(%d)")
        local utcSec = tonumber(utcSecTxt)
        timeFunction(utcSec, utcOffset)
        local fromated = format(df)
        local summer = (df.summerTime and "Summer" or "Winter")
        local expSummer = (expDls == "1" and "Summer" or "Winter")
        local msg = location .. " -> " .. utcSecTxt .. " -> " .. expDate .. "(" .. expSummer .. ") ~= " .. fromated .. "(" .. summer .. ")"
        assert(fromated == expDate, msg)
    end
end

function testEurope(df, city, utcOffset)
    local location = "Europe_" .. city
    testLocal(df, location, utcOffset, function(ts, utcOffset) return df:setTime(ts, utcOffset) end)
end

function testDifferentInstances()
    --1466765445,2016-06-24 12:50:45,1
    local df1 = DateFormat.new()
    df1:setTime(1466765445, 3600)
    local formated1 = format(df1)
    assert("2016-06-24 12:50:45" == formated1, formated1)

    --1467547980,2016-07-03 14:13:00,1
    local df2 = DateFormat.new()
    df2:setTime(1467547980, 3600)
    local formated2 = format(df2)
    assert("2016-07-03 14:13:00" == formated2, formated2)

    formated1 = format(df1)
    assert("2016-06-24 12:50:45" == formated1, formated1)

    --1470679950,2016-08-08 20:12:30,1
    df1:setTime(1470679950, 3600)
    formated1 = format(df1)
    assert("2016-08-08 20:12:30" == formated1, formated1)

    formated2 = format(df2)
    assert("2016-07-03 14:13:00" == formated2, formated2)
end

print("Executing tests....")
df = DateFormat.new()
testDifferentInstances()
testUTC(df)
testEurope(df, "London", 0)
testEurope(df, "Warsaw", 3600)
testEurope(df, "Bucharest", 7200)

print("Done - Executed " .. testCnt .. " tests, all OK")
