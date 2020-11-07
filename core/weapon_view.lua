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
TakusMorphCatalogWeaponDB = {
	FavoriteList = {}
}
local weaponSlot = {}
for i = 12, 29 do
	weaponSlot[i] = 1
end

-- end

local function itemValid(sourceID)
	local isExist
	local categoryID, visualID, canEnchant, icon, _, itemLink, transmogLink, _, _ =
    	C_TransmogCollection.GetAppearanceSourceInfo(sourceID)
	if weaponSlot[categoryID] then
		return true
	end
	return isExist
end

local function getItemInfo(sourceID)
	local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
    if not sourceInfo.name then
        sourceInfo.name = "UNKNOWN"
    end
	return sourceInfo.itemID .. "    " .. sourceInfo.name
end

local function getItemID(sourceID)
	local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
	return sourceInfo.itemID
end

local function getItemName(sourceID)
	local categoryID, visualID, canEnchant, icon, _, itemLink, transmogLink, _, _ =
    	C_TransmogCollection.GetAppearanceSourceInfo(sourceID)
	if weaponSlot[categoryID] then
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

local function doSearchWeapon(inputStr)
	local result = {}
	local weaponID = 0
	while weaponID < MaxModelID do
		local name = getItemName(weaponID)
		if strmatch(string.lower(name), string.lower(inputStr)) then
			result[weaponID] = 1
        end
        weaponID = weaponID + 1
	end
	return result
end

-- TMCWeaponFrame (main)
local TMCWeaponFrame = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
TMCWeaponFrame:Hide()
TMCWeaponFrame:SetFrameStrata("DIALOG")
TMCWeaponFrame:SetWidth(WindowWidth)
TMCWeaponFrame:SetHeight(WindowHeight)
TMCWeaponFrame:SetPoint("TOPLEFT",0,0)
TMCWeaponFrame:SetMovable(true)
TMCWeaponFrame:SetMinResize(400, 400)
TMCWeaponFrame:SetClampedToScreen(true)
TMCWeaponFrame:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
TMCWeaponFrame:EnableKeyboard(true)
TMCWeaponFrame:SetScript("OnKeyDown", function(self, key)
	if key == "ESCAPE" then
		TMCWeaponFrame:Hide()
	end
end)
-- end TMCWeaponFrame

if Debug then
	print("TMCWeaponFrame OK")
end

-- Collection
TMCWeaponFrame.Collection = CreateFrame("Button", nil, TMCWeaponFrame, "UIPanelButtonTemplate")
TMCWeaponFrame.Collection:SetSize(120,30)
TMCWeaponFrame.Collection:SetPoint("TOPLEFT", 10, -10)
TMCWeaponFrame.Collection:SetText("Collection")
TMCWeaponFrame.Collection:SetScript("OnClick", function(self, Button, Down)
	OffsetModelID = 0
	ModelID = 0
	DisplayFavorites = false
	InSearchFlag = false
	NumberOfColumn = MaxNumberOfColumn
	TMCWeaponFrame.Gallery:Load(true)
end)
-- end Collection

-- Favorites
TMCWeaponFrame.Favorites = CreateFrame("Button", nil, TMCWeaponFrame, "UIPanelButtonTemplate")
TMCWeaponFrame.Favorites:SetSize(120, 30)
TMCWeaponFrame.Favorites:SetPoint("TOPLEFT", 130, -10)
TMCWeaponFrame.Favorites:SetText("Favorites")
TMCWeaponFrame.Favorites:SetScript("OnClick", function(self, Button, Down)
	OffsetModelID = 0
	ModelID = 0
	DisplayFavorites = true
	InSearchFlag = false
	GoBackDepth = 0
	TMCWeaponFrame.Gallery:Load(true)
end)
-- end Favorites

-- ModelPreview
TMCWeaponFrame.ModelPreview = CreateFrame("Frame", nil, TMCWeaponFrame, BackdropTemplateMixin and "BackdropTemplate")
TMCWeaponFrame.ModelPreview.CloseButton = CreateFrame(
		"Button", nil, TMCWeaponFrame.ModelPreview, "UIPanelCloseButton")
TMCWeaponFrame.ModelPreview.CloseButton:SetPoint("TOPRIGHT", 695, -5)
TMCWeaponFrame.ModelPreview.CloseButton:SetScript("OnClick", function(self, Button, Down)
	TMCWeaponFrame.ModelPreview:Hide()
end)

