require "dateformat";

-- df - UTC time without DST
local function isSummerTimeEurope(df)
    if df.month < 3 or df.month > 10 then return false end
    if df.month > 3 and df.month < 10 then return true end

    local previousSunday = df.day - df.dayOfWeek
    if df.month == 3 then
        if df.day >= 25 and df.dayOfWeek == 1 and df.hour == 0 then return false end
        return previousSunday > 23
    end

    if df.month == 10 then
        if df.day >= 25 and df.dayOfWeek == 1 and df.hour == 0 then return true end
        return previousSunday < 24
    end

    assert(false)
end

-- initializes "df" table with Central Europe time with daylight saving
--
-- ts - UTC seconds since 1.1.1970
-- utcOffset - UTC offset without daylight saving in seconds used to calculate local time from ts.
function df.setTime(utcSec, utcOffset)
    df.setTimeStamp(utcSec)
    df.utcSec = utcSec
    df.summerTime = isSummerTimeEurope(df)

    if df.summerTime then
        df.setTimeStamp(utcSec + utcOffset + 3600)
    else
        df.setTimeStamp(utcSec + utcOffset)
    end
end
