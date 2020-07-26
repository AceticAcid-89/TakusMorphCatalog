local _, ns = ...

-- settings
local Debug = false
local MaxNumberOfColumn = 5
local MinNumberOfColumn = 3
local NumberOfColumn = 5
local MaxModelID = 120000
local WindowWidth = 1000
local WindowHeight = 700

-- vars
local Cells = {}
local OffsetModelID = 0
local ModelID = OffsetModelID
local LastMaxModelID = 0
local GoBackStack = {}
local GoBackDepth = 0
local DisplayFavorites = false
local SearchResult = {}
local InSearchFlag = false
--
TakusMorphCatalogArmorDB = {
	FavoriteList = {}
}
local armorSlot = {}
for i = 1, 11 do
	armorSlot[i] = 1
end

local ArmorSlotSourceType = {
	[1] = 1, [2] = 3, [3] = 15, [4] = 5, [5] = 4,
	[6] = 19, [7] = 9, [8] = 10, [10] = 7, [11] = 8
}
-- end

local function itemValid(sourceID)
	local isExist
	local categoryID, visualID, canEnchant, icon, _, itemLink, transmogLink, _, _ =
    	C_TransmogCollection.GetAppearanceSourceInfo(sourceID)
	if armorSlot[categoryID] then
		return true
	end
	return isExist
end

local function getItemID(sourceID)
	local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
	return(sourceInfo.itemID)
end

local function getAromorSlot(sourceID)
	local categoryID, visualID, canEnchant, icon, _, itemLink, transmogLink, _, _ =
    	C_TransmogCollection.GetAppearanceSourceInfo(sourceID)
	return ArmorSlotSourceType[categoryID]
end

local function getItemLink(sourceID)
	local categoryID, visualID, canEnchant, icon, _, itemLink, transmogLink, _, _ =
    	C_TransmogCollection.GetAppearanceSourceInfo(sourceID)
	return itemLink
end

-- TMCArmorFrame (main)
local TMCArmorFrame = CreateFrame("Frame", nil, UIParent)
TMCArmorFrame:Hide()
TMCArmorFrame:SetFrameStrata("DIALOG")
TMCArmorFrame:SetWidth(WindowWidth)
TMCArmorFrame:SetHeight(WindowHeight)
TMCArmorFrame:SetPoint("TOPLEFT",0,0)
TMCArmorFrame:SetMovable(true)
TMCArmorFrame:SetMinResize(400, 400)
TMCArmorFrame:SetClampedToScreen(true)
TMCArmorFrame:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
TMCArmorFrame:EnableKeyboard(true)
TMCArmorFrame:SetScript("OnKeyDown", function(self, key)
	if key == "ESCAPE" then
		TMCArmorFrame:Hide()
	end
end)
-- end TMCArmorFrame

if Debug then
	print("TMCArmorFrame OK")
end

-- Collection
TMCArmorFrame.Collection = CreateFrame("Button", nil, TMCArmorFrame, "UIPanelButtonTemplate")
TMCArmorFrame.Collection:SetSize(120,30)
TMCArmorFrame.Collection:SetPoint("TOPLEFT", 10, -10)
TMCArmorFrame.Collection:SetText("Collection")
TMCArmorFrame.Collection:SetScript("OnClick", function(self, Button, Down)
	OffsetModelID = 0
	ModelID = 0
	DisplayFavorites = false
	InSearchFlag = false
	NumberOfColumn = MaxNumberOfColumn
	TMCArmorFrame.Gallery:Load(true)
end)
-- end Collection

-- Favorites
TMCArmorFrame.Favorites = CreateFrame("Button", nil, TMCArmorFrame, "UIPanelButtonTemplate")
TMCArmorFrame.Favorites:SetSize(120, 30)
TMCArmorFrame.Favorites:SetPoint("TOPLEFT", 130, -10)
TMCArmorFrame.Favorites:SetText("Favorites")
TMCArmorFrame.Favorites:SetScript("OnClick", function(self, Button, Down)
	OffsetModelID = 0
	ModelID = 0
	DisplayFavorites = true
	InSearchFlag = false
	GoBackDepth = 0
	TMCArmorFrame.Gallery:Load(true)
end)
-- end Favorites

