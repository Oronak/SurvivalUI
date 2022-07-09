--By Oronak for usage on TurtleWoW
SV_UI_X_POS = 20
SV_UI_Y_POS = -95;
SV_UI_SCALE = 1;
SV_UI_ORDER = {
	[1] = "Bright Campfire",
	[2] = "Dim Torch",
	[3] = "Traveler's Tent",
	[4] = "Fishing Boat"
}

--Debug Flag
local debug = false;

--GUI Components that will need global referencing
local SurvivalUI_GUI;
local SurvivalUI_Craft_Slot_RearrangeButtons = {};

local SurvivalUI_Skill_Level_Frame;
local SurvivalUI_Skill_Level_Bar;
local SurvivalUI_Skill_Level_Text;

local SurvivalUI_Craft_Slots = {};
local SurvivalUI_Craft_Slot_Names = {};
local SurvivalUI_Craft_Slot_Icons = {};
local SurvivalUI_Craft_Slot_Reagents = {};
local SurvivalUI_Craft_Slot_MultiCraft = {};

local SurvivalUI_Ready = false;
local SurvivalUI_IsRearrangeUnlocked = false;
local SurvivalUI_Tradeskill_MovedAway = false;

--Compatability checks
local ATSW = IsAddOnLoaded("AdvancedTradeSkillWindow");

--Skill reference
local numSurvivalSkills = 4; --Right now making this go above 4 will cause problems. Will make it scalable some other time if it ever matters
local survivalSkills = {
	[1] = { 
			["NAME"] = "Bright Campfire",
			["TYPE"] = "SPELL",
			["ID"] = 7359,
			["REAGENTS"] = {
				[1] = "Simple Wood",
				[2] = "Flint and Tinder"
			}
	},
	[2] = {
			["NAME"] = "Dim Torch",
			["TYPE"] = "TRADESKILL",
			["MULTI"] = true,
			["SKILLINDEX"] = nil
		  },
	[3] = {
			["NAME"] = "Traveler's Tent",
			["TYPE"] = "TRADESKILL",
			["MULTI"] = false,
			["SKILLINDEX"] = nil
		  },
	[4] = {
			["NAME"] ="Fishing Boat",
			["TYPE"] = "TRADESKILL",
			["MULTI"] = false,
			["SKILLINDEX"] = nil
		  }
};

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
	this:RegisterEvent("SPELLCAST_STOP");
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
		if (GetTradeSkillLine() == "Survival" ) then
			--Replace the default UI tradeskill window with this
			--I need this frame active to be able to even get a hook to craft anything
			if (not debug) then
				--If AdvancedTradeSkillWindow is being used
				if(ATSW) then
					ATSWFrame:SetAlpha(0);
					ATSWFrame:SetScale(0.001);
				else
					point, _, _, xOfs, yOfs = TradeSkillFrame:GetPoint();
					--I have to keep this frame active, so it gets fucked off to wherever you cant click (hopefully)
					TradeSkillFrame:SetPoint(point, TradeSkillFrame:GetParent(), xOfs-9999, yOfs); 
					TradeSkillFrame:SetAlpha(0);
										
					SurvivalUI_Tradeskill_MovedAway = true;
				end
			end
			SurvivalUI_UI_Update_List();
			SurvivalUI_GUI:Show();
		else
			if(ATSW) then
				ATSWFrame:SetAlpha(1);
				ATSWFrame:SetScale(1);
			else
				if(SurvivalUI_Tradeskill_MovedAway) then
					point, _, _, xOfs, yOfs = TradeSkillFrame:GetPoint();
					TradeSkillFrame:SetPoint(point, TradeSkillFrame:GetParent(), xOfs+9999, yOfs);
					SurvivalUI_Tradeskill_MovedAway = false;	
				end
				TradeSkillFrame:SetAlpha(1);
			end
			SurvivalUI_GUI:Hide();
		end
		
	elseif((event=="TRADE_SKILL_UPDATE" 
			or event=="BAG_UPDATE"
			or event == "SPELL_UPDATE_USABLE"
			or event == "SPELLCAST_STOP") 
			and SurvivalUI_Ready
			and SurvivalUI_GUI:IsShown()) then	
				SurvivalUI_UI_Update_List();
		
	elseif(event=="TRADE_SKILL_CLOSE") then	
		SurvivalUI_GUI:Hide();
		if(TradeSkillFrame ~= nil) then
			if(SurvivalUI_Tradeskill_MovedAway) then
				point, _, _, xOfs, yOfs = TradeSkillFrame:GetPoint();
				TradeSkillFrame:SetPoint(point, TradeSkillFrame:GetParent(), xOfs+9999, yOfs);
				SurvivalUI_Tradeskill_MovedAway = false;	
			end
			TradeSkillFrame:SetAlpha(1);
		end
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
			SurvivalUI_GUI:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", 0, 0)
		else 
			DEFAULT_CHAT_FRAME:AddMessage("You need to give it a number to scale by.");
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("To reset the SurivalUI to it's default position/scale:\n   /svui reset");
		DEFAULT_CHAT_FRAME:AddMessage("Set the scale of the ui, use:\n   /svui scale X\n   NOTE: This is done multiplicatively, such as a 150% scale is scale 1.5\n              I wouldn't recommend going past a scale of 5.");
	end
