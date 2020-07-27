local _, ns = ...

-- settings
local Debug = false
local MaxNumberOfColumn = 5
local MinNumberOfColumn = 3
local NumberOfColumn = 5
local MaxModelID = 1380
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
TakusMorphCatalogDB = {
	FavoriteList = {}
}
local mountTable = {}
for index, mountID in ipairs(C_MountJournal.GetMountIDs()) do
	mountTable[mountID] = 1
end
-- end

-- TMCFrame (main)
local TMCFrame = CreateFrame("Frame", nil, UIParent)
TMCFrame:Hide()
TMCFrame:SetFrameStrata("DIALOG")
TMCFrame:SetWidth(WindowWidth)
TMCFrame:SetHeight(WindowHeight)
TMCFrame:SetPoint("TOPLEFT",0,0)
TMCFrame:SetMovable(true)
TMCFrame:SetMinResize(400, 400)
TMCFrame:SetClampedToScreen(true)
TMCFrame:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
TMCFrame:EnableKeyboard(true)
TMCFrame:SetScript("OnKeyDown", function(self, key)
	if key == "ESCAPE" then
		TMCFrame:Hide()
	end
end)
-- end TMCFrame

if Debug then
	print("TMCFrame OK")
end

-- Collection
TMCFrame.Collection = CreateFrame("Button", nil, TMCFrame, "UIPanelButtonTemplate")
TMCFrame.Collection:SetSize(120,30)
TMCFrame.Collection:SetPoint("TOPLEFT", 10, -10)
TMCFrame.Collection:SetText("Collection")
TMCFrame.Collection:SetScript("OnClick", function(self, Button, Down)
	OffsetModelID = 0
	ModelID = 0
	DisplayFavorites = false
	InSearchFlag = false
	NumberOfColumn = MaxNumberOfColumn
	TMCFrame.Gallery:Load(true)
end)
-- end Collection

-- Favorites
TMCFrame.Favorites = CreateFrame("Button", nil, TMCFrame, "UIPanelButtonTemplate")
TMCFrame.Favorites:SetSize(120, 30)
TMCFrame.Favorites:SetPoint("TOPLEFT", 130, -10)
TMCFrame.Favorites:SetText("Favorites")
TMCFrame.Favorites:SetScript("OnClick", function(self, Button, Down)
	OffsetModelID = 0
	ModelID = 0
	DisplayFavorites = true
	InSearchFlag = false
	GoBackDepth = 0
	TMCFrame.Gallery:Load(true)
end)
-- end Favorites

-- ModelPreview
TMCFrame.ModelPreview = CreateFrame("Frame", nil, TMCFrame)
TMCFrame.ModelPreview.CloseButton = CreateFrame(
		"Button", nil, TMCFrame.ModelPreview, "UIPanelCloseButton")
TMCFrame.ModelPreview.CloseButton:SetPoint("TOPRIGHT", 695, -5)
TMCFrame.ModelPreview.CloseButton:SetScript("OnClick", function(self, Button, Down)
	TMCFrame.ModelPreview:Hide()
end)

TMCFrame.ModelPreview:SetFrameStrata("DIALOG")
TMCFrame.ModelPreview:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    insets = {left = 11, right = 12, top = 12, bottom = 11}
})
TMCFrame.ModelPreview:SetAllPoints()
--
TMCFrame.ModelPreview.ModelFrame = CreateFrame(
		"DressUpModel", "OVERLAY", TMCFrame.ModelPreview)
TMCFrame.ModelPreview:Hide()

--
TMCFrame.ModelPreview.FontString = TMCFrame.ModelPreview.ModelFrame:CreateFontString(
		nil, "BACKGROUND", "GameFontWhite")
TMCFrame.ModelPreview.FontString:SetJustifyV("TOP")
TMCFrame.ModelPreview.FontString:SetJustifyH("LEFT")
TMCFrame.ModelPreview.FontString:SetPoint("TOPLEFT", 15, -15)

