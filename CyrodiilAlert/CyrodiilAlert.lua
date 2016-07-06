-- Cyrodiil Alert
-- Original Author: @Tanthul, Dark Moon Guild (Scourge EU)
-- Updated by: @Enodoc, UESP
-- Thanks to @Garkin for AvA Messages code

CA = {}

CA.name = "CyrodiilAlert"
CA.version = "2.0.1"
CA.initialised = false

-- Default settings.
CA.defaults = {
    locx            	= 560,
    locy            	= 180,
    scaling         	= 1.0,
	notifyDelay		= 5,
	chatOutput		= true,
	onlyChat		= false,
	onlyMyAlliance		= false,
	outside			= false,
	inside			= true,
	allianceColors		= true,
	dumpAttack		= true,
	siegesAttDef		= true,
	siegesByAlliance	= true,
	showAttack		= true,
	showAttackEnd		= true,
	showOwnerChanged	= true,
	showTowns		= true,
	showEmperors		= true,
	showGates		= true,
	showScrolls		= true,
	showFlags		= true,
	showFlagsResources	= false,
	showFlagsDistricts	= false,
	showFlagsNeutral	= true,
	showFlagsTowns		= true,
	showClaim		= true,
	showQueue		= true,
	showImperial		= true,
	showDistricts		= true,
	showDistrictsOut	= false,
	showTelvar		= true,
	showInit		= true,
	locked			= true,
	vanillaAvA		= true,
	vanillaOutside		= false,
	vanillaChat		= false,
	chooseUI		= "ESO UI",
	keepCapture		= "Major",
	sound			= true,
    textAlign       	= "CENTER",
}

CA_ACE = LibStub("AceTimer-3.0")

function CA.Initialise(eventCode, addOnName)

	-- Initialize self only.
	if (CA.name ~= addOnName) then return end

	-- Load saved variables.
	CA.vars = ZO_SavedVars:NewAccountWide("CA_SavedVariables", 1, nil, CA.defaults)
	RegisterForAssignedCampaignData()

        --set hooks
	CA.HookAvAMessages()

	
	CyrodiilAlert:ClearAnchors();
	CyrodiilAlert:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, CA.vars.locx, CA.vars.locy)

    
	CyrodiilAlertBG:SetAlpha(0)
    
	CyrodiilAlertNotifyTaken:ClearAnchors();
	CyrodiilAlertNotifyTaken:SetAnchor(TOP, CyrodiilAlert, TOP, 0, 0)
	CyrodiilAlertNotifyTaken:SetWidth( 800 )
	CyrodiilAlertNotifyTaken:SetHeight( 40 )

	CyrodiilAlertNotify:ClearAnchors();
	CyrodiilAlertNotify:SetAnchor(TOP, CyrodiilAlertNotifyTaken, BOTTOM, 0, 0)
	CyrodiilAlertNotify:SetWidth( 800 )
	CyrodiilAlertNotify:SetHeight(40 )

	CyrodiilAlertNotifyExtra:ClearAnchors();
	CyrodiilAlertNotifyExtra:SetAnchor(TOP, CyrodiilAlertNotify, BOTTOM, 0, 0)
	CyrodiilAlertNotifyExtra:SetWidth( 800 )
	CyrodiilAlertNotifyExtra:SetHeight( 70 )
        
    -- Event registration.    
	EVENT_MANAGER:RegisterForEvent("CA", EVENT_KEEP_UNDER_ATTACK_CHANGED, CA.OnKeepUnderAttackChanged)
	EVENT_MANAGER:RegisterForEvent("CA", EVENT_KEEP_ALLIANCE_OWNER_CHANGED, CA.OnAllianceOwnerChanged)
	EVENT_MANAGER:RegisterForEvent("CA", EVENT_KEEP_GATE_STATE_CHANGED, CA.OnGateChanged)
	EVENT_MANAGER:RegisterForEvent("CA", EVENT_DEPOSE_EMPEROR_NOTIFICATION, CA.OnDeposeEmperor)
	EVENT_MANAGER:RegisterForEvent("CA", EVENT_CORONATE_EMPEROR_NOTIFICATION, CA.OnCoronateEmperor)
	EVENT_MANAGER:RegisterForEvent("CA", EVENT_ARTIFACT_CONTROL_STATE, CA.OnArtifactControlState)
	EVENT_MANAGER:RegisterForEvent("CA", EVENT_OBJECTIVE_CONTROL_STATE, CA.OnObjectiveControlState)
	EVENT_MANAGER:RegisterForEvent("CA", EVENT_GUILD_CLAIM_KEEP_CAMPAIGN_NOTIFICATION, CA.OnClaimKeep)
	EVENT_MANAGER:RegisterForEvent("CA", EVENT_CAMPAIGN_QUEUE_POSITION_CHANGED, CA.CampaignQueue)
	EVENT_MANAGER:RegisterForEvent("CA", EVENT_ZONE_CHANGED, CA.OnNewZone)
	EVENT_MANAGER:RegisterForEvent("CA", EVENT_PLAYER_ACTIVATED, CA.OnUILoad)
	EVENT_MANAGER:RegisterForEvent("CA", EVENT_ACTION_LAYER_POPPED, CA.ShowInterface)
	EVENT_MANAGER:RegisterForEvent("CA", EVENT_ACTION_LAYER_PUSHED, CA.HideInterface)
	EVENT_MANAGER:RegisterForEvent("CA", EVENT_IMPERIAL_CITY_ACCESS_GAINED_NOTIFICATION, CA.OnImperialAccessGained)
	EVENT_MANAGER:RegisterForEvent("CA", EVENT_IMPERIAL_CITY_ACCESS_LOST_NOTIFICATION, CA.OnImperialAccessLost)

	-- Under Attack table setup
	CA.ua = {}
	for i=1,152 do --there are not more than 152 keeps
		CA.ua[i] = {}
		for j=1,2 do
			CA.ua[i][j] = 0 --col 1 = ua, col 2 = alliance
		end
	end

	-- Empty variables
	CA.campaignId = nil
	CA.currentId = nil
	CA.campaignName = nil
	myAlliance = nil
	CA.keepsReady = false

	-- colour setup
	CA.colAld = GetAllianceColor(ALLIANCE_ALDMERI_DOMINION)
	CA.colDag = GetAllianceColor(ALLIANCE_DAGGERFALL_COVENANT)
	CA.colEbo = GetAllianceColor(ALLIANCE_EBONHEART_PACT)
	CA.colGrn = ZO_ColorDef:FromInterfaceColor(INTERFACE_COLOR_TYPE_KEEP_TOOLTIP,KEEP_TOOLTIP_COLOR_ACCESSIBLE)
	CA.colRed = ZO_ColorDef:FromInterfaceColor(INTERFACE_COLOR_TYPE_KEEP_TOOLTIP,KEEP_TOOLTIP_COLOR_NOT_ACCESSIBLE)
	CA.colWht = ZO_ColorDef:New(0.9,0.9,0.9,1)
	CA.colGry = ZO_ColorDef:New(0.525,0.525,0.525,1)
	CA.colOng = ZO_ColorDef:New(0.84,0.4,0.05,1)
	CA.colBlu = ZO_ColorDef:FromInterfaceColor(INTERFACE_COLOR_TYPE_KEEP_TOOLTIP,KEEP_TOOLTIP_COLOR_OWNER)
	CA.colTel = ZO_ColorDef:FromInterfaceColor(INTERFACE_COLOR_TYPE_CURRENCY,CURRENCY_COLOR_TELVAR_STONES)


    -- Configuration Menu setup.
    CA.CreateConfigMenu()
    CA.initialised = true   
--	d("CA Debug: Ran Through Init") 
end


EVENT_MANAGER:RegisterForEvent("CA", EVENT_ADD_ON_LOADED, CA.Initialise)


function CA.HideInterface(eventCode, layerIndex, activeLayerIndex)
	if (activeLayerIndex == 3) then
		CyrodiilAlert:SetHidden(true)
	end
end

function CA.ShowInterface(...)
    CyrodiilAlert:SetHidden(false)
end

function CA.OnNewZone(eventCode, unitTag, subZoneName, newSubzone)
--	d("CA Debug: New Zone")
	zo_callLater(CA.OnNewZoneCont,1000)
end

function CA.OnUILoad(eventCode)
--	d("CA Debug: UI Loaded, Player Activated")
	zo_callLater(CA.OnNewZoneCont,1000)
end

function CA.OnNewZoneCont()
	if (IsInCampaign()) then
		if (CA.currentId ~= GetCurrentCampaignId()) then
--			d("CA Debug: In AvA, New Zone, New Campaign ID")
			CA.currentId = GetCurrentCampaignId()
			CA.campaignId = GetCurrentCampaignId()
			CA.campaignName = GetCampaignName(CA.campaignId)
			myAlliance = GetUnitAlliance("player")
			zo_callLater(CA.InitKeeps, 1000)
		elseif (CA.currentId == GetCurrentCampaignId()) then
--			d("CA Debug: In AvA, New Zone, Same Campaign ID")
		end
	elseif (not IsInCampaign()) then
		if (CA.currentId ~= GetCurrentCampaignId()) then
--			d("CA Debug: Not AvA, New Zone, New Campaign ID")
			CA.currentId = GetCurrentCampaignId()
			CA.campaignId = GetAssignedCampaignId()
			CA.campaignName = GetCampaignName(CA.campaignId)
			myAlliance = GetUnitAlliance("player")
			zo_callLater(CA.InitKeeps, 1000)
		elseif (CA.currentId == GetCurrentCampaignId()) then
--			d("CA Debug: Not AvA, New Zone, Same Campaign ID")
		end
	end
end

