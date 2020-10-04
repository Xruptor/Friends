KillAlert = KillAlert or {};
if (not KillAlert.Localization) then
	KillAlert.Localization = {};
	KillAlert.Localization.Language = {};
end

local localizationWarning = false;

function KillAlert.Localization.GetMapping()

	local lang = KillAlert.Localization.Language[SystemData.Settings.Language.active];
	
	if (not lang) then
		if (not localizationWarning) then
			--d("Your current language is not supported. English will be used instead.");
			localizationWarning = true;
		end
		lang = KillAlert.Localization.Language[SystemData.Settings.Language.ENGLISH];
	end
	
	return lang;
	
end