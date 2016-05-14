local df = require "dateformat";

print("collectgarbage 1",collectgarbage("count")*1024)

print("A", df.new(1463145687) )

print("collectgarbage 2",collectgarbage("count")*1024)