function CA.InitKeeps()

	local initText = CA.colOng:Colorize("Cyrodiil Alert Initialized")
	local campWelcome = CA.colWht:Colorize("Welcome to ") .. CA.colGrn:Colorize(CA.campaignName) .. CA.colWht:Colorize("!")
	local campHome = CA.colWht:Colorize("Home Campaign: ") .. CA.colGrn:Colorize(CA.campaignName)
	local icEntryStatus
	if (DoesAllianceHaveImperialCityAccess(CA.campaignId,myAlliance)) and (IsCollectibleUnlocked(GetImperialCityCollectibleId())) then
		icEntryStatus = CA.colWht:Colorize("You currently have Imperial City access")
	elseif (not DoesAllianceHaveImperialCityAccess(CA.campaignId,myAlliance)) and (IsCollectibleUnlocked(GetImperialCityCollectibleId())) then
		icEntryStatus = CA.colGry:Colorize("You do not have Imperial City access")
	else
		icEntryStatus = ""
	end
	local outOff = CA.colGry:Colorize("Notifications outside of Cyrodiil are OFF")
	local chatOn = CA.colWht:Colorize("Chat output is On")
	local chatOff = CA.colGry:Colorize("Chat output is Off")
	local notiOn = CA.colWht:Colorize("On-Screen Notifications are On")
	local notiOff = CA.colWht:Colorize("On-Screen Notifications are Off")

	if (CA.timerId) then
		CA_ACE:CancelTimer(CA.timerId)
	end
	if (CA.timerIdTaken) then
		CA_ACE:CancelTimer(CA.timerIdTaken)
	end
	if (CA.timerIdExtra) then
		CA_ACE:CancelTimer(CA.timerIdExtra)
	end
	
	if (IsInCampaign()) then
		if (CA.vars.showInit) then
			d(initText)
			d(campWelcome)
			CA.NotifyInitMessage(initText,CSA_EVENT_COMBINED_TEXT,"Display_Announcement",campWelcome,icEntryStatus)
			CA.timerIdTaken = CA_ACE:ScheduleTimer("ClearNotifyTaken", CA.vars.notifyDelay)
			CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
		end
		for i=1,152 do
			CA.ua[i][2] = GetKeepAlliance(i, BGQUERY_LOCAL)
			if (GetKeepUnderAttack(i, BGQUERY_LOCAL)) then
				CA.ua[i][1] = 1
			else
				CA.ua[i][1] = 0
			end
		end
		if (CA.vars.showInit) then
			if (CA.vars.showImperial) then
				CA.dumpImperial()
			end
			if (CA.vars.showDistricts) then
				CA.dumpDistricts()
			end
			CA.vars.dumpAttack = true CA.dumpChat()
		end
	elseif (not IsInCampaign()) then
		if (CA.vars.showInit) then
			d(initText)
			if (CA.vars.outside) then
				CA.NotifyInitMessage(initText,CSA_EVENT_COMBINED_TEXT,"Display_Annoucement",campHome,icEntryStatus)
				CA.timerIdTaken = CA_ACE:ScheduleTimer("ClearNotifyTaken", CA.vars.notifyDelay)
				CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
			end
		end
		for i=1,152 do
			CA.ua[i][2] = GetKeepAlliance(i, BGQUERY_ASSIGNED_CAMPAIGN)
			if (GetKeepUnderAttack(i, BGQUERY_ASSIGNED_CAMPAIGN)) then
				CA.ua[i][1] = 1
			else
				CA.ua[i][1] = 0
			end
		end
		if ((CA.vars.outside) and (CA.vars.showInit)) then
			d(campHome)
			CA.dumpImperial()
			CA.vars.dumpAttack = true CA.dumpDistricts() CA.dumpChat()
		elseif ((not CA.vars.outside) and (CA.vars.showInit)) then
			d(outOff)
		end
	end
	
	if (((CA.vars.outside) or (IsInCampaign())) and (CA.vars.showInit)) then
		if (CA.vars.chatOutput) then
			d(chatOn)
		elseif (not CA.vars.chatOutput) then
			d(chatOff)
		end
		
		if (not CA.vars.onlyChat) then
			CA.NotifyMessage(notiOn,CSA_EVENT_SMALL_TEXT,nil)
		elseif (CA.vars.onlyChat) then
			CA.NotifyMessage(notiOff,CSA_EVENT_SMALL_TEXT,nil)
		end
		CA.timerId = CA_ACE:ScheduleTimer("ClearNotify", CA.vars.notifyDelay)
	end
	CA.keepsReady = true
end

function CA.dumpChat()

	local statusText = CA.colGry:Colorize("Cyrodiil Status:")
	local uaText = CA.colRed:Colorize("Under Attack!")
	local noAttacks = CA.colWht:Colorize("     No keeps are under attack")

	local attTot = 0
	d(statusText)
	for i = 1,87 do
		attTot = attTot + CA.ua[i][1]
		local keepName = GetKeepName(i)
		if (CA.ua[i][1] == 0 and not CA.vars.dumpAttack) then
		if (CA.ua[i][2] == 1) then
			d(CA.colAld:Colorize(keepName))
		elseif (CA.ua[i][2] == 2) then
			d(CA.colEbo:Colorize(keepName))
		elseif (CA.ua[i][2] == 3) then
			d(CA.colDag:Colorize(keepName))
		end
		elseif (CA.ua[i][1] == 1) then
		if (CA.ua[i][2] == 1) then
			d(CA.colAld:Colorize(keepName) .. CA.colWht:Colorize(" - ") .. uaText)
		elseif (CA.ua[i][2] == 2) then
			d(CA.colEbo:Colorize(keepName) .. CA.colWht:Colorize(" - ") .. uaText)
		elseif (CA.ua[i][2] == 3) then
			d(CA.colDag:Colorize(keepName) .. CA.colWht:Colorize(" - ") .. uaText)
		end
		GetKeepAlliance(i, BGQUERY_LOCAL)
		local keepAlliance = GetKeepAlliance(i, BGQUERY_LOCAL)
		local defendSiege = GetNumSieges(i, BGQUERY_LOCAL, keepAlliance)
		local allSiege = GetNumSieges(i, BGQUERY_LOCAL, ALLIANCE_ALDMERI_DOMINION)
		allSiege = allSiege + GetNumSieges(i, BGQUERY_LOCAL, ALLIANCE_DAGGERFALL_COVENANT)
		allSiege = allSiege + GetNumSieges(i, BGQUERY_LOCAL, ALLIANCE_EBONHEART_PACT)
		local adSiege = GetNumSieges(i, BGQUERY_LOCAL, ALLIANCE_ALDMERI_DOMINION)
		local dcSiege = GetNumSieges(i, BGQUERY_LOCAL, ALLIANCE_DAGGERFALL_COVENANT)
		local epSiege = GetNumSieges(i, BGQUERY_LOCAL, ALLIANCE_EBONHEART_PACT)
		local mySiege = GetNumSieges(i, BGQUERY_LOCAL, myAlliance)
		local attackSiege = allSiege - defendSiege
		if (allSiege ~= 0) then
			if (CA.vars.siegesAttDef) and (CA.vars.siegesByAlliance) then
				d(CA.colWht:Colorize("     Sieges: A:") .. CA.colRed:Colorize(attackSiege) .. CA.colWht:Colorize(" / D:") .. CA.colGrn:Colorize(defendSiege) .. CA.colWht:Colorize("  (") .. CA.colAld:Colorize(adSiege) .. CA.colWht:Colorize(", ") .. CA.colDag:Colorize(dcSiege) .. CA.colWht:Colorize(", ") .. CA.colEbo:Colorize(epSiege) .. CA.colWht:Colorize(")"))
			elseif (CA.vars.siegesAttDef) and (not CA.vars.siegesByAlliance) then
				d(CA.colWht:Colorize("     Sieges: Att: ") .. CA.colRed:Colorize(attackSiege) .. CA.colWht:Colorize(" / Def:") .. CA.colGrn:Colorize(defendSiege))
			elseif (not CA.vars.siegesAttDef) and (CA.vars.siegesByAlliance) then
				d(CA.colWht:Colorize("     Sieges: AD: ") .. CA.colAld:Colorize(adSiege) .. CA.colWht:Colorize(", DC: ") .. CA.colDag:Colorize(dcSiege) .. CA.colWht:Colorize(", EP: ") .. CA.colEbo:Colorize(epSiege) .. CA.colWht:Colorize(")"))
			end
		elseif (allSiege == 0) and ((CA.vars.siegesAttDef) or (CA.vars.siegesByAlliance)) then
			d(CA.colWht:Colorize("     Sieges: None"))
		end
		end
	end
	for i = 132,134 do
		attTot = attTot + CA.ua[i][1]
		local keepName = GetKeepName(i)
		if (CA.ua[i][1] == 0 and not CA.vars.dumpAttack) then
		if (CA.ua[i][2] == 1) then
			d(CA.colAld:Colorize(keepName))
		elseif (CA.ua[i][2] == 2) then
			d(CA.colEbo:Colorize(keepName))
		elseif (CA.ua[i][2] == 3) then
			d(CA.colDag:Colorize(keepName))
		end
		elseif (CA.ua[i][1] == 1) then
		if (CA.ua[i][2] == 1) then
			d(CA.colAld:Colorize(keepName) .. CA.colWht:Colorize(" - ") .. uaText)
		elseif (CA.ua[i][2] == 2) then
			d(CA.colEbo:Colorize(keepName) .. CA.colWht:Colorize(" - ") .. uaText)
		elseif (CA.ua[i][2] == 3) then
			d(CA.colDag:Colorize(keepName) .. CA.colWht:Colorize(" - ") .. uaText)
		end
		GetKeepAlliance(i, BGQUERY_LOCAL)
		local keepAlliance = GetKeepAlliance(i, BGQUERY_LOCAL)
		local defendSiege = GetNumSieges(i, BGQUERY_LOCAL, keepAlliance)
		local allSiege = GetNumSieges(i, BGQUERY_LOCAL, ALLIANCE_ALDMERI_DOMINION)
		allSiege = allSiege + GetNumSieges(i, BGQUERY_LOCAL, ALLIANCE_DAGGERFALL_COVENANT)
		allSiege = allSiege + GetNumSieges(i, BGQUERY_LOCAL, ALLIANCE_EBONHEART_PACT)
		local adSiege = GetNumSieges(i, BGQUERY_LOCAL, ALLIANCE_ALDMERI_DOMINION)
		local dcSiege = GetNumSieges(i, BGQUERY_LOCAL, ALLIANCE_DAGGERFALL_COVENANT)
		local epSiege = GetNumSieges(i, BGQUERY_LOCAL, ALLIANCE_EBONHEART_PACT)
		local mySiege = GetNumSieges(i, BGQUERY_LOCAL, myAlliance)
		local attackSiege = allSiege - defendSiege
		if (allSiege ~= 0) then
			if (CA.vars.siegesAttDef) and (CA.vars.siegesByAlliance) then
				d(CA.colWht:Colorize("     Sieges: A:") .. CA.colRed:Colorize(attackSiege) .. CA.colWht:Colorize(" / D:") .. CA.colGrn:Colorize(defendSiege) .. CA.colWht:Colorize("  (") .. CA.colAld:Colorize(adSiege) .. CA.colWht:Colorize(", ") .. CA.colDag:Colorize(dcSiege) .. CA.colWht:Colorize(", ") .. CA.colEbo:Colorize(epSiege) .. CA.colWht:Colorize(")"))
			elseif (CA.vars.siegesAttDef) and (not CA.vars.siegesByAlliance) then
				d(CA.colWht:Colorize("     Sieges: Att: ") .. CA.colRed:Colorize(attackSiege) .. CA.colWht:Colorize(" / Def:") .. CA.colGrn:Colorize(defendSiege))
			elseif (not CA.vars.siegesAttDef) and (CA.vars.siegesByAlliance) then
				d(CA.colWht:Colorize("     Sieges: AD: ") .. CA.colAld:Colorize(adSiege) .. CA.colWht:Colorize(", DC: ") .. CA.colDag:Colorize(dcSiege) .. CA.colWht:Colorize(", EP: ") .. CA.colEbo:Colorize(epSiege) .. CA.colWht:Colorize(")"))
			end
		elseif (allSiege == 0) and ((CA.vars.siegesAttDef) or (CA.vars.siegesByAlliance)) then
			d(CA.colWht:Colorize("     Sieges: None"))
		end
		end
	end
	if (attTot == 0) then
		d(noAttacks)
	end
