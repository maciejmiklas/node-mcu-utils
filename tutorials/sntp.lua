--settings 
local default_ntpserver="pool.ntp.org" --use pool.ntp.org  or time.nist.gov
local udptimer=4
local udptimeout=500 --milliseconds
local timezone=1
--end settings


function update(ntpserver)
  if not ntpserver then
    ntpserver = default_ntpserver
  end

  local request=string.char(0x1b) .. string.rep(0x0,47) --create request string  
  local cu=net.createConnection(net.UDP,0)--udp connection not secured
  cu:dns(ntpserver,function(conn,ip)
    --if dns suceed
        print("from IP:",ip);
        --setup timeout 
      tmr.alarm(udptimer,udptimeout,0,function()
              cu:close()
              cu=nil    
              return("timeout")    
              end) 
    
    --open connection
      cu:connect(123,ip)
     --cu:connect(123,"178.23.124.2")
        cu:send(request)
        cu:on("receive",function(cu,c) 

            --something received, close connection and dispose element
            tmr.stop(udptimer)
            cu:close()
            cu=nil 

            --calc timestamp
            local bytes=c:sub(41,44)
            local highw = bytes:byte(1) * 256 + bytes:byte(2)
            local loww = bytes:byte(3) * 256 + bytes:byte(4)    
            local ntpstamp=( highw * 65536 + loww ) + ( timezone * 3600)   -- 1=timezone NTP-stamp, seconds since 1.1.1900
            local ustamp=ntpstamp - 1104494400 - 1104494400      -- UNIX-timestamp, seconds since 1.1.1970
        
            --make unix timestamp readable
            local hour = ustamp % 86400 / 3600
            local minute = ustamp % 3600 / 60
            local second = ustamp % 60
            local str = string.format("%02u:%02u:%02u",hour,minute,second)
            --print(string.format("UNIX-Timestamp: %u -> %02u:%02u:%02u",ustamp,hour,minute,second))
            print (str)
            return(str)
        end)
  end)
end

return {update=update}