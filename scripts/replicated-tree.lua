local function getReplicatedStorageTree()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    if not replicatedStorage then
        warn("ReplicatedStorage not found!")
        return
    end

    local lines = {}
    local function recurse(instance, indent, isLast)
        indent = indent or ""
        local prefix = (indent ~= "") and (isLast and "└── " or "├── ") or ""
        table.insert(lines, indent .. prefix .. instance.Name .. " (" .. instance.ClassName .. ")")
        local children = instance:GetChildren()
        local childIndent = indent .. (isLast and "    " or "│   ")
        for i, child in ipairs(children) do
            recurse(child, childIndent, i == #children)
        end
    end

    table.insert(lines, "ReplicatedStorage (" .. replicatedStorage.ClassName .. ")")
    local children = replicatedStorage:GetChildren()
    for i, child in ipairs(children) do
        recurse(child, "", i == #children)
    end

    return table.concat(lines, "\n")
end

local treeText = getReplicatedStorageTree()
if treeText then
    print(treeText)
    if setclipboard then
        setclipboard(treeText)
    else
    end
end