end

function CA.dumpImperial()
	local rulesetId = GetCampaignRulesetId(CA.campaignId)
-- GetAvAKeepScore returns 4 variables: bool:all_own_held; int:num_enemy_held; int:num_own_held; int:num_own_total
	local ADKeeps = {}
	ADKeeps[1],ADKeeps[2],ADKeeps[3],ADKeeps[4] = GetAvAKeepScore(CA.campaignId, ALLIANCE_ALDMERI_DOMINION)
	local EPKeeps = {}
	EPKeeps[1],EPKeeps[2],EPKeeps[3],EPKeeps[4] = GetAvAKeepScore(CA.campaignId, ALLIANCE_EBONHEART_PACT)
	local DCKeeps = {}
	DCKeeps[1],DCKeeps[2],DCKeeps[3],DCKeeps[4] = GetAvAKeepScore(CA.campaignId, ALLIANCE_DAGGERFALL_COVENANT)
--	d(ADKeeps)
--	d(EPKeeps)
--	d(DCKeeps)
	local ICAccessRule = GetCampaignRulesetImperialAccessRule(rulesetId)
	local ICAccessKeepsAD = {}
	local ICAccessKeepsEP = {}
	local ICAccessKeepsDC = {}
	local ICAccessCounterAD = 0
	local ICAccessCounterEP = 0
	local ICAccessCounterDC = 0
	local ICNumKeepsAD = 0
	local ICNumKeepsEP = 0
	local ICNumKeepsDC = 0
	if ICAccessRule == IMPERIAL_CITY_ACCESS_RULE_TYPE_NATIVE_KEEPS then
		ICNumKeepsAD = 6
		ICNumKeepsEP = 6
		ICNumKeepsDC = 6
		ICAccessCounterAD = ADKeeps[3]
		ICAccessCounterEP = EPKeeps[3]
		ICAccessCounterDC = DCKeeps[3]
	elseif ICAccessRule == IMPERIAL_CITY_ACCESS_RULE_TYPE_NATIVE_KEEPS_PLUS_ONE then
		ICNumKeepsAD = 7
		ICNumKeepsEP = 7
		ICNumKeepsDC = 7
		ICAccessCounterAD = ADKeeps[3]
		ICAccessCounterEP = EPKeeps[3]
		ICAccessCounterDC = DCKeeps[3]
		if ADKeeps[2] > 0 then ICAccessCounterAD = ICAccessCounterAD + 1 end
		if EPKeeps[2] > 0 then ICAccessCounterEP = ICAccessCounterEP + 1 end
		if DCKeeps[2] > 0 then ICAccessCounterDC = ICAccessCounterDC + 1 end
	elseif ICAccessRule == IMPERIAL_CITY_ACCESS_RULE_TYPE_MAJORITY_KEEPS then
		ICNumKeepsAD = 10
		ICNumKeepsEP = 10
		ICNumKeepsDC = 10
		ICAccessCounterAD = ADKeeps[2] + ADKeeps[3]
		ICAccessCounterEP = EPKeeps[2] + EPKeeps[3]
		ICAccessCounterDC = DCKeeps[2] + DCKeeps[3]
	elseif ICAccessRule == IMPERIAL_CITY_ACCESS_RULE_TYPE_EVERYONE then
		ICNumKeepsAD = 0
		ICNumKeepsEP = 0
		ICNumKeepsDC = 0
		ICAccessCounterAD = ADKeeps[2] + ADKeeps[3]
		ICAccessCounterEP = EPKeeps[2] + EPKeeps[3]
		ICAccessCounterDC = DCKeeps[2] + DCKeeps[3]
	end
	local ADlockCol
	local EPlockCol
	local DClockCol
	d(CA.colGry:Colorize("Imperial City:"))
	if not IsCollectibleUnlocked(GetImperialCityCollectibleId()) then
		ADlockCol = CA.colGry
	elseif ICAccessCounterAD < ICNumKeepsAD then
		ADlockCol = CA.colRed
	else
		ADlockCol = CA.colGrn
	end
	if DoesAllianceHaveImperialCityAccess(CA.campaignId,ALLIANCE_ALDMERI_DOMINION) then
		d(CA.colAld:Colorize("     Aldmeri Dominion") .. CA.colWht:Colorize(": ") .. ADlockCol:Colorize("Unlocked") .. CA.colWht:Colorize(", Keeps Controlled: ") .. ADlockCol:Colorize(ICAccessCounterAD) .. CA.colWht:Colorize(" of ") .. CA.colOng:Colorize(ICNumKeepsAD))
	else
		d(CA.colAld:Colorize("     Aldmeri Dominion") .. CA.colWht:Colorize(": ") .. ADlockCol:Colorize("Locked") .. CA.colWht:Colorize(", Keeps Controlled: ") .. ADlockCol:Colorize(ICAccessCounterAD) .. CA.colWht:Colorize(" of ") .. CA.colOng:Colorize(ICNumKeepsAD))
	end
	if not IsCollectibleUnlocked(GetImperialCityCollectibleId()) then
		EPlockCol = CA.colGry
	elseif ICAccessCounterEP < ICNumKeepsEP then
		EPlockCol = CA.colRed
	else
		EPlockCol = CA.colGrn
	end
	if DoesAllianceHaveImperialCityAccess(CA.campaignId,ALLIANCE_EBONHEART_PACT) then
		d(CA.colEbo:Colorize("     Ebonheart Pact") .. CA.colWht:Colorize(": ") .. EPlockCol:Colorize("Unlocked") .. CA.colWht:Colorize(", Keeps Controlled: ") .. EPlockCol:Colorize(ICAccessCounterEP) .. CA.colWht:Colorize(" of ") .. CA.colOng:Colorize(ICNumKeepsEP))
	else
		d(CA.colEbo:Colorize("     Ebonheart Pact") .. CA.colWht:Colorize(": ") .. EPlockCol:Colorize("Locked") .. CA.colWht:Colorize(", Keeps Controlled: ") .. EPlockCol:Colorize(ICAccessCounterEP) .. CA.colWht:Colorize(" of ") .. CA.colOng:Colorize(ICNumKeepsEP))
	end
	if not IsCollectibleUnlocked(GetImperialCityCollectibleId()) then
		DClockCol = CA.colGry
	elseif ICAccessCounterDC < ICNumKeepsDC then
		DClockCol = CA.colRed
	else
		DClockCol = CA.colGrn
	end
	if DoesAllianceHaveImperialCityAccess(CA.campaignId,ALLIANCE_DAGGERFALL_COVENANT) then
		d(CA.colDag:Colorize("     Daggerfall Covenant") .. CA.colWht:Colorize(": ") .. DClockCol:Colorize("Unlocked") .. CA.colWht:Colorize(", Keeps Controlled: ") .. DClockCol:Colorize(ICAccessCounterDC) .. CA.colWht:Colorize(" of ") .. CA.colOng:Colorize(ICNumKeepsDC))
	else
		d(CA.colDag:Colorize("     Daggerfall Covenant") .. CA.colWht:Colorize(": ") .. DClockCol:Colorize("Locked") .. CA.colWht:Colorize(", Keeps Controlled: ") .. DClockCol:Colorize(ICAccessCounterDC) .. CA.colWht:Colorize(" of ") .. CA.colOng:Colorize(ICNumKeepsDC))
	end
	if (DoesAllianceHaveImperialCityAccess(CA.campaignId,myAlliance)) and (IsCollectibleUnlocked(GetImperialCityCollectibleId())) then
		d(CA.colGrn:Colorize("     You currently have Imperial City access"))
	elseif IsCollectibleUnlocked(GetImperialCityCollectibleId()) then
		d(CA.colRed:Colorize("     You do not have Imperial City access"))
	else
		d(CA.colGry:Colorize("     You do not have Imperial City access"))
	end
end

