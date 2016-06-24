print("RAM", collectgarbage("count")*1024)

require "dateformat";

local date = DateFormatFactory:asEurope(1463145687, 3600)

print("Date 1: ", date)
print("Date 2:", date.year, date.month, date.day, date.hour, date.min, date.sec)
print("DayOfYear: ", date.dayOfYear)
print("DayOfWeek: ", date.dayOfWeek)

print("RAM", collectgarbage("count")*1024)