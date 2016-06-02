print("RAM 1", collectgarbage("count") * 1024)

require "dateformat";

df = DateFormatFactory:fromGMT(1463431707)
print(df)
print(df.year)
df.year = 2000
print(df.year)


print("-------")
o2 = DateFormatFactory:fromGMT(1473632175)
print(o2)
print(o2.year)
o2.year = 2010
print(o2.year, df.year)