function CA.dumpDistricts()
	local attTot = 0
	local aldTot = 0
	local dagTot = 0
	local eboTot = 0
	local aldNum = 0
	local dagNum = 0
	local eboNum = 0
	local ADcol = CA.colGry
	local DCcol = CA.colGry
	local EPcol = CA.colGry
	if myAlliance == ALLIANCE_ALDMERI_DOMINION then
		ADcol = CA.colGrn
	elseif myAlliance == ALLIANCE_DAGGERFALL_COVENANT then
		DCcol = CA.colGrn
	elseif myAlliance == ALLIANCE_EBONHEART_PACT then
		EPcol = CA.colGrn
	end
	if IsCollectibleUnlocked(GetImperialCityCollectibleId()) then
		d(CA.colGry:Colorize("Imperial Districts:"))
		for i = 141,143 do
			attTot = attTot + CA.ua[i][1]
			local keepName = GetKeepName(i)
			if (CA.ua[i][1] == 0 and not CA.vars.dumpAttack) then
				if (CA.ua[i][2] == 1) then
					d(CA.colAld:Colorize(keepName))
				elseif (CA.ua[i][2] == 2) then
					d(CA.colEbo:Colorize(keepName))
				elseif (CA.ua[i][2] == 3) then
					d(CA.colDag:Colorize(keepName))
				end
			elseif (CA.ua[i][1] == 1) then
				if (CA.ua[i][2] == 1) then
					d(CA.colAld:Colorize(keepName) .. CA.colWht:Colorize(" - ") .. CA.colRed:Colorize("Under Attack!"))
				elseif (CA.ua[i][2] == 2) then
					d(CA.colEbo:Colorize(keepName) .. CA.colWht:Colorize(" - ") .. CA.colRed:Colorize("Under Attack!"))
				elseif (CA.ua[i][2] == 3) then
					d(CA.colDag:Colorize(keepName) .. CA.colWht:Colorize(" - ") .. CA.colRed:Colorize("Under Attack!"))
				end
			end
			if (CA.ua[i][2] == 1) then
				aldTot = aldTot + GetDistrictOwnershipTelVarBonusPercent(i, BGQUERY_LOCAL)
				aldNum = aldNum + 1
			elseif (CA.ua[i][2] == 2) then
				eboTot = eboTot + GetDistrictOwnershipTelVarBonusPercent(i, BGQUERY_LOCAL)
				eboNum = eboNum + 1
			elseif (CA.ua[i][2] == 3) then
				dagTot = dagTot + GetDistrictOwnershipTelVarBonusPercent(i, BGQUERY_LOCAL)
				dagNum = dagNum + 1
			end
		end
		for i = 146,148 do
			attTot = attTot + CA.ua[i][1]
			local keepName = GetKeepName(i)
			if (CA.ua[i][1] == 0 and not CA.vars.dumpAttack) then
				if (CA.ua[i][2] == 1) then
					d(CA.colAld:Colorize(keepName))
				elseif (CA.ua[i][2] == 2) then
					d(CA.colEbo:Colorize(keepName))
				elseif (CA.ua[i][2] == 3) then
					d(CA.colDag:Colorize(keepName))
				end
			elseif (CA.ua[i][1] == 1) then
				if (CA.ua[i][2] == 1) then
					d(CA.colAld:Colorize(keepName) .. CA.colWht:Colorize(" - ") .. CA.colRed:Colorize("Under Attack!"))
				elseif (CA.ua[i][2] == 2) then
					d(CA.colEbo:Colorize(keepName) .. CA.colWht:Colorize(" - ") .. CA.colRed:Colorize("Under Attack!"))
				elseif (CA.ua[i][2] == 3) then
					d(CA.colDag:Colorize(keepName) .. CA.colWht:Colorize(" - ") .. CA.colRed:Colorize("Under Attack!"))
				end
			end
			if (CA.ua[i][2] == 1) then
				aldTot = aldTot + GetDistrictOwnershipTelVarBonusPercent(i, BGQUERY_LOCAL)
				aldNum = aldNum + 1
			elseif (CA.ua[i][2] == 2) then
				eboTot = eboTot + GetDistrictOwnershipTelVarBonusPercent(i, BGQUERY_LOCAL)
				eboNum = eboNum + 1
			elseif (CA.ua[i][2] == 3) then
				dagTot = dagTot + GetDistrictOwnershipTelVarBonusPercent(i, BGQUERY_LOCAL)
				dagNum = dagNum + 1
			end
		end
		if (attTot == 0) then
			d(CA.colWht:Colorize("     No districts are under attack"))
		end
		d(CA.colAld:Colorize("     Aldmeri Dominion") .. CA.colWht:Colorize(": Districts: ") .. CA.colOng:Colorize(aldNum) .. CA.colWht:Colorize(", ") .. CA.colTel:Colorize("Tel Var Bonus") .. CA.colWht:Colorize(": ") .. ADcol:Colorize("+"..aldTot.."%").. zo_strformat(" |t16:16:<<X:1>>|t", "EsoUI/Art/Currency/currency_telvar.dds"))
		d(CA.colEbo:Colorize("     Ebonheart Pact") .. CA.colWht:Colorize(": Districts: ") .. CA.colOng:Colorize(eboNum) .. CA.colWht:Colorize(", ") .. CA.colTel:Colorize("Tel Var Bonus") .. CA.colWht:Colorize(": ") .. EPcol:Colorize("+"..eboTot.."%").. zo_strformat(" |t16:16:<<X:1>>|t", "EsoUI/Art/Currency/currency_telvar.dds"))
		d(CA.colDag:Colorize("     Daggerfall Covenant") .. CA.colWht:Colorize(": Districts: ") .. CA.colOng:Colorize(dagNum) .. CA.colWht:Colorize(", ") .. CA.colTel:Colorize("Tel Var Bonus") .. CA.colWht:Colorize(": ") .. DCcol:Colorize("+"..dagTot.."%").. zo_strformat(" |t16:16:<<X:1>>|t", "EsoUI/Art/Currency/currency_telvar.dds"))
	end
end

function CA.CampaignQueue(eventCode, campaignId, isGroup, position)

	local queueType

	if (not CA.vars.showQueue) then
		do return end
	end

	local campaignName = GetCampaignName(campaignId)
	if (isGroup) then
		queueType = " (Group)"
	elseif (not isGroup) then
		queueType = " (Solo)"
	else
	end

	if (CA.timerIdTaken) then
		CA_ACE:CancelTimer(CA.timerIdTaken)
	end

	local queueText = CA.colGrn:Colorize(campaignName) .. CA.colWht:Colorize(" Queue Position: " .. position .. queueType)
	
	if (CA.vars.chatOutput) then
		d(queueText)
	end
	
	if (not CA.vars.onlyChat) then
		CA.NotifyMessage(queueText,CSA_EVENT_SMALL_TEXT,"Quest_ObjectivesIncrement")

		CA.timerId = CA_ACE:ScheduleTimer("ClearNotify", CA.vars.notifyDelay)
	end
end
	

