require "date_format";

-- UTC time without DST
function DateFormat:is_summer_time_europe()
    if self.month < 3 or self.month > 10 then return false end
    if self.month > 3 and self.month < 10 then return true end

    local previous_sunday = self.day - self.day_off_week
    if self.month == 3 then
        if self.day >= 25 and self.day_off_week == 1 and self.hour == 0 then return false end
        return previous_sunday > 23
    end

    if self.month == 10 then
        if self.day >= 25 and self.day_off_week == 1 and self.hour == 0 then return true end
        return previous_sunday < 24
    end

    assert(false)
end

-- initializes DateFormat table with Central Europe time with daylight saving
--
-- ts - UTC seconds since 1.1.1970
-- utc_offset - UTC offset without daylight saving in seconds used to calculate local time from ts.
function DateFormat:set_time(utcSec, utc_offset)
    self:set_time_stamp(utcSec)
    self.utcSec = utcSec
    self.summer_time = self:is_summer_time_europe()

    if self.summer_time then
        self:set_time_stamp(utcSec + utc_offset + 3600)
    else
        self:set_time_stamp(utcSec + utc_offset)
    end
end
