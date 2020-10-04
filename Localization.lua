Friends = Friends or {};
if (not Friends.Localization) then
	Friends.Localization = {};
	Friends.Localization.Language = {};
end

local localizationWarning = false;

function Friends.Localization.GetMapping()

	local lang = Friends.Localization.Language[SystemData.Settings.Language.active];
	
	if (not lang) then
		if (not localizationWarning) then
			--d("Your current language is not supported. English will be used instead.");
			localizationWarning = true;
		end
		lang = Friends.Localization.Language[SystemData.Settings.Language.ENGLISH];
	end
	
	return lang;
	
end