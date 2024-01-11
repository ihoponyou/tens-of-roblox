--!strict

local TableUtil = {}

function TableUtil.GetKeys(dict: {[any]: any}): {any}
    local keys = {}

    for k, _ in dict do
        table.insert(keys, k)
    end

    return keys
end

return TableUtil
