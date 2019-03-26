collectgarbage()
print("RAM before", node.heap())

require "dateformatEurope";

df.set_time(1463145687, 3600)
print(string.format("%04u-%02u-%02u %02u:%02u:%02d", 
	df.year, df.month, df.day, df.hour, df.min, df.sec))
print("day_off_week: ", df.day_off_week)

collectgarbage()
print("RAM after", node.heap())