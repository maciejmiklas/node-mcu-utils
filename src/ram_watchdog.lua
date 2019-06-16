rwd = {
    frequency_sec = 10,
    min_ram = 20480
}

local function on_scheduler()
    collectgarbage()
    local heap = node.heap()
    if heap < rwd.min_ram then
        if log.is_warn then
            log.warn("RWD restart, RAM: ", heap)
        end
        node.restart()
    end
end

function rwd.start()
    scheduler.register(on_scheduler, "blink", rwd.frequency_sec, rwd.frequency_sec)
end