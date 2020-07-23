local _, ns = ...

-- settings
local MaxNumberOfColumn = 5
local MinNumberOfColumn = 3
local NumberOfColumn = 5
local MaxModelID = 200000
local WindowWidth = 1000
local WindowHeight = 700
local MaxNumberOfRowsOnSinglePage = floor(700 * 5 / 1000)
local pageTotalNum = NumberOfColumn * MaxNumberOfRowsOnSinglePage

-- vars
local Cells = {}
local ModelID = 0
local LastMaxModelID = 0
local LastStartID = 0
local DisplayFavorites = false
local SearchResult = {}
local InSearchFlag = false
--
TakusMorphCatalogDB = {
	FavoriteList = {}
}
print("TakusMorphCatalog: Type /tmc to display the morph catalog !")
-- end


-- TMCFrame (core) ------------------------------------------------------------
local TMCFrame = CreateFrame("Frame", nil, UIParent)
TMCFrame:Hide()
TMCFrame:SetFrameStrata("DIALOG")
TMCFrame:SetWidth(WindowWidth)
TMCFrame:SetHeight(WindowHeight)
TMCFrame:SetPoint("TOPLEFT",0,0)
TMCFrame:SetMovable(true)
TMCFrame:EnableKeyboard(true)
TMCFrame:SetMinResize(400, 400)
TMCFrame:SetClampedToScreen(true)
TMCFrame:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
TMCFrame:SetScript("OnKeyDown", function(self, key)
	if key == "ESCAPE" then
		TMCFrame:Hide()
	end
end)
-- end TMCFrame ---------------------------------------------------------------


-- TMCFrame TitleFrame --------------------------------------------------------
TMCFrame.TitleFrame = CreateFrame("Frame", nil, TMCFrame)
TMCFrame.TitleFrame:SetFrameStrata("DIALOG")
TMCFrame.TitleFrame:SetSize(TMCFrame:GetWidth(), 40)
TMCFrame.TitleFrame:SetPoint("TOP")
TMCFrame.TitleFrame.Background =
	TMCFrame.TitleFrame:CreateTexture(nil, "BACKGROUND")
TMCFrame.TitleFrame.Background:SetColorTexture(1, 0, 0, 0)
TMCFrame.TitleFrame.Background:SetAllPoints(TMCFrame.TitleFrame)
TMCFrame.TitleFrame.FontString =
	TMCFrame.TitleFrame:CreateFontString(nil, nil, "GameFontNormal")
TMCFrame.TitleFrame.FontString:SetText("Taku's Morph Catalog")
TMCFrame.TitleFrame.FontString:SetAllPoints(TMCFrame.TitleFrame)
TMCFrame.TitleFrame.CloseButton = CreateFrame(
		"Button", nil, TMCFrame.TitleFrame, "UIPanelCloseButton")
TMCFrame.TitleFrame.CloseButton:SetPoint("RIGHT", -3, 0)
TMCFrame.TitleFrame.CloseButton:SetScript("OnClick", function()
	TMCFrame:Hide()
end)
TMCFrame.TitleFrame:SetScript("OnMouseDown", function()
	TMCFrame:StartMoving()
end)
TMCFrame.TitleFrame:SetScript("OnMouseUp", function()
	TMCFrame:StopMovingOrSizing()
end)
-- end TMCFrame TitleFrame ----------------------------------------------------


-- TMCFrame PageController ----------------------------------------------------
TMCFrame.PageController = CreateFrame("Frame", nil, TMCFrame)
TMCFrame.PageController:SetSize(TMCFrame:GetWidth(), 75)
TMCFrame.PageController:SetPoint("BOTTOM")
TMCFrame.PageController.FontString =
	TMCFrame.PageController:CreateFontString(nil, nil, "GameFontWhite")
TMCFrame.PageController.FontString:SetAllPoints(TMCFrame.PageController)

