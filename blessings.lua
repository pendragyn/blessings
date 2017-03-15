blessingsDB = {}
local function classblessings()
	local self = {}
	local f, e = CreateFrame("Frame"), {}
	local vars = {}
	local function getActionUnitID(gtype,nbr)
		local result
		if gtype == "raid" then
			result = gtype .. nbr
		else
			if nbr == 1 then
				result = "player"
			else
				result = gtype .. (nbr-1)
			end
		end
		return result
	end
	local function blessings()
		local groupCount = GetNumGroupMembers()
		local testUnitID
		local blesserCount = 0
		local chatType = "PARTY"
		if groupCount == 0 then
			groupCount = 1
		end
		if groupCount > 40 then
			groupCount = 40
		end
		if IsInRaid() then
			groupType = "raid"
		else
			groupType = "party"
		end		
		if IsInGroup() then
			if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
				chatType = 'INSTANCE_CHAT'
			elseif IsInRaid() then
				chatType = 'RAID'
			else	
				chatType = 'PARTY'
			end
		else
			chatType = 'SAY'  -- for testing purposes
		end
		print(chatType)
		vars.blessers = {}
		for i = 1, groupCount do
			local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
			testUnitID = getActionUnitID(groupType, i)	
			role = UnitGroupRolesAssigned(testUnitID)
			print(testUnitID, class, role)
			if class == "Paladin" and role == "DAMAGER" then
				vars.blessers[testUnitID] = {}
				vars.blessers[testUnitID].wisdom = false
				vars.blessers[testUnitID].kings = false
			end
		end
		local b = 0
		for i = 1, groupCount do
			local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3
			testUnitID = getActionUnitID(groupType, i)	
			role = UnitGroupRolesAssigned(testUnitID)
			name = "x"
			b = 0
			while name ~= nil do
				b = b + 1
				name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3 = UnitAura(testUnitID, b, "HELPFUL")
				if name == "Greater Blessing of Wisdom" then
					--print(name, caster)
					if vars.blessers[caster] == nil then
						vars.blessers[caster] = {}
						vars.blessers[caster].kings = false
					end
					vars.blessers[caster].wisdom = true
				elseif name == "Greater Blessing of Kings" then
					if vars.blessers[caster] == nil then
						vars.blessers[caster] = {}
						vars.blessers[caster].wisdom = false
					end
					vars.blessers[caster].kings = true
				end
			end
		end
		for k,v in pairs(vars.blessers) do
			if vars.blessers ~= nil then
				if not v.wisdom then
					print(UnitName(k).." has an unused Greater Blessing of Wisdom")
					SendChatMessage(UnitName(k).." has an available Greater Blessing of Wisdom", chatType)
				end	
				if not v.kings then
					print(UnitName(k).." has an unused Greater Blessing of Kings")
					SendChatMessage(UnitName(k).." has an available Greater Blessing of Kings", chatType)
				end
			end
		end
	end
	function e:READY_CHECK(...)
		blessings()
	end
	f:SetScript("OnEvent", function(self, event, ...)
		e[event](self, ...) -- call one of the functions above
	end)
	for k, v in pairs(e) do
	   f:RegisterEvent(k) -- Register all events for which handlers have been defined
	end
	return self
end
blessings = classblessings()