end

--Functionality
--magic numbers are funne :^)
--well not really but there isnt a point to making these assigns their own function since they're all specific to the texture that I had to painstakenly assign specific cutoffs to
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
	closeButton:SetWidth(17);
	closeButton:SetHeight(17);
	closeButton:SetScript("OnClick", function()
		this:GetParent():Hide()
		TradeSkillFrame:Hide();
	end)
	
	--Lock/Unlock
	local lockButtonBGFrame = CreateFrame("Frame", "SVOptionsFrameUnlockButtonBG", SurvivalUI_GUI)
	lockButtonBGFrame:SetPoint("TOPRIGHT", SurvivalUI_GUI, -8.9, -1.3)
	lockButtonBGFrame:SetWidth(16);
	lockButtonBGFrame:SetHeight(16);

	local lockButtonBG = SurvivalUI_GUI:CreateTexture(nil, "ARTWORK");
	lockButtonBG:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\lockbutton-border");
	lockButtonBG:SetAllPoints(lockButtonBGFrame);
		
	--Initial Lock Button Textures
	local lockUpButtonTex = SurvivalUI_GUI:CreateTexture(nil, "ARTWORK");
	lockUpButtonTex:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\lockbutton-locked-up");
	
	local lockDownButtonTex = SurvivalUI_GUI:CreateTexture(nil, "ARTWORK");
	lockDownButtonTex:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\lockbutton-locked-down");

	local lockButton = CreateFrame("Button", "SVOptionsFramelockButton", SurvivalUI_GUI, "UIPanelButtonTemplate")
	lockButton:SetPoint("TOPRIGHT", SurvivalUI_GUI, -9, -1.7)
	lockButton:SetWidth(16);
	lockButton:SetHeight(16);
	lockButton:SetNormalTexture(lockUpButtonTex);
	lockButton:SetPushedTexture(lockDownButtonTex);
	
	lockButton:SetScript("OnClick", function()
		if(SurvivalUI_IsRearrangeUnlocked) then
			this:SetNormalTexture("Interface\\AddOns\\SurvivalUI\\assets\\lockbutton-locked-up");
			this:SetPushedTexture("Interface\\AddOns\\SurvivalUI\\assets\\lockbutton-locked-down");
			SurvivalUI_IsRearrangeUnlocked = false;
			
			for i=1, numSurvivalSkills, 1 do
				SurvivalUI_Craft_Slot_RearrangeButtons[i]["UP"]:Hide();
				SurvivalUI_Craft_Slot_RearrangeButtons[i]["DOWN"]:Hide();
			end	
		else
			this:SetNormalTexture("Interface\\AddOns\\SurvivalUI\\assets\\lockbutton-unlocked-up");
			this:SetPushedTexture("Interface\\AddOns\\SurvivalUI\\assets\\lockbutton-unlocked-down");
			SurvivalUI_IsRearrangeUnlocked = true;
			
			for i=1, numSurvivalSkills, 1 do
				SurvivalUI_Craft_Slot_RearrangeButtons[i]["UP"]:Show();
				SurvivalUI_Craft_Slot_RearrangeButtons[i]["DOWN"]:Show();
			end
		end	
	end)	
	lockUpButtonTex:SetAllPoints(lockButton);
	lockDownButtonTex:SetAllPoints(lockButton);
	
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
	for i=1, numSurvivalSkills, 1 do
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

		--Rearranging Buttons Setup
		SurvivalUI_Craft_Slot_RearrangeButtons[i] = {};
		SurvivalUI_Craft_Slot_RearrangeButtons[i]["UP"] = CreateFrame("Button", "SVRearrangeButtonUP_"..i, SurvivalUI_Craft_Slots[i]["FRAME"]);
		SurvivalUI_Craft_Slot_RearrangeButtons[i]["UP"]:SetNormalTexture("Interface\\AddOns\\SurvivalUI\\assets\\up-arrow-up");
		SurvivalUI_Craft_Slot_RearrangeButtons[i]["UP"]:SetPushedTexture("Interface\\AddOns\\SurvivalUI\\assets\\up-arrow-down");
		SurvivalUI_Craft_Slot_RearrangeButtons[i]["UP"]:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
		
		SurvivalUI_Craft_Slot_RearrangeButtons[i]["UP"]:SetPoint("RIGHT", SurvivalUI_Craft_Slots[i]["FRAME"], 15.5, 6)
		SurvivalUI_Craft_Slot_RearrangeButtons[i]["UP"]:SetWidth(16);
		SurvivalUI_Craft_Slot_RearrangeButtons[i]["UP"]:SetHeight(16);
		
		SurvivalUI_Craft_Slot_RearrangeButtons[i]["UP"]:Hide();
		if(debug) then
			local upButtonBackground = SurvivalUI_Craft_Slot_RearrangeButtons[i]["UP"]:CreateTexture(nil, "OVERLAY");
			upButtonBackground:SetAllPoints(SurvivalUI_Craft_Slot_RearrangeButtons[i]["UP"]);
			upButtonBackground:SetTexture(0.1, 0.3, 0.4, 0.5);
			
			SurvivalUI_Craft_Slot_RearrangeButtons[i]["UP"]:Show();
		end	
		
		SurvivalUI_Craft_Slot_RearrangeButtons[i]["DOWN"] = CreateFrame("Button", "SVRearrangeButtonDOWN_"..i, SurvivalUI_Craft_Slots[i]["FRAME"]);
		SurvivalUI_Craft_Slot_RearrangeButtons[i]["DOWN"]:SetNormalTexture("Interface\\AddOns\\SurvivalUI\\assets\\down-arrow-up");
		SurvivalUI_Craft_Slot_RearrangeButtons[i]["DOWN"]:SetPushedTexture("Interface\\AddOns\\SurvivalUI\\assets\\down-arrow-down");
		SurvivalUI_Craft_Slot_RearrangeButtons[i]["DOWN"]:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
		SurvivalUI_Craft_Slot_RearrangeButtons[i]["DOWN"]:SetPoint("RIGHT", SurvivalUI_Craft_Slots[i]["FRAME"], 15.5, -8)
		SurvivalUI_Craft_Slot_RearrangeButtons[i]["DOWN"]:SetWidth(16);
		SurvivalUI_Craft_Slot_RearrangeButtons[i]["DOWN"]:SetHeight(16);
		
		SurvivalUI_Craft_Slot_RearrangeButtons[i]["DOWN"]:Hide();
		if(debug) then
			local downButtonBackground = SurvivalUI_Craft_Slot_RearrangeButtons[i]["DOWN"]:CreateTexture(nil, "OVERLAY");
			downButtonBackground:SetAllPoints(SurvivalUI_Craft_Slot_RearrangeButtons[i]["DOWN"]);
			downButtonBackground:SetTexture(0.1, 0.3, 0.4, 0.5);
			
			SurvivalUI_Craft_Slot_RearrangeButtons[i]["DOWN"]:Show();
		end	
	
		--Rearranging buttons handling
		local currPos = i;
			SurvivalUI_Craft_Slot_RearrangeButtons[i]["UP"]:SetScript("OnMouseUp", 
			function()		
				if(currPos-1 ~= 0) then
					local tmpSVSkillLink = survivalSkills[currPos];
					survivalSkills[currPos] = survivalSkills[currPos-1];
					survivalSkills[currPos-1] = tmpSVSkillLink;
					
					local tmpSVSaveLink = SV_UI_ORDER[currPos];
					SV_UI_ORDER[currPos] = SV_UI_ORDER[currPos-1];
					SV_UI_ORDER[currPos-1] = tmpSVSaveLink;
					
					--Rehide the reagents and craft counts to avoid persisting visual
					--Side effect of this approach is debug showing for them vanishes but who cares
					for j=1, numSurvivalSkills do
						for k=1, 4 do
							SurvivalUI_Craft_Slot_Reagents[j][k]["FRAME"]:Hide();
							SurvivalUI_Craft_Slot_Reagents[j][k]["TEXTURE"]:SetVertexColor(1, 1, 1);
							
							SurvivalUI_Craft_Slot_MultiCraft[j]["UP"]:Hide();
							SurvivalUI_Craft_Slot_MultiCraft[j]["DOWN"]:Hide();
							SurvivalUI_Craft_Slot_MultiCraft[j]["CRAFTNUM"]:Hide();	
						end
					end
				else --wrap around
					local tmpSVSkillLink = survivalSkills[currPos];
					survivalSkills[currPos] = survivalSkills[numSurvivalSkills];
					survivalSkills[numSurvivalSkills] = tmpSVSkillLink;
					
					local tmpSVSaveLink = SV_UI_ORDER[currPos];
					SV_UI_ORDER[currPos] = SV_UI_ORDER[numSurvivalSkills];
					SV_UI_ORDER[numSurvivalSkills] = tmpSVSaveLink;
					
					--Rehide the reagents and craft counts to avoid persisting visual
					--Side effect of this approach is debug showing for them vanishes but who cares
					for j=1, numSurvivalSkills do
						for k=1, 4 do
							SurvivalUI_Craft_Slot_Reagents[j][k]["FRAME"]:Hide();
							SurvivalUI_Craft_Slot_Reagents[j][k]["TEXTURE"]:SetVertexColor(1, 1, 1);
							
							SurvivalUI_Craft_Slot_MultiCraft[j]["UP"]:Hide();
							SurvivalUI_Craft_Slot_MultiCraft[j]["DOWN"]:Hide();
							SurvivalUI_Craft_Slot_MultiCraft[j]["CRAFTNUM"]:Hide();	
						end
					end
				end
				SurvivalUI_UI_Update_List();
			end)
			
			SurvivalUI_Craft_Slot_RearrangeButtons[i]["DOWN"]:SetScript("OnMouseUp", 
			function()
				_, _, _, xOfs, yOfs = this:GetPoint();
				this:SetPoint("RIGHT", this:GetParent(), xOfs-0.3, yOfs+0.3);
				
				if(currPos+1 ~= numSurvivalSkills+1) then
					local tmpSVSkillLink = survivalSkills[currPos];
					survivalSkills[currPos] = survivalSkills[currPos+1];
					survivalSkills[currPos+1] = tmpSVSkillLink;
					
					local tmpSVSaveLink = SV_UI_ORDER[currPos];
					SV_UI_ORDER[currPos] = SV_UI_ORDER[currPos+1];
					SV_UI_ORDER[currPos+1] = tmpSVSaveLink;
					
					--Rehide the reagents to avoid persisting visual
					--Side effect of this approach is debug showing for them vanishes but who cares
					for j=1, numSurvivalSkills do
						for k=1, 4 do
							SurvivalUI_Craft_Slot_Reagents[j][k]["FRAME"]:Hide();
							SurvivalUI_Craft_Slot_Reagents[j][k]["TEXTURE"]:SetVertexColor(1, 1, 1);
							
							SurvivalUI_Craft_Slot_MultiCraft[j]["UP"]:Hide();
							SurvivalUI_Craft_Slot_MultiCraft[j]["DOWN"]:Hide();
							SurvivalUI_Craft_Slot_MultiCraft[j]["CRAFTNUM"]:Hide();	
						end
					end
				else --wrap around
					local tmpSVSkillLink = survivalSkills[currPos];
					survivalSkills[currPos] = survivalSkills[1];
					survivalSkills[1] = tmpSVSkillLink;
					
					local tmpSVSaveLink = SV_UI_ORDER[currPos];
					SV_UI_ORDER[currPos] = SV_UI_ORDER[1];
					SV_UI_ORDER[1] = tmpSVSaveLink;
					
					--Rehide the reagents to avoid persisting visual
					--Side effect of this approach is debug showing for them vanishes but who cares
					for j=1, numSurvivalSkills do
						for k=1, 4 do
							SurvivalUI_Craft_Slot_Reagents[j][k]["FRAME"]:Hide();
							SurvivalUI_Craft_Slot_Reagents[j][k]["TEXTURE"]:SetVertexColor(1, 1, 1);
							
							SurvivalUI_Craft_Slot_MultiCraft[j]["UP"]:Hide();
							SurvivalUI_Craft_Slot_MultiCraft[j]["DOWN"]:Hide();
							SurvivalUI_Craft_Slot_MultiCraft[j]["CRAFTNUM"]:Hide();	
						end
					end
				end
				SurvivalUI_UI_Update_List();
			end)

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
		local skillNameFrame = CreateFrame("Button", "SurvivalUI_Craft_Slot_Names_"..i, SurvivalUI_GUI);
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
		
		--Multi craft option for crafting stuff that would warrant it (atm just dim torch)
		SurvivalUI_Craft_Slot_MultiCraft[i] = {};
		SurvivalUI_Craft_Slot_MultiCraft[i]["UP"] = CreateFrame("Button", "SurvivalUI_Craft_Slot_MultiCraft_Up_"..i, SurvivalUI_Craft_Slots[i]["FRAME"]);
		SurvivalUI_Craft_Slot_MultiCraft[i]["UP"]:SetHeight(10);
		SurvivalUI_Craft_Slot_MultiCraft[i]["UP"]:SetWidth(10);
		SurvivalUI_Craft_Slot_MultiCraft[i]["UP"]:SetNormalTexture("Interface\\AddOns\\SurvivalUI\\assets\\up-arrow-up");
		SurvivalUI_Craft_Slot_MultiCraft[i]["UP"]:SetPushedTexture("Interface\\AddOns\\SurvivalUI\\assets\\up-arrow-down");
		SurvivalUI_Craft_Slot_MultiCraft[i]["UP"]:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
		SurvivalUI_Craft_Slot_MultiCraft[i]["UP"]:SetPoint("TOPLEFT", SurvivalUI_Craft_Slots[i]["FRAME"], "TOPLEFT", 29.1, -0.2);
		local currCraftSlot = i;
		SurvivalUI_Craft_Slot_MultiCraft[i]["UP"]:SetScript("OnClick", 
		function()
			for j=1, numSurvivalSkills, 1 do
				SurvivalUI_Craft_Slot_MultiCraft[j]["CRAFTNUM"]:ClearFocus();
			end
			
			local currCount = SurvivalUI_Craft_Slot_MultiCraft[currCraftSlot]["CRAFTNUM"]:GetNumber();
			SurvivalUI_Craft_Slot_MultiCraft[currCraftSlot]["CRAFTNUM"]:SetNumber(currCount+1);
		end);
		SurvivalUI_Craft_Slot_MultiCraft[i]["UP"]:Enable();
		SurvivalUI_Craft_Slot_MultiCraft[i]["UP"]:Hide();
		
		SurvivalUI_Craft_Slot_MultiCraft[i]["DOWN"] = CreateFrame("Button", "SurvivalUI_Craft_Slot_MultiCraft_Down_"..i, SurvivalUI_Craft_Slots[i]["FRAME"]);
		SurvivalUI_Craft_Slot_MultiCraft[i]["DOWN"]:SetHeight(10);
		SurvivalUI_Craft_Slot_MultiCraft[i]["DOWN"]:SetWidth(10);
		SurvivalUI_Craft_Slot_MultiCraft[i]["DOWN"]:SetNormalTexture("Interface\\AddOns\\SurvivalUI\\assets\\down-arrow-up");
		SurvivalUI_Craft_Slot_MultiCraft[i]["DOWN"]:SetPushedTexture("Interface\\AddOns\\SurvivalUI\\assets\\down-arrow-down");
		SurvivalUI_Craft_Slot_MultiCraft[i]["DOWN"]:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
		SurvivalUI_Craft_Slot_MultiCraft[i]["DOWN"]:SetPoint("TOPLEFT", SurvivalUI_Craft_Slots[i]["FRAME"], "TOPLEFT", 29.1, -17.2);
		SurvivalUI_Craft_Slot_MultiCraft[i]["DOWN"]:SetScript("OnClick", 
		function()
			for j=1, numSurvivalSkills, 1 do
				SurvivalUI_Craft_Slot_MultiCraft[j]["CRAFTNUM"]:ClearFocus();
			end
			
			local currCount = SurvivalUI_Craft_Slot_MultiCraft[currCraftSlot]["CRAFTNUM"]:GetNumber();
			if(currCount-1 > 0) then
				SurvivalUI_Craft_Slot_MultiCraft[currCraftSlot]["CRAFTNUM"]:SetNumber(currCount-1);
			end
		end);
		SurvivalUI_Craft_Slot_MultiCraft[i]["DOWN"]:Enable();
		SurvivalUI_Craft_Slot_MultiCraft[i]["DOWN"]:Hide();
		
		SurvivalUI_Craft_Slot_MultiCraft[i]["CRAFTNUM"] = CreateFrame("EditBox", "SurvivalUI_Craft_Slot_MultiCraft_CraftNum_", SurvivalUI_Craft_Slots[i]["FRAME"])
		SurvivalUI_Craft_Slot_MultiCraft[i]["CRAFTNUM"]:SetScale(1);
		SurvivalUI_Craft_Slot_MultiCraft[i]["CRAFTNUM"]:SetFont("Fonts\\FRIZQT__.TTF", 5.5)
		SurvivalUI_Craft_Slot_MultiCraft[i]["CRAFTNUM"]:SetHeight(14)
		SurvivalUI_Craft_Slot_MultiCraft[i]["CRAFTNUM"]:SetWidth(10)
		SurvivalUI_Craft_Slot_MultiCraft[i]["CRAFTNUM"]:SetPoint("TOPLEFT", SurvivalUI_Craft_Slots[i]["FRAME"], "TOPLEFT", 29.1, -6.5);
		SurvivalUI_Craft_Slot_MultiCraft[i]["CRAFTNUM"]:SetJustifyH("CENTER");
		SurvivalUI_Craft_Slot_MultiCraft[i]["CRAFTNUM"]:SetNumber(1);
		SurvivalUI_Craft_Slot_MultiCraft[i]["CRAFTNUM"]:SetNumeric(true);
		SurvivalUI_Craft_Slot_MultiCraft[i]["CRAFTNUM"]:SetMaxLetters(2);
		SurvivalUI_Craft_Slot_MultiCraft[i]["CRAFTNUM"]:SetAutoFocus(false);
		
		local craftNumBGFrame = CreateFrame("Frame", "CraftNumBG_"..i, SurvivalUI_Craft_Slot_MultiCraft[i]["CRAFTNUM"])
		craftNumBGFrame:SetPoint("TOPLEFT", SurvivalUI_Craft_Slots[i]["FRAME"], "TOPLEFT", 27.4, -6.8);
		craftNumBGFrame:SetWidth(14);
		craftNumBGFrame:SetHeight(14);
		
		local craftNumBG = SurvivalUI_Craft_Slot_MultiCraft[i]["CRAFTNUM"]:CreateTexture(nil, "ARTWORK");
		craftNumBG:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\lockbutton-border");
		craftNumBG:SetAllPoints(craftNumBGFrame);
		craftNumBGFrame:Show();
		
		SurvivalUI_Craft_Slot_MultiCraft[i]["CRAFTNUM"]:Hide();
		
		SurvivalUI_Craft_Slots[i]["FRAME"]:Hide();		

		if(debug) then
			SurvivalUI_Craft_Slots[i]["FRAME"]:CreateTexture(nil, "OVERLAY");
			local craftBackground = SurvivalUI_Craft_Slots[i]["FRAME"]:CreateTexture(nil, "OVERLAY");
			craftBackground:SetAllPoints(SurvivalUI_Craft_Slots[i]["FRAME"]);
			craftBackground:SetTexture(0.1, 0.3, 0.4, 0.5);
			
			SurvivalUI_Craft_Slots[i]["FRAME"]:Show();

			
			SurvivalUI_Craft_Slot_Names[i]["NAME"]:Show();
			SurvivalUI_Craft_Slot_Names[i]["COOLDOWN"]:Show();
			SurvivalUI_Craft_Slot_MultiCraft[i]["UP"]:Show();
			SurvivalUI_Craft_Slot_MultiCraft[i]["DOWN"]:Show();
			SurvivalUI_Craft_Slot_MultiCraft[i]["CRAFTNUM"]:Show();
		end	
		
		--Loaded ordering setup 
		if(survivalSkills[i]["NAME"] ~= SV_UI_ORDER[i]) then			
			for j=1, numSurvivalSkills, 1 do
				if(survivalSkills[j]["NAME"] == SV_UI_ORDER[i]) then
					local tmpSVSkillLink = survivalSkills[i];
					
					survivalSkills[i] = survivalSkills[j];
					survivalSkills[j] = tmpSVSkillLink;
					if(debug) then
						DEFAULT_CHAT_FRAME:AddMessage("Swapping position of "..survivalSkills[i]["NAME"].." and "..survivalSkills[j]["NAME"]);
					end
					break;
				end
			end
		end
		
	end
	SurvivalUI_GUI:Hide();
