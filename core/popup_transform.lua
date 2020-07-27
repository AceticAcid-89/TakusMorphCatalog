local _, ns = ...

ns.display_favorite = {}

function Transform()
    local npc_name, npc_guid = getTargetInfo()
    local npc_id = common.split(npc_guid, "-")[6]
    local found
    for _, k in ipairs({0, 1, 2}) do
        local tableId = "npc_id_table_" .. k
        if ns[tableId]["npc_id_" .. npc_id] then
            local display_id = ns[tableId]["npc_id_" .. npc_id].display_id

            -- add to display_favorite
            if IsShiftKeyDown() then
                ns.display_favorite = {}
                table.insert(ns.display_favorite, display_id)
                print("add " .. npc_name .. " to favorites")
            -- transform

            else
                local msg
                if IsAltKeyDown() then
                    msg = ".mount " .. display_id
                    print("Mount as " .. npc_name)
                else
                    msg = ".morph " .. display_id
                    print("Play as " .. npc_name)
                end
                DEFAULT_CHAT_FRAME.editBox:SetText(msg)
                ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
            end

            found = true
            break
        end
    end
    if not found then
        print("not found npc_id " .. npc_id .. " with npc_name " .. npc_name .. " in database")
    end
end

common = {}

function common.split(szFullString, szSeparator)
    local nFindStartIndex = 1
    local nSplitIndex = 1
    local nSplitArray = {}
    while true do
        local nFindLastIndex = string.find(
                szFullString, szSeparator, nFindStartIndex)
        if not nFindLastIndex then
            nSplitArray[nSplitIndex] = string.sub(
                    szFullString, nFindStartIndex, string.len(szFullString))
            break
        end
        nSplitArray[nSplitIndex] = string.sub(
                szFullString, nFindStartIndex, nFindLastIndex - 1)
        nFindStartIndex = nFindLastIndex + string.len(szSeparator)
        nSplitIndex = nSplitIndex + 1
    end
    return nSplitArray
end

function assignFuncHook(args, ...)
    if args.which == "TARGET" then
        local info = UIDropDownMenu_CreateInfo()
        info.text = "Transform"
        info.notCheckable = true
        info.func = Transform
        UIDropDownMenu_AddButton(info)
    end
end

function getTargetInfo()
    if UnitExists("target") then
        local name = UnitName("target")
        local guid = UnitGUID("target")
        return name, guid
    else
        print("no target")
        return 0, 0
    end
end

local popupTransform = CreateFrame("Frame","popupTransform")
popupTransform:SetScript("OnEvent", function()
    hooksecurefunc("UnitPopup_ShowMenu", assignFuncHook)
end)
popupTransform:RegisterEvent("PLAYER_LOGIN")
