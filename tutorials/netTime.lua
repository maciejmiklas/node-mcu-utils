function parseTime(conn, data)
	print("Response: ", data)
	conn:close()
end

function GET(host, path)
	local head = "GET "..path.." HTTP/1.1\r\nHost: "..host.."\r\nUser-Agent: Mozilla/4.0 (compatible; esp8266 Lua;)\r\n\r\n"
	return function(conn, payload)
		conn:send(head)
	end
end

function getTime()
	local conn = net.createConnection(net.TCP, 0)
	conn:on("connection", GET("www.timeapi.org", "/utc/now"))
	conn:on("receive", parseTime)
	conn:connect(80, "www.timeapi.org")
end