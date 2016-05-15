local dfl = require "dateformat";
local df = dfl.new(1463145687)

print("collectgarbage 1",collectgarbage("count")*1024)

print("A", df )

print("collectgarbage 2",collectgarbage("count")*1024)

local function test(ts, expected)
	df.setTime(ts)
	if df ~= expected then
		print(ts.."->"..df.." ~= "..expected)
	end
end