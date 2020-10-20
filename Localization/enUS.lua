KillAlert = KillAlert or {};

local localizationWarning = false;
local match = match

if (not KillAlert.Localization) then
	KillAlert.Localization = {};
	KillAlert.Localization.Language = {};
end

function KillAlert.Localization.GetMapping()

	local lang = KillAlert.Localization.Language[SystemData.Settings.Language.active];
	
	if (not lang) then
		if (not localizationWarning) then
			d("[KillAlert] Your current language is not supported. English will be used instead.");
			localizationWarning = true;
		end
		lang = KillAlert.Localization.Language[SystemData.Settings.Language.ENGLISH];
	end
	
	return lang;
	
end

local function ParseCombatMessage(message)

	local localization = KillAlert.Localization.GetMapping()
	local victim, verb, player, weapon, location = message:match(localization["CombatMessageParseString"]);
	
	return victim, verb, player, weapon, location;

end

KillAlert.Localization.Language[SystemData.Settings.Language.ENGLISH] = 
{
	CombatMessageParseString = L"([%a]+) has been ([%a]+) by ([%a]+)'s ([%a%d%p  ]+) in ([^%.]+).",
	SlashCommandsList = "[KillAlert] List of commands.",
	SlashCommandsList1 = "/killalert groupweaponkills  -  Toggles display of group weapon/ability kill information.",
	SlashCommandsList2 = "/killalert showlocation  -  Toggles display of kill location.",
	SlashCommandsList3 = "/killalert showabilityicons  -  Toggles display of kill ability icons.",
	SlashCommandsList4 = "/killalert showchatalerts  -  Toggles displaying of alerts to chat window.",
	OFF = "OFF",
	ON = "ON",
	ADDON_INIT_1 = L"[KillAlert] Addon initialized. Use '/killalert'",
	ADDON_INIT_2 = L"[KillAlert] Addon initialized.",

};

KillAlert.CombatMessageParser = ParseCombatMessage;