-- ModelPreview
TMCArmorFrame.ModelPreview = CreateFrame("Frame", nil, TMCArmorFrame)
TMCArmorFrame.ModelPreview.CloseButton = CreateFrame(
		"Button", nil, TMCArmorFrame.ModelPreview, "UIPanelCloseButton")
TMCArmorFrame.ModelPreview.CloseButton:SetPoint("TOPRIGHT", 695, -5)
TMCArmorFrame.ModelPreview.CloseButton:SetScript("OnClick", function(self, Button, Down)
	TMCArmorFrame.ModelPreview:Hide()
end)

TMCArmorFrame.ModelPreview:SetFrameStrata("DIALOG")
TMCArmorFrame.ModelPreview:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    insets = {left = 11, right = 12, top = 12, bottom = 11}
})
TMCArmorFrame.ModelPreview:SetAllPoints()
--
TMCArmorFrame.ModelPreview.ModelFrame = CreateFrame(
		"DressUpModel", "OVERLAY", TMCArmorFrame.ModelPreview)
TMCArmorFrame.ModelPreview:Hide()

--
TMCArmorFrame.ModelPreview.FontString = TMCArmorFrame.ModelPreview.ModelFrame:CreateFontString(
		nil, "BACKGROUND", "GameFontWhite")
TMCArmorFrame.ModelPreview.FontString:SetJustifyV("TOP")
TMCArmorFrame.ModelPreview.FontString:SetJustifyH("LEFT")
TMCArmorFrame.ModelPreview.FontString:SetPoint("TOPLEFT", 15, -15)

--
TMCArmorFrame.ModelPreview.ModelFrame.DisplayInfo = 0
TMCArmorFrame.ModelPreview.ModelFrame:SetWidth(WindowWidth - 300)
TMCArmorFrame.ModelPreview.ModelFrame:SetHeight(WindowHeight)
TMCArmorFrame.ModelPreview.ModelFrame:SetPoint("TOPRIGHT", 700, 0)
TMCArmorFrame.ModelPreview.ModelFrame:SetBackdrop({
	bgFile = "Interface\\FrameGeneral\\UI-Background-Marble.PNG",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    insets = {left = 11, right = 12, top = 12, bottom = 11}
})

local lastX = 0
local lastY = 520

local function OnUpdate(self, elapsed)
	local x, y = GetCursorPosition()
	if x > 1140 or x < 780 then
		self:SetFacing(0)
		self:SetModelScale(1)
		return
	end
	if y > 700 or y < 340 then
		self:SetFacing(0)
		self:SetModelScale(1)
		return
	end
	offsetX = x - lastX
	offsetY = y - lastY
	offsetDegree = offsetX / 100 * math.pi
	offsetScale = (offsetY / 180 * 2) * 0.45 + 1
	self:SetFacing(offsetDegree)
	self:SetModelScale(offsetScale)
end
TMCArmorFrame.ModelPreview.ModelFrame:EnableMouse()
TMCArmorFrame.ModelPreview.ModelFrame:SetScript("OnUpdate", OnUpdate)
TMCArmorFrame.ModelPreview.ModelFrame:Show()
--
TMCArmorFrame.ModelPreview.Favorite = TMCArmorFrame.ModelPreview.ModelFrame:CreateTexture(nil, "ARTWORK")
TMCArmorFrame.ModelPreview.Favorite:SetPoint("BOTTOMRIGHT", -10, 0)
TMCArmorFrame.ModelPreview.Favorite:SetSize(40, 40)
TMCArmorFrame.ModelPreview.Favorite:SetTexture("Interface\\Collections\\Collections")
TMCArmorFrame.ModelPreview.Favorite:SetTexCoord(0.18, 0.02, 0.18, 0.07, 0.23, 0.02, 0.23, 0.07)

