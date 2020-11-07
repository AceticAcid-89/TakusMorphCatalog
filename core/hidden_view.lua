local _, ns = ...

-- settings
local Debug = false
local MaxNumberOfColumn = 5
local MinNumberOfColumn = 3
local NumberOfColumn = 5
local MaxModelID = 110000
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
TakusMorphCatalogHiddenDB = {
	FavoriteList = {}
}
local hiddenSlot = {}
for i = 0, 29 do
	hiddenSlot[i] = 1
end

local weaponSlot = {}
for i = 12, 29 do
	weaponSlot[i] = 1
end

local armorSlot = {}
for i = 1, 11 do
	armorSlot[i] = 1
end

local ArmorSlotSourceType = {
	[1] = 1, [2] = 3, [3] = 15, [4] = 5, [5] = 4,
	[6] = 19, [7] = 9, [8] = 10, [10] = 7, [11] = 8
}
-- end

local function getAromorSlot(sourceID)
	local categoryID, visualID, canEnchant, icon, _, itemLink, transmogLink, _, _ =
    	C_TransmogCollection.GetAppearanceSourceInfo(sourceID)
	return ArmorSlotSourceType[categoryID]
end

local function isWeapon(sourceID)
	local categoryID, visualID, canEnchant, icon, _, itemLink, transmogLink, _, _ =
    	C_TransmogCollection.GetAppearanceSourceInfo(sourceID)
	if weaponSlot[categoryID] then
		return true
	else
		return false
	end
end

local function getItemInfo(sourceID)
	local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
    if not sourceInfo.name then
        sourceInfo.name = "UNKNOWN"
    end
	return sourceInfo.itemID .. "    " .. sourceInfo.name
end

local function itemValid(sourceID)
	local isExist
	if HiddenItems[sourceID] then
        return true
    end
	return isExist
end

local function getItemID(sourceID)
	local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
	return sourceInfo.itemID
end

local function getItemName(sourceID)
	local categoryID, visualID, canEnchant, icon, _, itemLink, transmogLink, _, _ =
    	C_TransmogCollection.GetAppearanceSourceInfo(sourceID)
	if hiddenSlot[categoryID] then
		return itemLink
	else
		return ""
	end
end

local function getItemLink(sourceID)
	local categoryID, visualID, canEnchant, icon, _, itemLink, transmogLink, _, _ =
    	C_TransmogCollection.GetAppearanceSourceInfo(sourceID)
	return itemLink
end

local function doSearchHidden(inputStr)
	local result = {}
	local hiddenID = 0
	while hiddenID < MaxModelID do
		local name = getItemName(hiddenID)
		if strmatch(string.lower(name), string.lower(inputStr)) then
			result[hiddenID] = 1
        end
        hiddenID = hiddenID + 1
	end
	return result
end

-- TMCHiddenFrame (main)
local TMCHiddenFrame = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
TMCHiddenFrame:Hide()
TMCHiddenFrame:SetFrameStrata("DIALOG")
TMCHiddenFrame:SetWidth(WindowWidth)
TMCHiddenFrame:SetHeight(WindowHeight)
TMCHiddenFrame:SetPoint("TOPLEFT",0,0)
TMCHiddenFrame:SetMovable(true)
TMCHiddenFrame:SetMinResize(400, 400)
TMCHiddenFrame:SetClampedToScreen(true)
TMCHiddenFrame:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
TMCHiddenFrame:EnableKeyboard(true)
TMCHiddenFrame:SetScript("OnKeyDown", function(self, key)
	if key == "ESCAPE" then
		TMCHiddenFrame:Hide()
	end
end)
-- end TMCHiddenFrame

if Debug then
	print("TMCHiddenFrame OK")
end

-- Collection
TMCHiddenFrame.Collection = CreateFrame("Button", nil, TMCHiddenFrame, "UIPanelButtonTemplate")
TMCHiddenFrame.Collection:SetSize(120,30)
TMCHiddenFrame.Collection:SetPoint("TOPLEFT", 10, -10)
TMCHiddenFrame.Collection:SetText("Collection")
TMCHiddenFrame.Collection:SetScript("OnClick", function(self, Button, Down)
	OffsetModelID = 0
	ModelID = 0
	DisplayFavorites = false
	InSearchFlag = false
	NumberOfColumn = MaxNumberOfColumn
	TMCHiddenFrame.Gallery:Load(true)
end)
-- end Collection

