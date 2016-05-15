local dfl = require "dateformat";
local df = dfl.new(1463145687)

print("RAM",collectgarbage("count")*1024)

print(df)

print("RAM",collectgarbage("count")*1024)

local function test(ts, expected)
	df.setTime(ts)
	if df ~= expected then
		print(ts.."->"..df.." ~= "..expected)
	end
end