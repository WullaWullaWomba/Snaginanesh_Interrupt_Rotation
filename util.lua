--luacheck: globals GetPlayerInfoByGUID IsInGroup GetNumGroupMembers IsInRaid
local _, SIR = ...
SIR.data = SIR.data or {}
SIR.util = SIR.util or {}
SIR.frameUtil = SIR.frameUtil or {}
SIR.rotationFrames = SIR.rotationFrames or {}
SIR.func = SIR.func or {}
SIR.optionFrames = SIR.optionFrames or {}
SIR.test = false
local classColorsHex = SIR.data.classColorsHex
local makeCopy
makeCopy = function(input)
    if type(input) == "table" then
        local table = {}
        for k, v in pairs(input) do
            table[k] = makeCopy(v)
        end
        return table
    else
        return input
    end
end
local myToons = {
    "Addonmsg",
    "Metestpet",
    "Trololololoo",
    "Megokick",
}
SIR.util = {
    ["contains"] = function(table, e)
        for i=1, #table do
            if table[i] == e then
                return true
            end
        end
        return false
    end,
    ["remove"] = function(table, i)
        for j=i, #table do
            table[j] = table[j+1]
        end
    end,
    ["iterateGroup"] = function(func)
        if IsInGroup() then
            local groupType = "raid"
            local numGroup = GetNumGroupMembers()
            if not IsInRaid() then
                groupType = "party"
                numGroup = numGroup -1
                func("player")
            end
            for i=1, numGroup do
                func(groupType..i)
            end
        else
            func("player")
        end
    end,
    ["myPrint"] = function(...)
        if SIR.test or SIR.util.contains(myToons, SIR.playerInfo["NAME"]) then
            print(...)
        end
    end,
    ["setTextClassColor"] = function(text, class)
        if classColorsHex[class] then
            local coloredText = "\124cFF"..classColorsHex[class]..text.."\124r"
            return coloredText
        else
            if type(class) == "string" then
                return text
            else
                SIR.util.myPrint("SIR - util.setTextClassColor - class must be a string")
                return text
            end
        end
    end,
    ["tableInsertAtStart"] = function(table, element)
        for i=#table+1, 1, -1 do
            table[i] = table[i-1]
        end
        table[1] = element
    end,
    ["tableMoveToEnd"] = function(table)
        table[#table+1] = table[1]
        for i=1, #table do
            table[i] = table[i+1]
        end
    end,
    ["makeCopy"] = makeCopy,
    ["reverseTable"] = function(table)
        local i, j = 1, #table
        while i < j do
            table[i], table[j] = table[j], table[i]
            i = i+1
            j = j-1
        end
    end,
    ["getColouredNameByGUID"] = function(GUID)
        local _, class, _, _, _, name = GetPlayerInfoByGUID(GUID)
        return "\124cFF"..classColorsHex[class]..name.."\124r"
    end
}