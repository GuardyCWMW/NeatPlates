-- Run from the repository root with Lua 5.1: lua tools\test_castbar.lua
local function read(path)
	path = path:gsub("\\", package.config:sub(1, 1))
	local file = assert(io.open(path, "r"))
	local text = file:read("*a")
	file:close()
	return text
end

local source = read("NeatPlates\\NeatPlatesCore.lua")
local function section(text, first, last)
	local start = assert(text:find(first, 1, true))
	local finish = assert(text:find(last, start, true))
	return text:sub(start, finish - 1)
end

local function load(code, env)
	local chunk = assert(loadstring(code))
	setfenv(chunk, env)
	return chunk()
end

local function equal(actual, expected)
	assert(actual == expected, tostring(actual).." ~= "..tostring(expected))
end

local secret = {}
local env = setmetatable({
	NEATPLATES_IS_RETAIL = true,
	ShowCastBars = true,
	ShowCastSpellName = true,
	ShowSpellTarget = true,
	L = {You = "You"},
	NEATPLATES_CLASS_COLORS = {MAGE = {}},
	SpellSchoolByGUID = {},
	Enum = {StatusBarTimerDirection = {RemainingTime = 1, ElapsedTime = 0}, StatusBarInterpolation = {Immediate = 0}},
}, {__index = _G})

local now, startTime, endTime = 12, 10000, 15000
local durationObject = {}
local targetname, isYou, isPlayer, targetclass = "Caster", false, false, "MAGE"
env.GetTime = function() return now end
env.IsSecretValue = function(value) return value == secret end
env.UnitCastingInfo = function() return "Spell", "Spell", 123, startTime, endTime, false, nil, false end
env.UnitChannelInfo = function() return "Spell", "Spell", 123, startTime, endTime, false, false end
env.UnitCastingDuration = function() return durationObject end
env.UnitChannelDuration = env.UnitCastingDuration
env.UnitName = function() return targetname end
env.UnitIsUnit = function() return isYou end
env.UnitIsPlayer = function() return isPlayer end
env.UnitClass = function() return "Mage", targetclass end
env.NEATPLATES_CLASS_COLORS.MAGE = {r = 0.25, g = 0.5, b = 1}
env.NeatPlatesUtility = {}
load(section(read("NeatPlates\\NeatPlatesUtility.lua"), "local function ConvertRGBtoColorString", "local function round")
	.."\nNeatPlatesUtility.ConvertRGBtoColorString = ConvertRGBtoColorString", env)
env.ConvertRGBtoColorString = load(section(source, "local ConvertRGBtoColorString", "local fade")
	.."\nreturn ConvertRGBtoColorString", env)
env.UpdateCastbarColor = function() return true end
env.ApplyCastInterruptibilityVisuals = function() end
env.UpdateIndicator_CustomScaleText = function() end
env.UpdateIndicator_CustomAlpha = function() end

local function font()
	return {SetText = function(self, text) self.text = text end}
end
local bar = {
	durationtext = font(),
	SetScript = function(self, event, callback) self[event] = callback end,
	SetTimerDuration = function(self, object, interpolation, direction)
		self.timer, self.direction = object, direction
		self.min, self.max = 0, 5
	end,
	SetMinMaxValues = function(self, min, max) self.min, self.max = min, max end,
	GetMinMaxValues = function(self) return self.min, self.max end,
	SetValue = function(self, value) self.value = value end,
	Show = function(self) self.shown = true end,
	Hide = function(self) self.shown = false end,
}
local plate = {extended = {
	unit = {guid = "test"},
	IsShown = function() return true end,
	visual = {
		castbar = bar, durationtext = bar.durationtext, spelltarget = font(), spelltext = font(),
		spellicon = {SetTexture = function() end},
	},
}}
env.UpdateReferences = function()
	env.extended, env.visual, env.unit = plate.extended, plate.extended.visual, plate.extended.unit
end
env.activetheme = {}

