PrioritiesDB = {}
local function classPriorities()
	--print(CompactPartyFrame)
	local self = {}
	local f, e = CreateFrame("Frame"), {}
	local vars = {}
	local timer = 0
	local CYCLE_TIME = .05
	vars.spellQueue = .2
	vars.friendlyRangeCheck = "Flash of Light"
	vars.priority = {}
	vars.priority.spell = "Holy Shock"
	vars.priority.unit = "player"
	vars.priority.raidFrame = ""
	vars.aoeCount = 0
	
	vars.prioritySpellIcon = {}
	vars.prioritySpellIcon.frame = CreateFrame("Frame", "vars.prioritySpellIcon", UIParent)
	vars.prioritySpellIcon.frame:SetFrameStrata("HIGH")
	vars.prioritySpellIcon.frame:SetWidth(24)
	vars.prioritySpellIcon.frame:SetHeight(24)
	vars.prioritySpellIcon.texture = vars.prioritySpellIcon.frame:CreateTexture(nil,"OVERLAY ")
	vars.prioritySpellIcon.texture:SetAllPoints(vars.prioritySpellIcon.frame)	
	vars.prioritySpellIcon.frame.texture = vars.prioritySpellIcon.texture
	vars.prioritySpellIcon.frame:SetPoint("BOTTOMLEFT", 0, 0)
	vars.prioritySpellIcon.frame:Show()
	vars.prioritySpellIcon.frame:SetFrameLevel(7)
	vars.prioritySpellIcon.texture:SetTexture(GetSpellTexture(spellID))
	local isCastableOn = function(unitID, spellName)
		local inRange, checkedRange
		if spell == nil then
			inRange, checkedRange = UnitInRange(unitID)
			if not checkedRange then
				if spellName == nil then
					inRange = IsSpellInRange(vars.friendlyRangeCheck, unitID)
				else
					inRange = IsSpellInRange(spellName, unitID)
				end
			end
		else
			inRange = IsSpellInRange(unitID, spellName)
		end
		if inRange == 1 then
			inRange = true
		elseif inRange ~= true then
			inRange = false
		end
		return inRange
	end
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
	local castTimeLeft = function()	
		local result
		spellname, subText, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("player")			
		if spellname ~= nil then
			result = (endTime - vars.timeSnap*1000)/1000
		else
			spellname, subText, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo("player")
			if spellname ~= nil then
				result = (endTime - vars.timeSnap*1000)/1000
			else
				result = 0
			end
		end
		return result
	end
	local GCDtimeLeft = function()
		local result = 999
		local start, durationc, enable = GetSpellCooldown(61304) --apparently works for all classes/levels."Flash of Light"
		-- not valid so give it a crazy cooldown.
		if durationc == nil then
			result = 999
		elseif durationc == 0 then
			result = 0
		else
			result = start + durationc - vars.timeSnap
		end
		--print(durationc,result)
		return result
	end		
	local spellCD = function(spellName)
		local result = 999
		local count = 0 --GetSpellCharges(spellName)
		local start, durationc, enable = GetSpellCooldown(spellName)
		-- not valid so give it a crazy cooldown.
		if durationc == nil then
			result = 999
		-- check to see if its just a GCD
		elseif durationc < 0 or count > 0 then
			result = 0
		-- otherwise return when it will be off its cd
		else
			result = start + durationc - vars.timeSnap
			if result < 0 then
				result = 0
			end
		end
		return result
	end	
	function e:UNIT_SPELLCAST_SUCCEEDED(...)
		local unitID, spellName, rank, lineID, spellID = ...
	end
	function memberToHeal()	
		--/script print(CompactPartyFrame:GetChildren())
		--/script print(CompactRaidGroup3Member3)CompactRaidGroupYMemberX
		local groupCount, groupType, testUnitID, priorityHealth, priorityMaxHealth, priorityHealthDeficit, health, maxHealth, healthPercent, tmpInc
		groupCount = GetNumGroupMembers()
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
		vars.priority.healthPercent = 2
		vars.priority.spell = ""
		vars.priority.unit = "player"
		vars.priority.raidFrame = nil
		vars.aoeCount = 0
		for i = 1, groupCount do
			testUnitID = getActionUnitID(groupType, i)			
			health = UnitHealth(testUnitID)
			maxHealth = UnitHealthMax(testUnitID)
			tmpInc = UnitGetIncomingHeals(testUnitID)
			if tmpInc == nil then
				tmpInc = 0
			end
			healthInc = health + tmpInc
			if healthInc > maxHealth then
				healthInc = maxHealth
			end
			healthPercent = healthInc/maxHealth
			if not UnitIsDeadOrGhost(testUnitID) and isCastableOn(testUnitID) then -- and isCastableOn(testUnitID)
				if healthPercent < .9 then
					vars.aoeCount = vars.aoeCount + 1
				end
				if healthPercent < vars.priority.healthPercent then
					vars.priority.health = health
					vars.priority.maxHealth = maxHealth
					vars.priority.healthInc = healthInc
					vars.priority.healthPercent = healthPercent
					vars.priority.unitID = testUnitID
				end
			end
		end
		if vars.priority.healthPercent == 2 then
			testUnitID = getActionUnitID(groupType, 1)
			health = UnitHealth(testUnitID)
			maxHealth = UnitHealthMax(testUnitID)
			healthInc = health + UnitGetIncomingHeals(testUnitID)
			if healthInc > maxHealth then
				healthInc = maxHealth
			end
			healthPercent = healthInc/maxHealth
			vars.priority.health = health
			vars.priority.maxHealth = maxHealth
			vars.priority.healthInc = healthInc
			vars.priority.healthPercent = healthPercent
			vars.priority.unitID = testUnitID
		end
		if groupType == "party" then
			for i = 1, 5 do
				if _G["CompactPartyFrameMember"..i] ~= nil and _G["CompactPartyFrameMember"..i].unit == vars.priority.unitID then
					vars.priority.raidFrame = _G["CompactPartyFrameMember"..i]
				elseif _G["CompactRaidFrame"..i] ~= nil and _G["CompactRaidFrame"..i].unit == vars.priority.unitID then
					vars.priority.raidFrame = _G["CompactRaidFrame"..i]
				end
			end
		else
			for p = 1, 8 do
				for m = 1, 5 do
					if _G["CompactRaidGroup"..p.."Member"..m] ~= nil and _G["CompactRaidGroup"..p.."Member"..m].unit == vars.priority.unitID then
						vars.priority.raidFrame = _G["CompactRaidGroup"..p.."Member"..m]
					end
				end
			end
		end
	end
	function monkHealToUse()
		if spellCD("Vivify") <= vars.timeToAct and vars.priority.healthPercent < .9 then
			vars.priority.spell = "Vivify"
		else
			vars.priority.spell = ""
		end	
		--print(vars.priority.spell)
	end
	function paladinHealToUse()		
		if spellCD("Light of Dawn") <= vars.timeToAct and vars.aoeCount > 2 then
			vars.priority.spell = "Light of Dawn"
		elseif vars.priority.healthPercent == 0 then
			vars.priority.spell = ""
		elseif spellCD("Holy Shock") <= vars.timeToAct and vars.priority.healthPercent < .9 then
			vars.priority.spell = "Holy Shock"
		elseif spellCD("Flash of Light") <= vars.timeToAct and vars.priority.healthPercent < .9 then
			vars.priority.spell = "Flash of Light"
		elseif spellCD("Judgment") <= vars.timeToAct and IsSpellInRange("Judgment", "target") == 1 then
			vars.priority.spell = "Judgment"
		elseif spellCD("Holy Shock") <= vars.timeToAct and IsSpellInRange("Holy Shock", "target") == 1 then
			vars.priority.spell = "Holy Shock"
		elseif spellCD("Crusader Strike") <= vars.timeToAct and IsSpellInRange("Crusader Strike", "target") == 1 then
			vars.priority.spell = "Crusader Strike"
		else
			vars.priority.spell = ""
		end
	end
	function healToUse()		
		if UnitClass("player") == "Monk" then
			if GetSpecialization() == 2 then
				vars.friendlyRangeCheck = "Vivify"
				monkHealToUse()
			end
		elseif UnitClass("player") == "Paladin" then
			if GetSpecialization() == 1 then
				vars.friendlyRangeCheck = "Flash of Light"
				paladinHealToUse()
			end
		end
	end
	function main()
		-- vars.raidframes are unitframes
		-- vars.raidframes.unit is the raidID
		if castTimeLeft() > GCDtimeLeft() then
			vars.timeToAct = castTimeLeft()
		else
			vars.timeToAct = GCDtimeLeft()
		end
		
		memberToHeal()	
		
		healToUse()
		--print(vars.priority.raidFrame)
		if vars.priority.raidFrame ~= nil then
			local left, bottom, width, height = vars.priority.raidFrame:GetRect()
			local ih = height - 20
			vars.prioritySpellIcon.frame:SetWidth(ih)
			vars.prioritySpellIcon.frame:SetHeight(ih)
			vars.prioritySpellIcon.frame:SetPoint("BOTTOMLEFT", left + width/2 - ih/2, bottom + 10)
		end
		local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(vars.priority.spell)
		vars.prioritySpellIcon.texture:SetTexture(GetSpellTexture(spellID))
	end
	function e:PLAYER_LOGIN(...)
		f:SetScript("OnUpdate", function(self, elapsed)
		  timer = timer + elapsed
		  if timer >= CYCLE_TIME then
			vars.timeSnap = GetTime()
			timer = 0
			main()
		  end
		end)
	end
	f:SetScript("OnEvent", function(self, event, ...)
		e[event](self, ...) -- call one of the functions above
	end)

	for k, v in pairs(e) do
	   f:RegisterEvent(k) -- Register all events for which handlers have been defined
	end
	
	return self
	
end
Priorities = classPriorities()