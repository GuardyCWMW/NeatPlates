-- Retail 12.1 aura adapter. Aura data can be secret in combat, so Blizzard's
-- native AuraContainer owns filtering, sorting, timing, and visibility.
if not NEATPLATES_IS_RETAIL then return end

-- Blizzard_AuraContainer is load-on-demand. If its template is not available
-- yet, silently returning here leaves NeatPlates without an aura widget at all.
if C_AddOns and C_AddOns.LoadAddOn then
	pcall(C_AddOns.LoadAddOn, "Blizzard_AuraContainer")
end
if not (C_XMLUtil and C_XMLUtil.GetTemplateInfo and C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")) then return end

local Containers = {}
local AuraScale = 1
local AuraAlignment = "BOTTOM"
local AuraLimit = 9
local DebuffFilterMode = 2
local BuffFilterMode = 1
local DebuffStyle = 1

local function CreateDurationFormatter()
	if not (C_StringUtil and C_StringUtil.CreateNumericRuleFormatter) then return nil end

	local formatter = C_StringUtil.CreateNumericRuleFormatter()
	formatter:AddBreakpoint({
		threshold = 0,
		step = 1,
		format = "%d",
	})
	formatter:AddBreakpoint({
		threshold = 60,
		format = "%d:%02d",
		components = {
			{ div = 60 },
			{ mod = 60 },
		},
	})
	formatter:AddBreakpoint({
		threshold = 180,
		format = "%dm",
		components = {
			{
				div = 60,
				step = 1,
			},
		},
	})

	return formatter
end

local DurationFormatter = CreateDurationFormatter()

local function GetAuraDimensions()
	if DebuffStyle == 1 then
		return 26.5 * AuraScale, 14.5 * AuraScale
	end

	return 16.5 * AuraScale, 14.5 * AuraScale
end

local function GetLayout()
	local width, height = GetAuraDimensions()
	return {
		elementSpacing = 3,
		lineSpacing = 3,
		groupSpacing = 3,
		groupLineSpacing = 3,
		elementWidth = width,
		elementHeight = height,
		maximumLineSize = (width + 3) * 5,
	}
end

local function ApplyAuraButtonStyle(auraButton)
	local width, height = GetAuraDimensions()

	auraButton:SetSize(width, height)
	auraButton:SetScale(1)

	if auraButton.Icon then
		auraButton.Icon:SetAllPoints(auraButton)
		if DebuffStyle == 3 then
			auraButton.Icon:SetTexCoord(0, 1, 0, 1)
		elseif DebuffStyle == 1 then
			auraButton.Icon:SetTexCoord(0.07, 0.93, 0.23, 0.77)
		else
			auraButton.Icon:SetTexCoord(0.10, 0.93, 0.12, 0.88)
		end
	end

	if auraButton.Cooldown then
		auraButton.Cooldown:SetAllPoints(auraButton)
		auraButton.Cooldown:SetHideCountdownNumbers(true)
	end

	if auraButton.Count then
		auraButton.Count:ClearAllPoints()
		auraButton.Count:SetPoint("BOTTOMRIGHT", auraButton, "BOTTOMRIGHT", 2, -1)
	end

	if auraButton.TimerText then
		local fontSize = DebuffStyle == 1 and 8 or 9
		auraButton.TimerText:ClearAllPoints()
		auraButton.TimerText:SetPoint("TOPRIGHT", auraButton, "TOPRIGHT", -1, 7)
		auraButton.TimerText:SetWidth(width)
		auraButton.TimerText:SetHeight(12)
		auraButton.TimerText:SetJustifyH("RIGHT")
		auraButton.TimerText:SetFont("Fonts\\ARIALN.TTF", fontSize, "OUTLINE")
		auraButton.TimerText:SetShadowOffset(1, -1)
		auraButton.TimerText:SetShadowColor(0, 0, 0, 1)
	end
end

local function InitializeAuraButton(auraButton)
	local container = auraButton:GetParent()
	container.neatAuraButtons = container.neatAuraButtons or {}
	container.neatAuraButtons[auraButton] = true

	auraButton:SetMouseMotionEnabled(true)

	local icon = auraButton:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints(auraButton)
	auraButton.Icon = icon
	auraButton:SetIcon(icon)

	local cooldown = CreateFrame("Cooldown", nil, auraButton, "CooldownFrameTemplate")
	cooldown:SetAllPoints(auraButton)
	cooldown:EnableMouse(false)
	cooldown:SetHideCountdownNumbers(true)
	cooldown:SetDrawBling(false)
	auraButton.Cooldown = cooldown
	auraButton:SetDurationCooldown(cooldown)

	local count = auraButton:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	count:SetPoint("BOTTOMRIGHT", auraButton, "BOTTOMRIGHT", 2, -1)
	auraButton.Count = count
	auraButton:SetApplicationCount(count)

	local timerText = cooldown:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	auraButton.TimerText = timerText
	if DurationFormatter then
		auraButton:SetDurationText(timerText, { textFormatter = DurationFormatter })
	end

	ApplyAuraButtonStyle(auraButton)
end

local function ConfigureContainer(frame)
	local layout = GetLayout()

	local debuffFilter = "HARMFUL|PLAYER"
	local debuffMax = AuraLimit
	if DebuffFilterMode == 1 then
		debuffMax = 0
	elseif DebuffFilterMode == 3 then
		debuffFilter = "HARMFUL"
	end

	local buffFilter = "HELPFUL"
	local buffMax = 0
	if BuffFilterMode == 2 then
		buffFilter = "HELPFUL|PLAYER"
		buffMax = AuraLimit
	elseif BuffFilterMode == 3 then
		buffMax = AuraLimit
	end

	frame:SetAuraGroupFilterString("debuffs", debuffFilter)
	frame:SetAuraGroupMaxFrameCount("debuffs", debuffMax)
	frame:SetAuraGroupSortMethod("debuffs", AuraContainerSortMethod.Expiration, AuraContainerSortDirection.Normal)
	frame:SetAuraGroupLayout("debuffs", layout)

	frame:SetAuraGroupFilterString("buffs", buffFilter)
	frame:SetAuraGroupMaxFrameCount("buffs", buffMax)
	frame:SetAuraGroupSortMethod("buffs", AuraContainerSortMethod.Expiration, AuraContainerSortDirection.Normal)
	frame:SetAuraGroupLayout("buffs", layout)

	frame:SetFlowLayoutMaximumLineSize(layout.maximumLineSize)

	local horizontal = AnchorUtil.FlowDirection.Right
	if AuraAlignment == "BOTTOMRIGHT" then
		horizontal = AnchorUtil.FlowDirection.Left
	end
	frame:SetFlowLayoutAnchorPoint(AuraAlignment == "BOTTOMRIGHT" and "BOTTOMRIGHT" or "BOTTOMLEFT")
	frame:SetFlowLayoutGrowthDirection(horizontal, AnchorUtil.FlowDirection.Up)

	-- Aura buttons become restricted after Blizzard's container takes
	-- ownership of them. Their dimensions are updated by the group layout;
	-- touching the buttons again here causes ADDON_ACTION_FORBIDDEN on 12.1.
end

local function UpdateWidgetContext(frame, unit)
	local unitid = unit and unit.unitid
	frame.lastUnitToken = unitid
	if unitid then
		frame:SetEnabled(true)
		frame:SetUnit(unitid)
		frame:Show()
		frame:UpdateAllAuras()
	else
		frame:SetEnabled(false)
		frame:Hide()
	end
end

local function UpdateWidgetOffset(frame, x, y)
	x = x or frame.lastOffset.x or 0
	y = y or frame.lastOffset.y or 0
	frame.lastOffset.x = x
	frame.lastOffset.y = y

	local config = frame.lastConfig
	frame:ClearAllPoints()
	frame:SetPoint(config.anchor or "TOP", config.relFrame or frame:GetParent(), config.anchorRel or config.anchor or "TOP", config.x or 0, (config.y or 0) + y)
end

local function SetCustomPoint(frame, anchor, relFrame, anchorRel, x, y)
	frame.lastConfig.anchor = anchor
	frame.lastConfig.relFrame = relFrame
	frame.lastConfig.anchorRel = anchorRel
	frame.lastConfig.x = x
	frame.lastConfig.y = y
	UpdateWidgetOffset(frame)
end

local function CreateAuraWidget(parent)
	-- The legacy widget host intentionally sits one frame level behind the
	-- health bar. Retail aura buttons must instead live on the visible text
	-- frame, matching the parent/level arrangement used by modern nameplates.
	local auraParent = parent:GetParent() or parent
	local frame = CreateFrame("AuraContainer", nil, auraParent, "CustomAuraContainerTemplate")
	frame:SetSize(128, 40)
	frame:SetFrameLevel((auraParent:GetFrameLevel() or 0) + 10)
	frame.lastConfig = {}
	frame.lastOffset = {}

	local layout = GetLayout()
	frame:AddAuraGroup("debuffs", "HARMFUL|PLAYER", {
		maxFrameCount = AuraLimit,
		sortMethod = AuraContainerSortMethod.Expiration,
		sortDirection = AuraContainerSortDirection.Normal,
		initializeFrame = InitializeAuraButton,
		layout = layout,
	})
	frame:AddAuraGroup("buffs", "HELPFUL", {
		maxFrameCount = AuraLimit,
		sortMethod = AuraContainerSortMethod.Expiration,
		sortDirection = AuraContainerSortDirection.Normal,
		initializeFrame = InitializeAuraButton,
		layout = layout,
	})
	frame:SetAuraProcessingPolicy(CustomAuraContainerAuraProcessingPolicy.ProcessAura, {
		displayOnlyDispellableDebuffs = false,
		ignoreBuffs = false,
		ignoreDebuffs = false,
		ignoreDispelDebuffs = false,
	})
	ConfigureContainer(frame)
	frame:SetEnabled(false)

	frame.UpdateContext = UpdateWidgetContext
	frame.Update = UpdateWidgetContext
	frame.UpdateTarget = UpdateWidgetContext
	frame.UpdateConfig = ConfigureContainer
	frame.SetCustomPoint = SetCustomPoint
	frame.UpdateOffset = UpdateWidgetOffset

	Containers[frame] = true
	return frame
end

local function SetAuraIconStyle(_, scale)
	AuraScale = tonumber(scale) or 1
	for frame in pairs(Containers) do ConfigureContainer(frame) end
end

local function SetAuraOptions(options)
	local alignments = {"BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}
	AuraScale = tonumber(options.AuraScale) or AuraScale
	AuraAlignment = alignments[options.WidgetAuraAlignment] or "BOTTOM"
	DebuffFilterMode = tonumber(options.WidgetDebuffFilter) or DebuffFilterMode
	BuffFilterMode = tonumber(options.WidgetBuffFilter) or BuffFilterMode
	DebuffStyle = tonumber(options.WidgetDebuffStyle) or DebuffStyle
	for frame in pairs(Containers) do ConfigureContainer(frame) end
end

local function EnableAuraWatcher()
	for frame in pairs(Containers) do
		if frame.lastUnitToken then
			frame:SetEnabled(true)
			frame:SetUnit(frame.lastUnitToken)
			frame:Show()
			frame:UpdateAllAuras()
		end
	end
end

local function DisableAuraWatcher()
	for frame in pairs(Containers) do
		frame:SetEnabled(false)
		frame:Hide()
	end
end

local function Noop() end

NeatPlatesWidgets.CreateAuraWidget = CreateAuraWidget
NeatPlatesWidgets.EnableAuraWatcher = EnableAuraWatcher
NeatPlatesWidgets.DisableAuraWatcher = DisableAuraWatcher
NeatPlatesWidgets.SetAuraIconStyle = SetAuraIconStyle
NeatPlatesWidgets.SetAuraOptions = SetAuraOptions
NeatPlatesWidgets.SetAuraSortMode = Noop
NeatPlatesWidgets.SetAuraFilter = Noop
NeatPlatesWidgets.SetEmphasizedAuraFilter = Noop
NeatPlatesWidgets.SetPandemic = Noop
NeatPlatesWidgets.SetBorderTypes = Noop
NeatPlatesWidgets.SetSpacerSlots = Noop
NeatPlatesWidgets.SetEmphasizedSlots = Noop
NeatPlatesWidgets.SetRangeWidgetOptions = Noop
NeatPlatesWidgets.UsesRetailAuraContainer = true
-- AuraContainer visibility is a secret aspect in Retail 12.1. Aura spotlighting
-- cannot query it from addon code, so leave that optional signal disabled.
NeatPlatesWidgets.IsAuraShown = function() return false end
