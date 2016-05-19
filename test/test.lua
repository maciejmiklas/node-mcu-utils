print("RAM",collectgarbage("count")*1024)

require "dateformat";

df:setTime(1463145687)

print("Date 1: ", df)
print("Date 2:", df.year, df.month, df.day, df.hour, df.min, df.sec)
print("DayOfYear: ", df:getDayOfYear())
print("DayOfWeek: ", df:getDayOfWeek())

print("RAM",collectgarbage("count")*1024)