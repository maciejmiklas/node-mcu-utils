function repeats(s,c)
    local _,n = s:gsub(c,"")
    return n
end

print(repeats("A001BBD0","0"))
print(repeats("A001BBD0","B"))