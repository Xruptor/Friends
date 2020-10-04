<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <UiMod name="Friends" version="2.1" date="04/10/2020">
	<VersionSettings gameVersion="1.4.8" windowsVersion="1.0" savedVariablesVersion="1.0" /> 
     <Author name="Caffeine" />
        <Description text="Adds new announcements when someone in your group gets a kill or dies." />
		<Dependencies>
			<Dependency name="LibGroup" />
		</Dependencies>
        <Files>
		
			<File name="Localization.lua" />
			<File name="Localization/enUS.lua" />
			
            <File name="Friends.lua" />
			<File name="FriendsKilledBy.xml" />
				
        </Files>
		<SavedVariables>			
		  <SavedVariable name="Friends.IconList" global="true"/>				
		</SavedVariables>	
        <OnInitialize>
            <CallFunction name="Friends.init" />
        </OnInitialize>
        <OnUpdate>
			<CallFunction name="Friends.OnUpdate" />
    	  </OnUpdate>
        <OnShutdown />
    </UiMod>
</ModuleFile>