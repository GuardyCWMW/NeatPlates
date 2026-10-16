---------------
-- Threat Percentage Widget
---------------

local font = "FONTS\\arialn.ttf"
local GetRelativeThreat = NeatPlatesUtility.GetRelativeThreat
local IsSecretValue = issecretvalue or function() return false end

local function UpdateThreatPercentageWidget(self, unit, showFriendly)
	if NEATPLATES_IS_RETAIL then
		local _, _, threat = UnitDetailedThreatSituation("player", unit)

		if IsSecretValue(threat) then
			-- SetFormattedText is a supported secret-value text sink. Do not inspect
			-- or transform the protected value in Lua before handing it to the UI.
			self.Text:SetFormattedText("%.0f%%", threat)
			self:Show()
		elseif threat and threat > 0 then
			self.Text:SetFormattedText("%.0f%%", threat)
			self:Show()
		else
			self.Text:SetText("")
			self:Hide()
		end
		return
	end

	local threat, targetOf = GetRelativeThreat(unit)
	local threatPercent

	if threat and threat > 0 then
		threatPercent = math.floor(threat)..'%'
		self.Text:SetText(threatPercent)
		self:Show()
	else
		self.Text:SetText("")
		self:Hide()
	end

end

local function UpdateWidget(frame)
	local unitid = frame.unitid

	if unitid then
		UpdateThreatPercentageWidget(frame, unitid)
	end
end

local function UpdateWidgetContext(frame, unit)
	local unitid = unit.unitid

	if NEATPLATES_IS_RETAIL then
		-- The modern API is authoritative: it returns a percentage only when
		-- threat data exists. Legacy combat, party, and pet checks can be false
		-- on Forever even though the percentage itself is available.
		frame.unitid = unitid
		UpdateThreatPercentageWidget(frame, unitid)
		return
	end

	if unit.reaction == "FRIENDLY" or (not InCombatLockdown()) or (not (UnitInParty("player") or HasPetUI())) then
		frame:Hide()
		return
	end

	frame.unitid = unitid

	-- Legacy clients use the widget's original per-unit event handling.
	frame:UnregisterAllEvents()
	frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
	frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
	frame:RegisterUnitEvent("UNIT_HEALTH", unitid)
	frame:SetScript("OnEvent", UpdateWidget)

	UpdateThreatPercentageWidget(frame, unitid)
end

local function CreateThreatPercentageWidget(parent)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetWidth(32); frame:SetHeight(12)

	-- frame.Icon = frame:CreateTexture(nil, "ARTWORK")
	-- frame.Icon:SetAllPoints(frame)

	frame.Text = frame:CreateFontString(nil, "OVERLAY")
	frame.Text:SetFont(font, 10, "OUTLINE")
	frame.Text:SetAllPoints(frame)
	frame.Text:SetJustifyH("CENTER")

	frame:Hide()
	frame.Update = UpdateWidget
	frame.UpdateContext = UpdateWidgetContext
	return frame
end

NeatPlatesWidgets.CreateThreatPercentageWidget = CreateThreatPercentageWidget


