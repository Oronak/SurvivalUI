--By Oronak for usage on TurtleWoW
SV_UI_X_POS = 20
SV_UI_Y_POS = -95;
SV_UI_SCALE = 1;

--Debug Flag
local debug = false;

--GUI Components that will need referencing
local SurvivalUI_GUI;
local SurvivalUI_Skill_Level_Frame;
local SurvivalUI_Skill_Level_Bar;
local SurvivalUI_Skill_Level_Text;

local SurvivalUI_Craft_Slots = {};
local SurvivalUI_Craft_Slot_Names = {};
local SurvivalUI_Craft_Slot_Icons = {};
local SurvivalUI_Craft_Slot_Reagents = {};

local SurvivalUI_Ready = false;

--Compatability checks
local ATSW = IsAddOnLoaded("AdvancedTradeSkillWindow");

--Skill reference
local numCraftingSkills = 3; --Right now making this go above 3 will cause problems. Will make it scalable later
local survivalCraftingSkills = {
	[1] = "Dim Torch",
	[2] = "Traveler's Tent",
	[3] = "Fishing Boat",
};

local numSpellbookSkills = 1; --Same here, leave as is
local survivalSpellbookSkills = {
	[1] = { 
			["NAME"] = "Bright Campfire",
			["ID"] = 7359,
			["REAGENTS"] = {
				[1] = "Simple Wood",
				[2] = "Flint and Tinder"
			}
	}
}

local survivalReagents = {
	["Simple Wood"] = 4470,
	["Handful of Copper Bolts"] = 4359,
	["Linen Cloth"] = 2589,
	["Unlit Poor Torch"] = 6183,
	["Flint and Tinder"] = 4471
}

--Bindings
function SurvivalUI_Load()
	SLASH_SURVIVALUI1 = "/svui";
	SlashCmdList["SURVIVALUI"] = SurvivalUI_Command;
		
	this:RegisterEvent("PLAYER_LOGIN");
	this:RegisterEvent("ADDON_LOADED");
	this:RegisterEvent("BAG_UPDATE");
	this:RegisterEvent("TRADE_SKILL_UPDATE");
	this:RegisterEvent("TRADE_SKILL_SHOW");
	this:RegisterEvent("TRADE_SKILL_CLOSE");
	this:RegisterEvent("SPELL_UPDATE_USABLE");
end

function SurvivalUI_OnEvent(event)
	if (event == "PLAYER_LOGIN") then
		SurvivalUI_Ready = SurvivalUI_UI_Setup();
		local TITLE = GetAddOnMetadata("SurvivalUI", "Title")
		local VERSION = GetAddOnMetadata("SurvivalUI", "Version")
		local AUTHOR = GetAddOnMetadata("SurvivalUI", "Author")
		DEFAULT_CHAT_FRAME:AddMessage(TITLE .. " v" .. VERSION .. " by " .. AUTHOR .." was loaded.")
	
	elseif(event=="ADDON_LOADED") then
		SurvivalUI_Ready = true;
	
	elseif(event=="TRADE_SKILL_SHOW") then
		if (GetTradeSkillLine() == "Survival") then
			--Replace the default UI tradeskill window with this
			--I need this frame active to be able to even get a hook to craft anything
			if (not debug) then
				--If AdvancedTradeSkillWindow is being used
				if(ATSW) then
					ATSWFrame:SetAlpha(0);
					ATSWFrame:SetScale(0.001);
				else
					TradeSkillFrame:SetAlpha(0);
					TradeSkillFrame:SetScale(0.001);
				end
			end
			SurvivalUI_UI_Update_List();
			SurvivalUI_GUI:Show();
		else
			if(ATSW) then
				ATSWFrame:SetAlpha(1);
				ATSWFrame:SetScale(1);
			else
				TradeSkillFrame:SetScale(1);
				TradeSkillFrame:SetAlpha(1);
			end
			SurvivalUI_GUI:Hide();
		end
		
	elseif((event=="TRADE_SKILL_UPDATE" 
			or event=="BAG_UPDATE"
			or event == "SPELL_UPDATE_USABLE") 
			and SurvivalUI_Ready
			and SurvivalUI_GUI:IsShown()) then	
				SurvivalUI_UI_Update_List();
		
	elseif(event=="TRADE_SKILL_CLOSE") then	
		SurvivalUI_GUI:Hide();
	end
end