--
TMCArmorFrame.ModelPreview.AddToFavorite = CreateFrame(
		"Button", nil, TMCArmorFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCArmorFrame.ModelPreview.AddToFavorite:SetSize(120, 30)
TMCArmorFrame.ModelPreview.AddToFavorite:SetPoint("BOTTOMLEFT", 11, 11)
TMCArmorFrame.ModelPreview.AddToFavorite:SetText("Add to Favorite")
TMCArmorFrame.ModelPreview.AddToFavorite:SetScript("OnClick", function(self, Button, Down)
	TakusMorphCatalogArmorDB.FavoriteList[TMCArmorFrame.ModelPreview.ModelFrame.DisplayInfo] = 1
	TMCArmorFrame.ModelPreview.AddToFavorite:Hide()
	TMCArmorFrame.ModelPreview.RemoveFavorite:Show()
	TMCArmorFrame.ModelPreview.Favorite:Show()
	ModelID = OffsetModelID
	TMCArmorFrame.Gallery:Load()
end)

--
TMCArmorFrame.ModelPreview.RemoveFavorite = CreateFrame(
		"Button", nil, TMCArmorFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCArmorFrame.ModelPreview.RemoveFavorite:SetSize(120, 30)
TMCArmorFrame.ModelPreview.RemoveFavorite:SetPoint("BOTTOMLEFT", 11, 11)
TMCArmorFrame.ModelPreview.RemoveFavorite:SetText("Remove Favorite")
TMCArmorFrame.ModelPreview.RemoveFavorite:SetScript("OnClick", function(self, Button, Down)
	TakusMorphCatalogArmorDB.FavoriteList[TMCArmorFrame.ModelPreview.ModelFrame.DisplayInfo] = nil
	TMCArmorFrame.ModelPreview.AddToFavorite:Show()
	TMCArmorFrame.ModelPreview.RemoveFavorite:Hide()
	TMCArmorFrame.ModelPreview.Favorite:Hide()
	ModelID = OffsetModelID
	TMCArmorFrame.Gallery:Load()
end)

--
TMCArmorFrame.ModelPreview.morphAS = CreateFrame(
		"Button", nil, TMCArmorFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCArmorFrame.ModelPreview.morphAS:SetSize(100, 30)
TMCArmorFrame.ModelPreview.morphAS:SetPoint("BOTTOMLEFT", 131, 11)
TMCArmorFrame.ModelPreview.morphAS:SetText("MORPH AS")
TMCArmorFrame.ModelPreview.morphAS:SetScript("OnClick", function(self, Button, Down)
	local armor_slot = getAromorSlot(TMCArmorFrame.ModelPreview.ModelFrame.DisplayInfo)
	msg = ".item " .. armor_slot .. " " .. getItemID(TMCArmorFrame.ModelPreview.ModelFrame.DisplayInfo)
	DEFAULT_CHAT_FRAME.editBox:SetText(msg)
	ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
end)

-- end ModelPreview

-- TitleFrame
TMCArmorFrame.TitleFrame = CreateFrame("Frame", nil, TMCArmorFrame)
TMCArmorFrame.TitleFrame:SetSize(TMCArmorFrame:GetWidth(), 40)
TMCArmorFrame.TitleFrame:SetPoint("TOP")
TMCArmorFrame.TitleFrame.Background = TMCArmorFrame.TitleFrame:CreateTexture(nil, "BACKGROUND")
TMCArmorFrame.TitleFrame.Background:SetColorTexture(1, 0, 0, 0)
TMCArmorFrame.TitleFrame.Background:SetAllPoints(TMCArmorFrame.TitleFrame)
TMCArmorFrame.TitleFrame.FontString = TMCArmorFrame.TitleFrame:CreateFontString(nil, nil, "GameFontNormal")
TMCArmorFrame.TitleFrame.FontString:SetText("Taku's Morph Catalog")
TMCArmorFrame.TitleFrame.FontString:SetAllPoints(TMCArmorFrame.TitleFrame)
TMCArmorFrame.TitleFrame.CloseButton = CreateFrame("Button", nil, TMCArmorFrame.TitleFrame, "UIPanelCloseButton")
TMCArmorFrame.TitleFrame.CloseButton:SetPoint("RIGHT", -3, 0)
TMCArmorFrame.TitleFrame.CloseButton:SetScript("OnClick", function(self, Button, Down)
	TMCArmorFrame:Hide()
end)
TMCArmorFrame.TitleFrame:SetScript("OnMouseDown", function(self, Button)
	TMCArmorFrame:StartMoving()
end)
TMCArmorFrame.TitleFrame:SetScript("OnMouseUp", function(self, Button)
	TMCArmorFrame:StopMovingOrSizing()
end)
-- end TitleFrame

-- PageController
TMCArmorFrame.PageController = CreateFrame("Frame", nil, TMCArmorFrame)
TMCArmorFrame.PageController:SetSize(TMCArmorFrame:GetWidth(), 75)
TMCArmorFrame.PageController:SetPoint("BOTTOM")
TMCArmorFrame.PageController.FontString = TMCArmorFrame.PageController:CreateFontString(
		nil, nil, "GameFontWhite")
TMCArmorFrame.PageController.FontString:SetAllPoints(TMCArmorFrame.PageController)

function TMCArmorFrame.PageController:UpdateButtons()
	if (ModelID >= MaxModelID) then
		TMCArmorFrame.NextPageButton:SetBackdrop({
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled",
		  insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
	else
		TMCArmorFrame.NextPageButton:SetBackdrop( {
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up",
		  insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
	end
	if (GoBackDepth == 0) then
		TMCArmorFrame.PreviousPageButton:SetBackdrop( {
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled",
		  insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
	else
		TMCArmorFrame.PreviousPageButton:SetBackdrop( {
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up",
		  insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
	end
end
-- end PageController

-- NextPageButton
TMCArmorFrame.NextPageButton = CreateFrame("Button", nil, TMCArmorFrame.PageController)
--
TMCArmorFrame.NextPageButton:SetSize(45, 45)
TMCArmorFrame.NextPageButton:SetPoint("Center", 100, 0)
TMCArmorFrame.NextPageButton:SetBackdrop( {
  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up",
  insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
--
TMCArmorFrame.NextPageButton.HoverGlow = TMCArmorFrame.NextPageButton:CreateTexture(nil, "BACKGROUND")
TMCArmorFrame.NextPageButton.HoverGlow:SetTexture("Interface\\Buttons\\CheckButtonGlow")
TMCArmorFrame.NextPageButton.HoverGlow:SetAllPoints(TMCArmorFrame.NextPageButton)
TMCArmorFrame.NextPageButton.HoverGlow:SetAlpha(0)
--
TMCArmorFrame.NextPageButton:SetScript("OnEnter", function()
	if (ModelID < MaxModelID) then
		TMCArmorFrame.NextPageButton.HoverGlow:SetAlpha(1)
	end
end);
--
TMCArmorFrame.NextPageButton:SetScript("OnLeave", function()
	TMCArmorFrame.NextPageButton.HoverGlow:SetAlpha(0)
end);
--
TMCArmorFrame.NextPageButton:SetScript("OnClick", function(self, Button, Down)
	if (ModelID >= MaxModelID) then
		return
	end
	OffsetModelID = ModelID
	--
	GoBackStack[GoBackDepth] = {LastMaxModelID=LastMaxModelID, Zoom=NumberOfColumn}
	GoBackDepth = GoBackDepth + 1
	--
	if InSearchFlag then
		TMCArmorFrame.Gallery:Load(false, InSearchFlag)
	else
		TMCArmorFrame.Gallery:Load()
	end
	--
end)
-- end NextPageButton

-- GoToEditBox
TMCArmorFrame.GoToEditBox = CreateFrame('EditBox', nil, TMCArmorFrame.PageController, "InputBoxTemplate")
--
TMCArmorFrame.GoToEditBox.FontString = TMCArmorFrame.GoToEditBox:CreateFontString(nil, nil, "GameFontWhite")
TMCArmorFrame.GoToEditBox.FontString:SetPoint("LEFT", -50, 0)
TMCArmorFrame.GoToEditBox.FontString:SetText("GotoID")
--
TMCArmorFrame.GoToEditBox:SetPoint("LEFT", 100, 0)
TMCArmorFrame.GoToEditBox:SetMultiLine(false)
TMCArmorFrame.GoToEditBox:SetAutoFocus(false)
TMCArmorFrame.GoToEditBox:EnableMouse(true)
TMCArmorFrame.GoToEditBox:SetMaxLetters(6)
TMCArmorFrame.GoToEditBox:SetTextInsets(0, 0, 0, 0)
TMCArmorFrame.GoToEditBox:SetFont('Fonts\\ARIALN.ttf', 12, '')
TMCArmorFrame.GoToEditBox:SetWidth(70)
TMCArmorFrame.GoToEditBox:SetHeight(20)
TMCArmorFrame.GoToEditBox:SetScript('OnEscapePressed', function() TMCArmorFrame.GoToEditBox:ClearFocus() end)
TMCArmorFrame.GoToEditBox:SetScript('OnEnterPressed', function()
	TMCArmorFrame.GoToEditBox:ClearFocus()
	--
	OffsetModelID = tonumber(TMCArmorFrame.GoToEditBox:GetText())
	if OffsetModelID >= MaxModelID then
		OffsetModelID = MaxModelID
	end
	NumberOfColumn = MaxNumberOfColumn
	ModelID = OffsetModelID
	InSearchFlag = false
	TMCArmorFrame.Gallery:Load(true)
end)
-- end GoToEditBox

-- search editBox
TMCArmorFrame.searchEditBox = CreateFrame(
		'EditBox', nil, TMCArmorFrame.PageController, "InputBoxTemplate")
--
TMCArmorFrame.searchEditBox.FontString =
	TMCArmorFrame.searchEditBox:CreateFontString(nil, nil, "GameFontWhite")
TMCArmorFrame.searchEditBox.FontString:SetPoint("LEFT", -50, 0)
TMCArmorFrame.searchEditBox.FontString:SetText("Search")
--
TMCArmorFrame.searchEditBox:SetPoint("RIGHT", -50, 0)
TMCArmorFrame.searchEditBox:SetMultiLine(false)
TMCArmorFrame.searchEditBox:SetAutoFocus(false)
TMCArmorFrame.searchEditBox:EnableMouse(true)
TMCArmorFrame.searchEditBox:SetMaxLetters(50)
TMCArmorFrame.searchEditBox:SetTextInsets(0, 0, 0, 0)
TMCArmorFrame.searchEditBox:SetFont('Fonts\\ARIALN.ttf', 12, '')
TMCArmorFrame.searchEditBox:SetWidth(70)
TMCArmorFrame.searchEditBox:SetHeight(20)
TMCArmorFrame.searchEditBox:SetScript(
		'OnEscapePressed', function() TMCArmorFrame.searchEditBox:ClearFocus() end)
TMCArmorFrame.searchEditBox:SetScript('OnEnterPressed', function()
	TMCArmorFrame.searchEditBox:ClearFocus()
	InSearchFlag = true
	OffsetModelID = 0
	ModelID = 0
	DisplayFavorites = false
	NumberOfColumn = MaxNumberOfColumn
	--
	SearchResult = doSearch(TMCArmorFrame.searchEditBox:GetText())
	TMCArmorFrame.Gallery:Load(true, InSearchFlag)
end)
-- end editBox

-- PreviousPageButton
TMCArmorFrame.PreviousPageButton = CreateFrame("Button", nil, TMCArmorFrame.PageController)
TMCArmorFrame.PreviousPageButton:SetSize(45, 45)
TMCArmorFrame.PreviousPageButton:SetPoint("Center", -100, 0)
TMCArmorFrame.PreviousPageButton:SetBackdrop({
  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled",
  insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
TMCArmorFrame.PreviousPageButton.HoverGlow =
	TMCArmorFrame.PreviousPageButton:CreateTexture(nil, "BACKGROUND")
TMCArmorFrame.PreviousPageButton.HoverGlow:SetTexture("Interface\\Buttons\\CheckButtonGlow")
TMCArmorFrame.PreviousPageButton.HoverGlow:SetAllPoints(TMCArmorFrame.PreviousPageButton)
TMCArmorFrame.PreviousPageButton.HoverGlow:SetAlpha(0)
TMCArmorFrame.PreviousPageButton:SetScript("OnEnter", function()
	if (GoBackDepth > 0) then
		TMCArmorFrame.PreviousPageButton.HoverGlow:SetAlpha(1)
	end
end);
TMCArmorFrame.PreviousPageButton:SetScript("OnLeave", function()
	TMCArmorFrame.PreviousPageButton.HoverGlow:SetAlpha(0)
end);
TMCArmorFrame.PreviousPageButton:SetScript("OnClick", function(self, Button, Down)
	if (GoBackDepth == 0) then
		return
	end
	OffsetModelID = GoBackStack[GoBackDepth-1].LastMaxModelID
	--
	ModelID = OffsetModelID
	NumberOfColumn = MaxNumberOfColumn
	TMCArmorFrame.Gallery:Load(true, InSearchFlag)
	--
	ModelID = OffsetModelID
	NumberOfColumn = GoBackStack[GoBackDepth-1].Zoom
	GoBackStack[GoBackDepth-1] = nil
	GoBackDepth = GoBackDepth - 1
	TMCArmorFrame.Gallery:Load()
	--
end)

function doSearch(inputStr)
	local result = {}
	for _, k in ipairs({0, 1, 2}) do
		local tableId = "npc_id_table_" .. k
		for npc_id, info in pairs(ns[tableId]) do
			local npc_en_name = info["en_name"]
			local npc_cn_name = info["cn_name"]
			if string.match(string.lower(npc_en_name), string.lower(inputStr)) then
				result[tonumber(info["display_id"])] = 1
			end
			if string.match(string.lower(npc_cn_name), string.lower(inputStr)) then
				result[tonumber(info["display_id"])] = 1
			end
		end
	end
	return result
end

-- end PreviousPageButton

function doGetDisplayInfo(inputDisplayID)
	local result = ""
	for _, k in ipairs({0, 1, 2}) do
		local tableId = "display_id_table_" .. k
		for display_id, items in pairs(ns[tableId]) do
			if display_id == "display_id_" .. inputDisplayID then
				for _, item in ipairs(items) do
					local npc_id = item.npc_id
					local en_name = item.en_name
					local cn_name = item.cn_name
					local item_str = en_name .. " " .. cn_name .. " " .. npc_id  ..
							 "\n"
					result = table.concat({result, item_str})
				end
			end
		end
	end
	return result
end

-- Gallery
TMCArmorFrame.Gallery = CreateFrame("Frame", nil, TMCArmorFrame)
TMCArmorFrame.Gallery:SetPoint("TOP", 0, -50)
TMCArmorFrame.Gallery:SetSize(TMCArmorFrame:GetWidth() - 50, TMCArmorFrame:GetHeight() - 125)
TMCArmorFrame.Gallery:SetScript("OnMouseWheel", function(self, delta)
	NewNumberOfColumn = NumberOfColumn
	if (delta < 0) then
		if (NumberOfColumn == MaxNumberOfColumn) then
			return
		end
		NewNumberOfColumn = NumberOfColumn * 2
		-- pop all inferior zoom from gobackstack
		Depth = GoBackDepth - 1
		while Depth > 0 and GoBackStack[Depth].Zoom < NumberOfColumn do
			GoBackStack[Depth] = nil
			Depth = Depth - 1
			GoBackDepth = GoBackDepth - 1
		end
	else
		if (NumberOfColumn == MinNumberOfColumn) then
			return
		end
		NewNumberOfColumn = NumberOfColumn / 2
	end
	ModelID = OffsetModelID
	NumberOfColumn = NewNumberOfColumn
	TMCArmorFrame.Gallery:Load()
end)

function TMCArmorFrame.Gallery:Load(Reset, is_search)
	if Debug then
		print("--- TMCArmorFrame.Gallery:Loadxx ---")
		print("ModelID .. " .. ModelID)
		print("LastMaxModelID .. " .. LastMaxModelID)
		print("OffsetModelID .. " .. OffsetModelID)
	end
	TMCArmorFrame.Gallery:SetSize(TMCArmorFrame:GetWidth() - 50, TMCArmorFrame:GetHeight() - 125)
	local ColumnWidth = TMCArmorFrame.Gallery:GetWidth() / NumberOfColumn
	local MaxNumberOfRowsOnSinglePage = floor(TMCArmorFrame.Gallery:GetHeight() / ColumnWidth)
	LastMaxModelID = ModelID
	ModelID = OffsetModelID
	local CellIndex = 0
	while CellIndex < NumberOfColumn * MaxNumberOfRowsOnSinglePage do
		OffsetX = CellIndex % NumberOfColumn
		OffsetY = floor(CellIndex / NumberOfColumn)
		if (OffsetY == MaxNumberOfRowsOnSinglePage) then
			break
		end
		local bNewWidget = (Cells[CellIndex] == nil)
		if bNewWidget then
			Cells[CellIndex] = CreateFrame("Button", nil, TMCArmorFrame.Gallery)
			Cells[CellIndex].Favorite=Cells[CellIndex]:CreateTexture(nil, "ARTWORK")
			Cells[CellIndex].Favorite:SetPoint("TOPLEFT", -5, 0)
			Cells[CellIndex].Favorite:SetSize(20, 20)
			Cells[CellIndex].Favorite:SetTexture("Interface\\Collections\\Collections")
			Cells[CellIndex].Favorite:SetTexCoord(0.18, 0.02, 0.18, 0.07, 0.23, 0.02, 0.23, 0.07)
			Cells[CellIndex]:SetFrameStrata("DIALOG")
			Cells[CellIndex].HighlightBackground = Cells[CellIndex]:CreateTexture(nil, "BACKGROUND")
			Cells[CellIndex].HighlightBackground:SetColorTexture(50, 50, 50, 0.2)
			Cells[CellIndex].HighlightBackground:SetAllPoints(Cells[CellIndex])
			Cells[CellIndex].DisplayFontString = Cells[CellIndex]:CreateFontString(nil, nil, "GameFontWhite")
			Cells[CellIndex].DisplayFontString:SetPoint("TOP", 0, 0)
			Cells[CellIndex]:SetHighlightTexture(Cells[CellIndex].HighlightBackground)
			Cells[CellIndex]:RegisterForClicks("AnyUp")
			Cells[CellIndex].ModelFrame = CreateFrame("DressUpModel", nil, Cells[CellIndex])
			Cells[CellIndex].ModelFrame:SetAutoDress(false)
			Cells[CellIndex].ModelFrame:SetUnit("player")
			Cells[CellIndex].ModelFrame:SetSheathed(false)
			Cells[CellIndex].ModelFrame:Undress()
			Cells[CellIndex]:SetScript("OnEnter", function(self, Button, Down)
				local cpmsoleCmd = "/console SET alwaysCompareItems 0"
				DEFAULT_CHAT_FRAME.editBox:SetText(cpmsoleCmd)
				ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
				GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        		GameTooltip:SetHyperlink(getItemLink(self.ModelFrame.DisplayInfo))
				GameTooltip:Show()
			end)
			Cells[CellIndex]:SetScript("OnLeave", function(self, Button, Down)
				local cpmsoleCmd = "/console SET alwaysCompareItems 0"
				DEFAULT_CHAT_FRAME.editBox:SetText(cpmsoleCmd)
				ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
				GameTooltip:Hide()
			end)
			Cells[CellIndex]:SetScript("OnClick", function(self, Button, Down)
				TMCArmorFrame.ModelPreview.ModelFrame:SetAutoDress(false)
				TMCArmorFrame.ModelPreview.ModelFrame:SetUnit("player")
				TMCArmorFrame.ModelPreview.ModelFrame:SetSheathed(false)
				TMCArmorFrame.ModelPreview.ModelFrame:Undress()
				TMCArmorFrame.ModelPreview.ModelFrame:TryOn(getItemLink(self.ModelFrame.DisplayInfo))
				TMCArmorFrame.ModelPreview.ModelFrame.DisplayInfo = self.ModelFrame.DisplayInfo
				if TakusMorphCatalogArmorDB.FavoriteList[self.ModelFrame.DisplayInfo] then
					TMCArmorFrame.ModelPreview.Favorite:Show()
					TMCArmorFrame.ModelPreview.AddToFavorite:Hide()
					TMCArmorFrame.ModelPreview.RemoveFavorite:Show()
				else
					TMCArmorFrame.ModelPreview.Favorite:Hide()
					TMCArmorFrame.ModelPreview.AddToFavorite:Show()
					TMCArmorFrame.ModelPreview.RemoveFavorite:Hide()
				end
				TMCArmorFrame.ModelPreview:Show()
			end)
		end
		-- always do
		Cells[CellIndex]:Show()
		if bNewWidget or Cells[CellIndex].ModelFrame.DisplayInfo < ModelID or Reset or is_search then
			if (DisplayFavorites) then
				while ModelID <= MaxModelID do
					if (TakusMorphCatalogArmorDB.FavoriteList[ModelID]) and itemValid(ModelID) then
						Cells[CellIndex].ModelFrame:Undress()
						Cells[CellIndex].ModelFrame:TryOn(getItemLink(ModelID))
						Cells[CellIndex].DisplayFontString:SetText(ModelID)
						ModelID = ModelID + 1
						break
					end
					ModelID = ModelID + 1
				end
			else
				while ModelID <= MaxModelID do
					if itemValid(ModelID) then
						if is_search then
							if SearchResult[ModelID] then
								Cells[CellIndex].ModelFrame:Undress()
								Cells[CellIndex].ModelFrame:TryOn(getItemLink(ModelID))
								Cells[CellIndex].DisplayFontString:SetText(ModelID)
								ModelID = ModelID + 1
								break
							end
						else
							Cells[CellIndex].ModelFrame:Undress()
							Cells[CellIndex].ModelFrame:TryOn(getItemLink(ModelID))
							Cells[CellIndex].DisplayFontString:SetText(ModelID)
							ModelID = ModelID + 1
							break
						end
					end
					ModelID = ModelID + 1
				end
			end
			Cells[CellIndex].ModelFrame.DisplayInfo = ModelID - 1
		else
			ModelID = Cells[CellIndex].ModelFrame.DisplayInfo + 1
		end
		if (Cells[CellIndex].ModelFrame.DisplayInfo == MaxModelID) then
			Cells[CellIndex]:Hide()
		end
		Cells[CellIndex]:SetWidth(ColumnWidth)
		Cells[CellIndex]:SetHeight(ColumnWidth)
		Cells[CellIndex]:SetPoint("TOPLEFT", OffsetX * ColumnWidth, OffsetY * - ColumnWidth)
		if (TakusMorphCatalogArmorDB.FavoriteList[Cells[CellIndex].ModelFrame.DisplayInfo]) then
			Cells[CellIndex].Favorite:Show()
		else
			Cells[CellIndex].Favorite:Hide()
		end
		Cells[CellIndex].ModelFrame:SetAllPoints()
		CellIndex = CellIndex + 1
	end --while
	while Cells[CellIndex] ~= nil do
		Cells[CellIndex]:Hide()
		CellIndex = CellIndex + 1
	end
	--
	TMCArmorFrame.PageController.FontString:SetText(LastMaxModelID .. " - " .. ModelID - 1)
	TMCArmorFrame.PageController:UpdateButtons()
end
-- end Gallery

if Debug then
	print("ModelFrames OK")
end

function TMCArmorFrame.TAKUSMORPHCATALOGArmors()
	TMCArmorFrame:Show()
	OffsetModelID = 0
	ModelID = 0
	DisplayFavorites = false
	InSearchFlag = false
	NumberOfColumn = MaxNumberOfColumn
	TMCArmorFrame.Gallery:Load(true)
end

ns.ArmorsTMCFrame = TMCArmorFrame