-- Favorites
TMCHiddenFrame.Favorites = CreateFrame("Button", nil, TMCHiddenFrame, "UIPanelButtonTemplate")
TMCHiddenFrame.Favorites:SetSize(120, 30)
TMCHiddenFrame.Favorites:SetPoint("TOPLEFT", 130, -10)
TMCHiddenFrame.Favorites:SetText("Favorites")
TMCHiddenFrame.Favorites:SetScript("OnClick", function(self, Button, Down)
	OffsetModelID = 0
	ModelID = 0
	DisplayFavorites = true
	InSearchFlag = false
	GoBackDepth = 0
	TMCHiddenFrame.Gallery:Load(true)
end)
-- end Favorites

-- ModelPreview
TMCHiddenFrame.ModelPreview = CreateFrame("Frame", nil, TMCHiddenFrame, BackdropTemplateMixin and "BackdropTemplate")
TMCHiddenFrame.ModelPreview.CloseButton = CreateFrame(
		"Button", nil, TMCHiddenFrame.ModelPreview, "UIPanelCloseButton")
TMCHiddenFrame.ModelPreview.CloseButton:SetPoint("TOPRIGHT", 695, -5)
TMCHiddenFrame.ModelPreview.CloseButton:SetScript("OnClick", function(self, Button, Down)
	TMCHiddenFrame.ModelPreview:Hide()
end)

TMCHiddenFrame.ModelPreview:SetFrameStrata("DIALOG")
TMCHiddenFrame.ModelPreview:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    insets = {left = 11, right = 12, top = 12, bottom = 11}
})
TMCHiddenFrame.ModelPreview:SetAllPoints()
--
TMCHiddenFrame.ModelPreview.ModelFrame = CreateFrame(
		"DressUpModel", "OVERLAY", TMCHiddenFrame.ModelPreview, BackdropTemplateMixin and "BackdropTemplate")
TMCHiddenFrame.ModelPreview:Hide()

--
TMCHiddenFrame.ModelPreview.FontString = TMCHiddenFrame.ModelPreview.ModelFrame:CreateFontString(
		nil, "BACKGROUND", "GameFontWhite")
TMCHiddenFrame.ModelPreview.FontString:SetJustifyV("TOP")
TMCHiddenFrame.ModelPreview.FontString:SetJustifyH("LEFT")
TMCHiddenFrame.ModelPreview.FontString:SetPoint("TOPLEFT", 15, -15)

--
TMCHiddenFrame.ModelPreview.ModelFrame.DisplayInfo = 0
TMCHiddenFrame.ModelPreview.ModelFrame:SetWidth(WindowWidth - 300)
TMCHiddenFrame.ModelPreview.ModelFrame:SetHeight(WindowHeight)
TMCHiddenFrame.ModelPreview.ModelFrame:SetPoint("TOPRIGHT", 700, 0)
TMCHiddenFrame.ModelPreview.ModelFrame:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
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
	local offsetX = x - lastX
	local offsetY = y - lastY
	local offsetDegree = offsetX / 100 * math.pi
	local offsetScale = (offsetY / 180 * 2) * 0.45 + 1
	self:SetFacing(offsetDegree)
	self:SetModelScale(offsetScale)
end
TMCHiddenFrame.ModelPreview.ModelFrame:EnableMouse()
TMCHiddenFrame.ModelPreview.ModelFrame:SetScript("OnUpdate", OnUpdate)
TMCHiddenFrame.ModelPreview.ModelFrame:Show()
--
TMCHiddenFrame.ModelPreview.Favorite = TMCHiddenFrame.ModelPreview.ModelFrame:CreateTexture(nil, "ARTWORK")
TMCHiddenFrame.ModelPreview.Favorite:SetPoint("BOTTOMRIGHT", -10, 0)
TMCHiddenFrame.ModelPreview.Favorite:SetSize(40, 40)
TMCHiddenFrame.ModelPreview.Favorite:SetTexture("Interface\\Collections\\Collections")
TMCHiddenFrame.ModelPreview.Favorite:SetTexCoord(0.18, 0.02, 0.18, 0.07, 0.23, 0.02, 0.23, 0.07)