load(section(source, "\tlocal function OnUpdateCastBarForward", "\t-- OnInterruptedCasting"), env)
load(section(source, "\t-- OnHideCastbar", "\nend -- End Indicator section"), env)
local eventHandler = load(section(source, "local function NameplateEventHandler", "local function RetailNameplateEventHandler")
	.."\nreturn NameplateEventHandler", env)

local textSource = read("NeatPlatesHub\\functions\\Text.lua")
local round = load(section(read("NeatPlates\\NeatPlatesUtility.lua"), "local function round(", "-- Fade frame function")
	.."\nreturn round", _G)
local modes = load(section(textSource, "local function CastbarDurationRemaining", "local CastbarDurationFunctions")
	.."\nreturn {CastbarDurationRemaining, CastbarDurationElapsed, CastbarDurationCastTime}", {
		tonumber = tonumber, math = math,
		round = round,
	})

for _, retail in ipairs({true, false}) do
	env.NEATPLATES_IS_RETAIL = retail
	for _, native in ipairs({true, false}) do
		durationObject = native and {} or nil
		for _, channel in ipairs({false, true}) do
			for mode, format in ipairs(modes) do
				env.activetheme.SetCastbarDuration = format
				eventHandler(plate, channel and "UNIT_SPELLCAST_CHANNEL_START" or "UNIT_SPELLCAST_START", "nameplate1")
				equal(plate.extended.visual.spelltarget.text, "Caster")
				assert(bar.OnUpdate, "Readable casts must update duration text")
				bar:OnUpdate()
				local expected = ({3, 2, channel and "3/5.0" or "2/5.0"})[mode]
				equal(tostring(bar.durationtext.text), tostring(expected))
				if retail and native then
					equal(bar.timer, durationObject)
					equal(bar.direction, channel and 1 or 0)
					equal(bar.min, 0)
					equal(bar.max, 5)
				else
					equal(bar.value, channel and 13000 or 12000)
				end
				eventHandler(plate, "UNIT_SPELLCAST_STOP", "nameplate1")
				equal(bar.OnUpdate, nil)
				equal(bar.castStartTime, nil)
				equal(plate.extended.visual.spelltarget.text, "")
			end
		end
	end
end

env.NEATPLATES_IS_RETAIL = true
startTime, endTime = 11000, 16000
durationObject = {}
env.activetheme.SetCastbarDuration = modes[3]
eventHandler(plate, "UNIT_SPELLCAST_DELAYED", "nameplate1")
bar:OnUpdate()
equal(bar.durationtext.text, "1/5.0")
local castingDuration = env.UnitCastingDuration
env.UnitCastingDuration = function() return nil end
eventHandler(plate, "UNIT_SPELLCAST_CHANNEL_UPDATE", "nameplate1")
bar:OnUpdate()
equal(bar.durationtext.text, "4/5.0")
env.UnitCastingDuration = castingDuration
env.activetheme.SetCastbarDuration = nil
bar:OnUpdate()
equal(bar.durationtext.text, "")
local setTimerDuration = bar.SetTimerDuration
bar.SetTimerDuration = nil
durationObject = {}
env.OnStartCasting(plate, "nameplate1", false)
bar:OnUpdate()
equal(bar.value, 12000)
bar.SetTimerDuration = setTimerDuration
durationObject = {}
for _, channel in ipairs({false, true}) do
	for _, times in ipairs({{secret, secret}, {10000, secret}, {secret, 15000}, {false, false}}) do
		startTime, endTime = times[1] or nil, times[2] or nil
		env.OnStartCasting(plate, "nameplate1", channel)
		equal(bar.OnUpdate, nil)
		equal(bar.durationtext.text, "")
		equal(bar.timer, durationObject)
		equal(bar.castStartTime, nil)
	end
end
durationObject = nil
env.OnStartCasting(plate, "nameplate1", false)
equal(bar.min, 0)
equal(bar.max, 1)
equal(bar.OnUpdate, nil)

local vars = {}
env.activetheme.SetCastbarDurationObject = load(section(textSource,
	"local function SetCastbarDurationObject", "\n------------------------------------------------------------------------------")
	.."\nreturn SetCastbarDurationObject", {LocalVars = vars})
