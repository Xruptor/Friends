KillAlert = KillAlert or {};
--Updated by Xruptor
--NOTE this addon is a heavily inspired and modified version of Caffeine's Friends addon from VinyUI.
--I have renamed it to KillAlert as I felt that Friends didn't really capture the overall essence of the addon and made it confusing in regards to the social aspect of friends.

--NOTE: This is a fork of Friends by Caffeine.  I have spoken to Caffeine and the author has given a nod and a thumbs up to go ahead with this fork.

local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local towstring = towstring
local tinsert = table.insert

local TextLogGetEntry = TextLogGetEntry
local TextLogGetNumEntries = TextLogGetNumEntries
local CreateHyperLink = CreateHyperLink

local ORDER_COLOR = {0,205,255};
local DESTR_COLOR = {255,25,25};
local LOCATION_COLOR = {169,169,169};
local WEAPONUSED_COLOR = {255, 165, 0};

local SelfName;
local localization;

local TIME_DELAY = 6 -- seconds untill kill announcement fades away
local timeUntillFadeOut;

local TIME_DELAY_KBM = 8 -- seconds untill kill announcement fades away
local timeUntillFadeOutKilledByMe;

KillAlert.sessionUnknownList = {};
KillAlert.combatListIndex = 0;
KillAlert.combatListOrder = {};
KillAlert.combatListAbilityName = {};

local function Print(str)
    EA_ChatWindow.Print(towstring(str));
end

local function FixString(str)
	if (str == nil) then return nil end	
	local str = str;
	local pos = str:find (L"^", 1, true);
	if (pos) then str = str:sub (1, pos - 1) end	
	pos = str:find (L" ", 1, true);
	if (pos) then str = str:sub (1, pos - 1) end	
	return str;
end

--SimpleFixString does not remove the spaces, and does not cut off at first space found
function SimpleFixString (str)
	if (str == nil) then return nil end
	local str = str
	local pos = str:find (L"^", 1, true)
	if (pos) then str = str:sub (1, pos - 1) end
	return str
end

local function IsInGroup()
	return (GetNumGroupmates() > 0)
end

local function GetIconByAbilityName(abilityName)
	if not abilityName then return nil end

	--if type(abilityName) == "wstring" then
	local origAbilityName = SimpleFixString(abilityName):lower()
	abilityName = towstring(abilityName):lower()

	--first check to see if we grabbed it already from combatlog parser
	if KillAlert.combatListAbilityName[abilityName] or KillAlert.combatListAbilityName[origAbilityName] then
		--d("we got it from combat parser")
		return KillAlert.combatListAbilityName[abilityName] or KillAlert.combatListAbilityName[origAbilityName];
	end
	
	--second check to see if we already have it stored, that way we don't have to go through the loop
	if KillAlert.IconList[abilityName] or KillAlert.IconList[origAbilityName] then
		--d("we got it stored")
		return KillAlert.IconList[abilityName] or KillAlert.IconList[origAbilityName] ;
	end
	
	--lastly, check the current session list and see if it was already parsed
	if KillAlert.sessionUnknownList[abilityName] then
		--d("we got it from session list")
		--it's already been parsed so if we didn't have an icon for it then it's "icon000000"
		return nil
	end
	
	--check to see if it's a weapon kill instead of an abilityName
	local rightHand = SimpleFixString(CharacterWindow.equipmentData[GameData.EquipSlots.RIGHT_HAND].name):lower()
	local leftHand = SimpleFixString(CharacterWindow.equipmentData[GameData.EquipSlots.LEFT_HAND].name):lower()
	local rangedSlot = SimpleFixString(CharacterWindow.equipmentData[GameData.EquipSlots.RANGED].name):lower()
	
	--first check
	if (abilityName == rightHand or abilityName == towstring(rightHand) or origAbilityName == rightHand or towstring(origAbilityName) == towstring(rightHand)) then return nil end
	if (abilityName == leftHand or abilityName == towstring(leftHand) or origAbilityName == leftHand or towstring(origAbilityName) == towstring(leftHand)) then return nil end
	if (abilityName == rangedSlot or abilityName == towstring(rangedSlot) or origAbilityName == rangedSlot or towstring(origAbilityName) == towstring(rangedSlot)) then return nil end
	
	--for some reason sometimes an empty space is added to the end of the strings, so they don't compare properly
	if rightHand then rightHand = (rightHand):sub(1, (rightHand):len() - 1)	end
	if leftHand then leftHand = (leftHand):sub(1, (leftHand):len() - 1)	end
	if rangedSlot then rangedSlot = (rangedSlot):sub(1, (rangedSlot):len() - 1)	end
	
	--second check
	if (abilityName == rightHand or abilityName == towstring(rightHand) or origAbilityName == rightHand or towstring(origAbilityName) == towstring(rightHand)) then return nil end
	if (abilityName == leftHand or abilityName == towstring(leftHand) or origAbilityName == leftHand or towstring(origAbilityName) == towstring(leftHand)) then return nil end
	if (abilityName == rangedSlot or abilityName == towstring(rangedSlot) or origAbilityName == rangedSlot or towstring(origAbilityName) == towstring(rangedSlot)) then return nil end
	
	--it's probably a weapon attack or something I completely missed, or a buff that triggers or something lets just store it, to avoid going through loop again
	KillAlert.sessionUnknownList[abilityName] = "icon000000"
	--store it for future processing
	KillAlert.IconList.UnknownAbilityID[abilityName] = "icon000000"

	return nil
