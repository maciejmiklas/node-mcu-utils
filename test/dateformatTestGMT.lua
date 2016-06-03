require "dateformat";

local tests = 0
local function test(ts, expected)
	tests = tests + 1
	local df = DateFormatFactory:fromGMT(ts)
	local sfStr = df:format()
	if sfStr ~= expected then
		print("Error: "..ts.."->"..sfStr.." ~= "..expected)
	end
end

print("Executing tests....")

for line in io.lines("test/datesGMT.csv") do
	local _, _, tss, date = string.find(line, "(%d+),(.*)")
	local ts = tonumber(tss)
	test(ts, date)
end

print("Done - executed "..tests.." tests")