--
TMCFrame.ModelPreview.ModelFrame.DisplayInfo = 0
TMCFrame.ModelPreview.ModelFrame:SetWidth(WindowWidth - 300)
TMCFrame.ModelPreview.ModelFrame:SetHeight(WindowHeight)
TMCFrame.ModelPreview.ModelFrame:SetPoint("TOPRIGHT", 700, 0)
TMCFrame.ModelPreview.ModelFrame:SetBackdrop({
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
	local offsetX = x - lastX
	local offsetY = y - lastY
	local offsetDegree = offsetX / 100 * math.pi
	local offsetScale = (offsetY / 180 * 2) * 0.45 + 1
	self:SetFacing(offsetDegree)
	self:SetModelScale(offsetScale)
end
TMCFrame.ModelPreview.ModelFrame:EnableMouse()
TMCFrame.ModelPreview.ModelFrame:SetScript("OnUpdate", OnUpdate)
TMCFrame.ModelPreview.ModelFrame:Show()
--
TMCFrame.ModelPreview.Favorite = TMCFrame.ModelPreview.ModelFrame:CreateTexture(nil, "ARTWORK")
TMCFrame.ModelPreview.Favorite:SetPoint("BOTTOMRIGHT", -10, 0)
TMCFrame.ModelPreview.Favorite:SetSize(40, 40)
TMCFrame.ModelPreview.Favorite:SetTexture("Interface\\Collections\\Collections")
TMCFrame.ModelPreview.Favorite:SetTexCoord(0.18, 0.02, 0.18, 0.07, 0.23, 0.02, 0.23, 0.07)

--
TMCFrame.ModelPreview.AddToFavorite = CreateFrame(
		"Button", nil, TMCFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCFrame.ModelPreview.AddToFavorite:SetSize(120, 30)
TMCFrame.ModelPreview.AddToFavorite:SetPoint("BOTTOMLEFT", 11, 11)
TMCFrame.ModelPreview.AddToFavorite:SetText("Add to Favorite")
TMCFrame.ModelPreview.AddToFavorite:SetScript("OnClick", function(self, Button, Down)
	TakusMorphCatalogDB.FavoriteList[TMCFrame.ModelPreview.ModelFrame.DisplayInfo] = 1
	TMCFrame.ModelPreview.AddToFavorite:Hide()
	TMCFrame.ModelPreview.RemoveFavorite:Show()
	TMCFrame.ModelPreview.Favorite:Show()
	ModelID = OffsetModelID
	TMCFrame.Gallery:Load()
end)

--
TMCFrame.ModelPreview.RemoveFavorite = CreateFrame(
		"Button", nil, TMCFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCFrame.ModelPreview.RemoveFavorite:SetSize(120, 30)
TMCFrame.ModelPreview.RemoveFavorite:SetPoint("BOTTOMLEFT", 11, 11)
TMCFrame.ModelPreview.RemoveFavorite:SetText("Remove Favorite")
TMCFrame.ModelPreview.RemoveFavorite:SetScript("OnClick", function(self, Button, Down)
	TakusMorphCatalogDB.FavoriteList[TMCFrame.ModelPreview.ModelFrame.DisplayInfo] = nil
	TMCFrame.ModelPreview.AddToFavorite:Show()
	TMCFrame.ModelPreview.RemoveFavorite:Hide()
	TMCFrame.ModelPreview.Favorite:Hide()
	ModelID = OffsetModelID
	TMCFrame.Gallery:Load()
end)

--
TMCFrame.ModelPreview.CopyID = CreateFrame(
		"Button", nil, TMCFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCFrame.ModelPreview.CopyID:SetSize(70, 30)
TMCFrame.ModelPreview.CopyID:SetPoint("BOTTOMLEFT", 131, 11)
TMCFrame.ModelPreview.CopyID:SetText("PLAY AS")
TMCFrame.ModelPreview.CopyID:SetScript("OnClick", function(self, Button, Down)
	local msg = ".morph " .. TMCFrame.ModelPreview.ModelFrame.DisplayInfo
	DEFAULT_CHAT_FRAME.editBox:SetText(msg)
	ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
end)

--
TMCFrame.ModelPreview.MountAs = CreateFrame(
		"Button", nil, TMCFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCFrame.ModelPreview.MountAs:SetSize(85, 30)
TMCFrame.ModelPreview.MountAs:SetPoint("BOTTOMLEFT", 201, 11)
TMCFrame.ModelPreview.MountAs:SetText("MOUNT AS")
TMCFrame.ModelPreview.MountAs:SetScript("OnClick", function(self, Button, Down)
	local msg = ".mount " .. TMCFrame.ModelPreview.ModelFrame.DisplayInfo
	DEFAULT_CHAT_FRAME.editBox:SetText(msg)
	ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
end)
-- end ModelPreview

local function getMountDisplayID(mountID)
    local mountDisplayId, _,_,_,_,_,_,_,_ =
		C_MountJournal.GetMountInfoExtraByID(mountID)
    return mountDisplayId
end


-- TitleFrame
TMCFrame.TitleFrame = CreateFrame("Frame", nil, TMCFrame)
TMCFrame.TitleFrame:SetSize(TMCFrame:GetWidth(), 40)
TMCFrame.TitleFrame:SetPoint("TOP")
TMCFrame.TitleFrame.Background = TMCFrame.TitleFrame:CreateTexture(nil, "BACKGROUND")
TMCFrame.TitleFrame.Background:SetColorTexture(1, 0, 0, 0)
TMCFrame.TitleFrame.Background:SetAllPoints(TMCFrame.TitleFrame)
TMCFrame.TitleFrame.FontString = TMCFrame.TitleFrame:CreateFontString(nil, nil, "GameFontNormal")
TMCFrame.TitleFrame.FontString:SetText("Taku's Morph Catalog")
TMCFrame.TitleFrame.FontString:SetAllPoints(TMCFrame.TitleFrame)
TMCFrame.TitleFrame.CloseButton = CreateFrame("Button", nil, TMCFrame.TitleFrame, "UIPanelCloseButton")
TMCFrame.TitleFrame.CloseButton:SetPoint("RIGHT", -3, 0)
TMCFrame.TitleFrame.CloseButton:SetScript("OnClick", function(self, Button, Down)
	TMCFrame:Hide()
end)
TMCFrame.TitleFrame:SetScript("OnMouseDown", function(self, Button)
	TMCFrame:StartMoving()
end)
TMCFrame.TitleFrame:SetScript("OnMouseUp", function(self, Button)
	TMCFrame:StopMovingOrSizing()
end)
-- end TitleFrame

-- PageController
TMCFrame.PageController = CreateFrame("Frame", nil, TMCFrame)
TMCFrame.PageController:SetSize(TMCFrame:GetWidth(), 75)
TMCFrame.PageController:SetPoint("BOTTOM")
TMCFrame.PageController.FontString = TMCFrame.PageController:CreateFontString(
		nil, nil, "GameFontWhite")
TMCFrame.PageController.FontString:SetAllPoints(TMCFrame.PageController)

function TMCFrame.PageController:UpdateButtons()
	if (ModelID >= MaxModelID) then
		TMCFrame.NextPageButton:SetBackdrop({
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled",
		  insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
	else
		TMCFrame.NextPageButton:SetBackdrop( {
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up",
		  insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
	end
	if (GoBackDepth == 0) then
		TMCFrame.PreviousPageButton:SetBackdrop( {
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled",
		  insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
	else
		TMCFrame.PreviousPageButton:SetBackdrop( {
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up",
		  insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
	end
end
-- end PageController

-- NextPageButton
TMCFrame.NextPageButton = CreateFrame("Button", nil, TMCFrame.PageController)
--
TMCFrame.NextPageButton:SetSize(45, 45)
TMCFrame.NextPageButton:SetPoint("Center", 100, 0)
TMCFrame.NextPageButton:SetBackdrop( {
  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up",
  insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
--
TMCFrame.NextPageButton.HoverGlow = TMCFrame.NextPageButton:CreateTexture(nil, "BACKGROUND")
TMCFrame.NextPageButton.HoverGlow:SetTexture("Interface\\Buttons\\CheckButtonGlow")
TMCFrame.NextPageButton.HoverGlow:SetAllPoints(TMCFrame.NextPageButton)
TMCFrame.NextPageButton.HoverGlow:SetAlpha(0)
--
TMCFrame.NextPageButton:SetScript("OnEnter", function()
	if (ModelID < MaxModelID) then
		TMCFrame.NextPageButton.HoverGlow:SetAlpha(1)
	end
end);
--
TMCFrame.NextPageButton:SetScript("OnLeave", function()
	TMCFrame.NextPageButton.HoverGlow:SetAlpha(0)
end);
--
TMCFrame.NextPageButton:SetScript("OnClick", function(self, Button, Down)
	if (ModelID >= MaxModelID) then
		return
	end
	OffsetModelID = ModelID
	--
	GoBackStack[GoBackDepth] = {LastMaxModelID=LastMaxModelID, Zoom=NumberOfColumn}
	GoBackDepth = GoBackDepth + 1
	--
	if InSearchFlag then
		TMCFrame.Gallery:Load(false, InSearchFlag)
	else
		TMCFrame.Gallery:Load()
	end
	--
end)
-- end NextPageButton

-- GoToEditBox
TMCFrame.GoToEditBox = CreateFrame('EditBox', nil, TMCFrame.PageController, "InputBoxTemplate")
--
TMCFrame.GoToEditBox.FontString = TMCFrame.GoToEditBox:CreateFontString(nil, nil, "GameFontWhite")
TMCFrame.GoToEditBox.FontString:SetPoint("LEFT", -50, 0)
TMCFrame.GoToEditBox.FontString:SetText("GotoID")
--
TMCFrame.GoToEditBox:SetPoint("LEFT", 100, 0)
TMCFrame.GoToEditBox:SetMultiLine(false)
TMCFrame.GoToEditBox:SetAutoFocus(false)
TMCFrame.GoToEditBox:EnableMouse(true)
TMCFrame.GoToEditBox:SetMaxLetters(6)
TMCFrame.GoToEditBox:SetTextInsets(0, 0, 0, 0)
TMCFrame.GoToEditBox:SetFont('Fonts\\ARIALN.ttf', 12, '')
TMCFrame.GoToEditBox:SetWidth(70)
TMCFrame.GoToEditBox:SetHeight(20)
TMCFrame.GoToEditBox:SetScript('OnEscapePressed', function() TMCFrame.GoToEditBox:ClearFocus() end)
TMCFrame.GoToEditBox:SetScript('OnEnterPressed', function()
	TMCFrame.GoToEditBox:ClearFocus()
	--
	OffsetModelID = tonumber(TMCFrame.GoToEditBox:GetText())
	if OffsetModelID >= MaxModelID then
		OffsetModelID = MaxModelID
	end
	NumberOfColumn = MaxNumberOfColumn
	ModelID = OffsetModelID
	InSearchFlag = false
	TMCFrame.Gallery:Load(true)
end)
-- end GoToEditBox

-- search editBox
TMCFrame.searchEditBox = CreateFrame(
		'EditBox', nil, TMCFrame.PageController, "InputBoxTemplate")
--
TMCFrame.searchEditBox.FontString =
	TMCFrame.searchEditBox:CreateFontString(nil, nil, "GameFontWhite")
TMCFrame.searchEditBox.FontString:SetPoint("LEFT", -50, 0)
TMCFrame.searchEditBox.FontString:SetText("Search")
--
TMCFrame.searchEditBox:SetPoint("RIGHT", -50, 0)
TMCFrame.searchEditBox:SetMultiLine(false)
TMCFrame.searchEditBox:SetAutoFocus(false)
TMCFrame.searchEditBox:EnableMouse(true)
TMCFrame.searchEditBox:SetMaxLetters(50)
TMCFrame.searchEditBox:SetTextInsets(0, 0, 0, 0)
TMCFrame.searchEditBox:SetFont('Fonts\\ARIALN.ttf', 12, '')
TMCFrame.searchEditBox:SetWidth(70)
TMCFrame.searchEditBox:SetHeight(20)
TMCFrame.searchEditBox:SetScript(
		'OnEscapePressed', function() TMCFrame.searchEditBox:ClearFocus() end)
TMCFrame.searchEditBox:SetScript('OnEnterPressed', function()
	TMCFrame.searchEditBox:ClearFocus()
	InSearchFlag = true
	OffsetModelID = 0
	ModelID = 0
	DisplayFavorites = false
	NumberOfColumn = MaxNumberOfColumn
	--
	SearchResult = doSearch(TMCFrame.searchEditBox:GetText())
	TMCFrame.Gallery:Load(true, InSearchFlag)
end)
-- end editBox

-- PreviousPageButton
TMCFrame.PreviousPageButton = CreateFrame("Button", nil, TMCFrame.PageController)
TMCFrame.PreviousPageButton:SetSize(45, 45)
TMCFrame.PreviousPageButton:SetPoint("Center", -100, 0)
TMCFrame.PreviousPageButton:SetBackdrop({
  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled",
  insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
TMCFrame.PreviousPageButton.HoverGlow =
	TMCFrame.PreviousPageButton:CreateTexture(nil, "BACKGROUND")
TMCFrame.PreviousPageButton.HoverGlow:SetTexture("Interface\\Buttons\\CheckButtonGlow")
TMCFrame.PreviousPageButton.HoverGlow:SetAllPoints(TMCFrame.PreviousPageButton)
TMCFrame.PreviousPageButton.HoverGlow:SetAlpha(0)
TMCFrame.PreviousPageButton:SetScript("OnEnter", function()
	if (GoBackDepth > 0) then
		TMCFrame.PreviousPageButton.HoverGlow:SetAlpha(1)
	end
end);
TMCFrame.PreviousPageButton:SetScript("OnLeave", function()
	TMCFrame.PreviousPageButton.HoverGlow:SetAlpha(0)
end);
TMCFrame.PreviousPageButton:SetScript("OnClick", function(self, Button, Down)
	if (GoBackDepth == 0) then
		return
	end
	OffsetModelID = GoBackStack[GoBackDepth-1].LastMaxModelID
	--
	ModelID = OffsetModelID
	NumberOfColumn = MaxNumberOfColumn
	TMCFrame.Gallery:Load(true, InSearchFlag)
	--
	ModelID = OffsetModelID
	NumberOfColumn = GoBackStack[GoBackDepth-1].Zoom
	GoBackStack[GoBackDepth-1] = nil
	GoBackDepth = GoBackDepth - 1
	TMCFrame.Gallery:Load()
	--
end)

local function doSearch(inputStr)
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

local function doGetDisplayInfo(inputDisplayID)
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
TMCFrame.Gallery = CreateFrame("Frame", nil, TMCFrame)
TMCFrame.Gallery:SetPoint("TOP", 0, -50)
TMCFrame.Gallery:SetSize(TMCFrame:GetWidth() - 50, TMCFrame:GetHeight() - 125)
TMCFrame.Gallery:SetScript("OnMouseWheel", function(self, delta)
	local NewNumberOfColumn = NumberOfColumn
	if (delta < 0) then
		if (NumberOfColumn == MaxNumberOfColumn) then
			return
		end
		NewNumberOfColumn = NumberOfColumn * 2
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
	TMCFrame.Gallery:Load()
end)

function TMCFrame.Gallery:Load(Reset, is_search)
	if Debug then
		print("--- TMCFrame.Gallery:Load ---")
		print("ModelID .. " .. ModelID)
		print("LastMaxModelID .. " .. LastMaxModelID)
		print("OffsetModelID .. " .. OffsetModelID)
	end
	--update FavoriteList from popup_transform
	for k, v in ipairs(ns.display_favorite) do
		TakusMorphCatalogDB.FavoriteList[tonumber(v)] = 1
		ns.display_favorite = {}
	end
	TMCFrame.Gallery:SetSize(TMCFrame:GetWidth() - 50, TMCFrame:GetHeight() - 125)
	local ColumnWidth = TMCFrame.Gallery:GetWidth() / NumberOfColumn
	local MaxNumberOfRowsOnSinglePage = floor(TMCFrame.Gallery:GetHeight() / ColumnWidth)
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
			Cells[CellIndex] = CreateFrame("Button", nil, TMCFrame.Gallery)
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
			Cells[CellIndex].ModelFrame = CreateFrame("PlayerModel", nil, Cells[CellIndex])
			Cells[CellIndex]:SetScript("OnClick", function(self, Button, Down)
                local mountDisplayId = getMountDisplayID(self.ModelFrame.DisplayInfo)
				TMCFrame.ModelPreview.ModelFrame:SetDisplayInfo(mountDisplayId)
                TMCFrame.ModelPreview.ModelFrame.DisplayInfo = mountDisplayId
				local displayResult = doGetDisplayInfo(mountDisplayId)
				TMCFrame.ModelPreview.FontString:SetText(displayResult)
				if TakusMorphCatalogDB.FavoriteList[mountDisplayId] then
					TMCFrame.ModelPreview.Favorite:Show()
					TMCFrame.ModelPreview.AddToFavorite:Hide()
					TMCFrame.ModelPreview.RemoveFavorite:Show()
				else
					TMCFrame.ModelPreview.Favorite:Hide()
					TMCFrame.ModelPreview.AddToFavorite:Show()
					TMCFrame.ModelPreview.RemoveFavorite:Hide()
				end
				TMCFrame.ModelPreview:Show()
			end)
		end
		-- always do
		Cells[CellIndex]:Show()
		if bNewWidget or Cells[CellIndex].ModelFrame.DisplayInfo < ModelID or Reset or is_search then
			Cells[CellIndex].ModelFrame:SetDisplayInfo(2418)
			if (DisplayFavorites) then
				while ModelID <= MaxModelID do
                    local mountDisplayId = getMountDisplayID(ModelID)
					if (TakusMorphCatalogDB.FavoriteList[mountDisplayId]) then
						Cells[CellIndex].ModelFrame:SetDisplayInfo(mountDisplayId)
						Cells[CellIndex].DisplayFontString:SetText(ModelID)
						ModelID = ModelID + 1
						break
					end
					ModelID = ModelID + 1
				end
			else
				while ModelID <= MaxModelID do
                    local mountDisplayId = getMountDisplayID(ModelID)
                    if mountTable[ModelID] and mountDisplayId then
                        if is_search then
                            if SearchResult[mountDisplayId] then
                                Cells[CellIndex].ModelFrame:SetDisplayInfo(mountDisplayId)
                                Cells[CellIndex].DisplayFontString:SetText(ModelID)
                            end
                        else
                            Cells[CellIndex].ModelFrame:SetDisplayInfo(mountDisplayId)
                            Cells[CellIndex].DisplayFontString:SetText(ModelID)
                        end
                    end
                    ModelID = ModelID + 1
                    local mountDisplayId = getMountDisplayID(ModelID - 1)
                    if mountTable[ModelID - 1] and mountDisplayId then
                        if not is_search then
                            break
                        else
                            if SearchResult[mountDisplayId] then
                                break
                            end
                        end
                    end
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
        local displayFavoriteID = getMountDisplayID(Cells[CellIndex].ModelFrame.DisplayInfo)
		if (TakusMorphCatalogDB.FavoriteList[displayFavoriteID]) then
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
	TMCFrame.PageController.FontString:SetText(LastMaxModelID .. " - " .. ModelID)
	TMCFrame.PageController:UpdateButtons()
end
-- end Gallery

if Debug then
	print("ModelFrames OK")
end


function TMCFrame.TAKUSMORPHCATALOGMounts()
	TMCFrame:Show()
	OffsetModelID = 0
	ModelID = 0
	DisplayFavorites = false
	InSearchFlag = false
	NumberOfColumn = MaxNumberOfColumn
	TMCFrame.Gallery:Load(true)
end

ns.MountsTMCFrame = TMCFrame