local remaining, elapsed, total = 3, 2, 5
durationObject = {
	GetRemainingDuration = function() return remaining end,
	GetElapsedDuration = function() return elapsed end,
	GetTotalDuration = function() return total end,
}
bar.durationtext.SetFormattedText = function(self, format, ...)
	self.format, self.args = format, {...}
	if remaining ~= secret then self.text = string.format(format, ...) end
end
for _, channel in ipairs({false, true}) do
	for _, protected in ipairs({false, true}) do
		startTime, endTime = secret, secret
		remaining, elapsed, total = 3, 2, 5
		if protected then remaining, elapsed, total = secret, secret, secret end
		for _, mode in ipairs({"TimeRemaining", "TimeElapsed", "TimeCastTime", "None"}) do
			vars.CastbarDurationMode = mode
			env.OnStartCasting(plate, "nameplate1", channel)
			assert(bar.OnUpdate, "Secret timestamps must use duration objects for text")
			bar:OnUpdate()
			if mode == "None" then
				equal(bar.durationtext.text, "")
			else
				equal(bar.durationtext.format, mode == "TimeCastTime" and "%.1f/%.1f" or "%.1f")
				equal(bar.durationtext.args[1], mode == "TimeRemaining" and remaining
					or mode == "TimeElapsed" and elapsed or channel and remaining or elapsed)
				if mode == "TimeCastTime" then equal(bar.durationtext.args[2], total) end
			end
			env.OnStopCasting(plate)
			equal(bar.OnUpdate, nil)
			equal(bar.castDuration, nil)
		end
	end
end

-- Repeated casts and theme changes must not leave a stale per-frame updater.
vars.CastbarDurationMode = "TimeRemaining"
remaining, elapsed, total = 3, 2, 5
for cast = 1, 100 do
	env.OnStartCasting(plate, "nameplate1", cast % 2 == 0)
	for tick = 1, 10 do bar:OnUpdate() end
	equal(bar.durationtext.text, "3.0")
	local formatter = env.activetheme.SetCastbarDurationObject
	env.activetheme.SetCastbarDurationObject = nil
	bar:OnUpdate()
	equal(bar.durationtext.text, "")
	env.activetheme.SetCastbarDurationObject = formatter
	env.OnStopCasting(plate)
	equal(bar.OnUpdate, nil)
	equal(bar.castDuration, nil)
end

local target = plate.extended.visual.spelltarget
local function updateTarget(expected)
	eventHandler(plate, "UNIT_TARGET", "nameplate1")
	equal(target.text, expected)
end
targetname = "New target"
updateTarget("New target")
isYou = true
updateTarget("|cFFFF1100>> You <<")
isYou, isPlayer = false, true
updateTarget("|cff3f7fffNew target")
targetclass = secret
updateTarget("New target")
targetclass = "UNKNOWN"
updateTarget("New target")
isYou, isPlayer = secret, secret
updateTarget("New target")
targetname = secret
updateTarget(secret)
targetname, isYou, isPlayer = nil, false, false
updateTarget("")
env.ShowSpellTarget = false
targetname = "Disabled"
updateTarget("")

local colorVars = {
	ColorShowPartyAggro = true,
	ColorPartyAggroText = true,
	ColorPartyAggro = {r = 1, g = 0, b = 0.4},
}
local hasThreat = true
local colorEnv = {
	LocalVars = colorVars,
	GetFriendlyThreat = function() return hasThreat end,
	StyleDelegate = function() return "Default" end,
	FriendlyNameColorFunctions = {},
	EnemyNameColorFunctions = {},
	NameColorDefault = function() return {r = 1, g = 1, b = 1, a = 1} end,
}
local nameColor = load(section(read("NeatPlatesHub\\functions\\Color.lua"),
	"local function SetNameColorDelegate", "\n--]]").."\nreturn SetNameColorDelegate", colorEnv)