function SurvivalUI_Command(command)
	if (command == "reset") then
		SV_UI_X_POS = 20;
		SV_UI_Y_POS = -95;
		SV_UI_SCALE = 1;
		SurvivalUI_GUI:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", SV_UI_X_POS, SV_UI_Y_POS);
		SurvivalUI_GUI:SetScale(SV_UI_SCALE);
	elseif (string.find(command, "scale")) then
		scaleTo = string.sub(command,7);
		if tonumber(scaleTo) then 
			SV_UI_SCALE = scaleTo;
			SurvivalUI_GUI:SetScale(scaleTo);
		else 
			DEFAULT_CHAT_FRAME:AddMessage("You need to give a number to scale by.");
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("To reset the SurivalUI to it's default settings:\n   /svui reset");
		DEFAULT_CHAT_FRAME:AddMessage("Set the scale of the ui, use:\n   /svui scale X");
	end
end

--Functionality
--magic numbers are funne :^)
function SurvivalUI_UI_Setup() 

	-- Option Frame
	SurvivalUI_GUI = CreateFrame("Frame", "SurvivalUI_GUI");
	SurvivalUI_GUI:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", SV_UI_X_POS, SV_UI_Y_POS);
	SurvivalUI_GUI:SetScale(SV_UI_SCALE);
	
	SurvivalUI_GUI:SetWidth(269);
	SurvivalUI_GUI:SetHeight(262);
	
	if(debug) then
		SurvivalUI_GUI:CreateTexture(nil, "BACKGROUND")
		local mainBackground = SurvivalUI_GUI:CreateTexture(nil, "BACKGROUND")
		mainBackground:SetAllPoints(SurvivalUI_GUI)
		mainBackground:SetTexture(0.1, 0.3, 0.4, 0.5)
	end
	
	--Border Textures
	local cornerTextureTopLeft = SurvivalUI_GUI:CreateTexture(nil, "BACKGROUND");
	cornerTextureTopLeft:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\top-left-border");
	cornerTextureTopLeft:SetTexCoord(0.03, 1, 0, 1) --White line fix. Cant get it to export without it
	cornerTextureTopLeft:SetHeight(256);
	cornerTextureTopLeft:SetWidth(256*0.97);
	cornerTextureTopLeft:SetDrawLayer("BACKGROUND", -8);
	cornerTextureTopLeft:SetPoint("LEFT", SurvivalUI_GUI, "LEFT", -29, 30);
	
	local titleText = SurvivalUI_GUI:CreateFontString(nil, "ARTWORK");
	titleText:SetFont("Fonts\\FRIZQT__.TTF", 7);
	titleText:SetTextColor(1, 0.8, 0); --My guess at the color
	titleText:SetText("Survival");
	titleText:SetPoint("TOPLEFT", SurvivalUI_GUI, 123, -6)
	titleText:SetJustifyH("LEFT");
	
	local cornerTextureBottomLeft = SurvivalUI_GUI:CreateTexture(nil, "BACKGROUND");
	cornerTextureBottomLeft:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\bottom-left-border");
	cornerTextureBottomLeft:SetTexCoord(0, 0.98, 0.45, 1) --White line fix. Cant get it to export without it
	cornerTextureBottomLeft:SetHeight(256*0.55);
	cornerTextureBottomLeft:SetWidth(256*0.98);
	cornerTextureBottomLeft:SetDrawLayer("BACKGROUND", -8);
	cornerTextureBottomLeft:SetPoint("LEFT", SurvivalUI_GUI, "LEFT", -6.82, -167.7);
	
	local cornerTextureTopRight = SurvivalUI_GUI:CreateTexture(nil, "BACKGROUND");
	cornerTextureTopRight:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\top-right-border");
	cornerTextureTopRight:SetTexCoord(0.435, 1, 0, 0.968) --White line fix. Cant get it to export without it
	cornerTextureTopRight:SetHeight(256*0.968);
	cornerTextureTopRight:SetWidth(256*0.565);
	cornerTextureTopRight:SetDrawLayer("BACKGROUND", -8);
	cornerTextureTopRight:SetPoint("LEFT", SurvivalUI_GUI, "LEFT", 216.8, 26.1);

	local cornerTextureBottomRight = SurvivalUI_GUI:CreateTexture(nil, "BACKGROUND");
	cornerTextureBottomRight:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\bottom-right-border");
	cornerTextureBottomRight:SetTexCoord(0.45, 1, 0.43, 1) --White line fix. Cant get it to export without it
	cornerTextureBottomRight:SetHeight(256*0.57);
	cornerTextureBottomRight:SetWidth(256*0.55);
	cornerTextureBottomRight:SetDrawLayer("BACKGROUND", -8);
	cornerTextureBottomRight:SetPoint("LEFT", SurvivalUI_GUI, "LEFT", 243, -169.2);
	
	--Book textures
	local bookTextureLeft = SurvivalUI_GUI:CreateTexture(nil, "BORDER");
	bookTextureLeft:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\arch-bookitemleft");
	bookTextureLeft:SetHeight(256*0.985);
	bookTextureLeft:SetWidth(256*0.985);
	bookTextureLeft:SetPoint("LEFT", SurvivalUI_GUI, "LEFT", 5.1, -11);
	
	local bookTextureRight = SurvivalUI_GUI:CreateTexture(nil, "BORDER");
	bookTextureRight:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\arch-bookitemright");
	bookTextureRight:SetHeight(256*0.985);
	bookTextureRight:SetWidth(16*0.985);
	bookTextureRight:SetPoint("LEFT", SurvivalUI_GUI, "RIGHT", -11.9, -11);
	
	local titleFrillLeft = SurvivalUI_GUI:CreateTexture(nil, "ARTWORK");
	titleFrillLeft:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\parts");
	titleFrillLeft:SetTexCoord(0, 0.11, 0.55, 0.7) 
	titleFrillLeft:SetHeight((512*0.15)/4);
	titleFrillLeft:SetWidth((256*0.48)/4);
	titleFrillLeft:SetPoint("TOPLEFT", SurvivalUI_GUI, "TOPLEFT", 85, -24);
	
	
	local titleFrillRight = SurvivalUI_GUI:CreateTexture(nil, "ARTWORK");
	titleFrillRight:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\parts");
	titleFrillRight:SetTexCoord(0, 0.11, 0.7, 0.85) 
	titleFrillRight:SetHeight((512*0.15)/4);
	titleFrillRight:SetWidth((256*0.48)/4);
	titleFrillRight:SetPoint("TOPLEFT", SurvivalUI_GUI, "TOPLEFT", 165, -25.3);	
		
	local mainText = SurvivalUI_GUI:CreateFontString(nil, "ARTWORK");
	mainText:SetFont("Fonts\\FRIZQT__.TTF", 10);
	mainText:SetTextColor(0.2, 0.1, 0); --My guess at the color
	mainText:SetText("Survival");
	mainText:SetPoint("TOPLEFT", SurvivalUI_GUI, 120, -30)
	mainText:SetJustifyH("LEFT");
	
	SurvivalUI_GUI:SetMovable(true)
	SurvivalUI_GUI:EnableMouse(true)
	SurvivalUI_GUI:SetClampedToScreen(false)
	SurvivalUI_GUI:RegisterForDrag("LeftButton")
	SurvivalUI_GUI:SetScript("OnMouseDown", function()
		if arg1 == "LeftButton" and not this.isMoving then
			this:StartMoving();
			this.isMoving = true;
		end
	end)
	SurvivalUI_GUI:SetScript("OnMouseUp", function()
		if arg1 == "LeftButton" and this.isMoving then
			this:StopMovingOrSizing();
			this.isMoving = false;
			_,_,_,SV_UI_X_POS,SV_UI_Y_POS = this:GetPoint();
		end
	end)
	SurvivalUI_GUI:SetScript("OnHide", function()
		if this.isMoving then
			this:StopMovingOrSizing();
			this.isMoving = false;
		end
	end)
	
	local closeButton = CreateFrame("Button", "SVOptionsFrameCloseButton", SurvivalUI_GUI, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", SurvivalUI_GUI, 3.3, -1)
	closeButton:SetWidth(17)
	closeButton:SetHeight(17)
	closeButton:SetScript("OnClick", function()
		this:GetParent():Hide()
		TradeSkillFrame:Hide();
	end)
	
	SurvivalUI_GUI:Hide();
	
	--Level bar setup
	SurvivalUI_Skill_Level_Frame = CreateFrame("Frame", "SurvivalUI_Skill_Level_Frame", SurvivalUI_GUI);
	SurvivalUI_Skill_Level_Frame:SetWidth(210);
	SurvivalUI_Skill_Level_Frame:SetHeight(15);
	SurvivalUI_Skill_Level_Frame:SetPoint("TOPLEFT", "SurvivalUI_GUI", "TOPLEFT", 38, -40);
	
	if(debug) then
		SurvivalUI_Skill_Level_Frame:CreateTexture(nil, "OVERLAY")
		local levelBackground = SurvivalUI_Skill_Level_Frame:CreateTexture(nil, "OVERLAY")
		levelBackground:SetAllPoints(SurvivalUI_Skill_Level_Frame)
		levelBackground:SetTexture(0.1, 0.3, 0.4, 0.5)
	end
	
	local skillLevelBarBg = SurvivalUI_Skill_Level_Frame:CreateTexture(nil, "ARTWORK");
	skillLevelBarBg:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\progress-bg");
	skillLevelBarBg:SetWidth(250);
	skillLevelBarBg:SetHeight(32);
	skillLevelBarBg:SetPoint("TOPLEFT", SurvivalUI_Skill_Level_Frame, "TOPLEFT", 0, 0);
	
	SurvivalUI_Skill_Level_Bar = SurvivalUI_Skill_Level_Frame:CreateTexture(nil, "OVERLAY");
	SurvivalUI_Skill_Level_Bar:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\progress");
	SurvivalUI_Skill_Level_Bar:SetWidth(201);
	SurvivalUI_Skill_Level_Bar:SetHeight(10);
	SurvivalUI_Skill_Level_Bar:SetPoint("TOPLEFT", SurvivalUI_Skill_Level_Frame, "TOPLEFT", 5.5, -6);
	
	SurvivalUI_Skill_Level_Text = SurvivalUI_Skill_Level_Frame:CreateFontString(nil, "OVERLAY");
	SurvivalUI_Skill_Level_Text:SetFont("Fonts\\FRIZQT__.TTF", 7);
	SurvivalUI_Skill_Level_Text:SetTextColor(1, 1, 1);
	SurvivalUI_Skill_Level_Text:SetText("0/0");
	SurvivalUI_Skill_Level_Text:SetPoint("LEFT", SurvivalUI_Skill_Level_Frame, "LEFT", 85, -3)
	
	--Setup the clickable slots
	for i=1, numCraftingSkills+numSpellbookSkills, 1 do
		SurvivalUI_Craft_Slots[i] = {};
		SurvivalUI_Craft_Slots[i]["FRAME"] = CreateFrame("Button", "SurvivalUI_Craft_Slots_"..i, SurvivalUI_GUI);
		SurvivalUI_Craft_Slots[i]["FRAME"]:SetHeight(27);
		SurvivalUI_Craft_Slots[i]["FRAME"]:SetWidth(205);
		SurvivalUI_Craft_Slots[i]["FRAME"]:SetPoint("TOPLEFT", "SurvivalUI_GUI", "TOPLEFT", 41, -72-((i-1)*44));

		SurvivalUI_Craft_Slots[i]["FRAME"]:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD");
		
		--Bar background art setup
		SurvivalUI_Craft_Slots[i]["TEXTURE"] = SurvivalUI_Craft_Slots[i]["FRAME"]:CreateTexture(nil, "ARTWORK");
		SurvivalUI_Craft_Slots[i]["TEXTURE"]:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\skill-bar");
		SurvivalUI_Craft_Slots[i]["TEXTURE"]:SetTexCoord(0.061, 0.934, 0.29, 0.73) --white line fix
		SurvivalUI_Craft_Slots[i]["TEXTURE"]:SetHeight((256*0.42)/3);
		SurvivalUI_Craft_Slots[i]["TEXTURE"]:SetWidth((512*0.873)/2.18);
		SurvivalUI_Craft_Slots[i]["TEXTURE"]:SetAlpha(0.7)
		SurvivalUI_Craft_Slots[i]["TEXTURE"]:SetPoint("TOPLEFT", SurvivalUI_Craft_Slots[i]["FRAME"], "TOPLEFT", 0, 2.3);	
		
		--Main icon setup
		SurvivalUI_Craft_Slot_Icons[i] = {};
		SurvivalUI_Craft_Slot_Icons[i]["FRAME"] = CreateFrame("Button", "SurvivalUI_Craft_Slot_Icons_"..i, SurvivalUI_Craft_Slots[i]["FRAME"]);
		SurvivalUI_Craft_Slot_Icons[i]["FRAME"]:SetHeight(26.1);
		SurvivalUI_Craft_Slot_Icons[i]["FRAME"]:SetWidth(26.1);
		SurvivalUI_Craft_Slot_Icons[i]["FRAME"]:SetPoint("TOPLEFT", SurvivalUI_Craft_Slots[i]["FRAME"], "TOPLEFT", 2, -0.5);	
		SurvivalUI_Craft_Slot_Icons[i]["TEXTURE"] = SurvivalUI_Craft_Slot_Icons[i]["FRAME"]:CreateTexture(nil, "OVERLAY");
		SurvivalUI_Craft_Slot_Icons[i]["TEXTURE"]:SetAllPoints(SurvivalUI_Craft_Slot_Icons[i]["FRAME"]);
		if(debug) then
			local craftSlotBackground = SurvivalUI_Craft_Slots[i]["FRAME"]:CreateTexture(nil, "OVERLAY");
			craftSlotBackground:SetAllPoints(SurvivalUI_Craft_Slot_Icons[i]["FRAME"]);
			craftSlotBackground:SetTexture(0.1, 0.3, 0.4, 0.5);
			
			SurvivalUI_Craft_Slot_Icons[i]["FRAME"]:Show();
		end		

		--Reagent Icons setup
		SurvivalUI_Craft_Slot_Reagents[i] = {};
		for j=1, 4, 1 do
			SurvivalUI_Craft_Slot_Reagents[i][j] = {};
			SurvivalUI_Craft_Slot_Reagents[i][j]["FRAME"] = CreateFrame("Button", "SurvivalUI_Craft_Slot_Reagents_"..i, SurvivalUI_Craft_Slots[i]["FRAME"]);
			SurvivalUI_Craft_Slot_Reagents[i][j]["FRAME"]:SetPoint("TOPLEFT", SurvivalUI_Craft_Slots[i]["FRAME"], "TOPLEFT", 177-((j-1)*26.2), -0.5);	
			SurvivalUI_Craft_Slot_Reagents[i][j]["FRAME"]:SetHeight(26.1);
			SurvivalUI_Craft_Slot_Reagents[i][j]["FRAME"]:SetWidth(26.1);
			SurvivalUI_Craft_Slot_Reagents[i][j]["TEXTURE"] = SurvivalUI_Craft_Slot_Reagents[i][j]["FRAME"]:CreateTexture(nil, "OVERLAY");
			SurvivalUI_Craft_Slot_Reagents[i][j]["TEXTURE"]:SetAllPoints(SurvivalUI_Craft_Slot_Reagents[i][j]["FRAME"]);
			
			SurvivalUI_Craft_Slot_Reagents[i][j]["FRAME"]:Hide();
			if(debug) then
				local reagentBackground = SurvivalUI_Craft_Slots[i]["FRAME"]:CreateTexture(nil, "OVERLAY");
				reagentBackground:SetAllPoints(SurvivalUI_Craft_Slot_Reagents[i][j]["FRAME"]);
				reagentBackground:SetTexture(0.1, 0.3, 0.4, 0.5);
				
				SurvivalUI_Craft_Slot_Reagents[i][j]["FRAME"]:Show();
			end		
			
			--Supply/Required text
			SurvivalUI_Craft_Slot_Reagents[i][j]["COUNT"] = SurvivalUI_Craft_Slot_Reagents[i][j]["FRAME"]:CreateFontString(nil, "OVERLAY", NumberFontNormal);
			SurvivalUI_Craft_Slot_Reagents[i][j]["COUNT"]:SetFont("Fonts\\FRIZQT__.TTF", 7, "OUTLINE");
			SurvivalUI_Craft_Slot_Reagents[i][j]["COUNT"]:SetText("N/A");
			SurvivalUI_Craft_Slot_Reagents[i][j]["COUNT"]:SetPoint("BOTTOMRIGHT", SurvivalUI_Craft_Slot_Reagents[i][j]["FRAME"], "BOTTOMRIGHT", -1, 2)
			SurvivalUI_Craft_Slot_Reagents[i][j]["COUNT"]:SetJustifyH("RIGHT");
			SurvivalUI_Craft_Slot_Reagents[i][j]["COUNT"]:Hide();
			if(debug) then				
				SurvivalUI_Craft_Slot_Reagents[i][j]["COUNT"]:Show();
			end	
			
		end
		
		--Text independent of the main movable button frames
		local skillNameFrame = CreateFrame("Button", "SurvivalUI_Craft_Slots_"..i, SurvivalUI_GUI);
		skillNameFrame:SetHeight(29);
		skillNameFrame:SetWidth(205);
		skillNameFrame:SetPoint("TOPLEFT", "SurvivalUI_GUI", "TOPLEFT", 41, -72-((i-1)*44));
		
		SurvivalUI_Craft_Slot_Names[i] = {};
		
		SurvivalUI_Craft_Slot_Names[i]["NAME"] = skillNameFrame:CreateFontString(nil, "ARTWORK");
		SurvivalUI_Craft_Slot_Names[i]["NAME"]:SetFont("Fonts\\FRIZQT__.TTF", 8);
		SurvivalUI_Craft_Slot_Names[i]["NAME"]:SetTextColor(0.2, 0.1, 0); --My guess at the color
		SurvivalUI_Craft_Slot_Names[i]["NAME"]:SetText("N/A");
		SurvivalUI_Craft_Slot_Names[i]["NAME"]:SetPoint("LEFT", skillNameFrame, 1, 21.5)
		SurvivalUI_Craft_Slot_Names[i]["NAME"]:SetJustifyH("CENTER");
		SurvivalUI_Craft_Slot_Names[i]["NAME"]:Hide();
		
		SurvivalUI_Craft_Slot_Names[i]["NAME"]:Hide();
		
		SurvivalUI_Craft_Slot_Names[i]["COOLDOWN"] = skillNameFrame:CreateFontString(nil, "ARTWORK");
		SurvivalUI_Craft_Slot_Names[i]["COOLDOWN"]:SetFont("Fonts\\FRIZQT__.TTF", 6);
		SurvivalUI_Craft_Slot_Names[i]["COOLDOWN"]:SetTextColor(100/255, 0, 0);
		SurvivalUI_Craft_Slot_Names[i]["COOLDOWN"]:SetText("N/A");
		SurvivalUI_Craft_Slot_Names[i]["COOLDOWN"]:SetPoint("RIGHT", skillNameFrame, -3, 20)
		SurvivalUI_Craft_Slot_Names[i]["COOLDOWN"]:SetJustifyH("RIGHT");
		SurvivalUI_Craft_Slot_Names[i]["COOLDOWN"]:Hide();
		
		SurvivalUI_Craft_Slot_Names[i]["COOLDOWN"]:Hide();
		
		SurvivalUI_Craft_Slots[i]["FRAME"]:Hide();

		if(debug) then
			SurvivalUI_Craft_Slots[i]["FRAME"]:CreateTexture(nil, "OVERLAY");
			local craftBackground = SurvivalUI_Craft_Slots[i]["FRAME"]:CreateTexture(nil, "OVERLAY");
			craftBackground:SetAllPoints(SurvivalUI_Craft_Slots[i]["FRAME"]);
			craftBackground:SetTexture(0.1, 0.3, 0.4, 0.5);
			
			SurvivalUI_Craft_Slots[i]["FRAME"]:Show();
			
			SurvivalUI_Craft_Slot_Names[i]["NAME"]:Show();
			SurvivalUI_Craft_Slot_Names[i]["COOLDOWN"]:Show();
		end	
		
	end
end

--Part where it checks your skill level and what you know, and makes adjustments
function SurvivalUI_UI_Update_List() 
	local skillOffset = FauxScrollFrame_GetOffset(TradeSkillListScrollFrame);	

	for i=1+numSpellbookSkills, numCraftingSkills+numSpellbookSkills, 1 do
	
		local skillIndex = (i-numSpellbookSkills) + skillOffset;
		local skillName, skillType, numAvailable, _ = GetTradeSkillInfo(skillIndex);
		
		if(skillName ~= nil) then 
			SurvivalUI_Craft_Slots[i]["FRAME"]:Show();
			SurvivalUI_Craft_Slots[i]["FRAME"]:Enable();
			
			--Click handling
			SurvivalUI_Craft_Slots[i]["FRAME"]:SetScript("OnClick", 
			function()
				DoTradeSkill(skillIndex, 1)
			end)
			
			--Crafting skill name setup
			SurvivalUI_Craft_Slot_Names[i]["NAME"]:SetText(skillName);
			SurvivalUI_Craft_Slot_Names[i]["NAME"]:Show();
			
			--Cooldown display
			if (GetTradeSkillCooldown(skillIndex) ) then
				SurvivalUI_Craft_Slot_Names[i]["COOLDOWN"]:SetText(COOLDOWN_REMAINING.." "..SecondsToTime(GetTradeSkillCooldown(skillIndex)));
				SurvivalUI_Craft_Slot_Names[i]["COOLDOWN"]:Show();
				SurvivalUI_Craft_Slots[i]["FRAME"]:Disable();
			else
				SurvivalUI_Craft_Slot_Names[i]["COOLDOWN"]:SetText("");
				SurvivalUI_Craft_Slot_Names[i]["COOLDOWN"]:Hide();
				SurvivalUI_Craft_Slots[i]["FRAME"]:Enable();
			end
			
			--Main Icon Setup
			local skillIconCheck = GetTradeSkillIcon(skillIndex);
			if(skillIconCheck ~= nil) then
				SurvivalUI_Craft_Slot_Icons[i]["TEXTURE"]:SetTexture(skillIconCheck);
			elseif (skillName == survivalCraftingSkills[2]) then --Bodge fix for currently missing icons for both of these as of writing. literally just war3 icons
				SurvivalUI_Craft_Slot_Icons[i]["TEXTURE"]:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\tent-icon");
			elseif (skillName == survivalCraftingSkills[3]) then
				SurvivalUI_Craft_Slot_Icons[i]["TEXTURE"]:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\boat-icon");
			end

			SurvivalUI_Craft_Slot_Icons[i]["FRAME"]:SetScript("OnEnter", function()
				GameTooltip:ClearLines();
				GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
				
				--fix until they add tooltips for these
				if (skillName == survivalCraftingSkills[2]) then
					GameTooltip:AddLine("Traveler's Tent", 1, 1, 1, 1);
					GameTooltip:AddLine("Builds a tent that provides rested\nexperience to anyone in it's range.");
				elseif (skillName == survivalCraftingSkills[3]) then
					GameTooltip:AddLine("Fishing Boat", 1, 1, 1, 1);
					GameTooltip:AddLine("Builds fishing boat, for fishing on.\nProvides +50 to your fishing skill.");
				else
					GameTooltip:SetTradeSkillItem(skillIndex);
				end
				
				GameTooltip:Show();
				CursorUpdate();
			end)
			SurvivalUI_Craft_Slot_Icons[i]["FRAME"]:SetScript("OnLeave", 
				function()
					GameTooltip:Hide();
					ResetCursor();
				end)
			SurvivalUI_Craft_Slot_Icons[i]["FRAME"]:Show();

			--Reagents Setup
			local numReagents = GetTradeSkillNumReagents(skillIndex);
			for j=1, numReagents, 1 do
				local reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(skillIndex, j);
				
				if(survivalReagents[reagentName] ~= nil) then
					--Seems to work to grab the link but errors out when using it. Will backup to hard coded strings for now
					--local reagentLink = GetTradeSkillReagentItemLink(skillIndex, j);
					SurvivalUI_Craft_Slot_Reagents[i][j]["FRAME"]:SetScript("OnEnter", 
						function()
							if (survivalReagents[reagentName] ~= nil) then
								GameTooltip:ClearLines();
								GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
								GameTooltip:SetHyperlink("item:"..survivalReagents[reagentName]..":0:0:0:0:0:0:0");
								GameTooltip:Show();
								CursorUpdate();
							end
						end)
					SurvivalUI_Craft_Slot_Reagents[i][j]["FRAME"]:SetScript("OnLeave", 
						function()
							GameTooltip:Hide();
							ResetCursor();
						end)
					
					SurvivalUI_Craft_Slot_Reagents[i][j]["TEXTURE"]:SetTexture(reagentTexture);
					if(playerReagentCount < reagentCount) then
						SurvivalUI_Craft_Slots[i]["FRAME"]:Disable();
						SurvivalUI_Craft_Slot_Reagents[i][j]["TEXTURE"]:SetVertexColor(0.5, 0.5, 0.5);
					else
						SurvivalUI_Craft_Slot_Reagents[i][j]["TEXTURE"]:SetVertexColor(1, 1, 1);
					end
					
					SurvivalUI_Craft_Slot_Reagents[i][j]["FRAME"]:Show();
					SurvivalUI_Craft_Slot_Reagents[i][j]["TEXTURE"]:Show();
					
					if(playerReagentCount >= 99) then
						SurvivalUI_Craft_Slot_Reagents[i][j]["COUNT"]:SetText("*/"..reagentCount);
					else
						SurvivalUI_Craft_Slot_Reagents[i][j]["COUNT"]:SetText(playerReagentCount.."/"..reagentCount);
					end
					SurvivalUI_Craft_Slot_Reagents[i][j]["COUNT"]:Show();
				end
			end
		end
		
	end
	
	--Campfire/Spell Handling
	--Campire is a spell and not tied to the profession tab at all. Needs different handling
	for i=1, numSpellbookSkills, 1 do
	
		SurvivalUI_Craft_Slots[i]["FRAME"]:Show();
		SurvivalUI_Craft_Slots[i]["FRAME"]:Enable();
		
		--Click handling
		SurvivalUI_Craft_Slots[i]["FRAME"]:SetScript("OnClick", 
		function()
			CastSpellByName(survivalSpellbookSkills[i]["NAME"]);
		end)
		
		spellID = SurvivalUI_GetSpellID(survivalSpellbookSkills[i]["NAME"]);
		
		--Main Icon
		SurvivalUI_Craft_Slot_Icons[i]["TEXTURE"]:SetTexture(GetSpellTexture(spellID, BOOKTYPE_SPELL));
		SurvivalUI_Craft_Slot_Icons[i]["FRAME"]:SetScript("OnEnter", 
			function()
				GameTooltip:ClearLines();
				GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
				GameTooltip:SetSpell(spellID, BOOKTYPE_SPELL);
				GameTooltip:Show();
				CursorUpdate();
			end)
		SurvivalUI_Craft_Slot_Icons[i]["FRAME"]:SetScript("OnLeave", 
			function()
				GameTooltip:Hide();
				ResetCursor();
			end)
		
		--Spell skill name setup
		SurvivalUI_Craft_Slot_Names[i]["NAME"]:SetText(survivalSpellbookSkills[i]["NAME"]);
		SurvivalUI_Craft_Slot_Names[i]["NAME"]:Show();
		
		for j=1, 4, 1 do
			if (survivalSpellbookSkills[i]["REAGENTS"][j] ~= nil) then	
				reagentName = survivalSpellbookSkills[i]["REAGENTS"][j];
				reagentID = survivalReagents[survivalSpellbookSkills[i]["REAGENTS"][j]];
				
				local _, itemLink, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(reagentID)
				SurvivalUI_Craft_Slot_Reagents[i][j]["FRAME"]:SetScript("OnEnter", 
					function()
						GameTooltip:ClearLines();
						GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
						GameTooltip:SetHyperlink(itemLink);
						GameTooltip:Show();
						CursorUpdate();
					end)
				SurvivalUI_Craft_Slot_Reagents[i][j]["FRAME"]:SetScript("OnLeave", 
					function()
						GameTooltip:Hide();
						ResetCursor();
					end)
				
				SurvivalUI_Craft_Slot_Reagents[i][j]["TEXTURE"]:SetTexture(itemTexture);
				SurvivalUI_Craft_Slot_Reagents[i][j]["FRAME"]:Show();
				SurvivalUI_Craft_Slot_Reagents[i][j]["TEXTURE"]:Show();
				
				--Getting reagent cost of a spell is a TBD thing. Too pain in the ass atm
				SurvivalUI_Craft_Slot_Reagents[i][j]["COUNT"]:Hide();

				
			end
		end
		
		--Cooldown display
		start, duration, _ = GetSpellCooldown(spellID, BOOKTYPE_SPELL);
		if (start ~= 0) then
			SurvivalUI_Craft_Slot_Names[i]["COOLDOWN"]:SetText(COOLDOWN_REMAINING.." "..SecondsToTime(duration-(GetTime()-start)));
			SurvivalUI_Craft_Slot_Names[i]["COOLDOWN"]:Show();
			SurvivalUI_Craft_Slots[i]["FRAME"]:Disable();
		else
			SurvivalUI_Craft_Slot_Names[i]["COOLDOWN"]:SetText("");
			SurvivalUI_Craft_Slot_Names[i]["COOLDOWN"]:Hide();
			SurvivalUI_Craft_Slots[i]["FRAME"]:Enable();
		end
		
	end
	
	for i=1, numCraftingSkills+numSpellbookSkills, 1 do
		if(SurvivalUI_Craft_Slots[i]["FRAME"]:IsEnabled() == 1) then
			--Animation push effect part
			SurvivalUI_Craft_Slots[i]["FRAME"]:SetScript("OnMouseDown", 
			function()
				_, _, _, xOfs, yOfs = this:GetPoint()
				this:SetPoint("TOPLEFT", "SurvivalUI_GUI", "TOPLEFT", xOfs+0.5, yOfs-0.5)
			end)
			SurvivalUI_Craft_Slots[i]["FRAME"]:SetScript("OnMouseUp", 
			function()
				_, _, _, xOfs, yOfs = this:GetPoint()
				this:SetPoint("TOPLEFT", "SurvivalUI_GUI", "TOPLEFT", xOfs-0.5, yOfs+0.5)
			end)
			SurvivalUI_Craft_Slots[i]["TEXTURE"]:SetVertexColor(1, 1, 1);
		else
			SurvivalUI_Craft_Slots[i]["FRAME"]:SetScript("OnMouseDown", nil);
			SurvivalUI_Craft_Slots[i]["FRAME"]:SetScript("OnMouseUp", nil);
			SurvivalUI_Craft_Slots[i]["TEXTURE"]:SetVertexColor(0.6, 0.6, 0.6);
		end
	end

	--Skill level display
	--Offset them all to make it sorta centered
	local _, skillLineRank, skillLineMaxRank = GetTradeSkillLine();
	SurvivalUI_Skill_Level_Bar:SetWidth(201*(skillLineRank/skillLineMaxRank));
	if (skillLineRank < 10) then
		SurvivalUI_Skill_Level_Text:SetText(skillLineRank.."/"..skillLineMaxRank);
		SurvivalUI_Skill_Level_Text:SetPoint("LEFT", SurvivalUI_Skill_Level_Frame, "LEFT", 92, -3);
	elseif (skillLineRank < 100) then
		SurvivalUI_Skill_Level_Text:SetText(skillLineRank.."/"..skillLineMaxRank);
		SurvivalUI_Skill_Level_Text:SetPoint("LEFT", SurvivalUI_Skill_Level_Frame, "LEFT", 87, -3);
	else
		SurvivalUI_Skill_Level_Text:SetText(skillLineRank.."/"..skillLineMaxRank);
		SurvivalUI_Skill_Level_Text:SetPoint("LEFT", SurvivalUI_Skill_Level_Frame, "LEFT", 85, -3);
	end
end

function SurvivalUI_GetSpellID(spellname)
    local i,done,name,id,spellrank=1,false;
	while not done do
        name,rank = GetSpellName(i,BOOKTYPE_SPELL);
        if not name then
            done=true;
        elseif (name==spellname and not spellrank) or (name==spellname and rank==spellrank) then
            id = i;
        end i = i+1;
    end
    return id
end