function TMCFrame.PageController:UpdateButtons()
	if (ModelID >= MaxModelID) then
		TMCFrame.NextPageButton:SetBackdrop({
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled",
		  insets = {left = 4, right = 4, top = 4, bottom = 4}
		})
	else
		TMCFrame.NextPageButton:SetBackdrop( {
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up",
		  insets = {left = 4, right = 4, top = 4, bottom = 4}
		})
	end

	if (LastStartID == 0) then
		TMCFrame.PreviousPageButton:SetBackdrop( {
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled",
		  insets = {left = 4, right = 4, top = 4, bottom = 4}
		})
	else
		TMCFrame.PreviousPageButton:SetBackdrop( {
		  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up",
		  insets = {left = 4, right = 4, top = 4, bottom = 4}
		})
	end
end
-- end TMCFrame PageController ------------------------------------------------


-- TMCFrame PreviousPageButton frame ------------------------------------------
TMCFrame.PreviousPageButton =
	CreateFrame("Button", nil, TMCFrame.PageController)
TMCFrame.PreviousPageButton:SetSize(45, 45)
TMCFrame.PreviousPageButton:SetPoint("Center", -100, 0)
TMCFrame.PreviousPageButton:SetBackdrop({
  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled",
  insets = {left = 4, right = 4, top = 4, bottom = 4}
})
TMCFrame.PreviousPageButton.HoverGlow =
	TMCFrame.PreviousPageButton:CreateTexture(nil, "BACKGROUND")
TMCFrame.PreviousPageButton.HoverGlow:SetTexture(
		"Interface\\Buttons\\CheckButtonGlow")
TMCFrame.PreviousPageButton.HoverGlow:SetAllPoints(
		TMCFrame.PreviousPageButton)
TMCFrame.PreviousPageButton.HoverGlow:SetAlpha(0)
TMCFrame.PreviousPageButton:SetScript("OnEnter", function()
	if (LastStartID > 0) then
		TMCFrame.PreviousPageButton.HoverGlow:SetAlpha(1)
	end
end);
TMCFrame.PreviousPageButton:SetScript("OnLeave", function()
	TMCFrame.PreviousPageButton.HoverGlow:SetAlpha(0)
end);
TMCFrame.PreviousPageButton:SetScript("OnClick", function()
	--if (LastStartID == 0) then
	--	return
	--end
	print(LastStartID)
	ModelID = LastStartID
	TMCFrame.Gallery:Load()
end)
-- end TMCFrame PreviousPageButton frame --------------------------------------


-- TMCFrame NextPageButton frame ----------------------------------------------
TMCFrame.NextPageButton = CreateFrame(
		"Button", nil, TMCFrame.PageController)
TMCFrame.NextPageButton:SetSize(45, 45)
TMCFrame.NextPageButton:SetPoint("Center", 100, 0)
TMCFrame.NextPageButton:SetBackdrop( {
  bgFile = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up",
  insets = {left = 4, right = 4, top = 4, bottom = 4}
})
TMCFrame.NextPageButton.HoverGlow =
	TMCFrame.NextPageButton:CreateTexture(nil, "BACKGROUND")
TMCFrame.NextPageButton.HoverGlow:SetTexture(
		"Interface\\Buttons\\CheckButtonGlow")
TMCFrame.NextPageButton.HoverGlow:SetAllPoints(TMCFrame.NextPageButton)
TMCFrame.NextPageButton.HoverGlow:SetAlpha(0)
TMCFrame.NextPageButton:SetScript("OnEnter", function()
	if (ModelID < MaxModelID) then
		TMCFrame.NextPageButton.HoverGlow:SetAlpha(1)
	end
end)
TMCFrame.NextPageButton:SetScript("OnLeave", function()
	TMCFrame.NextPageButton.HoverGlow:SetAlpha(0)
end)
TMCFrame.NextPageButton:SetScript("OnClick", function()
	if (ModelID >= MaxModelID) then
		return
	end
	local cacheLastId = LastStartID
	TMCFrame.Gallery:Load()
	LastStartID = cacheLastId
end)
-- end TMCFrame NextPageButton frame ------------------------------------------


-- TMCFrame GoToEditBox frame -------------------------------------------------
TMCFrame.GoToEditBox = CreateFrame(
		'EditBox', nil, TMCFrame.PageController, "InputBoxTemplate")
TMCFrame.GoToEditBox.FontString =
	TMCFrame.GoToEditBox:CreateFontString(nil, nil, "GameFontWhite")
