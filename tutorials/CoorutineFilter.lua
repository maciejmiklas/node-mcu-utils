value = "?"

lock = coroutine.create(function() coroutine.yield() xyz() end)
coroutine.resume(lock)

function abc()
	print("ABC 1")
	value = "YES !"
	coroutine.resume(lock)
	print("ABC 2")
end

function xyz()
	print("XYZ", value)
end

abc()
