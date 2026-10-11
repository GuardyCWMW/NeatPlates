local wowversion, wowbuild, wowdate, wowtocversion = GetBuildInfo()

NEATPLATES_IS_CLASSIC_WOTLKC = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
NEATPLATES_IS_CLASSIC_TBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
NEATPLATES_IS_CLASSIC_CATA = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC
NEATPLATES_IS_CLASSIC_MISTS = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
NEATPLATES_IS_CLASSIC_ERA = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
NEATPLATES_IS_FOREVER = NEATPLATES_IS_FOREVER == true or wowtocversion == 16001
-- Forever shares the modern, Secret Value-aware UI architecture even when
-- its WOW_PROJECT_ID differs from Mainline after a client update.
NEATPLATES_IS_RETAIL = NEATPLATES_IS_FOREVER or WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
NEATPLATES_IS_CLASSIC = NEATPLATES_IS_CLASSIC_TBC or NEATPLATES_IS_CLASSIC_ERA or NEATPLATES_IS_CLASSIC_WOTLKC or NEATPLATES_IS_CLASSIC_CATA or NEATPLATES_IS_CLASSIC_MISTS
if wowtocversion and (NEATPLATES_IS_FOREVER or wowtocversion > 90000 or (NEATPLATES_IS_CLASSIC and wowtocversion >= 11400)) then
	NeatPlatesBackdrop = "BackdropTemplate"
end

if NEATPLATES_IS_FOREVER and C_SpecializationInfo then
	GetSpecialization = GetSpecialization or C_SpecializationInfo.GetSpecialization
	GetSpecializationInfo = GetSpecializationInfo or C_SpecializationInfo.GetSpecializationInfo

	if not GetSpecializationRole and C_SpecializationInfo.GetSpecializationInfo then
		function GetSpecializationRole(specializationIndex, isInspect, isPet)
			return select(5, C_SpecializationInfo.GetSpecializationInfo(specializationIndex, isInspect or false, isPet or false))
		end
	end
end

-- Fill CUSTOM_CLASS_COLORS with the default colors
NEATPLATES_CLASS_COLORS = {}
for class, color in pairs(RAID_CLASS_COLORS) do
	NEATPLATES_CLASS_COLORS[class] = {r = color.r, g = color.g, b = color.b}
end
