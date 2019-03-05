require "timer";

scheduler.register(function() print("A") end, "FA", 100)
scheduler.register(function() print("B") end, "FB", 200)
scheduler.register(function() print("C") end, "FC", 300)
scheduler.call()