function CA.OnAllianceOwnerChanged(eventCode, keepId, battlegroundContext, owningAlliance)
--	d("CA Debug: Owner Changed, BGContext " .. battlegroundContext)
	if (not CA.keepsReady) then
		do return end
	end

	local keepType = GetKeepType(keepId)

	if ((CA.vars.outside == false) and (not IsInCampaign())) then
		do return end
	end

	if ((CA.vars.inside == false) and (IsInImperialCity()) and (keepType ~= KEEPTYPE_IMPERIAL_CITY_DISTRICT)) then
		do return end
	end
	
	if (CA.vars.showOwnerChanged == false) then
		do return end
	end

	if (CA.vars.showTowns == false) and (keepType == KEEPTYPE_TOWN) then
		do return end
	end

	if (CA.vars.showDistricts == false) and (keepType == KEEPTYPE_IMPERIAL_CITY_DISTRICT) then
		do return end
	end

	if (CA.vars.showDistrictsOut == false) and (keepType == KEEPTYPE_IMPERIAL_CITY_DISTRICT) and (not IsInImperialCity()) then
		do return end
	end

	local keepName = GetKeepName(keepId)
	local allianceName = GetAllianceName(owningAlliance)
	local oldAlliance = CA.ua[keepId][2]
	if ((owningAlliance == ALLIANCE_DAGGERFALL_COVENANT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colDag
	elseif ((owningAlliance == ALLIANCE_ALDMERI_DOMINION) and (CA.vars.allianceColors)) then
		allianceCol = CA.colAld
	elseif ((owningAlliance == ALLIANCE_EBONHEART_PACT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colEbo
	else
		allianceCol = CA.colOng
	end
	if ((oldAlliance == ALLIANCE_DAGGERFALL_COVENANT) and (CA.vars.allianceColors)) then
		oldCol = CA.colDag
	elseif ((oldAlliance == ALLIANCE_ALDMERI_DOMINION) and (CA.vars.allianceColors)) then
		oldCol = CA.colAld
	elseif ((oldAlliance == ALLIANCE_EBONHEART_PACT) and (CA.vars.allianceColors)) then
		oldCol = CA.colEbo
	else
		oldCol = CA.colOng
	end

	local TVbonus
	local ownTot
	local oldTot

	if keepType == KEEPTYPE_IMPERIAL_CITY_DISTRICT then
		TVbonus = GetDistrictOwnershipTelVarBonusPercent(keepId, BGQUERY_LOCAL)
		ownTot = 0
		oldTot = 0
		for i = 141,143 do
			if (CA.ua[i][2] == owningAlliance) then
				ownTot = ownTot + GetDistrictOwnershipTelVarBonusPercent(i, BGQUERY_LOCAL)
			elseif (CA.ua[i][2] == oldAlliance) then
				oldTot = oldTot + GetDistrictOwnershipTelVarBonusPercent(i, BGQUERY_LOCAL)
			end
		end
		for i = 146,148 do
			if (CA.ua[i][2] == owningAlliance) then
				ownTot = ownTot + GetDistrictOwnershipTelVarBonusPercent(i, BGQUERY_LOCAL)
			elseif (CA.ua[i][2] == oldAlliance) then
				oldTot = oldTot + GetDistrictOwnershipTelVarBonusPercent(i, BGQUERY_LOCAL)
			end
		end
	end

	if (CA.vars.onlyMyAlliance and (myAlliance ~= owningAlliance and myAlliance ~= oldAlliance)) then
		do return end
	end

	if (CA.timerIdTaken) then
		CA_ACE:CancelTimer(CA.timerIdTaken)
	end

	local captureText = allianceCol:Colorize(allianceName) .. CA.colWht:Colorize(" has captured ") .. oldCol:Colorize(keepName)
	local newTelvar
	local oldTelvar
	if keepType == KEEPTYPE_IMPERIAL_CITY_DISTRICT then
		newTelvar = allianceCol:Colorize(allianceName) .. CA.colGrn:Colorize(" +"..TVbonus.."% ") .. zo_strformat("|t16:16:<<X:1>>|t", "EsoUI/Art/Currency/currency_telvar.dds") .. CA.colWht:Colorize(" in Districts  (Total ") .. CA.colTel:Colorize("+"..ownTot+TVbonus.."%") .. CA.colWht:Colorize(")")
		oldTelvar = oldCol:Colorize(GetAllianceName(oldAlliance)) .. CA.colRed:Colorize(" -"..TVbonus.."% ") .. zo_strformat("|t16:16:<<X:1>>|t", "EsoUI/Art/Currency/currency_telvar.dds") .. CA.colWht:Colorize(" in Districts  (Total ") .. CA.colTel:Colorize("+"..oldTot-TVbonus.."%") .. CA.colWht:Colorize(")")
		newTelvar2 = allianceCol:Colorize(allianceName) .. CA.colGrn:Colorize(" +"..TVbonus.."% ") .. zo_strformat("|t30:30:<<X:1>>|t", "EsoUI/Art/Currency/currency_telvar_32.dds") .. CA.colWht:Colorize(" in Districts  (Total ") .. CA.colTel:Colorize("+"..ownTot+TVbonus.."%") .. CA.colWht:Colorize(")")
		oldTelvar2 = oldCol:Colorize(GetAllianceName(oldAlliance)) .. CA.colRed:Colorize(" -"..TVbonus.."% ") .. zo_strformat("|t30:30:<<X:1>>|t", "EsoUI/Art/Currency/currency_telvar_32.dds") .. CA.colWht:Colorize(" in Districts  (Total ") .. CA.colTel:Colorize("+"..oldTot-TVbonus.."%") .. CA.colWht:Colorize(")")
	end
	
	if (CA.vars.chatOutput) then
		d(captureText)
		if (CA.vars.showTelvar) and keepType == KEEPTYPE_IMPERIAL_CITY_DISTRICT then
			d(newTelvar)
			d(oldTelvar)
		end
	end

	local CSAcat
	if CA.vars.keepCapture == "Major" then
		CSAcat = CSA_EVENT_LARGE_TEXT
	else
		CSAcat = CSA_EVENT_SMALL_TEXT
	end
	
	if (not CA.vars.onlyChat) then
		CA.NotifyTakenMessage(captureText,CSAcat,"ElderScroll_Captured_Aldmeri")

		if (CA.vars.showTelvar) and keepType == KEEPTYPE_IMPERIAL_CITY_DISTRICT then
			CA.NotifyExtraMessage(newTelvar2 .. "\n" .. oldTelvar2,CSA_EVENT_SMALL_TEXT,"Telvar_MultiplierUp")
		end

		CA.timerIdTaken = CA_ACE:ScheduleTimer("ClearNotifyTaken", CA.vars.notifyDelay)
		CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
	end

end

function CA.OnKeepUnderAttackChanged(eventCode, keepId, battlegroundContext, underAttack)
--	d("CA Debug: Attack Status Changed, BGContext " .. battlegroundContext)
	if (not CA.keepsReady) then
		do return end
	end

	local keepType = GetKeepType(keepId)

	local keepAlliance = GetKeepAlliance(keepId, battlegroundContext)
	if (underAttack) then
		CA.ua[keepId][1]=1
		CA.ua[keepId][2]=keepAlliance
	end
	if (not underAttack) then
		CA.ua[keepId][1]=0
		CA.ua[keepId][2]=keepAlliance
	end


	if ((CA.vars.outside == false) and (not IsInCampaign())) then
		do return end
	end
	
	if ((CA.vars.inside == false) and (IsInImperialCity()) and (keepType ~= KEEPTYPE_IMPERIAL_CITY_DISTRICT)) then
		do return end
	end

	if (CA.vars.showTowns == false) and (keepType == KEEPTYPE_TOWN) then
		do return end
	end

	if (CA.vars.showDistricts == false) and (keepType == KEEPTYPE_IMPERIAL_CITY_DISTRICT) then
		do return end
	end

	if (CA.vars.showDistrictsOut == false) and (keepType == KEEPTYPE_IMPERIAL_CITY_DISTRICT) and (not IsInImperialCity()) then
		do return end
	end

	local keepName = GetKeepName(keepId)

	
	--Efficiently get the number of sieges
	local defendSiege = GetNumSieges(keepId, battlegroundContext, keepAlliance)
	local allSiege = GetNumSieges(keepId, battlegroundContext, ALLIANCE_ALDMERI_DOMINION)
	allSiege = allSiege + GetNumSieges(keepId, battlegroundContext, ALLIANCE_DAGGERFALL_COVENANT)
	allSiege = allSiege + GetNumSieges(keepId, battlegroundContext, ALLIANCE_EBONHEART_PACT)
	local adSiege = GetNumSieges(keepId, battlegroundContext, ALLIANCE_ALDMERI_DOMINION)
	local dcSiege = GetNumSieges(keepId, battlegroundContext, ALLIANCE_DAGGERFALL_COVENANT)
	local epSiege = GetNumSieges(keepId, battlegroundContext, ALLIANCE_EBONHEART_PACT)
	local mySiege = GetNumSieges(keepId, battlegroundContext, myAlliance)
	local attackSiege = allSiege - defendSiege


	local allianceName = GetAllianceName(keepAlliance)
	if ((keepAlliance == ALLIANCE_DAGGERFALL_COVENANT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colDag
	elseif ((keepAlliance == ALLIANCE_ALDMERI_DOMINION) and (CA.vars.allianceColors)) then
		allianceCol = CA.colAld
	elseif ((keepAlliance == ALLIANCE_EBONHEART_PACT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colEbo
	else
		allianceCol = CA.colOng
	end

	if (CA.vars.onlyMyAlliance and (myAlliance ~= keepAlliance and mySiege == 0)) then
		do return end
	end

	if (CA.timerId) then
		CA_ACE:CancelTimer(CA.timerId)
	end

	local uaText = allianceCol:Colorize(keepName) .. CA.colWht:Colorize(" is under attack!")
	local notuaText = allianceCol:Colorize(keepName) .. CA.colWht:Colorize(" is no longer under attack")
	local siegesTextAll = CA.colWht:Colorize("     Sieges: A:") .. CA.colRed:Colorize(attackSiege) .. CA.colWht:Colorize(" / D:") .. CA.colGrn:Colorize(defendSiege) .. CA.colWht:Colorize("  (") .. CA.colAld:Colorize(adSiege) .. CA.colWht:Colorize(", ") .. CA.colDag:Colorize(dcSiege) .. CA.colWht:Colorize(", ") .. CA.colEbo:Colorize(epSiege) .. CA.colWht:Colorize(")")
	local siegesTextAttDef = CA.colWht:Colorize("     Sieges: Att: ") .. CA.colRed:Colorize(attackSiege) .. CA.colWht:Colorize(" / Def:") .. CA.colGrn:Colorize(defendSiege)
	local siegesTextAlliance = CA.colWht:Colorize("     Sieges: AD: ") .. CA.colAld:Colorize(adSiege) .. CA.colWht:Colorize(", DC: ") .. CA.colDag:Colorize(dcSiege) .. CA.colWht:Colorize(", EP: ") .. CA.colEbo:Colorize(epSiege) .. CA.colWht:Colorize(")")
	local siegesTextNone = CA.colWht:Colorize("     Sieges: None")
	
	if (underAttack) and (CA.vars.showAttack) then
		if (CA.vars.chatOutput) then
		d(uaText)
			if (allSiege ~= 0) and (keepType ~= KEEPTYPE_IMPERIAL_CITY_DISTRICT and keepType ~= KEEPTYPE_TOWN) then
				if (CA.vars.siegesAttDef) and (CA.vars.siegesByAlliance) then
					d(siegesTextAll)
				elseif (CA.vars.siegesAttDef) and (not CA.vars.siegesByAlliance) then
					d(siegesTextAttDef)
				elseif (not CA.vars.siegesAttDef) and (CA.vars.siegesByAlliance) then
					d(siegesTextAlliance)
				end
			elseif (allSiege == 0) and (keepType ~= KEEPTYPE_IMPERIAL_CITY_DISTRICT and keepType ~= KEEPTYPE_TOWN) and ((CA.vars.siegesAttDef) or (CA.vars.siegesByAlliance)) then
				d(siegesTextNone)
			end
		end
		
		if (not CA.vars.onlyChat) then
			if (not CA.vars.siegesAttDef) and (not CA.vars.siegesByAlliance) then
				CA.NotifyMessage(uaText,CSA_EVENT_SMALL_TEXT,"AvA_Gate_Opened")
			else
				if (allSiege ~= 0) and (keepType ~= KEEPTYPE_IMPERIAL_CITY_DISTRICT and keepType ~= KEEPTYPE_TOWN) then
					if (CA.vars.siegesAttDef) and (CA.vars.siegesByAlliance) then
						CA.NotifyMessage(uaText .. siegesTextAll,CSA_EVENT_SMALL_TEXT,"AvA_Gate_Opened")
					elseif (CA.vars.siegesAttDef) and (not CA.vars.siegesByAlliance) then
						CA.NotifyMessage(uaText .. siegesTextAttDef,CSA_EVENT_SMALL_TEXT,"AvA_Gate_Opened")
					elseif (not CA.vars.siegesAttDef) and (CA.vars.siegesByAlliance) then
						CA.NotifyMessage(uaText .. siegesTextAlliance,CSA_EVENT_SMALL_TEXT,"AvA_Gate_Opened")
					else
						CA.NotifyMessage(uaText,CSA_EVENT_SMALL_TEXT,"AvA_Gate_Opened")
					end
				elseif (allSiege == 0) and (keepType ~= KEEPTYPE_IMPERIAL_CITY_DISTRICT and keepType ~= KEEPTYPE_TOWN) then
					if (CA.vars.siegesAttDef) or (CA.vars.siegesByAlliance) then
						CA.NotifyMessage(uaText .. siegesTextNone,CSA_EVENT_SMALL_TEXT,"AvA_Gate_Opened")
					else
						CA.NotifyMessage(uaText,CSA_EVENT_SMALL_TEXT,"AvA_Gate_Opened")
					end
				else
						CA.NotifyMessage(uaText,CSA_EVENT_SMALL_TEXT,"AvA_Gate_Opened")
				end
			end

			CA.timerId = CA_ACE:ScheduleTimer("ClearNotify", CA.vars.notifyDelay)
		end
	elseif (not underAttack) and (CA.vars.showAttackEnd) then
		if (CA.vars.chatOutput) then
			d(notuaText)
		end
		
		if (not CA.vars.onlyChat) then
			CA.NotifyMessage(notuaText,CSA_EVENT_SMALL_TEXT,"AvA_Gate_Closed")

			CA.timerId = CA_ACE:ScheduleTimer("ClearNotify", CA.vars.notifyDelay)
		end
	end
end



function CA.OnGateChanged(eventCode, keepId, open)
	if (not CA.keepsReady) then
		do return end
	end

	if ((CA.vars.outside == false) and (not IsInCampaign())) then
		do return end
	end
	
	if ((CA.vars.inside == false) and (IsInImperialCity())) then
		do return end
	end
	
	local keepName = GetKeepName(keepId)
	local keepAlliance = GetKeepAlliance(keepId, BGQUERY_LOCAL)
	if ((keepAlliance == ALLIANCE_DAGGERFALL_COVENANT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colDag
	elseif ((keepAlliance == ALLIANCE_ALDMERI_DOMINION) and (CA.vars.allianceColors)) then
		allianceCol = CA.colAld
	elseif ((keepAlliance == ALLIANCE_EBONHEART_PACT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colEbo
	else
		allianceCol = CA.colOng
	end
	
	if (CA.timerIdExtra) then
		CA_ACE:CancelTimer(CA.timerIdExtra)
	end
	
	if (not CA.vars.showGates) then
		do return end
	end

	local openText = CA.colWht:Colorize("The ") .. allianceCol:Colorize(keepName) .. CA.colWht:Colorize(" is open!")
	local closedText = CA.colWht:Colorize("The ") .. allianceCol:Colorize(keepName) .. CA.colWht:Colorize(" is closed!")	

	if (open) then
		if (CA.vars.chatOutput) then
			d(openText)
		end
		
		if ((not CA.vars.onlyChat) and (CA.vars.vanillaAvA)) then
			CA.NotifyExtraMessage(openText,CSA_EVENT_SMALL_TEXT,"AvA_Gate_Opened")

			CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
		end
	else
		if (CA.vars.chatOutput) then
			d(closedText)
		end
		
		if ((not CA.vars.onlyChat) and (CA.vars.vanillaAvA)) then
			CA.NotifyExtraMessage(closedText,CSA_EVENT_SMALL_TEXT,"AvA_Gate_Closed")

			CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
		end
	end
end


function CA.OnDeposeEmperor(eventCode, campaignId, emperorName, emperorAlliance, abdication)
	if ((CA.vars.outside == false) and (not IsInCampaign())) then
		do return end
	end
	
	if ((CA.vars.inside == false) and (IsInImperialCity())) then
		do return end
	end
	
	if (not CA.vars.showEmperors) then
		do return end
	end

	local allianceName = GetAllianceName(emperorAlliance)
	if ((emperorAlliance == ALLIANCE_DAGGERFALL_COVENANT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colDag
	elseif ((emperorAlliance == ALLIANCE_ALDMERI_DOMINION) and (CA.vars.allianceColors)) then
		allianceCol = CA.colAld
	elseif ((emperorAlliance == ALLIANCE_EBONHEART_PACT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colEbo
	else
		allianceCol = CA.colOng
	end
	
	if (CA.timerIdExtra) then
		CA_ACE:CancelTimer(CA.timerIdExtra)
	end
	
	if (GetCurrentCampaignId() ~= GetAssignedCampaignId()) then
		homeCamp = CA.colWht:Colorize("(" .. GetCampaignName(campaignId) .. ") ")
	else
		homeCamp = ""
	end

	local abdicateText = homeCamp .. CA.colWht:Colorize("Emperor ") .. CA.colGrn:Colorize(emperorName) .. CA.colWht:Colorize(" of ") .. allianceCol:Colorize(allianceName) .. CA.colWht:Colorize(" has abdicated!")
	local deposeText = homeCamp .. CA.colWht:Colorize("Emperor ") .. CA.colGrn:Colorize(emperorName) .. CA.colWht:Colorize(" of ") .. allianceCol:Colorize(allianceName) .. CA.colWht:Colorize(" has been deposed!")

	if (CA.vars.chatOutput) then
		if (abdication) then
			d(abdicateText)
		else
			d(deposeText)
		end
	end
	
	if ((not CA.vars.onlyChat) and (CA.vars.vanillaAvA)) then
		if (abdication) then
			CA.NotifyExtraMessage(abdicateText,CSA_EVENT_SMALL_TEXT,"Emperor_Abdicated")
		else
			CA.NotifyExtraMessage(deposeText,CSA_EVENT_SMALL_TEXT,"Emperor_Abdicated")
		end
		CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
	end

end

function CA.OnCoronateEmperor(eventCode, campaignId, emperorName, emperorAlliance)
	if ((CA.vars.outside == false) and (not IsInCampaign())) then
		do return end
	end
	
	if ((CA.vars.inside == false) and (IsInImperialCity())) then
		do return end
	end
	
	if (not CA.vars.showEmperors) then
		do return end
	end

	local allianceName = GetAllianceName(emperorAlliance)
	if ((emperorAlliance == ALLIANCE_DAGGERFALL_COVENANT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colDag
	elseif ((emperorAlliance == ALLIANCE_ALDMERI_DOMINION) and (CA.vars.allianceColors)) then
		allianceCol = CA.colAld
	elseif ((emperorAlliance == ALLIANCE_EBONHEART_PACT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colEbo
	else
		allianceCol = CA.colOng
	end
	
	if (CA.timerIdExtra) then
		CA_ACE:CancelTimer(CA.timerIdExtra)
	end

	if (GetCurrentCampaignId() ~= GetAssignedCampaignId()) then
		homeCamp = CA.colWht:Colorize("(" .. GetCampaignName(campaignId) .. ") ")
	else
		homeCamp = ""
	end

	local coronateText = homeCamp .. CA.colWht:Colorize("Emperor ") .. CA.colGrn:Colorize(emperorName) .. CA.colWht:Colorize(" of ") .. allianceCol:Colorize(allianceName) .. CA.colWht:Colorize(" has been crowned Emperor!")
	
	if (CA.vars.chatOutput) then
		d(coronateText)
	end
	
	if ((not CA.vars.onlyChat) and (CA.vars.vanillaAvA)) then
		CA.NotifyExtraMessage(coronateText,CSA_EVENT_SMALL_TEXT,"Emperor_Coronated_Aldmeri")

		CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
	end

end

function CA.OnArtifactControlState(eventCode, artifactName, keepId, playerName, playerAlliance, controlEvent, controlState, campaignId)
--	d("CA Debug: Artifact Control State, " .. artifactName .. ", Keep ID:" .. keepId .. ", Player: " .. playerName .. " of " .. playerAlliance)
--	local ctrlEvent = {[0]="Under Attack","Lost","Captured","Recaptured","Assaulted","Fully Held","Area Neutral","Flag Taken","Flag Returned","Flag Dropped","Flad Returned by Timer","None"}
--	local ctrlState = {[0]="Flag at Base","Flag Dropped","","Flag Held","Flag at Enemy Base","Area No Control","Area Below Control Threshold","Area Above Control Threshold","Area Max Control","Point Transitioning","Point Controlled","Unknown"}
--	d("Control Event: " .. ctrlEvent[controlEvent])
--	d("Control State: " .. ctrlState[controlState])

	local keepType = GetKeepType(keepId)

	if ((CA.vars.outside == false) and (not IsInCampaign())) then
		do return end
	end
	
	if ((CA.vars.inside == false) and (IsInImperialCity())) then
		do return end
	end
	
	if (CA.vars.showScrolls == false) then
		do return end
	end

	local allianceName = GetAllianceName(playerAlliance)
	if ((playerAlliance == ALLIANCE_DAGGERFALL_COVENANT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colDag
	elseif ((playerAlliance == ALLIANCE_ALDMERI_DOMINION) and (CA.vars.allianceColors)) then
		allianceCol = CA.colAld
	elseif ((playerAlliance == ALLIANCE_EBONHEART_PACT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colEbo
	else
		allianceCol = CA.colOng
	end

	local keepName = GetKeepName(keepId)
	if keepId == 0 then
		keepName = "(N/A)"
	end
	local keepAlliance = GetKeepAlliance(keepId, BGQUERY_LOCAL)

	if ((keepAlliance == ALLIANCE_DAGGERFALL_COVENANT) and (CA.vars.allianceColors)) then
		keepCol = CA.colDag
	elseif ((keepAlliance == ALLIANCE_ALDMERI_DOMINION) and (CA.vars.allianceColors)) then
		keepCol = CA.colAld
	elseif ((keepAlliance == ALLIANCE_EBONHEART_PACT) and (CA.vars.allianceColors)) then
		keepCol = CA.colEbo
	else
		keepCol = CA.colOng
	end
	
	if (CA.timerIdExtra) then
		CA_ACE:CancelTimer(CA.timerIdExtra)
	end

	if (GetCurrentCampaignId() ~= GetAssignedCampaignId()) then
		homeCamp = CA.colWht:Colorize("(" .. GetCampaignName(campaignId) .. ") ")
		if (GetCurrentCampaignId() ~= campaignId) then
			keepCol = CA.colOng
		end
	else
		homeCamp = ""
	end

	local pickupText = homeCamp .. CA.colGrn:Colorize(playerName) .. CA.colWht:Colorize(" of ") .. allianceCol:Colorize(allianceName) .. CA.colWht:Colorize(" has picked up ") .. CA.colOng:Colorize(artifactName)
	local takenText = homeCamp .. CA.colGrn:Colorize(playerName) .. CA.colWht:Colorize(" of ") .. allianceCol:Colorize(allianceName) .. CA.colWht:Colorize(" has taken ") .. CA.colOng:Colorize(artifactName) .. CA.colWht:Colorize(" from ") .. keepCol:Colorize(keepName)
	local droppedText = homeCamp .. CA.colGrn:Colorize(playerName) .. CA.colWht:Colorize(" of ") .. allianceCol:Colorize(allianceName) .. CA.colWht:Colorize(" has dropped ") .. CA.colOng:Colorize(artifactName)
	local capturedText = homeCamp .. CA.colGrn:Colorize(playerName) .. CA.colWht:Colorize(" of ") .. allianceCol:Colorize(allianceName) .. CA.colWht:Colorize(" has secured ") .. CA.colOng:Colorize(artifactName) .. CA.colWht:Colorize(" at ") .. keepCol:Colorize(keepName)
	local returnedText = homeCamp .. CA.colGrn:Colorize(playerName) .. CA.colWht:Colorize(" of ") .. allianceCol:Colorize(allianceName) .. CA.colWht:Colorize(" has returned ") .. CA.colOng:Colorize(artifactName) .. CA.colWht:Colorize(" to ") .. keepCol:Colorize(keepName)
	local timedoutText = homeCamp .. CA.colOng:Colorize(artifactName) .. CA.colWht:Colorize(" has returned to ") .. keepCol:Colorize(keepName) .. CA.colWht:Colorize(" (timed out)")
	
	if (controlEvent == OBJECTIVE_CONTROL_EVENT_FLAG_TAKEN) then	
		if (keepId == 0) then
			if (CA.vars.chatOutput) then
				d(pickupText)
			end
				
			if ((not CA.vars.onlyChat) and (CA.vars.vanillaAvA)) then
				CA.NotifyExtraMessage(pickupText,CSA_EVENT_SMALL_TEXT,"ElderScroll_Captured_Aldmeri")
			
				CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
			end
		else
			if (CA.vars.chatOutput) then
				d(takenText)
			end
				
			if ((not CA.vars.onlyChat) and (CA.vars.vanillaAvA)) then
				CA.NotifyExtraMessage(takenText,CSA_EVENT_SMALL_TEXT,"ElderScroll_Captured_Aldmeri")
				
				CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
			end
		end
			
	elseif (controlEvent == OBJECTIVE_CONTROL_EVENT_FLAG_DROPPED) then
		if (CA.vars.chatOutput) then
			d(droppedText)
		end
	
		if ((not CA.vars.onlyChat) and (CA.vars.vanillaAvA)) then
			CA.NotifyExtraMessage(droppedText,CSA_EVENT_SMALL_TEXT,"ElderScroll_Captured_Aldmeri")

			CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
		end

	elseif (controlEvent == OBJECTIVE_CONTROL_EVENT_CAPTURED) then
		if (CA.vars.chatOutput) then
			d(capturedText)
		end
	
		if ((not CA.vars.onlyChat) and (CA.vars.vanillaAvA)) then
			CA.NotifyExtraMessage(capturedText,CSA_EVENT_SMALL_TEXT,"ElderScroll_Captured_Aldmeri")

			CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
		end

	elseif (controlEvent == OBJECTIVE_CONTROL_EVENT_FLAG_RETURNED) then
		if (CA.vars.chatOutput) then
			d(returnedText)
		end
	
		if ((not CA.vars.onlyChat) and (CA.vars.vanillaAvA)) then
			CA.NotifyExtraMessage(returnedText,CSA_EVENT_SMALL_TEXT,"ElderScroll_Captured_Aldmeri")

			CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
		end

	elseif (controlEvent == OBJECTIVE_CONTROL_EVENT_FLAG_RETURNED_BY_TIMER) then
		if (CA.vars.chatOutput) then
			d(timedoutText)
		end
	
		if ((not CA.vars.onlyChat) and (CA.vars.vanillaAvA)) then
			CA.NotifyExtraMessage(timedoutText,CSA_EVENT_SMALL_TEXT,"ElderScroll_Captured_Aldmeri")

			CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
		end
	end
end

function CA.OnObjectiveControlState(eventCode, keepId, objectiveId, battlegroundContext, objectiveName, objectiveType, controlEvent, controlState, param1, param2)
--	d("CA Debug: Objective Control State, ID " .. objectiveId .. ": " .. objectiveName .. ", Param 1: " .. param1 .. ", Param 2: " .. param2)
--	local objType = {[0]="Default","Flag Capture","","Capture Point","Capture Area","Assault","Return","Ball","Artifact Offensive","Artifact Defensive","Artifact Return"}
--	local ctrlEvent = {[0]="Under Attack","Lost","Captured","Recaptured","Assaulted","Fully Held","Area Neutral","Flag Taken","Flag Returned","Flag Dropped","Flad Returned by Timer","None"}
--	local ctrlState = {[0]="Flag at Base","Flag Dropped","","Flag Held","Flag at Enemy Base","Area No Control","Area Below Control Threshold","Area Above Control Threshold","Area Max Control","Point Transitioning","Point Controlled","Unknown"}
--	d("Objective Type: " .. objType[objectiveType])
--	d("Control Event: " .. ctrlEvent[controlEvent])
--	d("Control State: " .. ctrlState[controlState])
	if (not CA.keepsReady) then
		do return end
	end

	local keepType = GetKeepType(keepId)

	if ((CA.vars.outside == false) and (not IsInCampaign())) then
		do return end
	end
	
	if ((CA.vars.inside == false) and (IsInImperialCity())) and (keepType ~= KEEPTYPE_IMPERIAL_CITY_DISTRICT) then
		do return end
	end

	if (CA.vars.showTowns == false) and (keepType == KEEPTYPE_TOWN) then
		do return end
	end
	
	if (CA.vars.showDistricts == false) and (keepType == KEEPTYPE_IMPERIAL_CITY_DISTRICT) then
		do return end
	end

	if (CA.vars.showDistrictsOut == false) and (keepType == KEEPTYPE_IMPERIAL_CITY_DISTRICT) and (not IsInImperialCity()) then
		do return end
	end

	if (CA.vars.showFlags == false) then
		do return end
	end

	if (CA.vars.showFlagsResources == false) and (keepType == KEEPTYPE_RESOURCE) then
--		d("CA Debug: Objective Control State, ID " .. objectiveId .. ": " .. objectiveName .. ", identified as Resource")
		do return end
	end
	if (CA.vars.showFlagsTowns == false) and (keepType == KEEPTYPE_TOWN) then
--		d("CA Debug: Objective Control State, ID " .. objectiveId .. ": " .. objectiveName .. ", identified as Town")
		do return end
	end
	if (CA.vars.showFlagsDistricts == false) and (keepType == KEEPTYPE_IMPERIAL_CITY_DISTRICT) then
--		d("CA Debug: Objective Control State, ID " .. objectiveId .. ": " .. objectiveName .. ", identified as District")
		do return end
	end

	local keepName = GetKeepName(keepId)
	local keepAlliance = CA.ua[keepId][2]
	local allianceName = GetAllianceName(param1)
	if ((param1 == ALLIANCE_DAGGERFALL_COVENANT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colDag
	elseif ((param1 == ALLIANCE_ALDMERI_DOMINION) and (CA.vars.allianceColors)) then
		allianceCol = CA.colAld
	elseif ((param1 == ALLIANCE_EBONHEART_PACT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colEbo
	else
		allianceCol = CA.colOng
	end
	if ((keepAlliance == ALLIANCE_DAGGERFALL_COVENANT) and (CA.vars.allianceColors)) then
		keepCol = CA.colDag
	elseif ((keepAlliance == ALLIANCE_ALDMERI_DOMINION) and (CA.vars.allianceColors)) then
		keepCol = CA.colAld
	elseif ((keepAlliance == ALLIANCE_EBONHEART_PACT) and (CA.vars.allianceColors)) then
		keepCol = CA.colEbo
	else
		keepCol = CA.colOng
	end

	if (CA.vars.onlyMyAlliance and (myAlliance ~= keepAlliance and myAlliance ~= param1)) then
		do return end
	end

	local capturedText = allianceCol:Colorize(allianceName) .. CA.colWht:Colorize(" has captured ") .. CA.colOng:Colorize(objectiveName)
	local recapturedText = allianceCol:Colorize(allianceName) .. CA.colWht:Colorize(" has recaptured ") .. CA.colOng:Colorize(objectiveName)
	local neutralText = CA.colOng:Colorize(objectiveName) .. CA.colWht:Colorize(" has fallen to ") .. CA.colGrn:Colorize("No Control")

	if (objectiveType == OBJECTIVE_CAPTURE_AREA) then

		if ((controlEvent == OBJECTIVE_CONTROL_EVENT_CAPTURED) or (controlEvent == OBJECTIVE_CONTROL_EVENT_RECAPTURED) or (controlEvent == OBJECTIVE_CONTROL_EVENT_AREA_NEUTRAL)) then
			if (CA.timerIdExtra) then
				CA_ACE:CancelTimer(CA.timerIdExtra)
			end
		end
	
		if (controlEvent == OBJECTIVE_CONTROL_EVENT_CAPTURED) then
	
			if (CA.vars.chatOutput) then
				d(capturedText)
			end
			
			if (not CA.vars.onlyChat) then
				CA.NotifyExtraMessage(capturedText,CSA_EVENT_SMALL_TEXT,"Justice_NowKOS")
		
				CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
			end
	
		elseif (controlEvent == OBJECTIVE_CONTROL_EVENT_RECAPTURED) then
	
			if (CA.vars.chatOutput) then
				d(recapturedText)
			end
			
			if (not CA.vars.onlyChat) then
				CA.NotifyExtraMessage(recapturedText,CSA_EVENT_SMALL_TEXT,"Justice_NowKOS")
		
				CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
			end

		elseif (controlEvent == OBJECTIVE_CONTROL_EVENT_AREA_NEUTRAL and CA.vars.showFlagsNeutral == true) then
	
			if (CA.vars.chatOutput) then
				d(neutralText)
			end
			
			if (not CA.vars.onlyChat) then
				CA.NotifyExtraMessage(neutralText,CSA_EVENT_SMALL_TEXT,"Justice_NowKOS")
		
				CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
			end

		end
	end

end

function CA.OnClaimKeep(eventCode, campaignId, keepId, guildName, playerName)
	if (not CA.keepsReady) then
		do return end
	end

	local keepType = GetKeepType(keepId)

	if ((CA.vars.outside == false) and (not IsInCampaign())) then
		do return end
	end
	
	if ((CA.vars.inside == false) and (IsInImperialCity())) and (keepType ~= KEEPTYPE_IMPERIAL_CITY_DISTRICT) then
		do return end
	end
	
	if (not CA.vars.showClaim) then
		do return end
	end

	local keepName = GetKeepName(keepId)
	local keepAlliance = CA.ua[keepId][2]
	local allianceName = GetAllianceName(keepAlliance)
	if ((keepAlliance == ALLIANCE_DAGGERFALL_COVENANT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colDag
	elseif ((keepAlliance == ALLIANCE_ALDMERI_DOMINION) and (CA.vars.allianceColors)) then
		allianceCol = CA.colAld
	elseif ((keepAlliance == ALLIANCE_EBONHEART_PACT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colEbo
	else
		allianceCol = CA.colOng
	end

	if (CA.vars.onlyMyAlliance and myAlliance ~= keepAlliance) then
		do return end
	end
	
	if (CA.timerIdExtra) then
		CA_ACE:CancelTimer(CA.timerIdExtra)
	end
	
	if (GetCurrentCampaignId() ~= GetAssignedCampaignId()) then
		homeCamp = CA.colWht:Colorize("(" .. GetCampaignName(campaignId) .. ") ")
			if (GetCurrentCampaignId() ~= campaignId) then
				allianceCol = CA.colOng
			end
	else
		homeCamp = ""
	end

	local claimText = homeCamp .. CA.colGrn:Colorize(playerName) .. CA.colWht:Colorize(" has claimed ") .. allianceCol:Colorize(keepName) .. CA.colWht:Colorize(" for ") .. CA.colBlu:Colorize(guildName)

	if (CA.vars.chatOutput) then
		d(claimText)
	end
	
	if (not CA.vars.onlyChat) then
		CA.NotifyExtraMessage(claimText,CSA_EVENT_SMALL_TEXT,"Quest_Complete")

		CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
	end

end

function CA.OnImperialAccessGained(eventCode, campaignId, alliance)
	if ((CA.vars.outside == false) and (not IsInCampaign())) then
		do return end
	end
	
	if (not CA.vars.showImperial) then
		do return end
	end

	local allianceName = GetAllianceName(alliance)
	if ((alliance == ALLIANCE_DAGGERFALL_COVENANT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colDag
	elseif ((alliance == ALLIANCE_ALDMERI_DOMINION) and (CA.vars.allianceColors)) then
		allianceCol = CA.colAld
	elseif ((alliance == ALLIANCE_EBONHEART_PACT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colEbo
	else
		allianceCol = CA.colOng
	end
	
	if (CA.timerIdExtra) then
		CA_ACE:CancelTimer(CA.timerIdExtra)
	end

	if (GetCurrentCampaignId() ~= GetAssignedCampaignId()) then
		homeCamp = CA.colWht:Colorize("(" .. GetCampaignName(campaignId) .. ") ")
	else
		homeCamp = ""
	end

	local myAccess
	if (DoesAllianceHaveImperialCityAccess(CA.campaignId,myAlliance)) and (IsCollectibleUnlocked(GetImperialCityCollectibleId())) then
		myAccess = CA.colWht:Colorize("     (You currently have Imperial City access)")
	else
		myAccess = CA.colGry:Colorize("     (You do not have Imperial City access)")
	end

	local icgainedText = homeCamp .. allianceCol:Colorize(allianceName) .. CA.colWht:Colorize(" has gained access to ") .. CA.colGrn:Colorize("Imperial City") .. CA.colWht:Colorize("!")
	
	if (CA.vars.chatOutput) then
		d(icgainedText)
		d(myAccess)
	end
	
	if ((not CA.vars.onlyChat) and (CA.vars.vanillaAvA)) then
		CA.NotifyExtraMessage(icgainedText .. "\n" .. myAccess,CSA_EVENT_SMALL_TEXT,"AvA_Gate_Opened")

		CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
	end

end

function CA.OnImperialAccessLost(eventCode, campaignId, alliance)
	if ((CA.vars.outside == false) and (not IsInCampaign())) then
		do return end
	end
	
	if (not CA.vars.showImperial) then
		do return end
	end

	local allianceName = GetAllianceName(alliance)
	if ((alliance == ALLIANCE_DAGGERFALL_COVENANT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colDag
	elseif ((alliance == ALLIANCE_ALDMERI_DOMINION) and (CA.vars.allianceColors)) then
		allianceCol = CA.colAld
	elseif ((alliance == ALLIANCE_EBONHEART_PACT) and (CA.vars.allianceColors)) then
		allianceCol = CA.colEbo
	else
		allianceCol = CA.colOng
	end
	
	if (CA.timerIdExtra) then
		CA_ACE:CancelTimer(CA.timerIdExtra)
	end

	if (GetCurrentCampaignId() ~= GetAssignedCampaignId()) then
		homeCamp = CA.colWht:Colorize("(" .. GetCampaignName(campaignId) .. ") ")
	else
		homeCamp = ""
	end
	
	local myAccess
	if (DoesAllianceHaveImperialCityAccess(CA.campaignId,myAlliance)) and (IsCollectibleUnlocked(GetImperialCityCollectibleId())) then
		myAccess = CA.colWht:Colorize("     (You currently have Imperial City access)")
	else
		myAccess = CA.colGry:Colorize("     (You do not have Imperial City access)")
	end

	local iclostText = homeCamp .. allianceCol:Colorize(allianceName) .. CA.colWht:Colorize(" has lost access to ") .. CA.colRed:Colorize("Imperial City") .. CA.colWht:Colorize("!")

	if (CA.vars.chatOutput) then
		d(iclostText)
		d(myAccess)
	end
	
	if ((not CA.vars.onlyChat) and (CA.vars.vanillaAvA)) then
		CA.NotifyExtraMessage(iclostText .. "\n" .. myAccess,CSA_EVENT_SMALL_TEXT,"AvA_Gate_Closed")

		CA.timerIdExtra = CA_ACE:ScheduleTimer("ClearNotifyExtra", CA.vars.notifyDelay)
	end

end

--AvA messages code courtesy of Garkin, from "No, thank you!"
function CA.HookAvAMessages()
    local handlers = ZO_CenterScreenAnnounce_GetHandlers()
    local avaEvents = {
        EVENT_ARTIFACT_CONTROL_STATE,
        EVENT_KEEP_GATE_STATE_CHANGED,
        EVENT_CORONATE_EMPEROR_NOTIFICATION,
        EVENT_DEPOSE_EMPEROR_NOTIFICATION,
        EVENT_IMPERIAL_CITY_ACCESS_GAINED_NOTIFICATION,
        EVENT_IMPERIAL_CITY_ACCESS_LOST_NOTIFICATION,
    }

    local function HookAvAEventHandler(event)
        local original = handlers[event]
        handlers[event] = function(...)
            if ((CA.vars.vanillaAvA == true) and ((IsInCampaign()) or (CA.vars.outside == true) or (CA.vars.vanillaOutside == true))) then
--		d("CA Debug: AvA Messages Event Handler")
		if CA.vars.vanillaChat == true then
                    local _,_,msg = original(...)
                    d(msg)
		end
                return
            else
                return original(...)
            end
        end
    end

    for i = 1, #avaEvents do
        HookAvAEventHandler(avaEvents[i])
    end


    --filter centerscreen announcements which are already in queue
    local messageQueue = CENTER_SCREEN_ANNOUNCE.m_displayQueue
    for i = #messageQueue, 1, -1 do
        for eventIndex = 1, #avaEvents do
            local priority = CENTER_SCREEN_ANNOUNCE:GetPriority(avaEvents[eventIndex])
            if messageQueue[i].priority == priority then
                if ((CA.vars.vanillaAvA == true) and ((IsInCampaign()) or (CA.vars.outside == true) or (CA.vars.vanillaOutside == true))) then
--		    d("CA Debug: AvA Message Queue")
		    if CA.vars.vanillaChat == true then
			d(messageQueue[i][2])
		    end
                    table.remove(messageQueue, i)
                    break
                end
            end
        end
    end
    
end

function CA_ACE:ClearNotify()
	CyrodiilAlertNotify:SetText("")
end

function CA_ACE:ClearNotifyTaken()
	CyrodiilAlertNotifyTaken:SetText("")
end

function CA_ACE:ClearNotifyExtra()
	CyrodiilAlertNotifyExtra:SetText("")
end

function CA.NotifyMessage(message,category,sound)
	if not CA.vars.sound then sound = nil end
	if CA.vars.chooseUI == "ESO UI" then
		CENTER_SCREEN_ANNOUNCE:AddMessage(0, category, sound, message, nil, nil, nil, nil, nil, CA.vars.notifyDelay*1000, nil)
	else
		CyrodiilAlertNotify:SetText(message)
	end
end
function CA.NotifyTakenMessage(message,category,sound)
	if not CA.vars.sound then sound = nil end
	if CA.vars.chooseUI == "ESO UI" then
		CENTER_SCREEN_ANNOUNCE:AddMessage(0, category, sound, message, nil, nil, nil, nil, nil, CA.vars.notifyDelay*1000, nil)
	else
		CyrodiilAlertNotifyTaken:SetText(message)
	end
end
function CA.NotifyExtraMessage(message,category,sound)
	if not CA.vars.sound then sound = nil end
	if CA.vars.chooseUI == "ESO UI" then
		CENTER_SCREEN_ANNOUNCE:AddMessage(0, category, sound, message, nil, nil, nil, nil, nil, CA.vars.notifyDelay*1000, nil)
	else
		CyrodiilAlertNotifyExtra:SetText(message)
	end
end
function CA.NotifyInitMessage(message,category,sound,msg2,msg3)
	if not CA.vars.sound then sound = nil end
	if CA.vars.chooseUI == "ESO UI" then
		CENTER_SCREEN_ANNOUNCE:AddMessage(0, CSA_EVENT_COMBINED_TEXT, sound, message, msg2, nil, nil, nil, nil, CA.vars.notifyDelay*1000, nil)
		CENTER_SCREEN_ANNOUNCE:AddMessage(0, CSA_EVENT_SMALL_TEXT, "Justice_NowKOS", msg3, nil, nil, nil, nil, nil, CA.vars.notifyDelay*1000, nil)
	else
		CyrodiilAlertNotifyTaken:SetText(message)
		CyrodiilAlertNotifyExtra:SetText(msg2 .. "\n" .. msg3)
	end
end

function CA.Movable()
	CA.vars.locked = not CA.vars.locked
	CyrodiilAlert:SetMovable(not CA.vars.locked)
	CyrodiilAlert:SetMouseEnabled(not CA.vars.locked)
	if (not CA.vars.locked) then
		CyrodiilAlertBG:SetAlpha(0.5)
	else
		CyrodiilAlertBG:SetAlpha(0)
	end
	if (CA.vars.locked) then
		CA.vars.locx = math.floor(CyrodiilAlert:GetLeft())
		CA.vars.locy = math.floor(CyrodiilAlert:GetTop())
	end
end

function CA.MoveStart()
    CyrodiilAlertBG:SetAlpha(0.5)
end 

function CA.MoveStop()
--    CyrodiilAlertBG:SetAlpha(0)
end 

function CA.SetTextAlign(newValue)
    CA.vars.textAlign = newValue
    local alignText = {}
    alignText["LEFT"]   = 0
    alignText["CENTER"] = 1
    alignText["RIGHT"]  = 2
    CyrodiilAlertNotify:SetHorizontalAlignment(alignText[newValue])
end

-- SLASH COMMAND FUNCTIONALITY
function CAslash(text )
	if (text == "show") then
		return CA.Movable()
	end
	if (text == "hide") then
		return CA.Movable()
	end
	if (text == "status") then
		CA.vars.dumpAttack = false return CA.dumpChat()
	end
	if (text == "attacks") then
		CA.vars.dumpAttack = true return CA.dumpChat()
	end
	if ((text == "imperial") or (text == "ic")) then
		CA.vars.dumpAttack = true CA.dumpImperial() CA.dumpDistricts()
	end
	if (text == "ic all") then
		CA.vars.dumpAttack = false CA.dumpImperial() CA.dumpDistricts()
	end
	if (text == "ic access") then
		CA.dumpImperial()
	end
	if (text == "ic districts") then
		CA.vars.dumpAttack = true return CA.dumpDistricts()
	end
	if (text == "init") then
		if (IsInCampaign()) then
			if (CA.currentId ~= GetCurrentCampaignId()) then
--				d("CA Debug: In AvA, Slash Init, New Campaign ID")
				CA.currentId = GetCurrentCampaignId()
				CA.campaignId = GetCurrentCampaignId()
				CA.campaignName = GetCampaignName(CA.campaignId)
				myAlliance = GetUnitAlliance("player")
			elseif (CA.currentId == GetCurrentCampaignId()) then
--				d("CA Debug: In AvA, Slash Init, Same Campaign ID")
			end
		elseif (not IsInCampaign()) then
			if (CA.currentId ~= GetCurrentCampaignId()) then
--				d("CA Debug: Not AvA, Slash Init, New Campaign ID")
				CA.currentId = GetCurrentCampaignId()
				CA.campaignId = GetAssignedCampaignId()
				CA.campaignName = GetCampaignName(CA.campaignId)
				myAlliance = GetUnitAlliance("player")
			elseif (CA.currentId == GetCurrentCampaignId()) then
--				d("CA Debug: Not AvA, Slash Init, Same Campaign ID")
			end
		end
		return CA.InitKeeps()
	end
	if (text == "out") then
		if (CA.vars.outside) then
			CA.vars.outside = false
			d("Notifications outside of Cyrodiil turned OFF.")
		else
			CA.vars.outside = true
			d("Notifications outside of Cyrodiil turned ON.")
		end
	end
	if (text == "clear") then
		CA_ACE:ClearNotify()
		CA_ACE:ClearNotifyTaken()
		CA_ACE:ClearNotifyExtra()
	end
	if (text == "help") then
		d("Avalable slash commands: show, hide, status, attacks, imperial, ic, init, out, clear, help")
	end
end -- CAslash
 
SLASH_COMMANDS["/ca"] = CAslash