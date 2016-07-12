start = collectgarbage("count") * 1024
require "dateformatEurope";

df.setEuropeTime(1463145687, 3600)

print("Date 2:", df.year, df.month, df.day, df.hour, df.min, df.sec)
print("DayOfWeek: ", df.dayOfWeek)

print("RAM consumed", collectgarbage("count") * 1024 - start)