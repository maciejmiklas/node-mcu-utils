if not file.exists("utils.log") then
    print("Log file not found")
    return
end

src = file.open("utils.log", "r")
if src then
    local chunk
    repeat
        chunk = src:read()
        if chunk then
            print(chunk)
        end
    until chunk == nil
    src:close();
end