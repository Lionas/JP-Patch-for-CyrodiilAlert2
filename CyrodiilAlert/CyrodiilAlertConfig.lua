local LAM = LibStub("LibAddonMenu-2.0")

function CA.CreateConfigMenu()

    local panelData = {
        type                = "panel",
        name                = CA.name,
        displayName         = CA.colOng:Colorize("Cyrodiil Alert 2"),
        author              = "Tanthul, Enodoc",
        version             = CA.version,
        slashCommand        = nil,
        registerForRefresh  = true,
        registerForDefaults = true,
    }
	local ConfigPanel = LAM:RegisterAddonPanel(CA.name.."Config", panelData)

	local ConfigData = {
		{
			type = "header",
			name = CA.colWht:Colorize("General Options"),
		},
		{
			type = "slider",
			name = "Notification Delay",
			tooltip = "Seconds for which the notification will remain on screen",
			min = 3,
			max = 10,
			step = 1,
			getFunc = function() return CA.vars.notifyDelay end,
			setFunc = function(newValue) CA.vars.notifyDelay = newValue end,
		},
		{
			type = "checkbox",
			name = "Output to Chat",
			tooltip = "Also outputs the notifications to your chat window",
			getFunc = function() return CA.vars.chatOutput end,
			setFunc = function(newValue) CA.vars.chatOutput = newValue end,
		},
		{
			type = "dropdown",
			name = "On-Screen Notifications",
			tooltip = "Disabled: No notifications on screen (combined with Output to Chat option allows notifications only in chat)\nESO UI: Display notifications using ESO's built-in announcement system\nCA UI: Display notifications in CyrodiilAlert's custom alert window",
			choices = {"Disabled", "ESO UI", "CA UI"},
			getFunc = function() return CA.vars.chooseUI end,
			setFunc = function(value)
				if value == "Disabled" then
					CA.vars.onlyChat = true
					CA.vars.chooseUI = value
				else
					CA.vars.onlyChat = false
					CA.vars.chooseUI = value
				end
			end,
		},
		{
			type = "checkbox",
			name = "     Sound",
			tooltip = "Enable notification sounds when using ESO UI",
			getFunc = function() return CA.vars.sound end,
			setFunc = function(newValue) CA.vars.sound = newValue;  end,
			disabled = function() return CA.vars.chooseUI ~= "ESO UI" end,
		},
		{
			type = "checkbox",
			name = "Enable Notifications Inside Imperial City",
			tooltip = "Get notifications for Cyrodiil when you are in the Imperial City",
			getFunc = function() return CA.vars.inside end,
			setFunc = function(newValue) CA.vars.inside = newValue;  end,
			disabled = function() return not IsCollectibleUnlocked(GetImperialCityCollectibleId()) end,
		},
		{
			type = "checkbox",
			name = "Enable Notifications Outside Cyrodiil",
			tooltip = "Get notifications when you are out of Cyrodiil",
			getFunc = function() return CA.vars.outside end,
			setFunc = function(newValue) CA.vars.outside = newValue;  end,
		},
		{
			type = "checkbox",
			name = "Disable Default ESO Notifications",
			tooltip = "Do not show the vanilla UI notifications for Artifact Gates, Emperors and Elder Scrolls (combined with related options below allows use of CA notifications instead)",
			getFunc = function() return CA.vars.vanillaAvA end,
			setFunc = function(newValue) CA.vars.vanillaAvA = newValue;  end,
			warning = "Overrides individual settings for these notifications when OFF",
		},
		{
			type = "checkbox",
			name = "     Disable Default Notifications Outside Cyrodiil",
			tooltip = "Do not show the vanilla UI notifications even if CA is disabled when out of Cyrodiil",
			getFunc = function() return CA.vars.vanillaOutside end,
			setFunc = function(newValue) CA.vars.vanillaOutside = newValue;  end,
			disabled = function() return ((not CA.vars.vanillaAvA) or (CA.vars.outside)) end,
		},
		{
			type = "checkbox",
			name = "     Redirect Default Notifications to Chat",
			tooltip = "Force the vanilla UI notifications to appear in the chat window",
			getFunc = function() return CA.vars.vanillaChat end,
			setFunc = function(newValue) CA.vars.vanillaChat = newValue;  end,
			disabled = function() return not CA.vars.vanillaAvA end,
		},
		{
			type = "checkbox",
			name = "Show Initialization Message",
			tooltip = "When you enter Cyrodiil, show Campaign Name, current Keep Status, Imperial City access, and Imperial District status in the chat window",
			getFunc = function() return CA.vars.showInit end,
			setFunc = function(newValue) CA.vars.showInit = newValue;  end,
		},
		{
			type = "checkbox",
			name = "Use Alliance Colors",
			tooltip = "Display alliance names in their colors; " .. CA.colAld:Colorize("Aldmeri Dominion") ..", " .. CA.colDag:Colorize("Daggerfall Covenant") .. ", " .. CA.colEbo:Colorize("Ebonheart Pact"),
			getFunc = function() return CA.vars.allianceColors end,
			setFunc = function(newValue) CA.vars.allianceColors = newValue;  end,
		},
		{
			type = "button",
			name = "Lock/Unlock",
			tooltip = "Lock/Unlock the alert window",
			func = function() CA.Movable() end,
		},
		{
			type = "header",
			name = CA.colWht:Colorize("Keep Status"),
		},
		{
			type = "description",
			title = "Reinitialize",
			text = "also available via '/ca init'",
			disabled = function() return not IsInCampaign() end,
			width = "half",
		},
		{
			type = "button",
			name = "Update Status",
			tooltip = "Reinitialize the add-on and update keep and resource ownership for current Cyrodiil campaign",
			func = function()
				if (IsInCampaign()) then
					if (CA.currentId ~= GetCurrentCampaignId()) then
--						d("CA Debug: In AvA, Button Update, New Campaign ID")
						CA.currentId = GetCurrentCampaignId()
						CA.campaignId = GetCurrentCampaignId()
						CA.campaignName = GetCampaignName(CA.campaignId)
						myAlliance = GetUnitAlliance("player")
					elseif (CA.currentId == GetCurrentCampaignId()) then
--						d("CA Debug: In AvA, Button Update, Same Campaign ID")
					end
				elseif (not IsInCampaign()) then
					if (CA.currentId ~= GetCurrentCampaignId()) then
--						d("CA Debug: Not AvA, Button Update, New Campaign ID")
						CA.currentId = GetCurrentCampaignId()
						CA.campaignId = GetAssignedCampaignId()
						CA.campaignName = GetCampaignName(CA.campaignId)
						myAlliance = GetUnitAlliance("player")
					elseif (CA.currentId == GetCurrentCampaignId()) then
--						d("CA Debug: Not AvA, Button Update, Same Campaign ID")
					end
				end
				return CA.InitKeeps() end,
			warning = "Dubious outside Cyrodiil",
			width = "half"
		},
		{
			type = "description",
			title = "Output Status to Chat",
			text = "also available via '/ca attacks' and '/ca status'",
		},
		{
			type = "button",
			name = "List Attacks",
			tooltip = "Output list of keeps and resources under attack",
			func = function() CA.vars.dumpAttack = true return CA.dumpChat() end,
			warning = "Dubious outside Cyrodiil",
			width = "half"
		},
		{
			type = "button",
			name = "List Status",
			tooltip = "Output ownership and attack status of all keeps and resources",
			func = function() CA.vars.dumpAttack = false return CA.dumpChat() end,
			warning = "Dubious outside Cyrodiil",
			width = "half",
		},
		{
			type = "description",
			title = "Imperial City",
			text = "also available via '/ca ic', '/ca ic all', '/ca ic access', or '/ca ic districts'",
			width = "half",
		},
		{
			type = "button",
			name = "Access & Districts",
			tooltip = "Output status of Imperial City access and district control",
			func = function() CA.vars.dumpAttack = true return CA.dumpImperial() end,
			warning = "Dubious outside Cyrodiil",
			width = "half",
		},	
		{
			type = "header",
			name = CA.colWht:Colorize("Notification Options"),
		},
		{
			type = "checkbox",
			name = "Enable Alliance Capture Notifications",
			tooltip = "Get notifications when an alliance captures an objective",
			getFunc = function() return CA.vars.showOwnerChanged end,
			setFunc = function(newValue) CA.vars.showOwnerChanged = newValue;  end,
		},
		{
			type = "dropdown",
			name = "     Notification Importance",
			tooltip = "Major: Alliance ownership changes are shown as major events in the ESO UI\nMinor: Alliance ownership changes are shown as minor events in the ESO UI",
			choices = {"Major", "Minor"},
			getFunc = function() return CA.vars.keepCapture end,
			setFunc = function(value)
				CA.vars.keepCapture = value
			end,
			disabled = function() return (not CA.vars.showOwnerChanged or CA.vars.chooseUI ~= "ESO UI") end,
		},
		{
			type = "checkbox",
			name = "Enable Attack Notifications",
			tooltip = "Get notifications about attacks",
			getFunc = function() return CA.vars.showAttack end,
			setFunc = function(newValue) CA.vars.showAttack = newValue;  end,
		},
		{
			type = "checkbox",
			name = "     Show Attack/Defense Sieges",
			tooltip = "Show siege weapon numbers by total attacking/defending",
			getFunc = function() return CA.vars.siegesAttDef end,
			setFunc = function(newValue) CA.vars.siegesAttDef = newValue;  end,
			disabled = function() return not CA.vars.showAttack end,
		},
		{
			type = "checkbox",
			name = "     Show Sieges by Alliance",
			tooltip = "Show siege weapon numbers by alliance",
			getFunc = function() return CA.vars.siegesByAlliance end,
			setFunc = function(newValue) CA.vars.siegesByAlliance = newValue;  end,
			disabled = function() return not CA.vars.showAttack end,
		},
		{
			type = "checkbox",
			name = "Enable Attack Ending Notifications",
			tooltip = "Get notifications about attacks ending",
			getFunc = function() return CA.vars.showAttackEnd end,
			setFunc = function(newValue) CA.vars.showAttackEnd = newValue;  end,
		},
		{
			type = "checkbox",
			name = "Enable Guild Claim Notifications",
			tooltip = "Get notifications about guilds claiming keeps",
			getFunc = function() return CA.vars.showClaim end,
			setFunc = function(newValue) CA.vars.showClaim = newValue;  end,
		},
		{
			type = "checkbox",
			name = "Enable Emperor Notifications",
			tooltip = "Get notifications about Emperors",
			getFunc = function() return CA.vars.showEmperors end,
			setFunc = function(newValue) CA.vars.showEmperors = newValue;  end,
			disabled = function() return not CA.vars.vanillaAvA end,
			warning = "Overriden by default UI notifications unless those are disabled",
		},
		{
			type = "checkbox",
			name = "Enable Imperial City Access Notifications",
			tooltip = "Get notifications about Imperial City access",
			getFunc = function() return CA.vars.showImperial end,
			setFunc = function(newValue) CA.vars.showImperial = newValue;  end,
		},
		{
			type = "checkbox",
			name = "Enable Queue Notifications",
			tooltip = "Get notifications when position in the Campaign Queue changes",
			getFunc = function() return CA.vars.showQueue end,
			setFunc = function(newValue) CA.vars.showQueue = newValue;  end,
		},
		{
			type = "checkbox",
			name = "Show Only My Alliance",
			tooltip = "Get keep and resource notifications for " .. GetAllianceName(GetUnitAlliance("player")) .. " only",
			getFunc = function() return CA.vars.onlyMyAlliance end,
			setFunc = function(newValue) CA.vars.onlyMyAlliance = newValue;  end,
		},
		{
			type = "header",
			name = CA.colWht:Colorize("Objective Options"),
		},
		{
			type = "checkbox",
			name = "Enable Town Capture Notifications",
			tooltip = "Get notifications about Cyrodiil town capture",
			getFunc = function() return CA.vars.showTowns end,
			setFunc = function(newValue) CA.vars.showTowns = newValue;  end,
		},
		{
			type = "checkbox",
			name = "Enable District Capture Notifications",
			tooltip = "Get notifications about Imperial City district capture",
			getFunc = function() return CA.vars.showDistricts end,
			setFunc = function(newValue) CA.vars.showDistricts = newValue;  end,
		},
		{
			type = "checkbox",
			name = "     Show District Capture in Cyrodiil",
			tooltip = "Get notifications for Imperial District capture when in Cyrodiil",
			getFunc = function() return CA.vars.showDistrictsOut end,
			setFunc = function(newValue) CA.vars.showDistrictsOut = newValue;  end,
			disabled = function() return not CA.vars.showDistricts  end,
		},
		{
			type = "checkbox",
			name = "     Show Tel Var Capture Bonus",
			tooltip = "Show the changes in the District Tel Var bonus",
			getFunc = function() return CA.vars.showTelvar end,
			setFunc = function(newValue) CA.vars.showTelvar = newValue;  end,
			disabled = function() return not CA.vars.showDistricts  end,
		},
		{
			type = "checkbox",
			name = "Enable Individual Flag Notifications",
			tooltip = "Get notifications about alliances securing individual keep flags",
			getFunc = function() return CA.vars.showFlags end,
			setFunc = function(newValue) CA.vars.showFlags = newValue;  end,
		},
		{
			type = "checkbox",
			name = "     Show Resource Flags",
			tooltip = "Get notifications for flags at Farms, Mines, and Lumbermills",
			getFunc = function() return CA.vars.showFlagsResources end,
			setFunc = function(newValue) CA.vars.showFlagsResources = newValue;  end,
			disabled = function() return not CA.vars.showFlags end,
		},
		{
			type = "checkbox",
			name = "     Show Town Flags",
			tooltip = "Get notifications for individual flags in Towns",
			getFunc = function() return CA.vars.showFlagsTowns end,
			setFunc = function(newValue) CA.vars.showFlagsTowns = newValue;  end,
			disabled = function() return ((not CA.vars.showFlags) or (not CA.vars.showTowns))  end,
		},
		{
			type = "checkbox",
			name = "     Show District Flags",
			tooltip = "Get notifications for flags in Imperial City Districts",
			getFunc = function() return CA.vars.showFlagsDistricts end,
			setFunc = function(newValue) CA.vars.showFlagsDistricts = newValue;  end,
			disabled = function() return ((not CA.vars.showFlags) or (not CA.vars.showDistricts))  end,
		},
		{
			type = "checkbox",
			name = "     Show Flags at Neutral",
			tooltip = "Get notifications when a flag falls to\n" .. CA.colGrn:Colorize("No Control") .. " during capture",
			getFunc = function() return CA.vars.showFlagsNeutral end,
			setFunc = function(newValue) CA.vars.showFlagsNeutral = newValue;  end,
			disabled = function() return not CA.vars.showFlags end,
		},
		{
			type = "checkbox",
			name = "Enable Gate Notifications",
			tooltip = "Get notifications about Artifact Gates",
			getFunc = function() return CA.vars.showGates end,
			setFunc = function(newValue) CA.vars.showGates = newValue;  end,
			disabled = function() return not CA.vars.vanillaAvA end,
			warning = "Overriden by default UI notifications unless those are disabled",
		},
		{
			type = "checkbox",
			name = "Enable Scroll Notifications",
			tooltip = "Get notifications about Elder Scrolls",
			getFunc = function() return CA.vars.showScrolls end,
			setFunc = function(newValue) CA.vars.showScrolls = newValue;  end,
			disabled = function() return not CA.vars.vanillaAvA end,
			warning = "Overriden by default UI notifications unless those are disabled",
		},
		{
			type = "description",
			text = "\nVersion |c60FF60" .. CA.version .. "|r by @Enodoc, Savant of the United Explorers of Scholarly Pursuits (UESP)\nUESP: The Unofficial Elder Scrolls Pages - A collaborative source for all knowledge on the Elder Scrolls series since 1995. Find us at www.uesp.net\n\nVersions prior to 1.0.0 by @Tanthul, Leader of the Dark Moon PVP Guild operating on the EU Scourge campaign. (AKA Nodens)\n\nAll rights reserved.",
		},
	}
	LAM:RegisterOptionControls(CA.name.."Config", ConfigData)

	
end -- CA.CreateConfigMenu