end

function KillAlert.init()
	
	localization = KillAlert.Localization.GetMapping()
	
	SelfName = FixString(GameData.Player.name);
	
	if not KillAlert.Settings then KillAlert.Settings = {}; end
	if KillAlert.Settings.groupWeaponKills == nil then KillAlert.Settings.groupWeaponKills = true; end
	if KillAlert.Settings.showLocation == nil then KillAlert.Settings.showLocation = false; end
	if KillAlert.Settings.showAbilityIcons == nil then KillAlert.Settings.showAbilityIcons = true; end
	if KillAlert.Settings.showChatAlerts == nil then KillAlert.Settings.showChatAlerts = true; end
	
	if not KillAlert.IconList then KillAlert.IconList = {}; end
	if not KillAlert.IconList.UnknownAbilityID then KillAlert.IconList.UnknownAbilityID = {}; end
	
	--reset, icon list for the session
	KillAlert.sessionUnknownList = {}
	
	CreateWindow("KillAlertKilledBy", true);
	LayoutEditor.RegisterWindow("KillAlertKilledBy", L"KillAlert 'Killed by'", L"KillAlert 'killed by' window", true, true, true, nil);
	WindowSetShowing ("KillAlertKilledBy", true);
	
	CreateWindow("KillAlertKilledByMe", true);
	LayoutEditor.RegisterWindow("KillAlertKilledByMe", L"KillAlert 'Killed by Me'", L"KillAlert 'killed by Me' window", true, true, true, nil);
	WindowSetShowing ("KillAlertKilledByMe", true);
	
	RegisterEventHandler(TextLogGetUpdateEventId("Combat"), "KillAlert.OnChatLogUpdated");
	RegisterEventHandler(SystemData.Events.LOADING_END, "KillAlert.ClearAllKillWindows");
	
	RegisterEventHandler(SystemData.Events.WORLD_OBJ_COMBAT_EVENT, "KillAlert.OnCombatEvent")
	KillAlert.parseUnknownsAbilities()
	
	if LibSlash then
		LibSlash.RegisterSlashCmd("killalert", function(args) KillAlert.SlashCmd(args) end)
		Print(localization.ADDON_INIT_1);
	else
		Print(localization.ADDON_INIT_2);
	end
	
end

function KillAlert.SlashCmd(args)

	local command;
	local parameter;
	local separator = string.find(args," ");
	
	if separator then
		command = string.sub(args, 0, separator-1);
		parameter = string.sub(args, separator+1, -1);
	else
		command = string.sub(args, 0, separator);
	end

    if command == "groupweaponkills" then
		if KillAlert.Settings.groupWeaponKills then
			KillAlert.Settings.groupWeaponKills = false
			Print("[KillAlert] groupweaponkills - "..localization.OFF)
		else
			KillAlert.Settings.groupWeaponKills = true
			Print("[KillAlert] groupweaponkills - "..localization.ON)
		end
    elseif command == "showlocation" then
		if KillAlert.Settings.showLocation then
			KillAlert.Settings.showLocation = false
			Print("[KillAlert] showlocation - "..localization.OFF)
		else
			KillAlert.Settings.showLocation = true
			Print("[KillAlert] showlocation - "..localization.ON)
		end
    elseif command == "showabilityicons" then
		if KillAlert.Settings.showAbilityIcons then
			KillAlert.Settings.showAbilityIcons = false
			Print("[KillAlert] showabilityicons - "..localization.OFF)
		else
			KillAlert.Settings.showAbilityIcons = true
			Print("[KillAlert] showabilityicons - "..localization.ON)
		end
    elseif command == "showchatalerts" then
		if KillAlert.Settings.showChatAlerts then
			KillAlert.Settings.showChatAlerts = false
			Print("[KillAlert] showchatalerts - "..localization.OFF)
		else
			KillAlert.Settings.showChatAlerts = true
			Print("[KillAlert] showchatalerts - "..localization.ON)
		end
	else
		Print(localization.SlashCommandsList);
		Print(localization.SlashCommandsList1);
		Print(localization.SlashCommandsList2);
		Print(localization.SlashCommandsList3);
		Print(localization.SlashCommandsList4);
	end

