itemTable = {}
HiddenItems = {}
waitList = {}
wait = {}

local EquipableSlot = {}
for i = 1, 29 do
	EquipableSlot[i] = 1
end

local function itemValid(sourceID)
	local isExist
	local categoryID, visualID, canEnchant, icon, _, itemLink, transmogLink, _, _ =
    	C_TransmogCollection.GetAppearanceSourceInfo(sourceID)
	if EquipableSlot[categoryID] then
		return true
	end
	return isExist
end

local function getItemID(sourceID)
	local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
	return sourceInfo.itemID
end

local function getItemName(sourceID)
	local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
	return sourceInfo.name
end

local cache_writer = CreateFrame('Frame')
cache_writer:RegisterEvent('GET_ITEM_INFO_RECEIVED')
cache_writer:SetScript('OnEvent', function(self, event, ...)
    if event == 'GET_ITEM_INFO_RECEIVED' then
        -- the info is now downloaded and cached
        local itemID = ...
        if waitList[itemID] then
            local name = getItemName(index)
            if not name then
                HiddenItems[wait[itemID]] = 1
                print("item " .. itemID .. " not found")
            else
                print("item " .. itemID .. " found")
                itemTable[name] = itemID
                waitList[itemID] = nil
                wait[itemID] = nil
            end
        end
    end
end)



local function normal_loop()
    --using for instead of ipairs because want to preserve order
    for index = 1, 110000, 1 do
        if itemValid(index) then
            local itemID = getItemID(index)
            local name = getItemName(index)
            if name then
                itemTable[name] = itemID
            else
                waitList[itemID] = 1
                wait[itemID] = index
            end
        end
    end
end

local initframe = CreateFrame("Frame", "MyInitFrame", UIParent)
initframe:RegisterEvent("PLAYER_LOGIN")
initframe:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        normal_loop()
    end
end)
