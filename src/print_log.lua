if not file.exists("utils.log") then
    print("Log file not found")
    return
end

src = file.open("utils.log", "r")
if src then
    local line
    repeat
        line = src:read()
        if line then
            print(line)
        end
    until line == nil
    src:close();
end