end

--lets do a entire ability DB check for unknown abilities, we really only want to do this once during login
function KillAlert.parseUnknownsAbilities()

	for id = 1, 100000
	do
		if GetAbilityName(id) and GetAbilityData(id) and (GetAbilityName(id)):len() > 0 then

			local data = GetAbilityData(id)
			local iconTexture, x, y = GetIconData(data.iconNum)
			
			if iconTexture and iconTexture ~= "icon000000" and iconTexture ~= "icon-00001" and iconTexture ~= "icon-00002"  then

				local firstCheck = SimpleFixString(GetAbilityName(id)):lower()
				local secondCheck = FixString(GetAbilityName(id)):lower()

				if KillAlert.IconList.UnknownAbilityID[firstCheck] then
					KillAlert.IconList[firstCheck] = iconTexture
					KillAlert.IconList.UnknownAbilityID[firstCheck] = nil
					
				elseif KillAlert.IconList.UnknownAbilityID[secondCheck] then
					KillAlert.IconList[secondCheck] = iconTexture
					KillAlert.IconList.UnknownAbilityID[secondCheck] = nil
				
				end
				
			end
				
		end
		
	end
	
end

function KillAlert.OnCombatEvent(objectID, amount, combatEvent, abilityID)

	local player, pet, ability, source

	player = (objectID == GameData.Player.worldObjNum)
	pet = (objectID == GameData.Player.Pet.objNum)
	
	if not KillAlert.combatListIndex then KillAlert.combatListIndex = 0 end
	if not KillAlert.combatListOrder then KillAlert.combatListOrder = {} end
	if not KillAlert.combatListAbilityName then KillAlert.combatListAbilityName = {} end
	
	--so if we have player or pet, that's incoming damage of which we don't care about, we care about outgoing
	if not player and not pet and abilityID and abilityID ~= 0 then
		--d("ObjectID: "..objectID.."  Amount: "..amount.."  Event: "..combatEvent.." abilityID: "..abilityID)
		
		local abilityName = GetAbilityName(abilityID)
		local data = GetAbilityData(abilityID)
		local icon = GetIconData(data.iconNum)
		
		if icon == "icon000000" or iconTexture == "icon-00001" or iconTexture == "icon-00002"  then icon = nil end

		if icon and abilityName and (abilityName):len() > 0 then
		
			--gotta remove that ^n from end of string
			abilityName = SimpleFixString(abilityName):lower()
			
			--local debugAbilityName = tostring(abilityName) --convert from wstring to string adds a "^n" to the end of a string, if you don't do SimpleFixString
			--d("abilityName: "..debugAbilityName.."  icon: "..icon)
			
			--first check to see if it's already in the list
			if KillAlert.combatListAbilityName[abilityName] then
				--d(debugAbilityName.." is already in list")
				return nil
			end
			
			--if it's not in the list then lets add it, start by incrementing the index
			KillAlert.combatListIndex = KillAlert.combatListIndex + 1
			
			--if the index is greater than 200 reset it back to 1, so we get rid of the oldest entry first
			if KillAlert.combatListIndex > 200 then KillAlert.combatListIndex = 1 end
			
			--check to see if we already have that entry, if so remove the old entry first, we really only want to keep the last 200 or so abilities last used
			--otherwise this list may grow too big and just consume way too much memory
			if KillAlert.combatListOrder[KillAlert.combatListIndex] then
				KillAlert.combatListAbilityName[KillAlert.combatListOrder[KillAlert.combatListIndex]] = nil --remove the ability by it's name
			end
			
			--now we can add it
			KillAlert.combatListOrder[KillAlert.combatListIndex] = abilityName
			KillAlert.combatListAbilityName[abilityName] = icon
			--d(debugAbilityName.." ++ has been added ==> "..tostring(KillAlert.combatListIndex))
			
			--check if we have it stored as unknown, if so update it so that other classes can refer to it
			if KillAlert.IconList.UnknownAbilityID[abilityName] then
				KillAlert.IconList[abilityName] = icon
				KillAlert.IconList.UnknownAbilityID[abilityName] = nil
			end
			
		end
  
	end