TMCFrame.GoToEditBox.FontString:SetPoint("LEFT", -50, 0)
TMCFrame.GoToEditBox.FontString:SetText("GotoID")
TMCFrame.GoToEditBox:SetPoint("LEFT", 100, 0)
TMCFrame.GoToEditBox:SetMultiLine(false)
TMCFrame.GoToEditBox:SetAutoFocus(false)
TMCFrame.GoToEditBox:EnableMouse(true)
TMCFrame.GoToEditBox:SetMaxLetters(6)
TMCFrame.GoToEditBox:SetTextInsets(0, 0, 0, 0)
TMCFrame.GoToEditBox:SetFont('Fonts\\ARIALN.ttf', 12, '')
TMCFrame.GoToEditBox:SetWidth(70)
TMCFrame.GoToEditBox:SetHeight(20)
TMCFrame.GoToEditBox:SetScript('OnEscapePressed', function()
	TMCFrame.GoToEditBox:ClearFocus()
end)
TMCFrame.GoToEditBox:SetScript('OnEnterPressed', function()
	TMCFrame.GoToEditBox:ClearFocus()
	NumberOfColumn = MaxNumberOfColumn
	InSearchFlag = false
	TMCFrame.Gallery:Load(true)
end)
-- end TMCFrame GoToEditBox frame ---------------------------------------------

-- TMCFrame searchEditBox frame -----------------------------------------------
TMCFrame.searchEditBox = CreateFrame(
		'EditBox', nil, TMCFrame.PageController, "InputBoxTemplate")
TMCFrame.searchEditBox.FontString =
	TMCFrame.searchEditBox:CreateFontString(nil, nil, "GameFontWhite")
TMCFrame.searchEditBox.FontString:SetPoint("LEFT", -50, 0)
TMCFrame.searchEditBox.FontString:SetText("Search")
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

local function doSearch(inputStr)
	local result = {}
	for _, k in ipairs({0, 1, 2}) do
		local tableId = "npc_id_table_" .. k
		for npc_id, info in pairs(ns[tableId]) do
			local npc_en_name = info["en_name"]
			local npc_cn_name = info["cn_name"]
			npc_en_name = string.lower(npc_en_name)
			npc_cn_name = string.lower(npc_cn_name)
			inputStr = string.lower(inputStr)
			if string.match(npc_en_name, inputStr) then
				result[tonumber(info["display_id"])] = 1
			end
			if string.match(npc_cn_name, inputStr) then
				result[tonumber(info["display_id"])] = 1
			end
		end
	end
	return result
end
TMCFrame.searchEditBox:SetScript('OnEnterPressed', function()
	TMCFrame.searchEditBox:ClearFocus()
	InSearchFlag = true
	ModelID = 0
	DisplayFavorites = false
	NumberOfColumn = MaxNumberOfColumn
	SearchResult = doSearch(TMCFrame.searchEditBox:GetText())
	TMCFrame.Gallery:Load(true, true)
end)
-- end TMCFrame searchEditBox frame -------------------------------------------


-- TMCFrame Collection frame --------------------------------------------------
TMCFrame.Collection = CreateFrame("Button", nil, TMCFrame, "UIPanelButtonTemplate")
TMCFrame.Collection:SetSize(120, 30)
TMCFrame.Collection:SetFrameStrata("TOOLTIP")
TMCFrame.Collection:SetPoint("TOPLEFT", 10, -10)
TMCFrame.Collection:SetText("Collection")
TMCFrame.Collection:SetScript("OnClick", function()
	ModelID = 0
	DisplayFavorites = false
	TMCFrame.Gallery:Load()
end)
-- end TMCFrame Collection ----------------------------------------------------


-- TMCFrame Favorites frame ---------------------------------------------------
TMCFrame.Favorites = CreateFrame("Button", nil, TMCFrame, "UIPanelButtonTemplate")
TMCFrame.Favorites:SetSize(120, 30)
TMCFrame.Favorites:SetFrameStrata("TOOLTIP")
TMCFrame.Favorites:SetPoint("TOPLEFT", 130, -10)
TMCFrame.Favorites:SetText("Favorites")
TMCFrame.Favorites:SetScript("OnClick", function()
	ModelID = 0
	DisplayFavorites = true
	TMCFrame.Gallery:Load()
end)
-- end TMCFrame Favorites -----------------------------------------------------


