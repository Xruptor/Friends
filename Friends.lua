Friends = Friends or {};

local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local towstring = towstring

local TextLogGetEntry = TextLogGetEntry
local TextLogGetNumEntries = TextLogGetNumEntries
local CreateHyperLink = CreateHyperLink

local ORDER_COLOR = {0,205,255};
local DESTR_COLOR = {255,70,70};
local LOCATION_COLOR = {169,169,169};

local localization;

local SelfName;

local TIME_DELAY = 6 -- seconds untill kill announcement fades away
local timeUntillFadeOut;

local function Print(str)
    EA_ChatWindow.Print(towstring(str));
end

local function fixName(name)
	if not name then return nil end
	local pos = name:find (L"^", 1, true);
	if (pos) then name = name:sub (1, pos - 1); end	
	return name;
end

function Friends.init()

	localization = Friends.Localization.GetMapping();
	SelfName = fixName(GameData.Player.name);
	
	-- load settings
	Friends.SavedSettings = Friends.SavedSettings or {};
	Friends.SavedSettings.chatFeedback = Friends.SavedSettings.chatFeedback or false;
	
	CreateWindow("FriendsKilledBy", true);
	LayoutEditor.RegisterWindow("FriendsKilledBy", L"Friends 'Killed by'", L"Friends 'killed by' window", true, true, true, nil);
	WindowSetShowing ("FriendsKilledBy", true);
	
	RegisterEventHandler(TextLogGetUpdateEventId("Combat"), "Friends.OnChatLogUpdated");
	RegisterEventHandler(SystemData.Events.LOADING_END, "Friends.ClearKillWindow");	
	
	if LibSlash then
		LibSlash.RegisterSlashCmd("friends", function(args) Friends.SlashCmd(args) end)
		Print(L"[Friends] Addon initialized. Use '/friends chat [on|off]' command to enable chat feedback.");
	else
		Print(L"[Friends] Addon initialized.");
	end
	
end


function Friends.SlashCmd(args)

	local command;
	local parameter;
	local separator = string.find(args," ");
	
	if separator then
		command = string.sub(args, 0, separator-1);
		parameter = string.sub(args, separator+1, -1);
	else
		command = string.sub(args, 0, separator);
	end

    if command == "chat" then
		if parameter == "on" then
			Friends.SavedSettings.chatFeedback = true;
			Print("[Friends] Chat feedback has been enabled.");
		elseif parameter == "off" then
			Friends.SavedSettings.chatFeedback = false;
			Print("[Friends] Chat feedback has been disabled.");
		else
			Print("[Friends] Accepted parameters to command 'chat' are [on|off].");
		end
	else
		Print("[Friends] Unknown command. ");
	end
	
end



function Friends.OnUpdate(timeElapsed)
	if (not timeUntillFadeOut) then return end
    timeUntillFadeOut = timeUntillFadeOut - timeElapsed;
    if (timeUntillFadeOut > 0) then return end
	Friends.ClearKillWindow();
	timeUntillFadeOut = nil;
end


function Friends.OnChatLogUpdated(updateType, filterType)

	if (updateType ~= SystemData.TextLogUpdate.ADDED) then return end
	if (filterType ~= SystemData.ChatLogFilters.RVR_KILLS_ORDER and filterType ~= SystemData.ChatLogFilters.RVR_KILLS_DESTRUCTION) then return end
	
    local indexOfLastEntry = TextLogGetNumEntries("Combat") - 1;    
    local _, _, message = TextLogGetEntry("Combat", indexOfLastEntry);
	--d(message)

	local victim, verb, player, weapon, location = localization["CombatMessageParser"](message);
	-- <icon876> = party flag icon

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

		-- leave it to DB2 to announce own killing blows
		if not (Deathblow and (player == SelfName)) then
			Friends.AnnounceKill(killString);
		end
		 
		killString = killString .. L" in ";
		killString = killString .. towstring(CreateHyperLink(L"", location, LOCATION_COLOR, {} ));		
		
		if Friends.SavedSettings.chatFeedback and Friends.SavedSettings.chatFeedback == true then
			EA_ChatWindow.Print(killString);
		end
	
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
			Friends.AnnounceKill(killString);
		end
		
		killString = killString .. L" in ";
		killString = killString .. towstring(CreateHyperLink(L"", location, LOCATION_COLOR, {} ));
		
		if Friends.SavedSettings.chatFeedback and Friends.SavedSettings.chatFeedback == true then
			EA_ChatWindow.Print(killString);
		end
	
	end
	
end

function Friends.AnnounceKill(killString)
	LabelSetText ("FriendsKilledByText", killString);	
	WindowStopAlphaAnimation ("FriendsKilledBy");
	WindowStartAlphaAnimation ("FriendsKilledBy", Window.AnimationType.SINGLE_NO_RESET, 1, 0, 0, true, 0, 1);
	WindowStartAlphaAnimation ("FriendsKilledBy", Window.AnimationType.SINGLE_NO_RESET, 0, 1, 0.2, true, 0, 1);
	timeUntillFadeOut = TIME_DELAY;
end

function Friends.ClearKillWindow()
	WindowStopAlphaAnimation ("FriendsKilledBy")
	WindowStartAlphaAnimation ("FriendsKilledBy", Window.AnimationType.SINGLE_NO_RESET, 1, 1, 0, true, 0, 1)
	WindowStartAlphaAnimation ("FriendsKilledBy", Window.AnimationType.SINGLE_NO_RESET, 1, 0, 1, true, 0, 1)
end







