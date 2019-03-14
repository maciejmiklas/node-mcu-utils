require "dateformat";

-- UTC time without DST
function DateFormat:isSummerTimeEurope()
    if self.month < 3 or self.month > 10 then return false end
    if self.month > 3 and self.month < 10 then return true end

    local previousSunday = self.day - self.dayOfWeek
    if self.month == 3 then
        if self.day >= 25 and self.dayOfWeek == 1 and self.hour == 0 then return false end
        return previousSunday > 23
    end

    if self.month == 10 then
        if self.day >= 25 and self.dayOfWeek == 1 and self.hour == 0 then return true end
        return previousSunday < 24
    end

    assert(false)
end

-- initializes DateFormat table with Central Europe time with daylight saving
--
-- ts - UTC seconds since 1.1.1970
-- utcOffset - UTC offset without daylight saving in seconds used to calculate local time from ts.
function DateFormat:setTime(utcSec, utcOffset)
    self:setTimeStamp(utcSec)
    self.utcSec = utcSec
    self.summerTime = self:isSummerTimeEurope()

    if self.summerTime then
        self:setTimeStamp(utcSec + utcOffset + 3600)
    else
        self:setTimeStamp(utcSec + utcOffset)
    end
end