env.activetheme.SetNameColor = nameColor
env.activetheme.SetUnitName = function() return "Name" end
env.UpdateIndicator_Subtext = function() end
env.UpdateReferences()
env.unit.reaction, env.unit.showName = "FRIENDLY", true
env.visual.name = font()
env.visual.name.SetTextColor = function(self, r, g, b, a)
	assert(type(r) == "number" and type(g) == "number" and type(b) == "number" and type(a) == "number",
		"SetTextColor requires numeric RGBA, not a color table")
	self.color = {r, g, b, a}
end
env.visual.healthbar, env.visual.powerbar = {SetStatusBarColor = function() end}, {SetStatusBarColor = function() end}
env.ApplyRetailProtectedPlayerColor = function(r, g, b, a) return r, g, b, a end
load(section(source, "\tfunction UpdateIndicator_Name()", "\t-- UpdateIndicator_Subtext:"), env)
load(section(source, "\tfunction UpdateIndicator_UnitColor()", "\t-- UpdateIndicator_Standard:"), env)
for _, alpha in ipairs({false, 0, 0.5, 1}) do
	colorVars.ColorPartyAggro.a = alpha ~= false and alpha or nil
	for _, update in ipairs({env.UpdateIndicator_Name, env.UpdateIndicator_UnitColor}) do
		update()
		equal(env.visual.name.color[1], 1)
		equal(env.visual.name.color[2], 0)
		equal(env.visual.name.color[3], 0.4)
		equal(env.visual.name.color[4], alpha ~= false and alpha or 1)
	end
end
hasThreat = false
env.UpdateIndicator_Name()
equal(env.visual.name.color[3], 1)
hasThreat = true
colorVars.ColorPartyAggroText = false
env.UpdateIndicator_UnitColor()
equal(env.visual.name.color[3], 1)

local function copyTable(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, entry in pairs(value) do result[key] = copyTable(entry) end
	return result
end

for _, locale in ipairs({"enUS", "ruRU", "koKR", "zhCN", "zhTW"}) do
	local themeEnv = setmetatable({
		GetLocale = function() return locale end,
		STANDARD_TEXT_FONT = "Fonts\\Locale.ttf",
		NeatPlatesUtility = {copyTable = copyTable},
		NeatPlatesThemeList = {},
		NeatPlatesHubFunctions = {ApplyHubFunctions = function() end},
	}, {__index = _G})
	load(read("NeatPlates_Roth\\NeatPlates_Roth.lua"), themeEnv)
	local roth = themeEnv.NeatPlatesThemeList.Roth
	local default = roth.Default
	equal(default.castbar.texture, "Interface\\Addons\\NeatPlates_Roth\\Media\\CastBar")
	equal(default.castbar.left * 128, 44)
	equal(default.castbar.right * 128, 126)
	equal(default.castbar.top * 64, 38)
	equal(default.castbar.bottom * 64, 45)
	local expectedFont = locale == "enUS"
		and "Interface\\Addons\\NeatPlatesHub\\shared\\RobotoCondensed-Bold.ttf" or themeEnv.STANDARD_TEXT_FONT
	for _, style in ipairs({default, roth.NameOnly}) do
		for _, element in ipairs({"spelltext", "spelltarget", "durationtext"}) do
			equal(style[element].typeface, expectedFont)
			equal(style[element].anchor, "CENTER")
		end
		assert(style.spelltext.y + style.spelltext.height / 2
			< style.castbar.y - style.castbar.height / 2, "Spell name must be below the bar")
		assert(style.spelltarget.y + style.spelltarget.height / 2
			<= style.spelltext.y - style.spelltext.height / 2, "Spell target must be below the spell name")
		equal(style.durationtext.y, style.castbar.y)
		equal(style.durationtext.x, style.castbar.x)
		assert(style.durationtext.width <= style.castbar.width, "Timer must fit within the bar width")
	end
	for _, element in ipairs({"castbar", "castborder", "castnostop", "spelltext", "spelltarget", "durationtext", "spellicon"}) do
		equal(roth.NameOnly[element].x - default[element].x, -2)
		equal(roth.NameOnly[element].y - default[element].y, -6)
	end
end

print("Cast-bar regression checks passed")
