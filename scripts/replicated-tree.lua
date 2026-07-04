local function getFullGameTree()
    local lines = {}
    local count = 0
    
    local function recurse(instance, indent, isLast)
        indent = indent or ""
        local prefix = (indent ~= "") and (isLast and "└── " or "├── ") or ""
        
        -- Safe property reading to prevent execution breaks on restricted instances
        local nameOk, name = pcall(function() return instance.Name end)
        local classOk, className = pcall(function() return instance.ClassName end)
        
        if not nameOk then name = "RestrictedName" end
        if not classOk then className = "RestrictedClass" end
        
        table.insert(lines, indent .. prefix .. name .. " (" .. className .. ")")
        
        -- Yield occasionally to keep the Roblox engine completely responsive
        count = count + 1
        if count % 1500 == 0 then
            task.wait()
        end
        
        local childrenOk, children = pcall(function() return instance:GetChildren() end)
        if childrenOk and children then
            local childIndent = indent .. (isLast and "    " or "│   ")
            for i, child in ipairs(children) do
                recurse(child, childIndent, i == #children)
            end
        end
    end

    table.insert(lines, "game (DataModel)")
    local children = game:GetChildren()
    for i, child in ipairs(children) do
        recurse(child, "    ", i == #children)
    end

    return table.concat(lines, "\n")
end

local treeText = getFullGameTree()
if treeText then
    print("[TaperUI] Full Game Tree compiled (" .. tostring(#treeText) .. " characters). Copying to clipboard...")
    if setclipboard then
        setclipboard(treeText)
    end
end