end

function KillAlert.OnUpdate(timeElapsed)
	if timeUntillFadeOut then
		timeUntillFadeOut = timeUntillFadeOut - timeElapsed;
		if (timeUntillFadeOut <= 0) then
			KillAlert.ClearKillWindow();
			timeUntillFadeOut = nil;
		end
	end
	
	if timeUntillFadeOutKilledByMe then
		timeUntillFadeOutKilledByMe = timeUntillFadeOutKilledByMe - timeElapsed;
		if (timeUntillFadeOutKilledByMe <= 0) then
			KillAlert.ClearKilledByMeWindow();
			timeUntillFadeOutKilledByMe = nil;
		end
	end
end

function KillAlert.OnChatLogUpdated(updateType, filterType)

	if (updateType ~= SystemData.TextLogUpdate.ADDED) then return end
	if not (filterType == SystemData.ChatLogFilters.RVR_KILLS_ORDER or filterType == SystemData.ChatLogFilters.RVR_KILLS_DESTRUCTION) then 
		return
	end
	
	local tmpWeaponLeft = towstring(" ( ");
	local tmpWeaponRight = towstring(" )");
    local indexOfLastEntry = TextLogGetNumEntries("Combat") - 1;    
    local _, _, message = TextLogGetEntry("Combat", indexOfLastEntry);
	--d(message)

	local victim, verb, player, weapon, location = KillAlert.CombatMessageParser(message);
	-- <icon876> = party flag icon
	--	L"<icon"..towstring(iconNum)..L">"
	
	--NOTE: To see these alerts in ANY chat window.. just make sure that the SAY filter option is enabled for that tab

	-- someone in my group got a kill
	if LibGroup.GroupMembers.ByName[player]	then

		local killString = L"";
		
		-- my group is playing destruction
		if (GameData.Player.realm == 2) then	
			killString = towstring(CreateHyperLink(L"", player, DESTR_COLOR, {} ));
			killString = killString .. L" killed ";
			killString = killString .. towstring(CreateHyperLink(L"", victim, ORDER_COLOR, {} ));
		-- my group is playing order
		elseif (GameData.Player.realm == 1) then
			killString = towstring(CreateHyperLink(L"", player, ORDER_COLOR, {} ));
			killString = killString .. L" killed ";
			killString = killString .. towstring(CreateHyperLink(L"", victim, DESTR_COLOR, {} ));
		end

		if (player ~= SelfName) then
			if not KillAlert.Settings.groupWeaponKills then
				KillAlert.AnnounceKill(killString);
			else
				KillAlert.AnnounceKill(killString .. towstring(CreateHyperLink(L"", tmpWeaponLeft .. weapon .. tmpWeaponRight, WEAPONUSED_COLOR, {} )) );
			end
		else
			--it was my kill
			local tmpIconTex = towstring("");
			local tmpIconTexIndent = towstring("");
			
			if KillAlert.Settings.showAbilityIcons then
				local iconTex = GetIconByAbilityName(weapon);
				if iconTex then
					--strip everything from front including leading zeros.  Add "icon" afterwards
					iconTex = iconTex:match("0*(%d+)", 1, true)
					if iconTex then
						tmpIconTex = L"<icon"..towstring(iconTex)..L">";
						tmpIconTexIndent = towstring(" ");
					end
				end
			end
			
			--do the regular announce
			KillAlert.AnnounceKill(killString .. towstring(tmpIconTexIndent .. tmpIconTex .. CreateHyperLink(L"", tmpWeaponLeft .. weapon .. tmpWeaponRight, WEAPONUSED_COLOR, {} )) );

			--now do the killed by me announcement
			KillAlert.AnnounceMyKill(killString, towstring(tmpIconTex .. tmpIconTexIndent .. CreateHyperLink(L"", weapon, WEAPONUSED_COLOR, {} )) );
			
			--only play the sound if we don't have Deathblow installed
			if not (Deathblow) then
				PlaySound(215)
			end
		end
		 
		if KillAlert.Settings.showLocation then
			killString = killString .. L" in ";
			killString = killString .. towstring(CreateHyperLink(L"", location, LOCATION_COLOR, {} ));
		end
		
		--my own kills or possibly groups kills with weapons
		if (player == SelfName or KillAlert.Settings.groupWeaponKills) then
			killString = killString .. L" with ";
			killString = killString .. towstring(CreateHyperLink(L"", weapon, WEAPONUSED_COLOR, {} ));	
		end
		
		if KillAlert.Settings.showChatAlerts then
			Print(killString);
		end
		
		return;
	
	-- someone in my group died 
	elseif LibGroup.GroupMembers.ByName[victim] then
		
		-- deaths in warbands (especially pug warbands) can get very spammy
		if ( IsWarBandActive() == true ) then return end

		local killString = L"";
	
		-- my group is playing destruction
		if (GameData.Player.realm == 2) then
			killString = towstring(CreateHyperLink(L"", player, ORDER_COLOR, {} ));
			killString = killString .. L" killed ";
			killString = killString .. towstring(CreateHyperLink(L"", victim, DESTR_COLOR, {} ));
		-- my group is playing order
		elseif (GameData.Player.realm == 1) then
			killString = towstring(CreateHyperLink(L"", player, DESTR_COLOR, {} ));
			killString = killString .. L" killed ";
			killString = killString .. towstring(CreateHyperLink(L"", victim, ORDER_COLOR, {} ));
		end	

		if (victim ~= SelfName) then
			if not KillAlert.Settings.groupWeaponKills then
				KillAlert.AnnounceKill(killString);
			else
				KillAlert.AnnounceKill(killString .. towstring(CreateHyperLink(L"", tmpWeaponLeft .. weapon .. tmpWeaponRight, WEAPONUSED_COLOR, {} )) );
			end
		else
			--it was my death
			KillAlert.AnnounceKill(killString .. towstring(CreateHyperLink(L"", tmpWeaponLeft .. weapon .. tmpWeaponRight, WEAPONUSED_COLOR, {} )) );
		end
		
		if KillAlert.Settings.showLocation then
			killString = killString .. L" in ";
			killString = killString .. towstring(CreateHyperLink(L"", location, LOCATION_COLOR, {} ));
		end
		
		--my own deaths or possibly groups deaths with weapons
		if (victim == SelfName or KillAlert.Settings.groupWeaponKills) then
			killString = killString .. L" with ";
			killString = killString .. towstring(CreateHyperLink(L"", weapon, WEAPONUSED_COLOR, {} ));	
		end
		
		if KillAlert.Settings.showChatAlerts then
			Print(killString);
		end
		
		return;
	
	end
	