-- TMCFrame ModelPreview frame ------------------------------------------------
TMCFrame.ModelPreview = CreateFrame("Frame", nil, TMCFrame)
TMCFrame.ModelPreview:SetFrameStrata("DIALOG")
TMCFrame.ModelPreview:SetAllPoints()
TMCFrame.ModelPreview:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    insets = {left = 11, right = 12, top = 12, bottom = 11}
})
TMCFrame.ModelPreview:Hide()
-- end TMCFrame ModelPreview frame --------------------------------------------


-- ModelPreview CloseButton frame ---------------------------------------------
TMCFrame.ModelPreview.CloseButton = CreateFrame(
		"Button", nil, TMCFrame.ModelPreview, "UIPanelCloseButton")
TMCFrame.ModelPreview.CloseButton:SetPoint("TOPRIGHT", 695, -5)
TMCFrame.ModelPreview.CloseButton:SetScript("OnClick", function()
	TMCFrame.ModelPreview:Hide()
end)
-- end ModelPreview CloseButton frame -----------------------------------------


-- ModelPreview ModelFrame frame ----------------------------------------------
TMCFrame.ModelPreview.ModelFrame = CreateFrame(
		"DressUpModel", "OVERLAY", TMCFrame.ModelPreview)
TMCFrame.ModelPreview.ModelFrame.DisplayInfo = 0
TMCFrame.ModelPreview.ModelFrame:SetWidth(WindowWidth - 300)
TMCFrame.ModelPreview.ModelFrame:SetHeight(WindowHeight)
TMCFrame.ModelPreview.ModelFrame:SetPoint("TOPRIGHT", 700, 0)
TMCFrame.ModelPreview.ModelFrame:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    insets = {left = 11, right = 12, top = 12, bottom = 11}
})
TMCFrame.ModelPreview.ModelFrame:EnableMouse()

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
TMCFrame.ModelPreview.ModelFrame:SetScript("OnUpdate", OnUpdate)
TMCFrame.ModelPreview.ModelFrame:Show()
-- end ModelPreview ModelFrame frame ------------------------------------------


-- ModelPreview FontString frame ----------------------------------------------
TMCFrame.ModelPreview.FontString =
	TMCFrame.ModelPreview.ModelFrame:CreateFontString(
			nil, "BACKGROUND", "GameFontWhite")
TMCFrame.ModelPreview.FontString:SetJustifyV("TOP")
TMCFrame.ModelPreview.FontString:SetJustifyH("LEFT")
TMCFrame.ModelPreview.FontString:SetPoint("TOPLEFT", 15, -15)
-- end ModelPreview FontString frame ------------------------------------------


-- ModelPreview Favorite frame ------------------------------------------------
TMCFrame.ModelPreview.Favorite =
	TMCFrame.ModelPreview.ModelFrame:CreateTexture(nil, "ARTWORK")
TMCFrame.ModelPreview.Favorite:SetPoint("BOTTOMRIGHT", -10, 0)
TMCFrame.ModelPreview.Favorite:SetSize(40, 40)
TMCFrame.ModelPreview.Favorite:SetTexture("Interface\\Collections\\Collections")
TMCFrame.ModelPreview.Favorite:SetTexCoord(
		0.18, 0.02, 0.18, 0.07, 0.23, 0.02, 0.23, 0.07)
-- end ModelPreview Favorite frame --------------------------------------------