--
TMCHiddenFrame.ModelPreview.AddToFavorite = CreateFrame(
		"Button", nil, TMCHiddenFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCHiddenFrame.ModelPreview.AddToFavorite:SetSize(120, 30)
TMCHiddenFrame.ModelPreview.AddToFavorite:SetPoint("BOTTOMLEFT", 11, 11)
TMCHiddenFrame.ModelPreview.AddToFavorite:SetText("Add to Favorite")
TMCHiddenFrame.ModelPreview.AddToFavorite:SetScript("OnClick", function(self, Button, Down)
	TakusMorphCatalogHiddenDB.FavoriteList[TMCHiddenFrame.ModelPreview.ModelFrame.DisplayInfo] = 1
	TMCHiddenFrame.ModelPreview.AddToFavorite:Hide()
	TMCHiddenFrame.ModelPreview.RemoveFavorite:Show()
	TMCHiddenFrame.ModelPreview.Favorite:Show()
	ModelID = OffsetModelID
	TMCHiddenFrame.Gallery:Load()
end)

--
TMCHiddenFrame.ModelPreview.RemoveFavorite = CreateFrame(
		"Button", nil, TMCHiddenFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCHiddenFrame.ModelPreview.RemoveFavorite:SetSize(120, 30)
TMCHiddenFrame.ModelPreview.RemoveFavorite:SetPoint("BOTTOMLEFT", 11, 11)
TMCHiddenFrame.ModelPreview.RemoveFavorite:SetText("Remove Favorite")
TMCHiddenFrame.ModelPreview.RemoveFavorite:SetScript("OnClick", function(self, Button, Down)
	TakusMorphCatalogHiddenDB.FavoriteList[TMCHiddenFrame.ModelPreview.ModelFrame.DisplayInfo] = nil
	TMCHiddenFrame.ModelPreview.AddToFavorite:Show()
	TMCHiddenFrame.ModelPreview.RemoveFavorite:Hide()
	TMCHiddenFrame.ModelPreview.Favorite:Hide()
	ModelID = OffsetModelID
	TMCHiddenFrame.Gallery:Load()
end)

--
TMCHiddenFrame.ModelPreview.mainHand = CreateFrame(
		"Button", nil, TMCHiddenFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCHiddenFrame.ModelPreview.mainHand:SetSize(100, 30)
TMCHiddenFrame.ModelPreview.mainHand:SetPoint("BOTTOMLEFT", 131, 11)
TMCHiddenFrame.ModelPreview.mainHand:SetText("MAIN HAND")
TMCHiddenFrame.ModelPreview.mainHand:SetScript("OnClick", function(self, Button, Down)
	local msg = ".item 16 " .. getItemID(TMCHiddenFrame.ModelPreview.ModelFrame.DisplayInfo)
	DEFAULT_CHAT_FRAME.editBox:SetText(msg)
	ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
end)

--
TMCHiddenFrame.ModelPreview.offHand = CreateFrame(
		"Button", nil, TMCHiddenFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCHiddenFrame.ModelPreview.offHand:SetSize(100, 30)
TMCHiddenFrame.ModelPreview.offHand:SetPoint("BOTTOMLEFT", 231, 11)
TMCHiddenFrame.ModelPreview.offHand:SetText("OFF HAND")
TMCHiddenFrame.ModelPreview.offHand:SetScript("OnClick", function(self, Button, Down)
	local msg = ".item 17 " .. getItemID(TMCHiddenFrame.ModelPreview.ModelFrame.DisplayInfo)
	DEFAULT_CHAT_FRAME.editBox:SetText(msg)
	ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
end)

TMCHiddenFrame.ModelPreview.morphAS = CreateFrame(
		"Button", nil, TMCHiddenFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCHiddenFrame.ModelPreview.morphAS:SetSize(100, 30)
TMCHiddenFrame.ModelPreview.morphAS:SetPoint("BOTTOMLEFT", 331, 11)
TMCHiddenFrame.ModelPreview.morphAS:SetText("MORPH AS")
TMCHiddenFrame.ModelPreview.morphAS:SetScript("OnClick", function(self, Button, Down)
	local armor_slot = getAromorSlot(TMCHiddenFrame.ModelPreview.ModelFrame.DisplayInfo)
	local msg = ".item " .. armor_slot .. " " .. getItemID(TMCHiddenFrame.ModelPreview.ModelFrame.DisplayInfo)
	DEFAULT_CHAT_FRAME.editBox:SetText(msg)
	ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
end)
-- end ModelPreview

-- TitleFrame
TMCHiddenFrame.TitleFrame = CreateFrame("Frame", nil, TMCHiddenFrame)
TMCHiddenFrame.TitleFrame:SetSize(TMCHiddenFrame:GetWidth(), 40)
TMCHiddenFrame.TitleFrame:SetPoint("TOP")
TMCHiddenFrame.TitleFrame.Background = TMCHiddenFrame.TitleFrame:CreateTexture(nil, "BACKGROUND")
TMCHiddenFrame.TitleFrame.Background:SetColorTexture(1, 0, 0, 0)
TMCHiddenFrame.TitleFrame.Background:SetAllPoints(TMCHiddenFrame.TitleFrame)
TMCHiddenFrame.TitleFrame.FontString = TMCHiddenFrame.TitleFrame:CreateFontString(nil, nil, "GameFontNormal")
TMCHiddenFrame.TitleFrame.FontString:SetText("Taku's Morph Catalog")
TMCHiddenFrame.TitleFrame.FontString:SetAllPoints(TMCHiddenFrame.TitleFrame)
TMCHiddenFrame.TitleFrame.CloseButton = CreateFrame("Button", nil, TMCHiddenFrame.TitleFrame, "UIPanelCloseButton")
TMCHiddenFrame.TitleFrame.CloseButton:SetPoint("RIGHT", -3, 0)
TMCHiddenFrame.TitleFrame.CloseButton:SetScript("OnClick", function(self, Button, Down)
	TMCHiddenFrame:Hide()
end)
TMCHiddenFrame.TitleFrame:SetScript("OnMouseDown", function(self, Button)
	TMCHiddenFrame:StartMoving()
end)
TMCHiddenFrame.TitleFrame:SetScript("OnMouseUp", function(self, Button)
	TMCHiddenFrame:StopMovingOrSizing()
end)
-- end TitleFrame

-- PageController
TMCHiddenFrame.PageController = CreateFrame("Frame", nil, TMCHiddenFrame)
TMCHiddenFrame.PageController:SetSize(TMCHiddenFrame:GetWidth(), 75)
TMCHiddenFrame.PageController:SetPoint("BOTTOM")
TMCHiddenFrame.PageController.FontString = TMCHiddenFrame.PageController:CreateFontString(
		nil, nil, "GameFontWhite")
TMCHiddenFrame.PageController.FontString:SetAllPoints(TMCHiddenFrame.PageController)

function TMCHiddenFrame.PageController:UpdateButtons()
	if (ModelID >= MaxModelID) then
		TMCHiddenFrame.NextPageButton:SetBackdrop({
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled",
		  insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
	else
		TMCHiddenFrame.NextPageButton:SetBackdrop( {
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up",
		  insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
	end
	if (GoBackDepth == 0) then
		TMCHiddenFrame.PreviousPageButton:SetBackdrop( {
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled",
		  insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
	else
		TMCHiddenFrame.PreviousPageButton:SetBackdrop( {
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up",
		  insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
	end
end
-- end PageController

-- NextPageButton
TMCHiddenFrame.NextPageButton = CreateFrame("Button", nil, TMCHiddenFrame.PageController, BackdropTemplateMixin and "BackdropTemplate")
--
TMCHiddenFrame.NextPageButton:SetSize(45, 45)
TMCHiddenFrame.NextPageButton:SetPoint("Center", 100, 0)
TMCHiddenFrame.NextPageButton:SetBackdrop( {
  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up",
  insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
--
TMCHiddenFrame.NextPageButton.HoverGlow = TMCHiddenFrame.NextPageButton:CreateTexture(nil, "BACKGROUND")
TMCHiddenFrame.NextPageButton.HoverGlow:SetTexture("Interface\\Buttons\\CheckButtonGlow")
TMCHiddenFrame.NextPageButton.HoverGlow:SetAllPoints(TMCHiddenFrame.NextPageButton)
TMCHiddenFrame.NextPageButton.HoverGlow:SetAlpha(0)
--
TMCHiddenFrame.NextPageButton:SetScript("OnEnter", function()
	if (ModelID < MaxModelID) then
		TMCHiddenFrame.NextPageButton.HoverGlow:SetAlpha(1)
	end
end);
--
TMCHiddenFrame.NextPageButton:SetScript("OnLeave", function()
	TMCHiddenFrame.NextPageButton.HoverGlow:SetAlpha(0)
end);
--
TMCHiddenFrame.NextPageButton:SetScript("OnClick", function(self, Button, Down)
	if (ModelID >= MaxModelID) then
		return
	end
	OffsetModelID = ModelID
	--
	GoBackStack[GoBackDepth] = {LastMaxModelID=LastMaxModelID, Zoom=NumberOfColumn}
	GoBackDepth = GoBackDepth + 1
	--
	if InSearchFlag then
		TMCHiddenFrame.Gallery:Load(false, InSearchFlag)
	else
		TMCHiddenFrame.Gallery:Load()
	end
	--
end)
-- end NextPageButton

-- GoToEditBox
TMCHiddenFrame.GoToEditBox = CreateFrame('EditBox', nil, TMCHiddenFrame.PageController, "InputBoxTemplate")
--
TMCHiddenFrame.GoToEditBox.FontString = TMCHiddenFrame.GoToEditBox:CreateFontString(nil, nil, "GameFontWhite")
TMCHiddenFrame.GoToEditBox.FontString:SetPoint("LEFT", -50, 0)
TMCHiddenFrame.GoToEditBox.FontString:SetText("GotoID")
--
TMCHiddenFrame.GoToEditBox:SetPoint("LEFT", 100, 0)
TMCHiddenFrame.GoToEditBox:SetMultiLine(false)
TMCHiddenFrame.GoToEditBox:SetAutoFocus(false)
TMCHiddenFrame.GoToEditBox:EnableMouse(true)
TMCHiddenFrame.GoToEditBox:SetMaxLetters(6)
TMCHiddenFrame.GoToEditBox:SetTextInsets(0, 0, 0, 0)
TMCHiddenFrame.GoToEditBox:SetFont('Fonts\\ARIALN.ttf', 12, '')
TMCHiddenFrame.GoToEditBox:SetWidth(70)
TMCHiddenFrame.GoToEditBox:SetHeight(20)
TMCHiddenFrame.GoToEditBox:SetScript('OnEscapePressed', function() TMCHiddenFrame.GoToEditBox:ClearFocus() end)
TMCHiddenFrame.GoToEditBox:SetScript('OnEnterPressed', function()
	TMCHiddenFrame.GoToEditBox:ClearFocus()
	--
	OffsetModelID = tonumber(TMCHiddenFrame.GoToEditBox:GetText())
	if OffsetModelID >= MaxModelID then
		OffsetModelID = MaxModelID
	end
	NumberOfColumn = MaxNumberOfColumn
	ModelID = OffsetModelID
	InSearchFlag = false
	TMCHiddenFrame.Gallery:Load(true)
end)
-- end GoToEditBox

-- search editBox
TMCHiddenFrame.searchEditBox = CreateFrame(
		'EditBox', nil, TMCHiddenFrame.PageController, "InputBoxTemplate")
--
TMCHiddenFrame.searchEditBox.FontString =
	TMCHiddenFrame.searchEditBox:CreateFontString(nil, nil, "GameFontWhite")
TMCHiddenFrame.searchEditBox.FontString:SetPoint("LEFT", -50, 0)
TMCHiddenFrame.searchEditBox.FontString:SetText("Search")
--
TMCHiddenFrame.searchEditBox:SetPoint("RIGHT", -50, 0)
TMCHiddenFrame.searchEditBox:SetMultiLine(false)
TMCHiddenFrame.searchEditBox:SetAutoFocus(false)
TMCHiddenFrame.searchEditBox:EnableMouse(true)
TMCHiddenFrame.searchEditBox:SetMaxLetters(50)
TMCHiddenFrame.searchEditBox:SetTextInsets(0, 0, 0, 0)
TMCHiddenFrame.searchEditBox:SetFont('Fonts\\ARIALN.ttf', 12, '')
TMCHiddenFrame.searchEditBox:SetWidth(70)
TMCHiddenFrame.searchEditBox:SetHeight(20)
TMCHiddenFrame.searchEditBox:SetScript(
		'OnEscapePressed', function() TMCHiddenFrame.searchEditBox:ClearFocus() end)
TMCHiddenFrame.searchEditBox:SetScript('OnEnterPressed', function()
	TMCHiddenFrame.searchEditBox:ClearFocus()
	InSearchFlag = true
	OffsetModelID = 0
	ModelID = 0
	DisplayFavorites = false
	NumberOfColumn = MaxNumberOfColumn
	--
	SearchResult = doSearchHidden(TMCHiddenFrame.searchEditBox:GetText())
	TMCHiddenFrame.Gallery:Load(true, InSearchFlag)
end)
-- end editBox

-- PreviousPageButton
TMCHiddenFrame.PreviousPageButton = CreateFrame("Button", nil, TMCHiddenFrame.PageController, BackdropTemplateMixin and "BackdropTemplate")
TMCHiddenFrame.PreviousPageButton:SetSize(45, 45)
TMCHiddenFrame.PreviousPageButton:SetPoint("Center", -100, 0)
TMCHiddenFrame.PreviousPageButton:SetBackdrop({
  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled",
  insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
TMCHiddenFrame.PreviousPageButton.HoverGlow =
	TMCHiddenFrame.PreviousPageButton:CreateTexture(nil, "BACKGROUND")
TMCHiddenFrame.PreviousPageButton.HoverGlow:SetTexture("Interface\\Buttons\\CheckButtonGlow")
TMCHiddenFrame.PreviousPageButton.HoverGlow:SetAllPoints(TMCHiddenFrame.PreviousPageButton)
TMCHiddenFrame.PreviousPageButton.HoverGlow:SetAlpha(0)
TMCHiddenFrame.PreviousPageButton:SetScript("OnEnter", function()
	if (GoBackDepth > 0) then
		TMCHiddenFrame.PreviousPageButton.HoverGlow:SetAlpha(1)
	end
end);
TMCHiddenFrame.PreviousPageButton:SetScript("OnLeave", function()
	TMCHiddenFrame.PreviousPageButton.HoverGlow:SetAlpha(0)
end);
TMCHiddenFrame.PreviousPageButton:SetScript("OnClick", function(self, Button, Down)
	if (GoBackDepth == 0) then
		return
	end
	OffsetModelID = GoBackStack[GoBackDepth-1].LastMaxModelID
	--
	ModelID = OffsetModelID
	NumberOfColumn = MaxNumberOfColumn
	TMCHiddenFrame.Gallery:Load(true, InSearchFlag)
	--
	ModelID = OffsetModelID
	NumberOfColumn = GoBackStack[GoBackDepth-1].Zoom
	GoBackStack[GoBackDepth-1] = nil
	GoBackDepth = GoBackDepth - 1
	TMCHiddenFrame.Gallery:Load()
	--
end)
-- end PreviousPageButton

-- Gallery
TMCHiddenFrame.Gallery = CreateFrame("Frame", nil, TMCHiddenFrame)
TMCHiddenFrame.Gallery:SetPoint("TOP", 0, -50)
TMCHiddenFrame.Gallery:SetSize(TMCHiddenFrame:GetWidth() - 50, TMCHiddenFrame:GetHeight() - 125)
TMCHiddenFrame.Gallery:SetScript("OnMouseWheel", function(self, delta)
	local NewNumberOfColumn = NumberOfColumn
	if (delta < 0) then
		if (NumberOfColumn == MaxNumberOfColumn) then
			return
		end
		local NewNumberOfColumn = NumberOfColumn * 2
		-- pop all inferior zoom from gobackstack
		local Depth = GoBackDepth - 1
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
	TMCHiddenFrame.Gallery:Load()
end)

function TMCHiddenFrame.Gallery:Load(Reset, is_search)
	if Debug then
		print("--- TMCHiddenFrame.Gallery:Load ---")
		print("ModelID .. " .. ModelID)
		print("LastMaxModelID .. " .. LastMaxModelID)
		print("OffsetModelID .. " .. OffsetModelID)
	end
	TMCHiddenFrame.Gallery:SetSize(TMCHiddenFrame:GetWidth() - 50, TMCHiddenFrame:GetHeight() - 125)
	local ColumnWidth = TMCHiddenFrame.Gallery:GetWidth() / NumberOfColumn
	local MaxNumberOfRowsOnSinglePage = floor(TMCHiddenFrame.Gallery:GetHeight() / ColumnWidth)
	LastMaxModelID = ModelID
	ModelID = OffsetModelID
	local CellIndex = 0
	while CellIndex < NumberOfColumn * MaxNumberOfRowsOnSinglePage do
		local OffsetX = CellIndex % NumberOfColumn
		local OffsetY = floor(CellIndex / NumberOfColumn)
		if (OffsetY == MaxNumberOfRowsOnSinglePage) then
			break
		end
		local bNewWidget = (Cells[CellIndex] == nil)
		if bNewWidget then
			Cells[CellIndex] = CreateFrame("Button", nil, TMCHiddenFrame.Gallery)
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
				GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        		GameTooltip:SetHyperlink(getItemLink(self.ModelFrame.DisplayInfo))
				GameTooltip:Show()
			end)
			Cells[CellIndex]:SetScript("OnLeave", function(self, Button, Down)
				GameTooltip:Hide()
			end)
			Cells[CellIndex]:SetScript("OnClick", function(self, Button, Down)
				TMCHiddenFrame.ModelPreview.ModelFrame:SetAutoDress(false)
				TMCHiddenFrame.ModelPreview.ModelFrame:SetUnit("player")
				TMCHiddenFrame.ModelPreview.ModelFrame:SetSheathed(false)
				TMCHiddenFrame.ModelPreview.ModelFrame:Undress()
				TMCHiddenFrame.ModelPreview.ModelFrame:TryOn(getItemLink(self.ModelFrame.DisplayInfo))
				TMCHiddenFrame.ModelPreview.ModelFrame.DisplayInfo = self.ModelFrame.DisplayInfo
                TMCHiddenFrame.ModelPreview.FontString:SetText(getItemInfo(self.ModelFrame.DisplayInfo))
				if isWeapon(self.ModelFrame.DisplayInfo) then
					TMCHiddenFrame.ModelPreview.mainHand:Show()
					TMCHiddenFrame.ModelPreview.offHand:Show()
					TMCHiddenFrame.ModelPreview.morphAS:Hide()
				else
					TMCHiddenFrame.ModelPreview.mainHand:Hide()
					TMCHiddenFrame.ModelPreview.offHand:Hide()
					TMCHiddenFrame.ModelPreview.morphAS:Show()
				end
				if TakusMorphCatalogHiddenDB.FavoriteList[self.ModelFrame.DisplayInfo] then
					TMCHiddenFrame.ModelPreview.Favorite:Show()
					TMCHiddenFrame.ModelPreview.AddToFavorite:Hide()
					TMCHiddenFrame.ModelPreview.RemoveFavorite:Show()
				else
					TMCHiddenFrame.ModelPreview.Favorite:Hide()
					TMCHiddenFrame.ModelPreview.AddToFavorite:Show()
					TMCHiddenFrame.ModelPreview.RemoveFavorite:Hide()
				end
				TMCHiddenFrame.ModelPreview:Show()
			end)
		end
		-- always do
		Cells[CellIndex]:Show()
		if bNewWidget or Cells[CellIndex].ModelFrame.DisplayInfo < ModelID or Reset or is_search then
			if (DisplayFavorites) then
				while ModelID <= MaxModelID do
					if (TakusMorphCatalogHiddenDB.FavoriteList[ModelID]) and itemValid(ModelID) then
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
		if (TakusMorphCatalogHiddenDB.FavoriteList[Cells[CellIndex].ModelFrame.DisplayInfo]) then
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
	TMCHiddenFrame.PageController.FontString:SetText(LastMaxModelID .. " - " .. ModelID - 1)
	TMCHiddenFrame.PageController:UpdateButtons()
end
-- end Gallery

if Debug then
	print("ModelFrames OK")
end


function TMCHiddenFrame.TAKUSMORPHCATALOGHidden()
	TMCHiddenFrame:Show()
	OffsetModelID = 0
	ModelID = 0
	DisplayFavorites = false
	InSearchFlag = false
	NumberOfColumn = MaxNumberOfColumn
	TMCHiddenFrame.Gallery:Load(true)
end

local function myframe_OnLoad()
	local consoleCmd = "/console SET alwaysCompareItems 0"
	DEFAULT_CHAT_FRAME.editBox:SetText(consoleCmd)
	ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
end

local myframe = CreateFrame("Frame", "myframe", UIParent);
myframe:SetScript("OnEvent", function() myframe_OnLoad() end)
myframe:RegisterEvent("PLAYER_LOGIN")

ns.HiddenTMCFrame = TMCHiddenFrame