end

function KillAlert.AnnounceKill(killString)
	LabelSetText ("KillAlertKilledByText", killString);	
	WindowStopAlphaAnimation ("KillAlertKilledBy");
	WindowStartAlphaAnimation ("KillAlertKilledBy", Window.AnimationType.SINGLE_NO_RESET, 1, 0, 0, true, 0, 1);
	WindowStartAlphaAnimation ("KillAlertKilledBy", Window.AnimationType.SINGLE_NO_RESET, 0, 1, 0.2, true, 0, 1);
	timeUntillFadeOut = TIME_DELAY;
end

function KillAlert.AnnounceMyKill(killString, weapString)
	LabelSetText ("KillAlertKilledByMeText", killString);
	LabelSetText ("KillAlertKilledByMeWeapon", weapString);	
	WindowStopAlphaAnimation ("KillAlertKilledByMe");
	WindowStartAlphaAnimation ("KillAlertKilledByMe", Window.AnimationType.SINGLE_NO_RESET, 1, 0, 0, true, 0, 1);
	WindowStartAlphaAnimation ("KillAlertKilledByMe", Window.AnimationType.SINGLE_NO_RESET, 0, 1, 0.2, true, 0, 1);
	timeUntillFadeOutKilledByMe = TIME_DELAY_KBM;
end

function KillAlert.ClearKillWindow()
	WindowStopAlphaAnimation ("KillAlertKilledBy")
	WindowStartAlphaAnimation ("KillAlertKilledBy", Window.AnimationType.SINGLE_NO_RESET, 1, 1, 0, true, 0, 1)
	WindowStartAlphaAnimation ("KillAlertKilledBy", Window.AnimationType.SINGLE_NO_RESET, 1, 0, 1, true, 0, 1)
end

function KillAlert.ClearKilledByMeWindow()
	WindowStopAlphaAnimation ("KillAlertKilledByMe")
	WindowStartAlphaAnimation ("KillAlertKilledByMe", Window.AnimationType.SINGLE_NO_RESET, 1, 1, 0, true, 0, 1)
	WindowStartAlphaAnimation ("KillAlertKilledByMe", Window.AnimationType.SINGLE_NO_RESET, 1, 0, 1, true, 0, 1)
end

function KillAlert.ClearAllKillWindows()
	KillAlert.ClearKillWindow();
	KillAlert.ClearKilledByMeWindow();
end