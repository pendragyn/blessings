PrioritiesDB = {}
local function classPriorities()
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
	vars.aoeCount1 = 0
	vars.playerMaxHealth = UnitHealthMax("player")
	vars.cds = {}
	vars.menuButton = CreateFrame("Button", nil, UIParent, "UIPanelInfoButton")
	vars.menuButton:SetPoint("BOTTOMLEFT", 0, 0)
	vars.menuButton:SetScript("OnClick", function(self, button, down)
		local c = UnitClass("player")
		local s = GetSpecialization()
		if vars.options[c] ~= nil then
			if vars.options[c][s] ~= nil then
				vars.options[c][s].frame:Show()
			end
		end
	end)
	vars.buildLines = function(args)
		args.var = args.frame:CreateFontString(nil, "TOOLTIP", "GameTooltipText")
		args.var:SetText(args.text)
		args.var:SetPoint("TOPLEFT", args.left,args.top)
		args.var:SetTextColor(1.0,1.0,1.0,0.8)
		args.var:SetFont("Fonts\\FRIZQT__.TTF", 12, "THICKOUTLINE")
	end
	
	vars.buildFrames = function(args)
		args.var.frame = CreateFrame("Frame", tostring(args.var)..".frame", UIParent, "BasicFrameTemplateWithInset")
		args.var.frame:SetWidth(args.width)
		args.var.frame:SetHeight(args.height)
		args.var.frame:SetPoint("CENTER", 0, 100)
		args.var.frame:Hide()
	end	
	vars.buildFields = function(args)
		-- create args.var outside and pass it to the function to make it referenceable later
		args.var:SetPoint("TOPLEFT", args.left, args.top)
		args.var:SetWidth(args.width) 
		args.var:SetHeight(13) 
		args.var:SetAlpha(1.0)
		args.var:SetNumber(args.defaultval)
		args.var:EnableKeyboard(false)
		args.var.step = args.step
		args.var.minval = args.minval
		args.var.maxval = args.maxval
		args.var.savetable = args.savetable
		args.var.savevar = args.savevar
		args.var:SetScript("OnMouseWheel", function(self, delta)
			self:SetText(math.floor(self:GetNumber()+delta*self.step))
			if self:GetNumber() > self.maxval then
				self:SetText(self.maxval)
			elseif self:GetNumber() < self.minval then
				self:SetText(self.minval)
			end
			self.savetable[self.savevar] = self:GetNumber()
		end)
	end
	vars.buildCDfield = function(args)
		local cdstring = ""
		for i = 1,#args.defaultval do
			cdstring = cdstring .. args.defaultval[i].."|"
		end
		-- create args.var outside and pass it to the function to make it referenceable later
		args.var:SetPoint("TOPLEFT", args.left, args.top)
		args.var:SetWidth(args.width) 
		args.var:SetHeight(args.height) 
		args.var:SetAlpha(1.0)
		args.var:SetText(cdstring)
		args.var:EnableKeyboard(true)
		args.var.step = args.step
		args.var.minval = args.minval
		args.var.maxval = args.maxval
		args.var.savetable = args.savetable
		args.var.savevar = args.savevar
		args.var:SetScript("OnEditFocusLost", function(self)
			local i = 1
			local vi = 1
			local v = self:GetText()
			local spell = ""
			self.savetable[self.savevar] = {}
			for i = 1,string.len(v) do
				c = string.sub(v, i, i)
				if c == "|" then
					self.savetable[self.savevar][vi] = spell
					spell = ""
					vi = vi + 1
				else
					spell = spell .. c
				end
			end
			parseSpellCDs(self.savetable[self.savevar])
		end)
	end
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
		
	vars.options = {}
	
	vars.buildOptions = {}
	
	vars.buildOptions.Monk = {}	
	
	vars.buildOptions.Monk[2] = function()
		if vars.options.Monk == nil then
			--monk options
			vars.options.Monk = {}
		end
		if PrioritiesDB.Monk == nil then
			PrioritiesDB.Monk = {}				
		end			
		if vars.options.Monk[2] == nil then			
			if PrioritiesDB.Monk[2] == nil then
				PrioritiesDB.Monk[2] = {}				
			end			
			--monk mistweaver options
			vars.options.Monk[2] = {}
			vars.buildFrames({var = vars.options.Monk[2], width = 1000, height = 400})
			
			if PrioritiesDB.Monk[2].lines == nil then
				PrioritiesDB.Monk[2].lines = {}				
			end			
			vars.options.Monk[2].lines = {}
			-- Cocoon
			if PrioritiesDB.Monk[2].lines[1] == nil then
				PrioritiesDB.Monk[2].lines[1] = {}				
			end			
			vars.options.Monk[2].lines[1] = {}
			vars.buildLines({var = vars.options.Monk[2].lines[1].text1, frame = vars.options.Monk[2].frame, text = "Life Cocoon if priority unit's health is below", left = 10, top = -50})
			
			if PrioritiesDB.Monk[2].lines[1].healthPerc == nil then
				PrioritiesDB.Monk[2].lines[1].healthPerc = 25				
			end						
			vars.options.Monk[2].lines[1].healthPerc = CreateFrame("EditBox", "vars.options.Monk[2].lines[1].healthPerc", vars.options.Monk[2].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Monk[2].lines[1].healthPerc, frame = vars.options.Monk[2].frame, width = 30, step = 5, minval = 0, maxval = 100,defaultval = PrioritiesDB.Monk[2].lines[1].healthPerc, top = -50, left = 350, savetable = PrioritiesDB.Monk[2].lines[1], savevar = "healthPerc"})
			
			vars.buildLines({var = vars.options.Monk[2].lines[1].text2, frame = vars.options.Monk[2].frame, text = "%.", left = 380, top = -50})
			
			
			--essence font
			if PrioritiesDB.Monk[2].lines[2] == nil then
				PrioritiesDB.Monk[2].lines[2] = {}				
			end			
			vars.options.Monk[2].lines[2] = {}
			vars.buildLines({var = vars.options.Monk[2].lines[2].text1, frame = vars.options.Monk[2].frame, text = "Essence Font if at least", left = 10, top = -70})	
			
			if PrioritiesDB.Monk[2].lines[2].aoeCount == nil then
				PrioritiesDB.Monk[2].lines[2].aoeCount = 5				
			end		
			vars.options.Monk[2].lines[2].aoeCount = CreateFrame("EditBox", "vars.options.Monk[2].lines[2].aoeCount", vars.options.Monk[2].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Monk[2].lines[2].aoeCount, frame = vars.options.Monk[2].frame, width = 20, step = 1, minval = 0, maxval = 40,defaultval = PrioritiesDB.Monk[2].lines[2].aoeCount, top = -70, left = 190, savetable = PrioritiesDB.Monk[2].lines[2], savevar = "aoeCount"})
			
			vars.buildLines({var = vars.options.Monk[2].lines[2].text2, frame = vars.options.Monk[2].frame, text = "raid members are within range and below", left = 215, top = -70})
			
			if PrioritiesDB.Monk[2].lines[2].aoePercent == nil then
				PrioritiesDB.Monk[2].lines[2].aoePercent = 90				
			end			
			vars.options.Monk[2].lines[2].aoePercent = CreateFrame("EditBox", "vars.options.Monk[2].lines[2].aoePercent", vars.options.Monk[2].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Monk[2].lines[2].aoePercent, frame = vars.options.Monk[2].frame, width = 30, step = 5, minval = 0, maxval = 100,defaultval = PrioritiesDB.Monk[2].lines[2].aoePercent, top = -70, left = 525, savetable = PrioritiesDB.Monk[2].lines[2], savevar = "aoePercent"})
			
			vars.buildLines({var = vars.options.Monk[2].lines[2].text3, frame = vars.options.Monk[2].frame, text = "% health and no more than", left = 560, top = -70})	
			
			if PrioritiesDB.Monk[2].lines[2].buffCount == nil then
				PrioritiesDB.Monk[2].lines[2].buffCount = 2			
			end		
			vars.options.Monk[2].lines[2].buffCount = CreateFrame("EditBox", "vars.options.Monk[2].lines[2].buffCount", vars.options.Monk[2].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Monk[2].lines[2].buffCount, frame = vars.options.Monk[2].frame, width = 20, step = 1, minval = 0, maxval = 40,defaultval = PrioritiesDB.Monk[2].lines[2].buffCount, top = -70, left = 770, savetable = PrioritiesDB.Monk[2].lines[2], savevar = "buffCount"})
			
			vars.buildLines({var = vars.options.Monk[2].lines[2].text4, frame = vars.options.Monk[2].frame, text = "raid members", left = 800, top = -90})
			
			vars.buildLines({var = vars.options.Monk[2].lines[2].text4, frame = vars.options.Monk[2].frame, text = "have the Essence font buff and I'm not moving.", left = 560, top = -90})
			
			--renewing mist
			if PrioritiesDB.Monk[2].lines[3] == nil then
				PrioritiesDB.Monk[2].lines[3] = {}				
			end			
			vars.options.Monk[2].lines[3] = {}
			vars.buildLines({var = vars.options.Monk[2].lines[3].text1, frame = vars.options.Monk[2].frame, text = "Renewing Mist if priority unit doesn't have the renewing mist buff and their health is below", left = 10, top = -110})
			
			if PrioritiesDB.Monk[2].lines[3].healthPerc == nil then
				PrioritiesDB.Monk[2].lines[3].healthPerc = 90			
			end		
			vars.options.Monk[2].lines[3].healthPerc = CreateFrame("EditBox", "vars.options.Monk[2].lines[3].healthPerc", vars.options.Monk[2].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Monk[2].lines[3].healthPerc, frame = vars.options.Monk[2].frame, width = 30, step = 5, minval = 0, maxval = 100,defaultval = PrioritiesDB.Monk[2].lines[3].healthPerc, top = -110, left = 700, savetable = PrioritiesDB.Monk[2].lines[3], savevar = "healthPerc"})
			
			vars.buildLines({var = vars.options.Monk[2].lines[3].text2, frame = vars.options.Monk[2].frame, text = "%.", left = 735, top = -110})
			--Enveloping Mist
			if PrioritiesDB.Monk[2].lines[4] == nil then
				PrioritiesDB.Monk[2].lines[4] = {}				
			end			
			vars.options.Monk[2].lines[4] = {}
			vars.buildLines({var = vars.options.Monk[2].lines[3].text1, frame = vars.options.Monk[2].frame, text = "Enveloption Mist if priority unit doesn't have the enveloping mist buff and their health is below", left = 10, top = -130})
			
			if PrioritiesDB.Monk[2].lines[4].healthPerc == nil then
				PrioritiesDB.Monk[2].lines[4].healthPerc = 90				
			end		
			vars.options.Monk[2].lines[4].healthPerc = CreateFrame("EditBox", "vars.options.Monk[2].lines[4].healthPerc", vars.options.Monk[2].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Monk[2].lines[4].healthPerc, frame = vars.options.Monk[2].frame, width = 30, step = 5, minval = 0, maxval = 100,defaultval = PrioritiesDB.Monk[2].lines[4].healthPerc, top = -130, left = 730, savetable = PrioritiesDB.Monk[2].lines[4], savevar = "healthPerc"})
			
			vars.buildLines({var = vars.options.Monk[2].lines[4].text2, frame = vars.options.Monk[2].frame, text = "% and you are not moving or", left = 765, top = -130})
			
			vars.buildLines({var = vars.options.Monk[2].lines[4].text3, frame = vars.options.Monk[2].frame, text = "you have the thunder focus tea buff.", left = 560, top = -150})
			
			--vivify
			if PrioritiesDB.Monk[2].lines[5] == nil then
				PrioritiesDB.Monk[2].lines[5] = {}				
			end			
			vars.options.Monk[2].lines[5] = {}
			vars.buildLines({var = vars.options.Monk[2].lines[5].text1, frame = vars.options.Monk[2].frame, text = "Vivify if priority unit's health is below", left = 10, top = -170})
			
			if PrioritiesDB.Monk[2].lines[5].healthPerc == nil then
				PrioritiesDB.Monk[2].lines[5].healthPerc = 70			
			end		
			vars.options.Monk[2].lines[5].healthPerc = CreateFrame("EditBox", "vars.options.Monk[2].lines[5].healthPerc", vars.options.Monk[2].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Monk[2].lines[5].healthPerc, frame = vars.options.Monk[2].frame, width = 30, step = 5, minval = 0, maxval = 100,defaultval = PrioritiesDB.Monk[2].lines[5].healthPerc, top = -170, left = 300, savetable = PrioritiesDB.Monk[2].lines[5], savevar = "healthPerc"})
			
			vars.buildLines({var = vars.options.Monk[2].lines[5].text2, frame = vars.options.Monk[2].frame, text = "% and you are not moving and there are at least ", left = 335, top = -170})
			
			if PrioritiesDB.Monk[2].lines[5].aoeCount == nil then
				PrioritiesDB.Monk[2].lines[5].aoeCount = 2			
			end		
			vars.options.Monk[2].lines[5].aoeCount = CreateFrame("EditBox", "vars.options.Monk[2].lines[5].healthPerc", vars.options.Monk[2].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Monk[2].lines[5].aoeCount, frame = vars.options.Monk[2].frame, width = 20, step = 1, minval = 0, maxval = 40,defaultval = PrioritiesDB.Monk[2].lines[5].aoeCount, top = -170, left = 700, savetable = PrioritiesDB.Monk[2].lines[5], savevar = "aoeCount"})
			
			vars.buildLines({var = vars.options.Monk[2].lines[5].text3, frame = vars.options.Monk[2].frame, text = "other raid member below ", left = 725, top = -170})
			
			if PrioritiesDB.Monk[2].lines[5].aoePercent == nil then
				PrioritiesDB.Monk[2].lines[5].aoePercent = 90			
			end		
			vars.options.Monk[2].lines[5].aoePercent = CreateFrame("EditBox", "vars.options.Monk[2].lines[5].aoePercent", vars.options.Monk[2].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Monk[2].lines[5].aoePercent, frame = vars.options.Monk[2].frame, width = 30, step = 5, minval = 0, maxval = 100,defaultval = PrioritiesDB.Monk[2].lines[5].aoePercent, top = -170, left = 915, savetable = PrioritiesDB.Monk[2].lines[5], savevar = "aoePercent"})
			
			vars.buildLines({var = vars.options.Monk[2].lines[5].text4, frame = vars.options.Monk[2].frame, text = "%", left = 950, top = -170})
			
			vars.buildLines({var = vars.options.Monk[2].lines[5].text5, frame = vars.options.Monk[2].frame, text = "health or I have the uplifting trance buff.", left = 560, top = -190})
			
			--Effuse	
			if PrioritiesDB.Monk[2].lines[6] == nil then
				PrioritiesDB.Monk[2].lines[6] = {}				
			end			
			vars.options.Monk[2].lines[6] = {}
			vars.buildLines({var = vars.options.Monk[2].lines[6].text1, frame = vars.options.Monk[2].frame, text = "Effuse if priority unit's health is below", left = 10, top = -210})
			
			if PrioritiesDB.Monk[2].lines[6].healthPerc == nil then
				PrioritiesDB.Monk[2].lines[6].healthPerc = 90			
			end		
			vars.options.Monk[2].lines[6].healthPerc = CreateFrame("EditBox", "vars.options.Monk[2].lines[6].healthPerc", vars.options.Monk[2].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Monk[2].lines[6].healthPerc, frame = vars.options.Monk[2].frame, width = 30, step = 5, minval = 0, maxval = 100,defaultval = PrioritiesDB.Monk[2].lines[6].healthPerc, top = -210, left = 310, savetable = PrioritiesDB.Monk[2].lines[6], savevar = "healthPerc"})
			
			vars.buildLines({var = vars.options.Monk[2].lines[6].text2, frame = vars.options.Monk[2].frame, text = "%.", left = 345, top = -190})	
			
			vars.options.Monk[2].lines[7] = {}
			vars.buildLines({var = vars.options.Monk[2].lines[7].text1, frame = vars.options.Monk[2].frame, text = "When in melee range Tiger Palm until you have three stacks of Teachings of the Monastery.", left = 10, top = -230})	
			
			vars.options.Monk[2].lines[8] = {}
			vars.buildLines({var = vars.options.Monk[2].lines[8].text1, frame = vars.options.Monk[2].frame, text = "When in melee range of your target Rising Sun Kick.", left = 10, top = -250})	
			
			vars.options.Monk[2].lines[9] = {}
			vars.buildLines({var = vars.options.Monk[2].lines[9].text1, frame = vars.options.Monk[2].frame, text = "When in melee range of your target Blackout Kick.", left = 10, top = -270})
			
			vars.options.Monk[2].lines[9] = {}
			vars.buildLines({var = vars.options.Monk[2].lines[9].text1, frame = vars.options.Monk[2].frame, text = "When in range of your target Crackling Jade Lightning.", left = 10, top = -290})
			
			vars.options.Monk[2].lines[10] = {}
			vars.buildLines({var = vars.options.Monk[2].lines[9].text1, frame = vars.options.Monk[2].frame, text = "Sheilun's Gift when it has at least 4 stacks and a non crit wont have any overhealing.", left = 10, top = -30})
			
			--CDs
			vars.options.Monk[2].lines[11] = {}
			vars.buildLines({var = vars.options.Monk[2].lines[11].text1, frame = vars.options.Monk[2].frame, text = "CDs.  Use Talent Row X for talent CDS. Include a | after each item.", left = 10, top = -330})			
								
			vars.options.Monk[2].CDS = CreateFrame("EditBox", "vars.options.Monk[2].CDS", vars.options.Monk[2].frame, "InputBoxTemplate")
			vars.buildCDfield({var = vars.options.Monk[2].CDS, frame = vars.options.Monk[2].frame, width = 980, height = 13, step = 5, minval = 0, maxval = 100, defaultval = PrioritiesDB.Monk[2].CDS, top = -350, left = 10, savetable = PrioritiesDB.Monk[2], savevar = "CDS"})
		end
	end
	
	vars.buildOptions.Paladin = {}
	vars.buildOptions.Paladin[1] = function()
		if vars.options.Paladin == nil then
			--monk options
			vars.options.Paladin = {}
		end
		if PrioritiesDB.Paladin == nil then
			PrioritiesDB.Paladin = {}				
		end			
		if vars.options.Paladin[1] == nil then			
			if PrioritiesDB.Paladin[1] == nil then
				PrioritiesDB.Paladin[1] = {}				
			end			
			--Paladin holy options
			vars.options.Paladin[1] = {}
			vars.buildFrames({var = vars.options.Paladin[1], width = 1000, height = 370})
			
			if PrioritiesDB.Paladin[1].lines == nil then
				PrioritiesDB.Paladin[1].lines = {}				
			end			
			vars.options.Paladin[1].lines = {}
			-- Holy Shock
			if PrioritiesDB.Paladin[1].lines[1] == nil then
				PrioritiesDB.Paladin[1].lines[1] = {}				
			end			
			vars.options.Paladin[1].lines[1] = {}
			vars.buildLines({var = vars.options.Paladin[1].lines[1].text1, frame = vars.options.Paladin[1].frame, text = "Holy Shock if priority unit's health is below", left = 10, top = -30})
			
			if PrioritiesDB.Paladin[1].lines[1].healthPerc == nil then
				PrioritiesDB.Paladin[1].lines[1].healthPerc = 90			
			end						
			vars.options.Paladin[1].lines[1].healthPerc = CreateFrame("EditBox", "vars.options.Paladin[1].lines[1].healthPerc", vars.options.Paladin[1].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Paladin[1].lines[1].healthPerc, frame = vars.options.Paladin[1].frame, width = 30, step = 5, minval = 0, maxval = 100,defaultval = PrioritiesDB.Paladin[1].lines[1].healthPerc, top = -30, left = 350, savetable = PrioritiesDB.Paladin[1].lines[1], savevar = "healthPerc"})
			
			vars.buildLines({var = vars.options.Paladin[1].lines[1].text2, frame = vars.options.Paladin[1].frame, text = "%.", left = 380, top = -30})	
			--Holy Shock damage		
			vars.options.Paladin[1].lines[2] = {}
			vars.buildLines({var = vars.options.Paladin[1].lines[2].text1, frame = vars.options.Paladin[1].frame, text = "Holy Shock hostile if targeted and in range", left = 10, top = -50})
			--Light of Dawn			
			if PrioritiesDB.Paladin[1].lines[3] == nil then
				PrioritiesDB.Paladin[1].lines[3] = {}				
			end			
			vars.options.Paladin[1].lines[3] = {}
			vars.buildLines({var = vars.options.Paladin[1].lines[3].text1, frame = vars.options.Paladin[1].frame, text = "Light of Dawn if ", left = 10, top = -70})
			
			if PrioritiesDB.Paladin[1].lines[3].aoeCount == nil then
				PrioritiesDB.Paladin[1].lines[3].aoeCount = 3				
			end						
			vars.options.Paladin[1].lines[3].aoeCount = CreateFrame("EditBox", "vars.options.Paladin[1].lines[3].aoeCount", vars.options.Paladin[1].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Paladin[1].lines[3].aoeCount, frame = vars.options.Paladin[1].frame, width = 20, step = 1, minval = 0, maxval = 40,defaultval = PrioritiesDB.Paladin[1].lines[3].aoeCount, top = -70, left = 150, savetable = PrioritiesDB.Paladin[1].lines[3], savevar = "aoeCount"})
			
			vars.buildLines({var = vars.options.Paladin[1].lines[3].text2, frame = vars.options.Paladin[1].frame, text = "raid members are below", left = 175, top = -70})	
			
			if PrioritiesDB.Paladin[1].lines[3].aoePercent == nil then
				PrioritiesDB.Paladin[1].lines[3].aoePercent = 90			
			end						
			vars.options.Paladin[1].lines[3].aoePercent = CreateFrame("EditBox", "vars.options.Paladin[1].lines[3].aoePercent", vars.options.Paladin[1].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Paladin[1].lines[3].aoePercent, frame = vars.options.Paladin[1].frame, width = 30, step = 5, minval = 0, maxval = 100,defaultval = PrioritiesDB.Paladin[1].lines[3].aoePercent, top = -70, left = 355, savetable = PrioritiesDB.Paladin[1].lines[3], savevar = "aoePercent"})
			
			vars.buildLines({var = vars.options.Paladin[1].lines[3].text2, frame = vars.options.Paladin[1].frame, text = "% and in range.", left = 385, top = -70})
			--judgment of light	
			vars.options.Paladin[1].lines[4] = {}
			vars.buildLines({var = vars.options.Paladin[1].lines[4].text1, frame = vars.options.Paladin[1].frame, text = "Judgment hostile if targeted and in range and using judgment of light", left = 10, top = -90})
			--Holy Prism			
			if PrioritiesDB.Paladin[1].lines[5] == nil then
				PrioritiesDB.Paladin[1].lines[5] = {}				
			end			
			vars.options.Paladin[1].lines[5] = {}
			vars.buildLines({var = vars.options.Paladin[1].lines[5].text1, frame = vars.options.Paladin[1].frame, text = "Holy Prism if ", left = 10, top = -110})
			
			if PrioritiesDB.Paladin[1].lines[5].aoeCount == nil then
				PrioritiesDB.Paladin[1].lines[5].aoeCount = 3				
			end						
			vars.options.Paladin[1].lines[5].aoeCount = CreateFrame("EditBox", "vars.options.Paladin[1].lines[5].aoeCount", vars.options.Paladin[1].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Paladin[1].lines[5].aoeCount, frame = vars.options.Paladin[1].frame, width = 20, step = 1, minval = 0, maxval = 40,defaultval = PrioritiesDB.Paladin[1].lines[5].aoeCount, top = -110, left = 120, savetable = PrioritiesDB.Paladin[1].lines[5], savevar = "aoeCount"})
			
			vars.buildLines({var = vars.options.Paladin[1].lines[5].text2, frame = vars.options.Paladin[1].frame, text = "raid members are below", left = 145, top = -110})	
			
			if PrioritiesDB.Paladin[1].lines[5].aoePercent == nil then
				PrioritiesDB.Paladin[1].lines[5].aoePercent = 90			
			end						
			vars.options.Paladin[1].lines[5].aoePercent = CreateFrame("EditBox", "vars.options.Paladin[1].lines[5].aoePercent", vars.options.Paladin[1].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Paladin[1].lines[5].aoePercent, frame = vars.options.Paladin[1].frame, width = 30, step = 5, minval = 0, maxval = 100,defaultval = PrioritiesDB.Paladin[1].lines[5].aoePercent, top = -110, left = 325, savetable = PrioritiesDB.Paladin[1].lines[5], savevar = "aoePercent"})
			
			vars.buildLines({var = vars.options.Paladin[1].lines[5].text2, frame = vars.options.Paladin[1].frame, text = "% and in range.", left = 355, top = -110})
			
			-- Bestow Faith
			if PrioritiesDB.Paladin[1].lines[6] == nil then
				PrioritiesDB.Paladin[1].lines[6] = {}				
			end			
			vars.options.Paladin[1].lines[6] = {}
			vars.buildLines({var = vars.options.Paladin[1].lines[6].text1, frame = vars.options.Paladin[1].frame, text = "Bestow Faith if priority unit's health is below", left = 10, top = -130})
			
			if PrioritiesDB.Paladin[1].lines[6].healthPerc == nil then
				PrioritiesDB.Paladin[1].lines[6].healthPerc = 90				
			end						
			vars.options.Paladin[1].lines[6].healthPerc = CreateFrame("EditBox", "vars.options.Paladin[1].lines[6].healthPerc", vars.options.Paladin[1].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Paladin[1].lines[6].healthPerc, frame = vars.options.Paladin[1].frame, width = 30, step = 5, minval = 0, maxval = 100,defaultval = PrioritiesDB.Paladin[1].lines[6].healthPerc, top = -130, left = 350, savetable = PrioritiesDB.Paladin[1].lines[6], savevar = "healthPerc"})
			
			vars.buildLines({var = vars.options.Paladin[1].lines[6].text2, frame = vars.options.Paladin[1].frame, text = "%.", left = 380, top = -130})	
			--Tyr's Deliverance
			vars.options.Paladin[1].lines[7] = {}
			vars.buildLines({var = vars.options.Paladin[1].lines[7].text1, frame = vars.options.Paladin[1].frame, text = "Tyr's Deliverance the same conditions as Light of Dawn", left = 10, top = -150})
			--Light of the Martyr		
			if PrioritiesDB.Paladin[1].lines[8] == nil then
				PrioritiesDB.Paladin[1].lines[8] = {}				
			end			
			vars.options.Paladin[1].lines[8] = {}
			vars.buildLines({var = vars.options.Paladin[1].lines[3].text1, frame = vars.options.Paladin[1].frame, text = "Light of the Martyr if priority unit's health is below", left = 10, top = -170})
			
			if PrioritiesDB.Paladin[1].lines[8].healthPerc == nil then
				PrioritiesDB.Paladin[1].lines[8].healthPerc = 10		
			end						
			vars.options.Paladin[1].lines[8].healthPerc = CreateFrame("EditBox", "vars.options.Paladin[1].lines[8].healthPerc", vars.options.Paladin[1].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Paladin[1].lines[8].healthPerc, frame = vars.options.Paladin[1].frame, width = 20, step = 5, minval = 0, maxval = 100,defaultval = PrioritiesDB.Paladin[1].lines[8].healthPerc, top = -170, left = 405, savetable = PrioritiesDB.Paladin[1].lines[8], savevar = "healthPerc"})
			
			vars.buildLines({var = vars.options.Paladin[1].lines[8].text2, frame = vars.options.Paladin[1].frame, text = "% and player's health is above", left = 430, top = -170})	
			
			if PrioritiesDB.Paladin[1].lines[8].playerHealthPerc == nil then
				PrioritiesDB.Paladin[1].lines[8].playerHealthPerc = 90			
			end						
			vars.options.Paladin[1].lines[8].playerHealthPerc = CreateFrame("EditBox", "vars.options.Paladin[1].lines[8].playerHealthPerc", vars.options.Paladin[1].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Paladin[1].lines[8].playerHealthPerc, frame = vars.options.Paladin[1].frame, width = 30, step = 5, minval = 0, maxval = 100,defaultval = PrioritiesDB.Paladin[1].lines[8].playerHealthPerc, top = -170, left = 660, savetable = PrioritiesDB.Paladin[1].lines[8], savevar = "playerHealthPerc"})
			
			vars.buildLines({var = vars.options.Paladin[1].lines[8].text2, frame = vars.options.Paladin[1].frame, text = "%.", left = 690, top = -170})
			-- Flash of Light
			if PrioritiesDB.Paladin[1].lines[9] == nil then
				PrioritiesDB.Paladin[1].lines[9] = {}				
			end			
			vars.options.Paladin[1].lines[9] = {}
			vars.buildLines({var = vars.options.Paladin[1].lines[9].text1, frame = vars.options.Paladin[1].frame, text = "Flash of Light if priority's health is below", left = 10, top = -190})
			
			if PrioritiesDB.Paladin[1].lines[9].healthPerc == nil then
				PrioritiesDB.Paladin[1].lines[9].healthPerc = 50				
			end						
			vars.options.Paladin[1].lines[9].healthPerc = CreateFrame("EditBox", "vars.options.Paladin[1].lines[9].healthPerc", vars.options.Paladin[1].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Paladin[1].lines[9].healthPerc, frame = vars.options.Paladin[1].frame, width = 30, step = 5, minval = 0, maxval = 100,defaultval = PrioritiesDB.Paladin[1].lines[9].healthPerc, top = -190, left = 350, savetable = PrioritiesDB.Paladin[1].lines[9], savevar = "healthPerc"})
			
			vars.buildLines({var = vars.options.Paladin[1].lines[9].text2, frame = vars.options.Paladin[1].frame, text = "%.", left = 380, top = -190})	
			-- Holy Light
			if PrioritiesDB.Paladin[1].lines[10] == nil then
				PrioritiesDB.Paladin[1].lines[10] = {}				
			end			
			vars.options.Paladin[1].lines[10] = {}
			vars.buildLines({var = vars.options.Paladin[1].lines[10].text1, frame = vars.options.Paladin[1].frame, text = "Holy Light if priority unit's health is below", left = 10, top = -210})
			
			if PrioritiesDB.Paladin[1].lines[10].healthPerc == nil then
				PrioritiesDB.Paladin[1].lines[10].healthPerc = 90				
			end						
			vars.options.Paladin[1].lines[10].healthPerc = CreateFrame("EditBox", "vars.options.Paladin[1].lines[10].healthPerc", vars.options.Paladin[1].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Paladin[1].lines[10].healthPerc, frame = vars.options.Paladin[1].frame, width = 30, step = 5, minval = 0, maxval = 100,defaultval = PrioritiesDB.Paladin[1].lines[10].healthPerc, top = -210, left = 350, savetable = PrioritiesDB.Paladin[1].lines[10], savevar = "healthPerc"})
			
			vars.buildLines({var = vars.options.Paladin[1].lines[10].text2, frame = vars.options.Paladin[1].frame, text = "%.", left = 380, top = -210})

			--Light of the Martyr		
			if PrioritiesDB.Paladin[1].lines[11] == nil then
				PrioritiesDB.Paladin[1].lines[11] = {}				
			end			
			vars.options.Paladin[1].lines[11] = {}
			vars.buildLines({var = vars.options.Paladin[1].lines[11].text1, frame = vars.options.Paladin[1].frame, text = "Light of the Martyr if priority unit's health is below", left = 10, top = -230})
			
			if PrioritiesDB.Paladin[1].lines[11].healthPerc == nil then
				PrioritiesDB.Paladin[1].lines[11].healthPerc = 50	
			end						
			vars.options.Paladin[1].lines[11].healthPerc = CreateFrame("EditBox", "vars.options.Paladin[1].lines[11].healthPerc", vars.options.Paladin[1].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Paladin[1].lines[11].healthPerc, frame = vars.options.Paladin[1].frame, width = 20, step = 5, minval = 0, maxval = 100,defaultval = PrioritiesDB.Paladin[1].lines[11].healthPerc, top = -230, left = 405, savetable = PrioritiesDB.Paladin[1].lines[11], savevar = "healthPerc"})
			
			vars.buildLines({var = vars.options.Paladin[1].lines[11].text2, frame = vars.options.Paladin[1].frame, text = "% and player's health is above", left = 430, top = -230})	
			
			if PrioritiesDB.Paladin[1].lines[11].playerHealthPerc == nil then
				PrioritiesDB.Paladin[1].lines[11].playerHealthPerc = 90			
			end						
			vars.options.Paladin[1].lines[11].playerHealthPerc = CreateFrame("EditBox", "vars.options.Paladin[1].lines[11].playerHealthPerc", vars.options.Paladin[1].frame, "InputBoxTemplate")
			vars.buildFields({var = vars.options.Paladin[1].lines[11].playerHealthPerc, frame = vars.options.Paladin[1].frame, width = 30, step = 5, minval = 0, maxval = 100,defaultval = PrioritiesDB.Paladin[1].lines[11].playerHealthPerc, top = -230, left = 660, savetable = PrioritiesDB.Paladin[1].lines[11], savevar = "playerHealthPerc"})
			
			vars.buildLines({var = vars.options.Paladin[1].lines[11].text2, frame = vars.options.Paladin[1].frame, text = "%.", left = 690, top = -230})	
			--Judgment	
			vars.options.Paladin[1].lines[12] = {}
			vars.buildLines({var = vars.options.Paladin[1].lines[12].text1, frame = vars.options.Paladin[1].frame, text = "Judgment hostile if targeted and in range", left = 10, top = -250})				
			--Crusader Strike	
			vars.options.Paladin[1].lines[13] = {}
			vars.buildLines({var = vars.options.Paladin[1].lines[13].text1, frame = vars.options.Paladin[1].frame, text = "Crusader Strike hostile if targeted and in range", left = 10, top = -270})				
			--Consecration	
			vars.options.Paladin[1].lines[14] = {}
			vars.buildLines({var = vars.options.Paladin[1].lines[14].text1, frame = vars.options.Paladin[1].frame, text = "Consecration hostile if targeted and in range", left = 10, top = -290})			
			--CDs	
			vars.options.Paladin[1].lines[15] = {}
			vars.buildLines({var = vars.options.Paladin[1].lines[15].text1, frame = vars.options.Paladin[1].frame, text = "CDs.  Use Talent Row X for talent CDS. Include a | after each item.", left = 10, top = -320})			
								
			vars.options.Paladin[1].CDS = CreateFrame("EditBox", "vars.options.Paladin[1].CDS", vars.options.Paladin[1].frame, "InputBoxTemplate")
			vars.buildCDfield({var = vars.options.Paladin[1].CDS, frame = vars.options.Paladin[1].frame, width = 980, height = 13, step = 5, minval = 0, maxval = 100, defaultval = PrioritiesDB.Paladin[1].CDS, top = -340, left = 10, savetable = PrioritiesDB.Paladin[1], savevar = "CDS"})
		end
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
	local spellCount = function(spellName)
		local result = 0
		result = GetSpellCount(spellName)
		if result == nil then
			result = 0
		end
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
	
	local spellCharges = function(spellName)
		local result = 0
		local count = GetSpellCharges(spellName)
		if count == nil then
			count = 0
		end
		result = count
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
	
	local buffCount = function(unitName,aura)
		--print(unitName,aura)
		local result = false
		local expiresIn = 0
		local f = fluff
		if f == nil then
			f = 2
		end
		--UnitAura doesnt work.
		local name, rank, icon, count, dispelType, duration, expires, caster, isStealable = UnitBuff(unitName, aura)
		if expires == nil then
			expiresIn = -1
		elseif expires == 0 then
			expiresIn = 999999
		else
			expiresIn = expires - vars.timeSnap
		end
		--print(expiresIn)
		if expiresIn <=f then	
			result = 0
		else
			result = count
		end
		--print(result)
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
		local groupCount, groupType, testUnitID, priorityHealth, priorityMaxHealth, priorityHealthDeficit, health, maxHealth, healthPercentInc, tmpInc, missingHealthInc
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
		vars.priority.healthPercentInc = 2
		vars.priority.spell = ""
		vars.priority.unit = ""
		vars.priority.raidFrame = nil
		vars.aoeCount1 = 0
		vars.aoeCount2 = 0
		vars.aoeCount3 = 0
		vars.aoeRange = 30
		if vars.class == "Paladin" and vars.spec == 1 then
			vars.aoeRange = 15
			if vars.talentChosen(7,2,"player") then
				vars.aoeRange = vars.aoeRange * 1.3
			end
			if auraDuration("player","Rule of Law","HELPFUL") > 0 then
				vars.aoeRange = vars.aoeRange * 1.5
			end
		end
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
				healthPercentInc = healthInc/maxHealth
				missingHealthInc = maxHealth - healthInc
				if missingHealthInc < 0 then
					missingHealthInc = 0
				end				
				-- class specific stuff
				if vars.class == "Monk" and vars.spec == 2 and distanceBetweenUs("player", testUnitID) <= 25 then
					if healthPercentInc < vars.options.Monk[2].lines[2].aoePercent:GetNumber()/100 then
						vars.aoeCount1 = vars.aoeCount1 + 1
					end
					if auraDuration(testUnitID,"Essence Font","HELPFUL|PLAYER") >= vars.timeToAct then
						vars.aoeCount2 = vars.aoeCount2 + 1
					end
					if healthPercentInc < vars.options.Monk[2].lines[5].aoePercent:GetNumber()/100 then
						vars.aoeCount3 = vars.aoeCount3 + 1
					end					
				elseif vars.class == "Paladin" and vars.spec == 1 then
					if distanceBetweenUs("player", testUnitID) <= vars.aoeRange then
						if healthPercentInc < vars.options.Paladin[1].lines[3].aoePercent:GetNumber()/100 then
							vars.aoeCount1 = vars.aoeCount1 + 1
						end
					end					
					if distanceBetweenUs("player", testUnitID) <= 40 then
						if healthPercentInc < vars.options.Paladin[1].lines[5].aoePercent:GetNumber()/100 then
							vars.aoeCount2 = vars.aoeCount2 + 1
						end
					end
				end
				
				if healthPercentInc < vars.priority.healthPercentInc then
					vars.priority.health = health
					vars.priority.maxHealth = maxHealth
					vars.priority.healthInc = healthInc
					vars.priority.healthPercentInc = healthPercentInc
					vars.priority.missingHealthInc = missingHealthInc
					vars.priority.unitID = testUnitID
				end
				--
			end
		end
		if vars.priority.healthPercentInc == 2 then
			testUnitID = getActionUnitID(groupType, 1)
			health = UnitHealth(testUnitID)
			maxHealth = UnitHealthMax(testUnitID)
			healthInc = health + UnitGetIncomingHeals(testUnitID)
			if healthInc > maxHealth then
				healthInc = maxHealth
			end
			healthPercentInc = healthInc/maxHealth
			vars.priority.health = health
			vars.priority.maxHealth = maxHealth
			vars.priority.healthInc = healthInc
			vars.priority.healthPercentInc = healthPercentInc
			vars.priority.missingHealthInc = missingHealthInc
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
		if spellCD("Sheilun's Gift") <= vars.timeToAct and spellCount("Sheilun's Gift") > 3 and spellCount("Sheilun's Gift")*vars.playerMaxHealth/25 < vars.priority.missingHealthInc then
			vars.priority.spell = "Sheilun's Gift"
		elseif spellCD("Life Cocoon") <= vars.timeToAct and vars.priority.healthPercentInc < vars.options.Monk[2].lines[1].healthPerc:GetNumber()/100 then
			vars.priority.spell = "Life Cocoon"
		elseif spellCD("Essence Font") <= vars.timeToAct and vars.aoeCount1 >= vars.options.Monk[2].lines[2].aoeCount:GetNumber() and not vars.isMoving("player") and auraDuration("player","Thunder Focus Tea","HELPFUL") == 0 and vars.aoeCount2 <= vars.options.Monk[2].lines[2].buffCount:GetNumber() then
			vars.priority.spell = "Essence Font"
		elseif spellCD("Renewing Mist") <= vars.timeToAct and vars.spellCasting ~= "Renewing Mist" and auraDuration(vars.priority.unitID,"Renewing Mist","HELPFUL") <= vars.timeToAct and vars.priority.healthPercentInc < vars.options.Monk[2].lines[3].healthPerc:GetNumber()/100 then
			vars.priority.spell = "Renewing Mist"
		elseif spellCD("Enveloping Mist") <= vars.timeToAct and vars.spellCasting ~= "Enveloping Mist" and auraDuration(vars.priority.unitID,"Enveloping Mist","HELPFUL") <= vars.timeToAct and vars.priority.healthPercentInc < vars.options.Monk[2].lines[4].healthPerc:GetNumber()/100 and (not vars.isMoving("player") or auraDuration("player","Thunder Focus Tea","HELPFUL") > 0) then
			vars.priority.spell = "Enveloping Mist"
		elseif spellCD("Vivify") <= vars.timeToAct and vars.priority.healthPercentInc < vars.options.Monk[2].lines[5].healthPerc:GetNumber()/100 and not vars.isMoving("player") and (vars.aoeCount3 >= vars.options.Monk[2].lines[5].aoeCount:GetNumber() or (auraDuration("player","Uplifting Trance","HELPFUL") >= vars.timeToAct and vars.spellCasting ~= "Vivify")) then
			vars.priority.spell = "Vivify"
		elseif spellCD("Effuse") <= vars.timeToAct and vars.priority.healthPercentInc < vars.options.Monk[2].lines[6].healthPerc:GetNumber()/100 and not vars.isMoving("player") then
			vars.priority.spell = "Effuse"
		elseif spellCD("Tiger Palm") <= vars.timeToAct and IsSpellInRange("Tiger Palm", "target") == 1 and buffCount("player", "Teachings of the Monastery") < 3 then
			vars.priority.spell = "Tiger Palm"
		elseif spellCD("Rising Sun Kick") <= vars.timeToAct and IsSpellInRange("Rising Sun Kick", "target") == 1 then
			vars.priority.spell = "Rising Sun Kick"
		elseif spellCD("Blackout Kick") <= vars.timeToAct and IsSpellInRange("Blackout Kick", "target") == 1 then
			vars.priority.spell = "Blackout Kick"
		elseif spellCD("Crackling Jade Lightning") <= vars.timeToAct and IsSpellInRange("Crackling Jade Lightning", "target") == 1 then
			vars.priority.spell = "Crackling Jade Lightning"
		else
			vars.priority.spell = ""
		end	
	end
	function paladinHealToUse()
		if spellCD("Holy Shock") <= vars.timeToAct and vars.priority.healthPercentInc < vars.options.Paladin[1].lines[1].healthPerc:GetNumber()/100 then
			vars.priority.spell = "Holy Shock"
		elseif spellCD("Holy Shock") <= vars.timeToAct and IsSpellInRange("Holy Shock", "target") == 1 then
			vars.priority.spell = "Holy Shock"
		elseif spellCD("Light of Dawn") <= vars.timeToAct and vars.aoeCount1 >= vars.options.Paladin[1].lines[3].aoeCount:GetNumber() then
			vars.priority.spell = "Light of Dawn"
		elseif vars.talentChosen(6,3,"player") and spellCD("Judgment") <= vars.timeToAct and IsSpellInRange("Judgment", "target") == 1 then
			vars.priority.spell = "Judgment"
		elseif vars.talentChosen(5,3,"player") and spellCD("Holy Prism") <= vars.timeToAct and vars.aoeCount1 >= vars.options.Paladin[1].lines[5].aoeCount:GetNumber() then
			vars.priority.spell = "Holy Prism"
		elseif spellCD("Bestow Faith") <= vars.timeToAct and vars.priority.healthPercentInc < vars.options.Paladin[1].lines[6].healthPerc:GetNumber()/100 then
			vars.priority.spell = "Bestow Faith"
		elseif spellCD("Tyr's Deliverance") <= vars.timeToAct and vars.aoeCount1 >= vars.options.Paladin[1].lines[3].aoeCount:GetNumber() and not vars.isMoving("player") then
			vars.priority.spell = "Tyr's Deliverance"
		elseif spellCD("Light of the Martyr") <= vars.timeToAct and vars.priority.healthPercentInc < vars.options.Paladin[1].lines[8].healthPerc:GetNumber()/100 and vars.playerHealthPercent > vars.options.Paladin[1].lines[8].playerHealthPerc:GetNumber()/100 then
			vars.priority.spell = "Light of the Martyr"
		elseif spellCD("Flash of Light") <= vars.timeToAct and vars.priority.healthPercentInc < vars.options.Paladin[1].lines[9].healthPerc:GetNumber()/100 and not vars.isMoving("player") then
			vars.priority.spell = "Flash of Light"
		elseif spellCD("Holy Light") <= vars.timeToAct and vars.priority.healthPercentInc < vars.options.Paladin[1].lines[10].healthPerc:GetNumber()/100 and not vars.isMoving("player") and vars.spellTarget ~= vars.priority.unitID then
			vars.priority.spell = "Holy Light"
		elseif spellCD("Light of the Martyr") <= vars.timeToAct and vars.priority.healthPercentInc < vars.options.Paladin[1].lines[11].healthPerc:GetNumber()/100 and vars.playerHealthPercent > vars.options.Paladin[1].lines[11].playerHealthPerc:GetNumber()/100 then
			vars.priority.spell = "Light of the Martyr"
		elseif spellCD("Judgment") <= vars.timeToAct and IsSpellInRange("Judgment", "target") == 1 then
			vars.priority.spell = "Judgment"
		elseif spellCD("Crusader Strike") <= vars.timeToAct and IsSpellInRange("Crusader Strike", "target") == 1 then
			vars.priority.spell = "Crusader Strike"
		elseif spellCD("Consecration") <= vars.timeToAct and IsSpellInRange("Crusader Strike", "target") == 1 then
			vars.priority.spell = "Consecration"
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
		
		vars.playerMaxHealth = UnitHealthMax("player")
		vars.playerHealth = UnitHealth("player")
		vars.playerHealthPercent = vars.playerHealth/vars.playerMaxHealth
		vars.baseMana = UnitPowerMax("player", UnitPowerType("player"))/5
		vars.playerMana = UnitPower("player", UnitPowerType("player"))
		vars.haste = 1 + GetHaste()/100
		vars.GCD = 1.5/(vars.haste)
		if vars.GCD < .75 then
			vars.GCD = .75
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
		vars.menuButton:SetPoint("BOTTOMLEFT", left + 30, bottom + height + 5)
		for i = 1,#vars.cds do
			if vars.cds[i].spellName ~= "" then
				local cd = spellCD(vars.cds[i].spellName)
				local charges = 0
				if vars.cds[i].spellName == "Sheilun's Gift" then
					charges = spellCount(vars.cds[i].spellName)
				else
					charges = spellCharges(vars.cds[i].spellName)
				end
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
				if charges < 2 then				
					vars.cds[i].charges:SetText("")
				else
					vars.cds[i].charges:SetText(charges)
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
	function parseSpellCDs(cds)
		local name, rank, icon, castingTime, minRange, maxRange, spellID, tmpSpellName
		print(cds)
		if cds ~= nil then
			for i = 1, #cds do
				tmpSpellName = cds[i]
				if string.sub(tmpSpellName, 1, 11) == "Talent Row " then
					local row = string.sub(tmpSpellName, 12, 12)
					for h = 1,3 do
						local talentID, name, texture, selected, available, spellID, tier, row, column = GetTalentInfo(row, h, 1)
						if selected then
							if GetSpellInfo(name) == nil then
								tmpSpellName = ""
							else
								tmpSpellName = name
							end
						end
					end
				end
				if vars.cds[i] == nil then
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
					vars.cds[i].frame:SetFrameLevel(30-i)
					vars.cds[i].texture:SetTexture(GetSpellTexture(spellID))
					vars.cds[i].cd = vars.cds[i].frame:CreateFontString(nil, "TOOLTIP", "GameTooltipText")
					vars.cds[i].cd:SetText("")
					vars.cds[i].cd:SetPoint("CENTER", 0,0)
					vars.cds[i].cd:SetTextColor(1.0,1.0,1.0,0.8)
					vars.cds[i].cd:SetFont("Fonts\\FRIZQT__.TTF", 24, "THICKOUTLINE")
					vars.cds[i].charges = vars.cds[i].frame:CreateFontString(nil, "TOOLTIP", "GameTooltipText")
					vars.cds[i].charges:SetText("")
					vars.cds[i].charges:SetPoint("BOTTOMRIGHT", 0,2)
					vars.cds[i].charges:SetTextColor(1.0,1.0,1.0,0.8)
					vars.cds[i].charges:SetFont("Fonts\\FRIZQT__.TTF", 12, "THICKOUTLINE")
					vars.cds[i].frame.spellID = 0
					vars.cds[i].frame:SetScript("OnEnter", function(self, motion)
									GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
									GameTooltip:SetSpellByID(self.spellID)
									GameTooltip:Show()
								end)			
					vars.cds[i].frame:SetScript("OnLeave", function(self, motion)
						GameTooltip:Hide()
					end)			
					vars.cds[i].frame:SetScript("OnLeave", function(self, motion)
						GameTooltip:Hide()
					end)
				end
				vars.cds[i].spellName = tmpSpellName
				name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(tmpSpellName)
				vars.cds[i].frame.spellID = spellID
			end		
			for i = #cds + 1, #vars.cds do
				vars.cds[i].spellName = ""
				vars.cds[i].frame.spellID = 0
			end
		end
	end
	function setupSpec()
		vars.class = UnitClass("player")
		vars.spec = GetSpecialization()
		if vars.buildOptions[vars.class] == nil then
			vars.buildOptions[vars.class] = {}
		end
		if vars.buildOptions[vars.class][vars.spec] ~= nil then
			vars.buildOptions[vars.class][vars.spec]()
		end
		if PrioritiesDB[vars.class] == nil then
			PrioritiesDB[vars.class] = {}				
		end			
		if PrioritiesDB[vars.class][vars.spec] == nil then
			PrioritiesDB[vars.class][vars.spec] = {}
		end
		buildCDs()
	end
	function buildCDs()
		for i = 1,#vars.cds do
			vars.cds[i].spellName = ""
			vars.cds[i].frame.spellID = 0
			vars.cds[i].frame:Hide()
		end
		if PrioritiesDB[vars.class][vars.spec].CDS == nil then
			if vars.class == "Monk" then
				if vars.spec == 2 then
					PrioritiesDB[vars.class][vars.spec].CDS = {"Sheilun's Gift","Renewing Mist","Thunder Focus Tea","Detox","Life Cocoon","Revival","Talent Row 7","Talent Row 6","Talent Row 5","Talent Row 4","Talent Row 1"} --
				end
			elseif vars.class == "Paladin" then
				if vars.spec == 1 then
					PrioritiesDB[vars.class][vars.spec].CDS = {"Holy Shock","Light of Dawn","Judgment","Crusader Strike","Cleanse"}--,"Judgment","Consecration","Cleanse","Divine Protection","Hammer of Justice","Avenging Wrath","Every Man for Himself","Divine Shield","Aura Mastery","Blessing of Freedom", "Blessing of Sacrifice", "Blessing of Protection","Divine Steed","Lay on Hands","Talent Row 1","Talent Row 2","Talent Row 3","Talent Row 5","Talent Row 7"})
				end
			else
				PrioritiesDB[vars.class][vars.spec].CDS = {}
			end
		end		
		parseSpellCDs(PrioritiesDB[vars.class][vars.spec].CDS)
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
	function e:UNIT_SPELLCAST_STOP(...)
		local unitID, spellName, rank, lineID, spellID = ...
		if UnitIsUnit(unitID,"player") then
			vars.spellCasting = ""
			vars.spellTarget = ""
		end
	end	
	function e:PLAYER_TALENT_UPDATE(...)
	    setupSpec()
	end
	function e:PLAYER_LOGIN(...)
		setupSpec()
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