TMCWeaponFrame.ModelPreview:SetFrameStrata("DIALOG")
TMCWeaponFrame.ModelPreview:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    insets = {left = 11, right = 12, top = 12, bottom = 11}
})
TMCWeaponFrame.ModelPreview:SetAllPoints()
--
TMCWeaponFrame.ModelPreview.ModelFrame = CreateFrame(
		"DressUpModel", "OVERLAY", TMCWeaponFrame.ModelPreview, BackdropTemplateMixin and "BackdropTemplate")
TMCWeaponFrame.ModelPreview:Hide()

--
TMCWeaponFrame.ModelPreview.FontString = TMCWeaponFrame.ModelPreview.ModelFrame:CreateFontString(
		nil, "BACKGROUND", "GameFontWhite")
TMCWeaponFrame.ModelPreview.FontString:SetJustifyV("TOP")
TMCWeaponFrame.ModelPreview.FontString:SetJustifyH("LEFT")
TMCWeaponFrame.ModelPreview.FontString:SetPoint("TOPLEFT", 15, -15)

--
TMCWeaponFrame.ModelPreview.ModelFrame.DisplayInfo = 0
TMCWeaponFrame.ModelPreview.ModelFrame:SetWidth(WindowWidth - 300)
TMCWeaponFrame.ModelPreview.ModelFrame:SetHeight(WindowHeight)
TMCWeaponFrame.ModelPreview.ModelFrame:SetPoint("TOPRIGHT", 700, 0)
TMCWeaponFrame.ModelPreview.ModelFrame:SetBackdrop({
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
TMCWeaponFrame.ModelPreview.ModelFrame:EnableMouse()
TMCWeaponFrame.ModelPreview.ModelFrame:SetScript("OnUpdate", OnUpdate)
TMCWeaponFrame.ModelPreview.ModelFrame:Show()
--
TMCWeaponFrame.ModelPreview.Favorite = TMCWeaponFrame.ModelPreview.ModelFrame:CreateTexture(nil, "ARTWORK")
TMCWeaponFrame.ModelPreview.Favorite:SetPoint("BOTTOMRIGHT", -10, 0)
TMCWeaponFrame.ModelPreview.Favorite:SetSize(40, 40)
TMCWeaponFrame.ModelPreview.Favorite:SetTexture("Interface\\Collections\\Collections")
TMCWeaponFrame.ModelPreview.Favorite:SetTexCoord(0.18, 0.02, 0.18, 0.07, 0.23, 0.02, 0.23, 0.07)

--
TMCWeaponFrame.ModelPreview.AddToFavorite = CreateFrame(
		"Button", nil, TMCWeaponFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCWeaponFrame.ModelPreview.AddToFavorite:SetSize(120, 30)
TMCWeaponFrame.ModelPreview.AddToFavorite:SetPoint("BOTTOMLEFT", 11, 11)
TMCWeaponFrame.ModelPreview.AddToFavorite:SetText("Add to Favorite")
TMCWeaponFrame.ModelPreview.AddToFavorite:SetScript("OnClick", function(self, Button, Down)
	TakusMorphCatalogWeaponDB.FavoriteList[TMCWeaponFrame.ModelPreview.ModelFrame.DisplayInfo] = 1
	TMCWeaponFrame.ModelPreview.AddToFavorite:Hide()
	TMCWeaponFrame.ModelPreview.RemoveFavorite:Show()
	TMCWeaponFrame.ModelPreview.Favorite:Show()
	ModelID = OffsetModelID
	TMCWeaponFrame.Gallery:Load()
end)

--
TMCWeaponFrame.ModelPreview.RemoveFavorite = CreateFrame(
		"Button", nil, TMCWeaponFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCWeaponFrame.ModelPreview.RemoveFavorite:SetSize(120, 30)
TMCWeaponFrame.ModelPreview.RemoveFavorite:SetPoint("BOTTOMLEFT", 11, 11)
TMCWeaponFrame.ModelPreview.RemoveFavorite:SetText("Remove Favorite")
TMCWeaponFrame.ModelPreview.RemoveFavorite:SetScript("OnClick", function(self, Button, Down)
	TakusMorphCatalogWeaponDB.FavoriteList[TMCWeaponFrame.ModelPreview.ModelFrame.DisplayInfo] = nil
	TMCWeaponFrame.ModelPreview.AddToFavorite:Show()
	TMCWeaponFrame.ModelPreview.RemoveFavorite:Hide()
	TMCWeaponFrame.ModelPreview.Favorite:Hide()
	ModelID = OffsetModelID
	TMCWeaponFrame.Gallery:Load()
end)

--
TMCWeaponFrame.ModelPreview.mainHand = CreateFrame(
		"Button", nil, TMCWeaponFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCWeaponFrame.ModelPreview.mainHand:SetSize(100, 30)
TMCWeaponFrame.ModelPreview.mainHand:SetPoint("BOTTOMLEFT", 131, 11)
TMCWeaponFrame.ModelPreview.mainHand:SetText("MAIN HAND")
TMCWeaponFrame.ModelPreview.mainHand:SetScript("OnClick", function(self, Button, Down)
	local msg = ".item 16 " .. getItemID(TMCWeaponFrame.ModelPreview.ModelFrame.DisplayInfo)
	DEFAULT_CHAT_FRAME.editBox:SetText(msg)
	ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
end)

--
TMCWeaponFrame.ModelPreview.offHand = CreateFrame(
		"Button", nil, TMCWeaponFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCWeaponFrame.ModelPreview.offHand:SetSize(100, 30)
TMCWeaponFrame.ModelPreview.offHand:SetPoint("BOTTOMLEFT", 231, 11)
TMCWeaponFrame.ModelPreview.offHand:SetText("OFF HAND")
TMCWeaponFrame.ModelPreview.offHand:SetScript("OnClick", function(self, Button, Down)
	local msg = ".item 17 " .. getItemID(TMCWeaponFrame.ModelPreview.ModelFrame.DisplayInfo)
	DEFAULT_CHAT_FRAME.editBox:SetText(msg)
	ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
end)
-- end ModelPreview

-- TitleFrame
TMCWeaponFrame.TitleFrame = CreateFrame("Frame", nil, TMCWeaponFrame)
TMCWeaponFrame.TitleFrame:SetSize(TMCWeaponFrame:GetWidth(), 40)
TMCWeaponFrame.TitleFrame:SetPoint("TOP")
TMCWeaponFrame.TitleFrame.Background = TMCWeaponFrame.TitleFrame:CreateTexture(nil, "BACKGROUND")
TMCWeaponFrame.TitleFrame.Background:SetColorTexture(1, 0, 0, 0)
TMCWeaponFrame.TitleFrame.Background:SetAllPoints(TMCWeaponFrame.TitleFrame)
TMCWeaponFrame.TitleFrame.FontString = TMCWeaponFrame.TitleFrame:CreateFontString(nil, nil, "GameFontNormal")
TMCWeaponFrame.TitleFrame.FontString:SetText("Taku's Morph Catalog")
TMCWeaponFrame.TitleFrame.FontString:SetAllPoints(TMCWeaponFrame.TitleFrame)
TMCWeaponFrame.TitleFrame.CloseButton = CreateFrame("Button", nil, TMCWeaponFrame.TitleFrame, "UIPanelCloseButton")
TMCWeaponFrame.TitleFrame.CloseButton:SetPoint("RIGHT", -3, 0)
TMCWeaponFrame.TitleFrame.CloseButton:SetScript("OnClick", function(self, Button, Down)
	TMCWeaponFrame:Hide()
end)
TMCWeaponFrame.TitleFrame:SetScript("OnMouseDown", function(self, Button)
	TMCWeaponFrame:StartMoving()
end)
TMCWeaponFrame.TitleFrame:SetScript("OnMouseUp", function(self, Button)
	TMCWeaponFrame:StopMovingOrSizing()
end)
-- end TitleFrame

-- PageController
TMCWeaponFrame.PageController = CreateFrame("Frame", nil, TMCWeaponFrame)
TMCWeaponFrame.PageController:SetSize(TMCWeaponFrame:GetWidth(), 75)
TMCWeaponFrame.PageController:SetPoint("BOTTOM")
TMCWeaponFrame.PageController.FontString = TMCWeaponFrame.PageController:CreateFontString(
		nil, nil, "GameFontWhite")
TMCWeaponFrame.PageController.FontString:SetAllPoints(TMCWeaponFrame.PageController)

function TMCWeaponFrame.PageController:UpdateButtons()
	if (ModelID >= MaxModelID) then
		TMCWeaponFrame.NextPageButton:SetBackdrop({
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled",
		  insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
	else
		TMCWeaponFrame.NextPageButton:SetBackdrop( {
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up",
		  insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
	end
	if (GoBackDepth == 0) then
		TMCWeaponFrame.PreviousPageButton:SetBackdrop( {
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled",
		  insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
	else
		TMCWeaponFrame.PreviousPageButton:SetBackdrop( {
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up",
		  insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
	end
end
-- end PageController

-- NextPageButton
TMCWeaponFrame.NextPageButton = CreateFrame("Button", nil, TMCWeaponFrame.PageController, BackdropTemplateMixin and "BackdropTemplate")
--
TMCWeaponFrame.NextPageButton:SetSize(45, 45)
TMCWeaponFrame.NextPageButton:SetPoint("Center", 100, 0)
TMCWeaponFrame.NextPageButton:SetBackdrop( {
  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up",
  insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
--
TMCWeaponFrame.NextPageButton.HoverGlow = TMCWeaponFrame.NextPageButton:CreateTexture(nil, "BACKGROUND")
TMCWeaponFrame.NextPageButton.HoverGlow:SetTexture("Interface\\Buttons\\CheckButtonGlow")
TMCWeaponFrame.NextPageButton.HoverGlow:SetAllPoints(TMCWeaponFrame.NextPageButton)
TMCWeaponFrame.NextPageButton.HoverGlow:SetAlpha(0)
--
TMCWeaponFrame.NextPageButton:SetScript("OnEnter", function()
	if (ModelID < MaxModelID) then
		TMCWeaponFrame.NextPageButton.HoverGlow:SetAlpha(1)
	end
end);
--
TMCWeaponFrame.NextPageButton:SetScript("OnLeave", function()
	TMCWeaponFrame.NextPageButton.HoverGlow:SetAlpha(0)
end);
--
TMCWeaponFrame.NextPageButton:SetScript("OnClick", function(self, Button, Down)
	if (ModelID >= MaxModelID) then
		return
	end
	OffsetModelID = ModelID
	--
	GoBackStack[GoBackDepth] = {LastMaxModelID=LastMaxModelID, Zoom=NumberOfColumn}
	GoBackDepth = GoBackDepth + 1
	--
	if InSearchFlag then
		TMCWeaponFrame.Gallery:Load(false, InSearchFlag)
	else
		TMCWeaponFrame.Gallery:Load()
	end
	--
end)
-- end NextPageButton

-- GoToEditBox
TMCWeaponFrame.GoToEditBox = CreateFrame('EditBox', nil, TMCWeaponFrame.PageController, "InputBoxTemplate")
--
TMCWeaponFrame.GoToEditBox.FontString = TMCWeaponFrame.GoToEditBox:CreateFontString(nil, nil, "GameFontWhite")
TMCWeaponFrame.GoToEditBox.FontString:SetPoint("LEFT", -50, 0)
TMCWeaponFrame.GoToEditBox.FontString:SetText("GotoID")
--
TMCWeaponFrame.GoToEditBox:SetPoint("LEFT", 100, 0)
TMCWeaponFrame.GoToEditBox:SetMultiLine(false)
TMCWeaponFrame.GoToEditBox:SetAutoFocus(false)
TMCWeaponFrame.GoToEditBox:EnableMouse(true)
TMCWeaponFrame.GoToEditBox:SetMaxLetters(6)
TMCWeaponFrame.GoToEditBox:SetTextInsets(0, 0, 0, 0)
TMCWeaponFrame.GoToEditBox:SetFont('Fonts\\ARIALN.ttf', 12, '')
TMCWeaponFrame.GoToEditBox:SetWidth(70)
TMCWeaponFrame.GoToEditBox:SetHeight(20)
TMCWeaponFrame.GoToEditBox:SetScript('OnEscapePressed', function() TMCWeaponFrame.GoToEditBox:ClearFocus() end)
TMCWeaponFrame.GoToEditBox:SetScript('OnEnterPressed', function()
	TMCWeaponFrame.GoToEditBox:ClearFocus()
	--
	OffsetModelID = tonumber(TMCWeaponFrame.GoToEditBox:GetText())
	if OffsetModelID >= MaxModelID then
		OffsetModelID = MaxModelID
	end
	NumberOfColumn = MaxNumberOfColumn
	ModelID = OffsetModelID
	InSearchFlag = false
	TMCWeaponFrame.Gallery:Load(true)
end)
-- end GoToEditBox

-- search editBox
TMCWeaponFrame.searchEditBox = CreateFrame(
		'EditBox', nil, TMCWeaponFrame.PageController, "InputBoxTemplate")
--
TMCWeaponFrame.searchEditBox.FontString =
	TMCWeaponFrame.searchEditBox:CreateFontString(nil, nil, "GameFontWhite")
TMCWeaponFrame.searchEditBox.FontString:SetPoint("LEFT", -50, 0)
TMCWeaponFrame.searchEditBox.FontString:SetText("Search")
--
TMCWeaponFrame.searchEditBox:SetPoint("RIGHT", -50, 0)
TMCWeaponFrame.searchEditBox:SetMultiLine(false)
TMCWeaponFrame.searchEditBox:SetAutoFocus(false)
TMCWeaponFrame.searchEditBox:EnableMouse(true)
TMCWeaponFrame.searchEditBox:SetMaxLetters(50)
TMCWeaponFrame.searchEditBox:SetTextInsets(0, 0, 0, 0)
TMCWeaponFrame.searchEditBox:SetFont('Fonts\\ARIALN.ttf', 12, '')
TMCWeaponFrame.searchEditBox:SetWidth(70)
TMCWeaponFrame.searchEditBox:SetHeight(20)
TMCWeaponFrame.searchEditBox:SetScript(
		'OnEscapePressed', function() TMCWeaponFrame.searchEditBox:ClearFocus() end)
TMCWeaponFrame.searchEditBox:SetScript('OnEnterPressed', function()
	TMCWeaponFrame.searchEditBox:ClearFocus()
	InSearchFlag = true
	OffsetModelID = 0
	ModelID = 0
	DisplayFavorites = false
	NumberOfColumn = MaxNumberOfColumn
	--
	SearchResult = doSearchWeapon(TMCWeaponFrame.searchEditBox:GetText())
	TMCWeaponFrame.Gallery:Load(true, InSearchFlag)
end)
-- end editBox

-- PreviousPageButton
TMCWeaponFrame.PreviousPageButton = CreateFrame("Button", nil, TMCWeaponFrame.PageController, BackdropTemplateMixin and "BackdropTemplate")
TMCWeaponFrame.PreviousPageButton:SetSize(45, 45)
TMCWeaponFrame.PreviousPageButton:SetPoint("Center", -100, 0)
TMCWeaponFrame.PreviousPageButton:SetBackdrop({
  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled",
  insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
TMCWeaponFrame.PreviousPageButton.HoverGlow =
	TMCWeaponFrame.PreviousPageButton:CreateTexture(nil, "BACKGROUND")
TMCWeaponFrame.PreviousPageButton.HoverGlow:SetTexture("Interface\\Buttons\\CheckButtonGlow")
TMCWeaponFrame.PreviousPageButton.HoverGlow:SetAllPoints(TMCWeaponFrame.PreviousPageButton)
TMCWeaponFrame.PreviousPageButton.HoverGlow:SetAlpha(0)
TMCWeaponFrame.PreviousPageButton:SetScript("OnEnter", function()
	if (GoBackDepth > 0) then
		TMCWeaponFrame.PreviousPageButton.HoverGlow:SetAlpha(1)
	end
end);
TMCWeaponFrame.PreviousPageButton:SetScript("OnLeave", function()
	TMCWeaponFrame.PreviousPageButton.HoverGlow:SetAlpha(0)
end);
TMCWeaponFrame.PreviousPageButton:SetScript("OnClick", function(self, Button, Down)
	if (GoBackDepth == 0) then
		return
	end
	OffsetModelID = GoBackStack[GoBackDepth-1].LastMaxModelID
	--
	ModelID = OffsetModelID
	NumberOfColumn = MaxNumberOfColumn
	TMCWeaponFrame.Gallery:Load(true, InSearchFlag)
	--
	ModelID = OffsetModelID
	NumberOfColumn = GoBackStack[GoBackDepth-1].Zoom
	GoBackStack[GoBackDepth-1] = nil
	GoBackDepth = GoBackDepth - 1
	TMCWeaponFrame.Gallery:Load()
	--
end)
-- end PreviousPageButton

-- Gallery
TMCWeaponFrame.Gallery = CreateFrame("Frame", nil, TMCWeaponFrame)
TMCWeaponFrame.Gallery:SetPoint("TOP", 0, -50)
TMCWeaponFrame.Gallery:SetSize(TMCWeaponFrame:GetWidth() - 50, TMCWeaponFrame:GetHeight() - 125)
TMCWeaponFrame.Gallery:SetScript("OnMouseWheel", function(self, delta)
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
	TMCWeaponFrame.Gallery:Load()
end)

function TMCWeaponFrame.Gallery:Load(Reset, is_search)
	if Debug then
		print("--- TMCWeaponFrame.Gallery:Load ---")
		print("ModelID .. " .. ModelID)
		print("LastMaxModelID .. " .. LastMaxModelID)
		print("OffsetModelID .. " .. OffsetModelID)
	end
	TMCWeaponFrame.Gallery:SetSize(TMCWeaponFrame:GetWidth() - 50, TMCWeaponFrame:GetHeight() - 125)
	local ColumnWidth = TMCWeaponFrame.Gallery:GetWidth() / NumberOfColumn
	local MaxNumberOfRowsOnSinglePage = floor(TMCWeaponFrame.Gallery:GetHeight() / ColumnWidth)
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
			Cells[CellIndex] = CreateFrame("Button", nil, TMCWeaponFrame.Gallery)
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
				TMCWeaponFrame.ModelPreview.ModelFrame:SetAutoDress(false)
				TMCWeaponFrame.ModelPreview.ModelFrame:SetUnit("player")
				TMCWeaponFrame.ModelPreview.ModelFrame:SetSheathed(false)
				TMCWeaponFrame.ModelPreview.ModelFrame:Undress()
				TMCWeaponFrame.ModelPreview.ModelFrame:TryOn(getItemLink(self.ModelFrame.DisplayInfo))
				TMCWeaponFrame.ModelPreview.ModelFrame.DisplayInfo = self.ModelFrame.DisplayInfo
                TMCWeaponFrame.ModelPreview.FontString:SetText(getItemInfo(self.ModelFrame.DisplayInfo))
				if TakusMorphCatalogWeaponDB.FavoriteList[self.ModelFrame.DisplayInfo] then
					TMCWeaponFrame.ModelPreview.Favorite:Show()
					TMCWeaponFrame.ModelPreview.AddToFavorite:Hide()
					TMCWeaponFrame.ModelPreview.RemoveFavorite:Show()
				else
					TMCWeaponFrame.ModelPreview.Favorite:Hide()
					TMCWeaponFrame.ModelPreview.AddToFavorite:Show()
					TMCWeaponFrame.ModelPreview.RemoveFavorite:Hide()
				end
				TMCWeaponFrame.ModelPreview:Show()
			end)
		end
		-- always do
		Cells[CellIndex]:Show()
		if bNewWidget or Cells[CellIndex].ModelFrame.DisplayInfo < ModelID or Reset or is_search then
			if (DisplayFavorites) then
				while ModelID <= MaxModelID do
					if (TakusMorphCatalogWeaponDB.FavoriteList[ModelID]) and itemValid(ModelID) then
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
		if (TakusMorphCatalogWeaponDB.FavoriteList[Cells[CellIndex].ModelFrame.DisplayInfo]) then
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
	TMCWeaponFrame.PageController.FontString:SetText(LastMaxModelID .. " - " .. ModelID - 1)
	TMCWeaponFrame.PageController:UpdateButtons()
end
-- end Gallery

if Debug then
	print("ModelFrames OK")
end


function TMCWeaponFrame.TAKUSMORPHCATALOGWeapons()
	TMCWeaponFrame:Show()
	OffsetModelID = 0
	ModelID = 0
	DisplayFavorites = false
	InSearchFlag = false
	NumberOfColumn = MaxNumberOfColumn
	TMCWeaponFrame.Gallery:Load(true)
end

local function myframe_OnLoad()
	local consoleCmd = "/console SET alwaysCompareItems 0"
	DEFAULT_CHAT_FRAME.editBox:SetText(consoleCmd)
	ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
end

local myframe = CreateFrame("Frame", "myframe", UIParent);
myframe:SetScript("OnEvent", function() myframe_OnLoad() end)
myframe:RegisterEvent("PLAYER_LOGIN")

ns.WeaponsTMCFrame = TMCWeaponFrame