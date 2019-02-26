log = {
    isInfo = true,
    isWarn = true
}

function log.info(msg)
    print("## " .. msg)
end

function log.error(msg)
    print("##ERR## " .. msg)
end

function log.warn(msg)
    print("##WARN## " .. msg)
end