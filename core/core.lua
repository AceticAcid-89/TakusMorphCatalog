local _, ns = ...

-- coreFrame (main)
local coreFrame = CreateFrame("Frame", nil, UIParent)
coreFrame:Hide()
coreFrame:SetFrameStrata("DIALOG")
coreFrame:SetWidth(1000)
coreFrame:SetHeight(700)
coreFrame:SetPoint("TOPLEFT",0,0)
coreFrame:SetMovable(true)
coreFrame:SetMinResize(400, 400)
coreFrame:SetClampedToScreen(true)
coreFrame:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = {left = 11, right = 12, top = 12, bottom = 11}
})
coreFrame:EnableKeyboard(true)
coreFrame:SetScript("OnKeyDown", function(self, key)
	if key == "ESCAPE" then
		coreFrame:Hide()
	end
end)
-- end coreFrame


coreFrame.FontString = coreFrame:CreateFontString(
		nil, "BACKGROUND", "GameFontRed")
coreFrame.FontString:SetPoint("CENTER")
coreFrame.FontString:SetFont("Fonts\\FRIZQT__.TTF", 80, "OUTLINE, MONOCHROME, THICKOUTLINE")


buttons = {}
Types = {"Models", "Mounts", "Armors", "Weapons", "Pets" }

function hideAll()
	for _, cataType in ipairs(Types) do
		if ns[cataType .. "TMCFrame"] then
			ns[cataType .. "TMCFrame"]:Hide()
		end
	end
end

for index, cataType in ipairs(Types) do
	buttons[index] = CreateFrame("Button", nil, coreFrame, "UIPanelButtonTemplate")
	buttons[index]:SetPoint("BOTTOMLEFT", 100 * (index - 1) + 3, -25)
	buttons[index]:SetSize(100, 30)
	buttons[index]:SetText(cataType)
	buttons[index]:SetScript("OnClick", function()
	coreFrame.FontString:Hide()
	hideAll()
	ns[cataType .. "TMCFrame"].TAKUSMORPHCATALOG()
end)
end

-- slash commands
SLASH_TAKUSMORPHCATALOG1 = '/tmc'
function SlashCmdList.TAKUSMORPHCATALOG()
	hideAll()
	coreFrame:Show()
	coreFrame.FontString:Show()
	coreFrame.FontString:SetText("TAKUS MORPH\nCATALOG")
end
-- end slash commands