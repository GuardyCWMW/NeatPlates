-- This marker is loaded only by NeatPlates_Camelot.toc.
NEATPLATES_IS_FOREVER = true

-- Forever exposes specialization data through C_SpecializationInfo, but does
-- not load all legacy global aliases that NeatPlates still uses.
if C_SpecializationInfo then
	GetSpecialization = GetSpecialization or C_SpecializationInfo.GetSpecialization
	GetSpecializationInfo = GetSpecializationInfo or C_SpecializationInfo.GetSpecializationInfo

	if not GetSpecializationRole and C_SpecializationInfo.GetSpecializationInfo then
		function GetSpecializationRole(specializationIndex, isInspect, isPet)
			return select(5, C_SpecializationInfo.GetSpecializationInfo(specializationIndex, isInspect or false, isPet or false))
		end
	end
end
