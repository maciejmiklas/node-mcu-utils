log = {
    isDebug = true,
    isInfo = true,
    isWarn = true
}

function log.debug(msg)
    print("# " .. msg)
end

function log.info(msg)
    print("## " .. msg)
end

function log.error(msg)
    print("##ERR## " .. msg)
end

function log.warn(msg)
    print("##WARN## " .. msg)
end