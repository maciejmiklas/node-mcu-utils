CurrentTimeFactory = {}

local ct = {
	ntpServer = nil,
	ntp = nil
}

mt = {
	__index = ct;
}

function CurrentTimeFactory:fromNTPServer(server)
	obj = {}
	setmetatable(obj, mt);	
	obj.ntpServer = server
		
end