end

--Part where it checks your skill level and what you know, and makes adjustments
function SurvivalUI_UI_Update_List() 
	local skillOffset = FauxScrollFrame_GetOffset(TradeSkillListScrollFrame);	
	local skillIndexCheck = 1 + skillOffset; 
	--Populate the skill index before making the buttons
	--Done to avoid any issue where the next loop and the index would be misaligned by rearranging the rows
	for i=1, numSurvivalSkills, 1 do
		if(survivalSkills[i]["TYPE"] == "TRADESKILL") then
			local skillName, _, _, _ = GetTradeSkillInfo(skillIndexCheck);
			for j=1, numSurvivalSkills, 1 do
				if(survivalSkills[j]["NAME"] == skillName) then
					survivalSkills[j]["SKILLINDEX"] = skillIndexCheck;
					if(debug) then
						DEFAULT_CHAT_FRAME:AddMessage("SKILLINDEX assigned for "..survivalSkills[j]["NAME"].." is "..skillIndexCheck);
					end
				end
			end	
			skillIndexCheck = skillIndexCheck + 1;
		end
	end

	for i=1, numSurvivalSkills, 1 do	
		if(survivalSkills[i]["TYPE"] == "TRADESKILL" and survivalSkills[i]["SKILLINDEX"] ~= nil) then 
			local skillIndex = survivalSkills[i]["SKILLINDEX"];
			local skillName, skillType, numAvailable, _ = GetTradeSkillInfo(skillIndex);
			if(skillName ~= nil) then 
				SurvivalUI_Craft_Slots[i]["FRAME"]:Show();
				SurvivalUI_Craft_Slots[i]["FRAME"]:Enable();
				
				--Click handling
				local multiCraftCheck = survivalSkills[i]["MULTI"];
				if(debug) then
					if(multiCraftCheck) then
						DEFAULT_CHAT_FRAME:AddMessage("MULTI assigned for "..skillName.." is true");
					end
				end
				if(multiCraftCheck) then
					SurvivalUI_Craft_Slot_MultiCraft[i]["CRAFTNUM"]:Show();
					SurvivalUI_Craft_Slot_MultiCraft[i]["UP"]:Show();
					SurvivalUI_Craft_Slot_MultiCraft[i]["DOWN"]:Show();
				end
				
				local multiCraftPos = i;
				SurvivalUI_Craft_Slots[i]["FRAME"]:SetScript("OnClick", 
				function()
					for j=1, numSurvivalSkills, 1 do
						SurvivalUI_Craft_Slot_MultiCraft[j]["CRAFTNUM"]:ClearFocus();
					end
					if (multiCraftCheck) then
						DoTradeSkill(skillIndex, SurvivalUI_Craft_Slot_MultiCraft[multiCraftPos]["CRAFTNUM"]:GetNumber());
					else
						DoTradeSkill(skillIndex, 1);
					end
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
				elseif (skillName == "Traveler's Tent") then --Bodge fix for currently missing icons for both of these as of writing. Im just using war3 icons as a sub
					SurvivalUI_Craft_Slot_Icons[i]["TEXTURE"]:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\tent-icon");
				elseif (skillName == "Fishing Boat") then
					SurvivalUI_Craft_Slot_Icons[i]["TEXTURE"]:SetTexture("Interface\\AddOns\\SurvivalUI\\assets\\boat-icon");
				end
				
				local skillIndexInternal = skillIndex; 
				SurvivalUI_Craft_Slot_Icons[i]["FRAME"]:SetScript("OnEnter", function()
					GameTooltip:ClearLines();
					GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
					
					--bodge fix until they add tooltips for these
					if (skillName == "Traveler's Tent") then
						GameTooltip:AddLine("Traveler's Tent", 1, 1, 1, 1);
						GameTooltip:AddLine("Builds a tent that provides rested\nexperience to anyone in it's range.");
					elseif (skillName == "Fishing Boat") then
						GameTooltip:AddLine("Fishing Boat", 1, 1, 1, 1);
						GameTooltip:AddLine("Builds fishing boat, for fishing on.\nProvides +50 to your fishing skill.");
					else
						GameTooltip:SetTradeSkillItem(skillIndexInternal);
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

		--Spell handling (aka the only the campfire atm)
		elseif (survivalSkills[i]["TYPE"] == "SPELL") then
			local spellName = survivalSkills[i]["NAME"];	
			
			SurvivalUI_Craft_Slots[i]["FRAME"]:Show();
			SurvivalUI_Craft_Slots[i]["FRAME"]:Enable();
			
			--Click handling
			SurvivalUI_Craft_Slots[i]["FRAME"]:SetScript("OnClick", 
			function()
				if(debug) then
					DEFAULT_CHAT_FRAME:AddMessage("Click handling called for "..spellName);
				end
				CastSpellByName(spellName);
			end)
			
			spellID = SurvivalUI_GetSpellID(survivalSkills[i]["NAME"]);
			
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
			SurvivalUI_Craft_Slot_Names[i]["NAME"]:SetText(survivalSkills[i]["NAME"]);
			SurvivalUI_Craft_Slot_Names[i]["NAME"]:Show();
			
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
			
			for j=1, 4, 1 do
				if (survivalSkills[i]["REAGENTS"][j] ~= nil) then	
					local reagentName = survivalSkills[i]["REAGENTS"][j];
					local reagentID = survivalReagents[survivalSkills[i]["REAGENTS"][j]];
					
					local reagentCount=1 --fixed at 1 unless something changes
					local playerReagentCount = SurivalUI_CheckBags(reagentName);
					
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
					if(playerReagentCount < reagentCount) then
						SurvivalUI_Craft_Slots[i]["FRAME"]:Disable();
						SurvivalUI_Craft_Slot_Reagents[i][j]["TEXTURE"]:SetVertexColor(0.5, 0.5, 0.5);
					else
						SurvivalUI_Craft_Slot_Reagents[i][j]["TEXTURE"]:SetVertexColor(1, 1, 1);
					end
					
					SurvivalUI_Craft_Slot_Reagents[i][j]["FRAME"]:Show();
					SurvivalUI_Craft_Slot_Reagents[i][j]["TEXTURE"]:Show();
									
					SurvivalUI_Craft_Slot_Reagents[i][j]["COUNT"]:Show();
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

	for i=1, numSurvivalSkills, 1 do
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

function SurivalUI_CheckBags(item)
	local totalCount = 0;
	for bagID=0, 4, 1 do
		local slots = GetContainerNumSlots(bagID);
		if (slots ~= nil) then
			for slot=1, slots, 1 do
				local _, itemCount, _, _ = GetContainerItemInfo(bagID, slot);
				local itemLink = GetContainerItemLink(bagID, slot);
				
				if(itemLink~= nil and strfind(itemLink, item)) then
					totalCount = totalCount + itemCount;
					if(debug) then 
						DEFAULT_CHAT_FRAME:AddMessage("Found "..item.. " in bag "..bagID.. " and slot "..slot);
					end
				end
			end
		end
	end
	return totalCount;
end
