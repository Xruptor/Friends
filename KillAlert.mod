<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <UiMod name="KillAlert" version="2.3" date="10/20/2020">
	<VersionSettings gameVersion="1.4.8" windowsVersion="1.0" savedVariablesVersion="1.0" /> 
     <Author name="Xruptor" />
        <Description text="Minimalistic addon that alerts you of your kills using an ability name and icon. It also announces you when someone in your group gets a kill or dies." />
		<Dependencies>
			<Dependency name="LibSlash" />
			<Dependency name="LibGroup" />
		</Dependencies>
        <Files>
		
			<File name="Localization.lua" />
			<File name="Localization/enUS.lua" />
			
            <File name="KillAlert.lua" />
			<File name="KillAlertFrames.xml" />
				
        </Files>
		<SavedVariables>			
		  <SavedVariable name="KillAlert.IconList" global="true"/>				
		</SavedVariables>	
        <OnInitialize>
            <CallFunction name="KillAlert.init" />
        </OnInitialize>
        <OnUpdate>
			<CallFunction name="KillAlert.OnUpdate" />
    	  </OnUpdate>
        <OnShutdown />
    </UiMod>
</ModuleFile>