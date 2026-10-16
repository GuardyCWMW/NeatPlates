-- Luacheck configuration for NeatPlates Community Edition.
-- https://luacheck.readthedocs.io/
--
-- WoW runs a customized Lua 5.1. There is no `require`, and the entire Blizzard
-- API arrives as globals, so an out-of-the-box luacheck run reports thousands of
-- false "undefined global" warnings. The lists below teach it the environment.
--
-- Rollout note: CI runs this as a NON-BLOCKING job while the legacy warning
-- backlog is worked down. Keep new and changed code warning-free, and do not
-- silence a whole category just to get a clean run.

std = "lua51"

-- Vendored third-party code follows its own conventions and licenses.
exclude_files = {
	"NeatPlates/libs/**/*.lua",
	".release/**/*.lua",
}

-- Legacy-codebase noise that is not worth blocking on today.
ignore = {
	"212", -- unused argument (pervasive in WoW event handlers)
	"213", -- unused loop variable
	"542", -- empty if branch
}

max_line_length = false

-- Cross-addon contracts owned by this project. These are intentionally global
-- because separate addon folders cannot share a private table; see AGENTS.md.
-- Listing them as writable keeps luacheck from flagging the assignments while
-- still catching typos elsewhere.
globals = {
	"NeatPlates",
	"NeatPlatesBackdrop",
	"NeatPlatesCore",
	"NeatPlatesEventFrame",
	"NeatPlatesHubDefaults",
	"NeatPlatesHubFunctions",
	"NeatPlatesHubHelpers",
	"NeatPlatesHubMenus",
	"NeatPlatesHubPrefixList",
	"NeatPlatesHubRapidPanel",
	"NeatPlatesHubSettings",
	"NeatPlatesOptions",
	"NeatPlatesPanel",
	"NeatPlatesSettings",
	"NeatPlatesSpellDB",
	"NeatPlatesTarget",
	"NeatPlatesThemeList",
	"NeatPlatesUtility",
	"NeatPlatesWidgets",
	"NeatPlatesWidgetSettings",

	-- Client flags set in NeatPlatesGlobals.lua / NeatPlatesForever.lua.
	"NEATPLATES_IS_CLASSIC",
	"NEATPLATES_IS_CLASSIC_CATA",
	"NEATPLATES_IS_CLASSIC_ERA",
	"NEATPLATES_IS_CLASSIC_MISTS",
	"NEATPLATES_IS_CLASSIC_TBC",
	"NEATPLATES_IS_CLASSIC_WOTLKC",
	"NEATPLATES_IS_FOREVER",
	"NEATPLATES_IS_RETAIL",
}

-- Blizzard API surface. Not exhaustive: add entries as code legitimately needs
-- them rather than disabling the undefined-global check (211/113).
read_globals = {
	-- Lua 5.1 extras WoW exposes
	"bit", "strsplit", "strjoin", "strtrim", "strmatch", "strfind", "strsub",
	"strlower", "strupper", "strrep", "strbyte", "strchar", "strconcat",
	"gsub", "format", "tinsert", "tremove", "twipe", "wipe", "sort",
	"max", "min", "abs", "ceil", "floor", "sqrt", "random", "date", "time",
	"geterrorhandler", "seterrorhandler", "securecall", "issecure",
	"hooksecurefunc", "scrub", "print",

	-- Secret-value handling (modern clients)
	"issecretvalue", "SecretValue",

	-- Core frame/UI
	"CreateFrame", "UIParent", "WorldFrame", "GameTooltip", "GameFontNormal",
	"GameFontHighlight", "NumberFontNormal", "InterfaceOptions_AddCategory",
	"InterfaceOptionsFrame_OpenToCategory", "Settings", "SlashCmdList",
	"StaticPopupDialogs", "StaticPopup_Show", "C_Timer", "C_AddOns",
	"LibStub", "GetTime", "GetLocale", "GetCVar", "SetCVar", "GetCVarBool",
	"GetCVarDefault", "InCombatLockdown", "IsAddOnLoaded", "GetAddOnMetadata",
	"RegisterAttributeDriver", "UnregisterAttributeDriver",

	-- Project / client constants
	"WOW_PROJECT_ID", "WOW_PROJECT_MAINLINE", "WOW_PROJECT_CLASSIC",
	"WOW_PROJECT_BURNING_CRUSADE_CLASSIC", "WOW_PROJECT_WRATH_CLASSIC",
	"WOW_PROJECT_CATACLYSM_CLASSIC", "WOW_PROJECT_MISTS_CLASSIC",

	-- Nameplates
	"C_NamePlate", "GetNamePlates", "GetNamePlateForUnit",

	-- Unit API
	"UnitName", "UnitGUID", "UnitExists", "UnitIsUnit", "UnitClass",
	"UnitHealth", "UnitHealthMax", "UnitPower", "UnitPowerMax", "UnitLevel",
	"UnitClassification", "UnitReaction", "UnitIsPlayer", "UnitIsFriend",
	"UnitIsEnemy", "UnitIsTapDenied", "UnitIsDead", "UnitIsDeadOrGhost",
	"UnitAffectingCombat", "UnitCanAttack", "UnitPlayerControlled",
	"UnitSelectionColor", "UnitDetailedThreatSituation", "UnitThreatSituation",
	"UnitGroupRolesAssigned", "UnitIsPVP", "UnitRace", "UnitSex",
	"UnitChannelInfo", "UnitCastingInfo", "UnitAura", "C_UnitAuras",
	"GetUnitName", "UnitIsQuestBoss", "UnitWidgetSet",

	-- Spell / item
	"GetSpellInfo", "C_Spell", "C_Item", "GetSpellTexture", "GetItemInfo",

	-- Specialization (aliased for Forever in NeatPlatesForever.lua)
	"GetSpecialization", "GetSpecializationInfo", "GetSpecializationRole",
	"GetActiveTalentGroup", "GetTalentTabInfo", "C_SpecializationInfo",

	-- Class/colour tables
	"RAID_CLASS_COLORS", "CUSTOM_CLASS_COLORS", "FACTION_BAR_COLORS",
	"LOCALIZED_CLASS_NAMES_MALE", "LOCALIZED_CLASS_NAMES_FEMALE",

	-- Quest / misc
	"C_QuestLog", "C_Scenario", "GetQuestLogIndexByID", "IsInInstance",
	"IsInRaid", "IsInGroup", "GetNumGroupMembers", "GetRaidTargetIndex",
	"C_ChatInfo", "C_CVar",
}