-- ModelPreview AddToFavorite frame -------------------------------------------
TMCFrame.ModelPreview.AddToFavorite = CreateFrame(
		"Button", nil, TMCFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCFrame.ModelPreview.AddToFavorite:SetSize(120, 30)
TMCFrame.ModelPreview.AddToFavorite:SetPoint("BOTTOMLEFT", 11, 11)
TMCFrame.ModelPreview.AddToFavorite:SetText("Add to Favorite")
TMCFrame.ModelPreview.AddToFavorite:SetScript("OnClick", function()
	TakusMorphCatalogDB.FavoriteList[
		TMCFrame.ModelPreview.ModelFrame.DisplayInfo] = 1
	TMCFrame.ModelPreview.AddToFavorite:Hide()
	TMCFrame.ModelPreview.RemoveFavorite:Show()
	TMCFrame.ModelPreview.Favorite:Show()
	TMCFrame.Gallery:Load()
end)
-- end ModelPreview AddToFavorite frame ---------------------------------------


-- ModelPreview RemoveFavorite frame ------------------------------------------
TMCFrame.ModelPreview.RemoveFavorite = CreateFrame(
		"Button", nil, TMCFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCFrame.ModelPreview.RemoveFavorite:SetSize(120, 30)
TMCFrame.ModelPreview.RemoveFavorite:SetPoint("BOTTOMLEFT", 11, 11)
TMCFrame.ModelPreview.RemoveFavorite:SetText("Remove Favorite")
TMCFrame.ModelPreview.RemoveFavorite:SetScript("OnClick", function()
	TakusMorphCatalogDB.FavoriteList[
		TMCFrame.ModelPreview.ModelFrame.DisplayInfo] = nil
	TMCFrame.ModelPreview.AddToFavorite:Show()
	TMCFrame.ModelPreview.RemoveFavorite:Hide()
	TMCFrame.ModelPreview.Favorite:Hide()
	TMCFrame.Gallery:Load()
end)
-- end ModelPreview RemoveFavorite frame --------------------------------------


-- ModelPreview PlayAs frame --------------------------------------------------
TMCFrame.ModelPreview.PlayAs = CreateFrame(
		"Button", nil, TMCFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCFrame.ModelPreview.PlayAs:SetSize(70, 30)
TMCFrame.ModelPreview.PlayAs:SetPoint("BOTTOMLEFT", 131, 11)
TMCFrame.ModelPreview.PlayAs:SetText("PLAY AS")
TMCFrame.ModelPreview.PlayAs:SetScript("OnClick", function()
	local msg = ".morph " .. TMCFrame.ModelPreview.ModelFrame.DisplayInfo
	DEFAULT_CHAT_FRAME.editBox:SetText(msg)
	ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
end)
-- end ModelPreview PlayAs frame ----------------------------------------------


-- ModelPreview MountAs frame -------------------------------------------------
TMCFrame.ModelPreview.MountAs = CreateFrame(
		"Button", nil, TMCFrame.ModelPreview.ModelFrame, "UIPanelButtonTemplate")
TMCFrame.ModelPreview.MountAs:SetSize(85, 30)
TMCFrame.ModelPreview.MountAs:SetPoint("BOTTOMLEFT", 201, 11)
TMCFrame.ModelPreview.MountAs:SetText("MOUNT AS")
TMCFrame.ModelPreview.MountAs:SetScript("OnClick", function()
	local msg = ".mount " .. TMCFrame.ModelPreview.ModelFrame.DisplayInfo
	DEFAULT_CHAT_FRAME.editBox:SetText(msg)
	ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
end)
-- end ModelPreview MountAs frame ---------------------------------------------


-- TMCFrame Gallery frame -----------------------------------------------------
TMCFrame.Gallery = CreateFrame("Frame", nil, TMCFrame)
TMCFrame.Gallery:SetPoint("TOP", 0, -50)
TMCFrame.Gallery:SetSize(TMCFrame:GetWidth() - 50, TMCFrame:GetHeight() - 125)

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


function createCellFrame(CellIndex)
	Cells[CellIndex] = CreateFrame("Button", nil, TMCFrame.Gallery)
	Cells[CellIndex]:SetFrameStrata("DIALOG")
	Cells[CellIndex]:RegisterForClicks("AnyUp")
	Cells[CellIndex].Favorite = Cells[CellIndex]:CreateTexture(nil, "ARTWORK")
	Cells[CellIndex].Favorite:SetPoint("TOPLEFT", -5, 0)
	Cells[CellIndex].Favorite:SetSize(20, 20)
	Cells[CellIndex].Favorite:SetTexture("Interface\\Collections\\Collections")
	Cells[CellIndex].Favorite:SetTexCoord(
			0.18, 0.02, 0.18, 0.07, 0.23, 0.02, 0.23, 0.07)
	Cells[CellIndex].HighlightBackground =
		Cells[CellIndex]:CreateTexture(nil, "BACKGROUND")
	Cells[CellIndex].HighlightBackground:SetColorTexture(50, 50, 50, 0.2)
	Cells[CellIndex].HighlightBackground:SetAllPoints(Cells[CellIndex])
	Cells[CellIndex]:SetHighlightTexture(Cells[CellIndex].HighlightBackground)
	Cells[CellIndex].DisplayFontString =
		Cells[CellIndex]:CreateFontString(nil, nil, "GameFontWhite")
	Cells[CellIndex].DisplayFontString:SetPoint("TOP", 0, 0)
	Cells[CellIndex].ModelFrame = CreateFrame("PlayerModel", nil, Cells[CellIndex])
	local ColumnWidth = TMCFrame.Gallery:GetWidth() / NumberOfColumn
	local OffsetX = CellIndex % NumberOfColumn
	local OffsetY = floor(CellIndex / NumberOfColumn)
	Cells[CellIndex]:SetWidth(ColumnWidth)
	Cells[CellIndex]:SetHeight(ColumnWidth)
	Cells[CellIndex]:SetPoint(
			"TOPLEFT", OffsetX * ColumnWidth, OffsetY * - ColumnWidth)
	Cells[CellIndex].ModelFrame:SetAllPoints()
	Cells[CellIndex]:Show()
end


function updateFavorites()
	--update FavoriteList from popup_transform
	for _, v in ipairs(ns.display_favorite) do
		TakusMorphCatalogDB.FavoriteList[tonumber(v)] = 1
		ns.display_favorite = {}
	end
end


function registerCellOnClick(CellIndex, clickModelID)
	Cells[CellIndex]:SetScript("OnClick", function()
		TMCFrame.ModelPreview.ModelFrame:SetDisplayInfo(clickModelID)
		local displayResult = doGetDisplayInfo(clickModelID)
		TMCFrame.ModelPreview.FontString:SetText(displayResult)
		if TakusMorphCatalogDB.FavoriteList[
				TMCFrame.ModelPreview.ModelFrame.DisplayInfo] then
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

function getModeID()
	while true do
		if not DisplayFavorites then
			ModelID = ModelID + 1
			return ModelID
		else
			ModelID = ModelID + 1
			if TakusMorphCatalogDB.FavoriteList[ModelID] then
				return ModelID
			end
		end
	end
end


function TMCFrame.Gallery:Load()
	local found = false
	LastStartID = ModelID
	updateFavorites()
	local CellIndex = 0

	while CellIndex < pageTotalNum do
		if Cells[CellIndex] then
			Cells[CellIndex]:Hide()
			Cells[CellIndex] = nil
		end
		createCellFrame(CellIndex)
		while ModelID <= MaxModelID do
			ModelID = getModeID()
			Cells[CellIndex].ModelFrame:SetDisplayInfo(ModelID)
			Cells[CellIndex].DisplayFontString:SetText(ModelID)
			if (Cells[CellIndex].ModelFrame.DisplayInfo == MaxModelID) then
				Cells[CellIndex]:Hide()
			end
			local BlankModelFileID = 2418
			if Cells[CellIndex].ModelFrame:GetModelFileID() ~= nil and
				Cells[CellIndex].ModelFrame:GetModelFileID() ~= BlankModelFileID then
				registerCellOnClick(CellIndex, ModelID)
				if TakusMorphCatalogDB.FavoriteList[ModelID] then
					Cells[CellIndex].Favorite:Show()
				else
					Cells[CellIndex].Favorite:Hide()
				end
				found = true
				print("xxx", LastStartID)
				break
			end
		end
		if found then
			CellIndex = CellIndex + 1
		end
	end
	TMCFrame.PageController.FontString:SetText(LastMaxModelID .. " - " .. ModelID)
	TMCFrame.PageController:UpdateButtons()
end
-- end TMCFrame Gallery frame -------------------------------------------------


-- slash commands -------------------------------------------------------------
SLASH_TAKUSMORPHCATALOG1 = '/tmc'
function SlashCmdList.TAKUSMORPHCATALOG()
	TMCFrame:Show()
	ModelID=LastMaxModelID
	TMCFrame.Gallery:Load()
end
-- end slash commands ---------------------------------------------------------
