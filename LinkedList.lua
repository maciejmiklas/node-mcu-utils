do
    print("################# 1 #################")
    local list
    list = { next = list, value = "A" }
    list = { next = list, value = "B" }
    list = { next = list, value = "C" }
    list = { next = list, value = "D" }

    local l = list
    while l do
        print(l.value)
        l = l.next
    end
end

do
    print("################# 2 #################")
    local list = { value = "A", next = { value = "B", next = { value = "C", next = { value = "D" } } } }

    local l = list
    while l do
        print(l.value)
        l = l.next
    end
end