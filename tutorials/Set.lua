function Set(list)
    local set = {}
    for _, v in ipairs(list) do
        set[v] = true
    end
    return set
end

ms = Set({ "A", "B", "c" })

print(ms.a, ms["a"], ms.A, ms["A"])

if ms.a then print("HI a") else print("NIX a") end

if ms.A then print("HI A") end