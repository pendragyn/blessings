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
	vars.spellCasting = ""
	vars.spellTarget = ""
	vars.timeSnap = 0
	vars.jumping = vars.timeSnap
	vars.priority = {}
	vars.priority.spell = "Holy Shock"
	vars.priority.unit = "player"
	vars.priority.raidFrame = ""
	vars.aoeCount = 0
	vars.cds = {}
	
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
	
	for i = 1,10 do
		vars.cds[i] = {}
		vars.cds[i].frame = CreateFrame("Frame", "vars.cds["..i.."]", UIParent)
		vars.cds[i].frame:SetFrameStrata("HIGH")
		vars.cds[i].frame:SetWidth(24)
		vars.cds[i].frame:SetHeight(24)
		vars.cds[i].texture = vars.cds[i].frame:CreateTexture(nil,"OVERLAY ")
		vars.cds[i].texture:SetAllPoints(vars.cds[i].frame)	
		vars.cds[i].frame.texture = vars.cds[i].texture
		vars.cds[i].frame:SetPoint("BOTTOMLEFT", 0, 0)
		vars.cds[i].frame:Hide()
		vars.cds[i].frame:SetFrameLevel(17-i)
		vars.cds[i].texture:SetTexture(GetSpellTexture(spellID))
		vars.cds[i].cd = vars.cds[i].frame:CreateFontString(nil, "TOOLTIP", "GameTooltipText")
		vars.cds[i].cd:SetText("")
		vars.cds[i].cd:SetPoint("CENTER", 0,0)
		vars.cds[i].cd:SetTextColor(1.0,1.0,1.0,0.8)
		vars.cds[i].cd:SetFont("Fonts\\FRIZQT__.TTF", 24, "THICKOUTLINE")
	end
	local function distanceBetweenUs(unit1, unit2)
		local result = 999
		local y1, x1, _, instance1 = UnitPosition(unit1)
		local y2, x2, _, instance2 = UnitPosition(unit2)
		--x1 = nil
		if x1 ~= nil and x2 ~= nil then
			result = ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
		else
			if unit1 == "player" then
				if IsItemInRange(37727, unit2) then
					result = 5
				elseif IsItemInRange(63427, unit2) then
					result = 6
				elseif IsItemInRange(34368, unit2) then
					result = 8
				elseif IsItemInRange(32321, unit2) then
					result = 10
				elseif IsItemInRange(1251, unit2) or IsItemInRange(33069, unit2) then
					result = 15
				elseif IsItemInRange(21519, unit2) then
					result = 20
				elseif IsItemInRange(31463, unit2) then
					result = 25
				elseif IsItemInRange(34191, unit2) then
					result = 30
				elseif IsItemInRange(18904, unit2) then
					result = 35
				elseif IsItemInRange(34471, unit2) then
					result = 40
				elseif IsItemInRange(32698, unit2) then
					result = 45
				elseif IsItemInRange(116139, unit2) then
					result = 50
				elseif IsItemInRange(32825, unit2) then
					result = 60
				elseif CheckInteractDistance(unit2, 2) then
					result = 8
				elseif CheckInteractDistance(unit2, 4) then
					result = 28
				end				
			end
			--print(result)
		end
		return result
	end
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
			--disabled channeling on soothing mist. gave crazy times.
			if spellname ~= nil and spellname ~= "Soothing Mist" then
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
		-- If the spell is on CD durationc will be the spell's CD.  otherwise it will be a GCD which is never more than 2
		elseif durationc <= 2 or count > 0 then
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
	local function auraDuration(unitID, aura, filter)
		local expiresIn
		local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3 = UnitAura(unitID,aura,nil,filter)
		if expires == nil then
			expiresIn = 0 
		--spell with no duration expires = 0
		elseif expires == 0 then
			expiresIn = 999999			
		else
			expiresIn = expires - vars.timeSnap
		end
		result = expiresIn	
		return result
	end
	vars.talentChosen = function(row,col,unit)
		local result = false
		local talentID, name, texture, selected, available = GetTalentInfo(row, col, 1, false, unit)
		result = selected
		return selected
	end	
	vars.isMoving = function(unitName)
		local speed = GetUnitSpeed(unitName)
		-- disabled casting while moving effects.  need to fix.
		-- if hasBuff(unitName,"Ice Floes",0) then
			-- return false
		-- else
		if speed > 0 then
			return true
		elseif (vars.timeSnap - vars.jumping) < .5 then
			return true
		else
			return false
		end		
	end
	function memberToHeal()	
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
		vars.priority.unit = ""
		vars.priority.raidFrame = nil
		vars.aoeCount = 0
		for i = 1, groupCount do
			testUnitID = getActionUnitID(groupType, i)
			if not UnitIsDeadOrGhost(testUnitID) and isCastableOn(testUnitID) then -- and isCastableOn(testUnitID)			
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
				
				-- class specific stuff
				if UnitClass("player") == "Monk" and distanceBetweenUs("player", testUnitID) <= 25 then
					if healthPercent < .9 then
						vars.aoeCount = vars.aoeCount + 1
					end
				elseif UnitClass("player") == "Paladin" and distanceBetweenUs("player", testUnitID) <= 15 then
					if healthPercent < .9 then
						vars.aoeCount = vars.aoeCount + 1
					end
				end
				
				if healthPercent < vars.priority.healthPercent then
					vars.priority.health = health
					vars.priority.maxHealth = maxHealth
					vars.priority.healthInc = healthInc
					vars.priority.healthPercent = healthPercent
					vars.priority.unitID = testUnitID
				end
				--
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
			-- if groupCount == 1 then
				-- vars.priority.raidFrame = vars.cds[1].frame
			-- else
			if CompactUnitFrameProfilesGeneralOptionsFrameKeepGroupsTogether:GetChecked() then
				--In party keep groups together is CompactPartyFrameMemberM pets are CompactRaidFrameX
				for i = 1, 5 do
					if _G["CompactPartyFrameMember"..i] ~= nil and _G["CompactPartyFrameMember"..i].unit == vars.priority.unitID and _G["CompactPartyFrameMember"..i]:IsVisible() then
						vars.priority.raidFrame = _G["CompactPartyFrameMember"..i]
					end
				end
			else
				--In party no groups together is CompactRaidFrameX pets the same
				for i = 1, 10 do
					if _G["CompactRaidFrame"..i] ~= nil and _G["CompactRaidFrame"..i].unit == vars.priority.unitID and _G["CompactRaidFrame"..i]:IsVisible() then
						vars.priority.raidFrame = _G["CompactRaidFrame"..i]
					end
				end
			end
		else --raid
			if CompactUnitFrameProfilesGeneralOptionsFrameKeepGroupsTogether:GetChecked() then
				--In raids keep groups together is CompactRaidGroupGMemberM pets are CompactRaidFrameX
				for p = 1, 8 do
					for m = 1, 5 do
						if _G["CompactRaidGroup"..p.."Member"..m] ~= nil and _G["CompactRaidGroup"..p.."Member"..m].unit == vars.priority.unitID and _G["CompactRaidGroup"..p.."Member"..m]:IsVisible() then
							vars.priority.raidFrame = _G["CompactRaidGroup"..p.."Member"..m]
						end
					end
				end
			else
				--In raids no groups together is CompactRaidFrameX pets the same
				for m = 1, 50 do
					if _G["CompactRaidFrame"..m] ~= nil and _G["CompactRaidFrame"..m].unit == vars.priority.unitID and _G["CompactRaidFrame"..m]:IsVisible() then
						vars.priority.raidFrame = _G["CompactRaidFrame"..m]
					end
				end
			end
		end
	end
	function monkHealToUse()
		--print(math.floor(vars.priority.healthPercent*100))
		if spellCD("Essence Font") <= vars.timeToAct and vars.talentChosen(1,1,"player") and vars.aoeCount > 4 and not vars.isMoving("player") then
			vars.priority.spell = "Essence Font"
		elseif spellCD("Life Cocoon") <= vars.timeToAct and vars.priority.healthPercent < .5 then
			vars.priority.spell = "Life Cocoon"
		elseif spellCD("Renewing Mist") <= vars.timeToAct and vars.spellCasting ~= "Renewing Mist" and auraDuration(vars.priority.unitID,"Renewing Mist","HELPFUL") < 2 and vars.priority.healthPercent < .9 then
			vars.priority.spell = "Renewing Mist"
		elseif spellCD("Enveloping Mist") <= vars.timeToAct and vars.spellCasting ~= "Enveloping Mist" and auraDuration(vars.priority.unitID,"Enveloping Mist","HELPFUL") < 2 and vars.priority.healthPercent < .9 and not vars.isMoving("player") then
			vars.priority.spell = "Enveloping Mist"
		elseif spellCD("Vivify") <= vars.timeToAct and vars.priority.healthPercent < .7 and not vars.isMoving("player") then
			vars.priority.spell = "Vivify"
		elseif spellCD("Effuse") <= vars.timeToAct and vars.priority.healthPercent < .9 and not vars.isMoving("player") then
			vars.priority.spell = "Effuse"
		elseif spellCD("Tiger Palm") <= vars.timeToAct and IsSpellInRange("Tiger Palm", "target") == 1 then
			vars.priority.spell = "Tiger Palm"
		else
			vars.priority.spell = ""
		end	
	end
	function paladinHealToUse()		
		if spellCD("Light of Dawn") <= vars.timeToAct and vars.aoeCount > 2 then
			vars.priority.spell = "Light of Dawn"
		elseif vars.priority.healthPercent == 0 then
			vars.priority.spell = ""
		elseif spellCD("Holy Shock") <= vars.timeToAct and IsSpellInRange("Holy Shock", vars.priority.unitID) == 1 and vars.priority.healthPercent < .9 then
			vars.priority.spell = "Holy Shock"
		elseif spellCD("Flash of Light") <= vars.timeToAct and vars.priority.healthPercent < .9 and not vars.isMoving("player") then
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
		if vars.priority.raidFrame ~= nil then
			--print(vars.priority.raidFrame:GetName())
			local left, bottom, width, height = vars.priority.raidFrame:GetRect()
			local ih = height*.6
			-- if vars.priority.raidFrame == vars.cds[1].frame then
				-- ih = 50
				-- vars.prioritySpellIcon.frame:SetWidth(ih)
				-- vars.prioritySpellIcon.frame:SetHeight(ih)
				-- vars.prioritySpellIcon.frame:SetPoint("BOTTOMLEFT", left-ih*2, bottom)
			-- else
				vars.prioritySpellIcon.frame:SetWidth(ih)
				vars.prioritySpellIcon.frame:SetHeight(ih)
				vars.prioritySpellIcon.frame:SetPoint("BOTTOMLEFT", left + width/2 - ih/2, bottom + height*.2)
			--end
		else
			--print(vars.priority.raidFrame)
		end
		local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(vars.priority.spell)
		vars.prioritySpellIcon.texture:SetTexture(GetSpellTexture(spellID))
		vars.renderCDs()
	end
	vars.renderCDs = function()		
		local left, bottom, width, height = CompactRaidFrameContainer:GetRect()
		local ih = vars.prioritySpellIcon.frame:GetWidth()
		for i = 1,10 do
			if vars.cds[i].spellName ~= "" then
				local cd = spellCD(vars.cds[i].spellName)
				local float = 0
				if cd <= 20 then
					float = (width-50)*(1-cd/20)
				end
				cd = math.ceil(cd)
				if cd > 60 then
					cd = math.ceil(cd/60)
				end
				vars.cds[i].cd:SetFont("Fonts\\FRIZQT__.TTF", math.floor(ih*.6), "THICKOUTLINE")
				if cd == 0 then				
					vars.cds[i].cd:SetText("")
				else
					vars.cds[i].cd:SetText(cd)
				end
				vars.cds[i].frame:SetWidth(ih)
				vars.cds[i].frame:SetHeight(ih)
				local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(vars.cds[i].spellName)
				vars.cds[i].texture:SetTexture(GetSpellTexture(spellID))
				vars.cds[i].frame:SetPoint("BOTTOMLEFT", left + width - float, bottom + height)
				vars.cds[i].frame:Show()
				--if cd == 0 then
					left = left + ih
					width = width - ih
				--elseif cd > 20 then
					width = width - ih
				--end
			else
				vars.cds[i].frame:Hide()
			end
		end
	end
	function buildCDs()
		for i = 1,10 do
			vars.cds[i].spellName = ""
			vars.cds[i].priority = i
			vars.cds[i].order = i
			vars.cds[i].frame:Hide()
		end
		if UnitClass("player") == "Monk" then
			if GetSpecialization() == 2 then
				vars.cds[1].spellName = "Life Cocoon"
				vars.cds[2].spellName = "Renewing Mist"
				vars.cds[3].spellName = "Revival"
				vars.cds[4].spellName = "Detox"
				vars.cds[5].spellName = "Healing Elixir"
				vars.cds[6].spellName = "Invoke Chi-Ji, the Red Crane"
				vars.cds[7].spellName = "Paralysis"
				vars.cds[8].spellName = "Rising Sun Kick"
				vars.cds[9].spellName = "Roll"
				vars.cds[10].spellName = "Song of Chi-Ji"
			end
		elseif UnitClass("player") == "Paladin" then
			if GetSpecialization() == 1 then
			end
		end
	end
	function e:UNIT_SPELLCAST_SUCCEEDED(...)
		local unitID, spellName, rank, lineID, spellID = ...
	end
	function e:UNIT_SPELLCAST_START(...)
		local unitID, spellName, rank, lineID, spellID = ...
		if UnitIsUnit(unitID,"player") then
			vars.spellCasting = spellName
			vars.spellTarget = vars.priority.unitID
		end
	end	
	function e:UNIT_SPELLCAST_END(...)
		local unitID, spellName, rank, lineID, spellID = ...
		if UnitIsUnit(unitID,"player") then
			vars.spellCasting = ""
			vars.spellTarget = ""
		end
	end	
	function e:PLAYER_LOGIN(...)
		buildCDs()
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
	local function hook_JumpOrAscendStart(...)
	   if startjump == 0 then
	     startjump = vars.timeSnap
	   end	   
	  vars.jumping = vars.timeSnap
	end
	hooksecurefunc("JumpOrAscendStart", hook_JumpOrAscendStart)
	
	return self
	
end
Priorities = classPriorities()