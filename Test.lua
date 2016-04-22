require "luasocket"
host = "www.w3.org"
file = "/TR/REC-html32.html"
c = assert(socket.connect(host, 80))