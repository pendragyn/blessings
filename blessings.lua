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
		local testUnitID = ""
		local unitName = ""
		local blesserCount = 0
		local unkKingsCount = 0
		local unkWisdomCount = 0
		local blessersNonWisdomCount = 0
		local blessersNonKingsCount = 0
		local chatType = "PARTY"
		local msg = ""
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
		if true then
			chatType = "WHISPER"
		end
		--print(chatType)
		vars.blessers = {}
		vars.unkKings = {}
		vars.unkWisdom = {}
		--print("-----blessers----")
		for i = 1, groupCount do
			local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
			testUnitID = getActionUnitID(groupType, i)
			unitName = UnitName(testUnitID)
			role = UnitGroupRolesAssigned(testUnitID)
			if class == "Paladin" and role == "DAMAGER" then
				blesserCount = blesserCount + 1
				vars.blessers[blesserCount] = {}
				vars.blessers[blesserCount].wisdom = nil
				vars.blessers[blesserCount].kings = nil
				vars.blessers[blesserCount].caster = unitName
				--print(vars.blessers[blesserCount].caster)
			end
		end
		local b = 0
		for i = 1, groupCount do
			local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3
			testUnitID = getActionUnitID(groupType, i)	
			unitName = UnitName(testUnitID)
			role = UnitGroupRolesAssigned(testUnitID)
			name = "x"
			b = 0
			while name ~= nil do
				b = b + 1
				name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3 =UnitAura(testUnitID, b, "HELPFUL")
				if caster == nil then
					if name == "Greater Blessing of Wisdom" then
						unkWisdomCount = unkWisdomCount + 1
						vars.unkWisdom[unkWisdomCount] = unitName
					elseif name == "Greater Blessing of Kings" then
						unkKingsCount = unkKingsCount + 1
						vars.unkKings[unkKingsCount] = unitName
					end
				else
					caster = UnitName(caster)
					for bc = 1, blesserCount do
						--print(caster,vars.blessers[bc].caster)
						if caster == vars.blessers[bc].caster then
							if name == "Greater Blessing of Wisdom" then
								vars.blessers[bc].wisdom = vars.blessers[bc].caster
							elseif name == "Greater Blessing of Kings" then
								vars.blessers[bc].kings = vars.blessers[bc].caster
							end
						end
					end
				end
			end
		end
		--print("-----Blessings-----")
		vars.blessersNonWisdom = {}
		vars.blessersNonKings = {}
		for bc =1, blesserCount do
			if vars.blessers[bc].wisdom == nil then
				if unkWisdomCount > 0 then
					blessersNonWisdomCount = blessersNonWisdomCount + 1
					vars.blessersNonWisdom[blessersNonWisdomCount] = vars.blessers[bc].caster
				else
					msg = vars.blessers[bc].caster.." has an available Greater Blessing of Wisdom"
					if chatType == "WHISPER" then
						print(msg)
					else
						SendChatMessage(msg, chatType)
					end
				end
			end	
			if vars.blessers[bc].kings == nil then
				if unkKingsCount > 0 then
					blessersNonKingsCount = blessersNonKingsCount + 1
					vars.blessersNonKings[blessersNonKingsCount] = vars.blessers[bc].caster
				else
					msg = vars.blessers[bc].caster.." has an available Greater Blessing of Kings"
					if chatType == "WHISPER" then
						print(msg)
					else
						SendChatMessage(msg, chatType)
					end
				end
			end
		end
		if blessersNonWisdomCount ~= unkWisdomCount then
			msg = ""
			for bc =1, blessersNonWisdomCount do
				msg = msg .. vars.blessersNonWisdom[blessersNonWisdomCount] .. " "
			end
			if (blessersNonWisdomCount-unkWisdomCount) == 1 then
				msg = msg .. "has an available Greater Blessing of Wisdom"
			else
				msg = msg .. "have " .. (blessersNonWisdomCount-unkWisdomCount).." available Greater Blessings of Wisdom"
			end
			if chatType == "WHISPER" then
				print(msg)
			else
				SendChatMessage(msg, chatType)
			end
		end
		if blessersNonKingsCount ~= unkKingsCount then
			msg = ""
			for bc =1, blessersNonKingsCount do
				msg = msg .. vars.blessersNonKings[blessersNonKingsCount] .. " "
			end
			if (blessersNonKingsCount-unkKingsCount) == 1 then
				msg = msg .. "has an available Greater Blessing of Kings"
			else
				msg = msg .. "have " ..(blessersNonKingsCount-unkKingsCount).." available Greater Blessings of Kings"
			end
			if chatType == "WHISPER" then
				print(msg)
			else
				SendChatMessage(msg, chatType)
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