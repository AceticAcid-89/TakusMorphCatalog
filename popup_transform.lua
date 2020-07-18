local _, ns = ...

UnitPopupButtons["PLAY_AS"] = {
	text = "play as",
    value = "play as",
	dist = 0,
	func = function()
        local npc_name, npc_guid = getTargetInfo()
        local npc_id = common.split(npc_guid, "-")[6]
        local found
        for _, k in ipairs({0, 1, 2}) do
            tableId = "npc_id_table_" .. k
            if ns[tableId]["npc_id_" .. npc_id] then
                local display_id = ns[tableId]["npc_id_" .. npc_id].display_id
                if IsAltKeyDown() then
                    msg = ".mount " .. display_id
                else
                    msg = ".morph " .. display_id
                end
                DEFAULT_CHAT_FRAME.editBox:SetText(msg)
                ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
                found = true
                break
            end
        end
        if not found then
            print("not found npc_id " .. npc_id .. " with npc_name " .. npc_name .. " in database")
        end
	end
}

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

function assignFuncHook(...)
	for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
        local button_id =
            "DropDownList".. UIDROPDOWNMENU_MENU_LEVEL .. "Button" .. i
		local button = _G[button_id]
		if button.value == "CANCEL" then
            button.func = UnitPopupButtons["PLAY_AS"].func
            button.text = UnitPopupButtons["PLAY_AS"].text
            button.value = "PLAY AS"
            button.tooltipTitle = "PLAY AS"
		end
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

hooksecurefunc("UnitPopup_ShowMenu", assignFuncHook)
