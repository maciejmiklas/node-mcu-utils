collectgarbage()
print("RAM before", node.heap())

require "dateformatEurope";

df.setTime(1463145687, 3600)
print(string.format("%04u-%02u-%02u %02u:%02u:%02d", 
	df.year, df.month, df.day, df.hour, df.min, df.sec))
print("DayOfWeek: ", df.dayOfWeek)

collectgarbage()
print("RAM after", node.heap())