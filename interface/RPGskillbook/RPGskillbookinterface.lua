require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"
require "/scripts/poly.lua"
require "/scripts/drawingutil.lua"
require "/scripts/ivrpgutil.lua"
-- engine callbacks
function init()
  --View:init()
  
  self.clickEvents = {}
  self.state = FSM:new()
  self.state:set(splashScreenState)
  self.system = celestial.currentSystem()
  self.pane = pane
  player.addCurrency("skillbookopen", 1)

  -- Initiating Level and XP
  self.xp = math.min(player.currency("experienceorb"), 500000)
  self.level = player.currency("currentlevel")
  self.mastery = player.currency("masterypoint")
  -- Mastery Conversion: 10000 Experience = 1 Mastery!!

  self.classTo = 0
  self.class = player.currency("classtype")
  self.specTo = 1
  self.spec = player.currency("spectype")
  self.profTo = 0
  self.profession = player.currency("proftype")
  self.affinityTo = 0
  self.affinity = player.currency("affinitytype")

  self.challengeText = {
    {
      {"Defeat 500 Tier 4 or higher enemies.", 500},
      {"Defeat 350 Tier 5 or higher enemies.", 350},
      {"Defeat Kluex.", 1},
      {"Defeat the Erchius Horror without taking damage.", 1}
    },
    {
      {"Defeat 400 Tier 6 or higher enemies.", 400},
      {"Defeat the Bone Dragon.", 1},
      {"Gather 5 Upgrade Modules. They are consumed.", 5}
    },
    {
      {"Defeat 400 Vault Tier or higher enemies.", 400},
      {"Defeat 2 Vault Guardians.", 2},
      {"Defeat the Heart of Ruin.", 1},
      {"Deafeat the Heart of Ruin without taking damage.", 1},
      {"-------------------------------------------------------. <- Period is max length!"}
    }
  }

  -- Loading Configs
  self.textData = root.assetJson("/ivrpgText.config")
  self.classList = root.assetJson("/ivrpgClassList.config")
  self.specList = root.assetJson("/ivrpgSpecList.config")
  self.profList = root.assetJson("/ivrpgProfessionList.config")
  self.statList = root.assetJson("/ivrpgStats.config")
  self.affinityList = root.assetJson("/ivrpgAffinityList.config")
  self.affinityDescriptions = root.assetJson("/affinities/affinityDescriptions.config")
  self.versionConfig = root.assetJson("/ivrpgVersion.config")
  self.lastLoreChecked = "changelog"
  self.loreDepth = 1
  self.loreTable = {"lore"}
  self.logTable = {"changelog"}
  self.lastSkillChecked = "body"
  self.skillDepth = 1
  self.skillTable = {"skill", "body"}
  updateStats()
  updateClassInfo()
  updateAffinityInfo()
  updateSpecInfo()
  updateProfessionInfo()
  updateLevel()
end

function dismissed()
  player.consumeCurrency("skillbookopen", player.currency("skillbookopen"))
end

function update(dt)
  --if not world.sendEntityMessage(player.id(), "holdingSkillBook"):result() then
  if player.currency("skillbookopen") == 2 then
    self.pane.dismiss()
  end

  if player.currency("experienceorb") ~= self.xp then
    updateLevel()
    if widget.getChecked("bookTabs.2") then
      local checked = widget.getChecked("classlayout.techicon1") and 1 or (widget.getChecked("classlayout.techicon2") and 2 or (widget.getChecked("classlayout.techicon3") and 3 or (widget.getChecked("classlayout.techicon4") and 4 or 0))) 
      if checked ~= 0 then unlockTechVisible((tostring(checked)), 2^(checked+1)) end
      updateClassWeapon()
    elseif widget.getChecked("bookTabs.3") then
      removeLayouts()
      changeToAffinities()
    elseif widget.getChecked("bookTabs.5") then
      changeToSpecialization()
    elseif widget.getChecked("bookTabs.6") then
      changeToProfession()
    elseif widget.getChecked("bookTabs.7") then
      changeToMastery()
    end
  end

  if player.currency("classtype") ~= self.class then
    self.class = player.currency("classtype")
    updateClassInfo()
    if widget.getChecked("bookTabs.2") then
      changeToClasses()
    elseif widget.getChecked("bookTabs.0") then
      changeToOverview()
    elseif widget.getChecked("bookTabs.5") then
      changeToSpecialization()
    end
  end

  if player.currency("affinitytype") ~= self.affinity then
    self.affinity = player.currency("affinitytype")
    updateAffinityInfo()
    if widget.getChecked("bookTabs.3") then
      changeToAffinities()
    elseif widget.getChecked("bookTabs.0") then
      changeToOverview()
    end
  end

  if player.currency("spectype") ~= self.spec then
    self.spec = player.currency("spectype")
    updateSpecInfo()
    unlockSpecWeapon()
    unlockSpecLore()
    if widget.getChecked("bookTabs.5") then
      changeToSpecialization()
    elseif widget.getChecked("bookTabs.0") then
      changeToOverview()
    end
  end

  if widget.getChecked("bookTabs.5") then
    changeToSpecialization()
  end

  if widget.getChecked("bookTabs.6") then
    changeToProfession()
  end

  if player.currency("masterypoint") ~= self.mastery then
    self.mastery = player.currency("masterypoint")
    if widget.getChecked("bookTabs.7") then
      changeToMastery()
    end
  end

  if status.statPositive("ivrpgmasteryunlocked") and widget.getChecked("bookTabs.7") then
    updateChallenges()
  end

  if widget.getChecked("bookTabs.8") then
    updateUpgradeTab()
  end

  if widget.getChecked("bookTabs.9") then
    updateSkillTab()
  end

  if widget.getChecked("bookTabs.10") then
    updateLoreTab()
  end

  updateStats()
  if widget.getChecked("bookTabs.4") then
    updateInfo()
  end
  --checkStatPoints()

  self.state:update(dt)
end

function updateBookTab()
  removeLayouts()
  if widget.getChecked("bookTabs.0") then
    changeToOverview()
  elseif widget.getChecked("bookTabs.1") then
    changeToStats()
  elseif widget.getChecked("bookTabs.2") then
    changeToClasses()
  elseif widget.getChecked("bookTabs.3") then
    changeToAffinities()
  elseif widget.getChecked("bookTabs.4") then
    changeToInfo()
  elseif widget.getChecked("bookTabs.5") then
    changeToSpecialization()
  elseif widget.getChecked("bookTabs.6") then
    changeToProfession()
  elseif widget.getChecked("bookTabs.7") then
    changeToMastery()
  elseif widget.getChecked("bookTabs.8") then
    changeToUpgrades()
  elseif widget.getChecked("bookTabs.9") then
    changeToSkills()
  elseif widget.getChecked("bookTabs.10") then
    changeToLore()
  end
end

function updateClassInfo()
  if self.class > 0 then
    self.classInfo = root.assetJson("/classes/" .. self.classList[self.class] .. ".config")
  else
    self.classInfo = root.assetJson("/classes/default.config")
  end
end

function updateSpecInfo()
  if self.spec > 0 and self.class > 0 then
    self.specInfo = root.assetJson("/specs/" .. self.specList[self.class][self.spec].name .. ".config")
  else
    self.specInfo = nil
  end
end

function updateProfessionInfo()
  if self.profession > 0 then
    self.profInfo = root.assetJson("/professions/" .. self.profList[self.profession] .. ".config")
  else
    self.profInfo = root.assetJson("/professions/default.config")
  end
end

function updateAffinityInfo()
  if self.affinity > 0 then
    self.affinityInfo = root.assetJson("/affinities/" .. self.affinityList[self.affinity] .. ".config")
  else
    self.affinityInfo = root.assetJson("/affinities/default.config")
  end
end

function updateLevel()
  self.xp = math.min(player.currency("experienceorb"), 500000)
  if self.xp < 100 then
    player.addCurrency("experienceorb", 100)
    status.setStatusProperty("ivrpgskillpoints", 1)
  end
  self.level = player.currency("currentlevel")
  self.newLevel = math.floor(math.sqrt(self.xp/100))
  self.newLevel = self.newLevel >= 50 and 50 or self.newLevel
  if self.newLevel > self.level then
    addStatPoints(self.newLevel, self.level)
  elseif self.newLevel < self.level then
    player.consumeCurrency("currentlevel", self.level - self.newLevel)
  end
  self.level = player.currency("currentlevel")
  widget.setText("statslayout.statpointsleft", player.currency("statpoint"))
  updateStats()
  self.toNext = 2*self.level*100+100
  updateOverview(self.toNext)
  updateBottomBar(self.toNext)
end

function startingStats()
  for k,v in pairs(self.statList) do
    if k ~= "default" then
      player.addCurrency(k .. "point", 1)
    end
  end
end

function addStatPoints(newLevel, oldLevel)
  player.addCurrency("currentlevel", newLevel - oldLevel)
  while newLevel > oldLevel do
    if oldLevel > 48 then
      player.addCurrency("statpoint", 4)
    elseif oldLevel > 38 then
      player.addCurrency("statpoint", 3)
    elseif oldLevel > 18 then
      player.addCurrency("statpoint", 2)
    elseif oldLevel > 0 then
      player.addCurrency("statpoint", 1)
    else
      startingStats()
    end
    oldLevel = oldLevel + 1
  end
end

function updateBottomBar(toNext)
  widget.setText("levelLabel", "Level " .. tostring(self.level))
  if self.level == 50 then
    widget.setText("xpLabel","Max XP!")
    widget.setProgress("experiencebar",1)
  else
    widget.setText("xpLabel",tostring(math.floor((self.xp-self.level^2*100))) .. "/" .. tostring(toNext))
    widget.setProgress("experiencebar",(self.xp-self.level^2*100)/toNext)
  end
end

function updateOverview(toNext)
  widget.setText("overviewlayout.levellabel","Level " .. tostring(self.level))
  if self.level == 50 then
    widget.setText("overviewlayout.xptglabel","Experience Needed For Level-Up: N/A.")
    widget.setText("overviewlayout.xptotallabel","Total Experience Orbs Collected: " .. tostring(self.xp))
  else
    widget.setText("overviewlayout.xptglabel","Experience Needed For Level-Up: " .. tostring(toNext - (math.floor(self.xp-self.level^2*100))))
    widget.setText("overviewlayout.xptotallabel","Total Experience Orbs Collected: " .. tostring(self.xp))
  end
  widget.setText("overviewlayout.statpointsremaining","Stat Points Available: " .. tostring(player.currency("statpoint")))

  local classicText = ""
  for k,v in ipairs(self.classInfo.classic) do
    if v.type == "movement" or v.type == "status" then
      classicText = classicText .. v.text .. "\n"
    end
  end
  widget.setText("overviewlayout.hardcoretext", classicText)
  widget.setText("overviewlayout.classtitle", self.classInfo.title)
  widget.setFontColor("overviewlayout.classtitle", self.classInfo.color)
  widget.setImage("overviewlayout.classicon", self.classInfo.image)

  widget.setText("overviewlayout.affinitytitle", self.affinityInfo.title)
  widget.setFontColor("overviewlayout.affinitytitle", self.affinityInfo.color)
  widget.setImage("overviewlayout.affinityicon", self.affinityInfo.image)

  widget.setText("overviewlayout.spectitle", (self.specInfo and self.specInfo.title or ""))
  
  if status.statPositive("ivrpghardcore") then
    widget.setText("overviewlayout.hardcoretoggletext", "Active")
    widget.setFontColor("overviewlayout.hardcoretoggletext", "green")
    widget.setVisible("overviewlayout.hardcoretext", true)
    widget.setVisible("overviewlayout.hardcoreweapontext", true)
  else
    widget.setText("overviewlayout.hardcoretoggletext", "Inactive")
    widget.setFontColor("overviewlayout.hardcoretoggletext", "red")
    widget.setVisible("overviewlayout.hardcoretext", false)
    widget.setVisible("overviewlayout.hardcoreweapontext", false)
  end

  if not status.statusProperty("ivrpgrallymode", false) then
    widget.setText("overviewlayout.rallymodeactive", "Inactive")
    widget.setFontColor("overviewlayout.rallymodeactive", "red")
  else
    widget.setText("overviewlayout.rallymodeactive", "Active")
    widget.setFontColor("overviewlayout.rallymodeactive", "green")
  end

end

function updateClassTab()
  if player.currency("classtype") == 0 then
    widget.setText("classlayout.classtitle","No Class Yet")
    widget.setImage("classlayout.classicon","/objects/class/noclass.png")
    widget.setImage("classlayout.effecticon","/objects/class/noclassicon.png")
    widget.setImage("classlayout.effecticon2","/objects/class/noclassicon.png")
  else
    updateClassInfo()
    local classInfo = self.classInfo
    widget.setText("classlayout.classtitle", classInfo.title)
    widget.setFontColor("classlayout.classtitle", classInfo.color)
    widget.setFontColor("classlayout.effecttext", classInfo.color)
    widget.setImage("classlayout.classicon", classInfo.image)
    widget.setText("classlayout.effecttext", classInfo.ability.text)
    widget.setImage("classlayout.effecticon", classInfo.ability.image)
    widget.setImage("classlayout.effecticon2", classInfo.ability.image)
    widget.setImage("classlayout.classweaponicon", classInfo.weapon.image)
    updateClassText()
    updateTechImages()
    updateClassWeapon()
  end
  
  if status.statPositive("ivrpgclassability") then widget.setText("classlayout.classabilitytoggletext", "Inactive")
  else widget.setText("classlayout.classabilitytoggletext", "Active") end

end

function updateClassText()
  --Weapon Bonus
  widget.setText("classlayout.weapontext", concatTableValues(self.classInfo.weaponBonuses, "\n"))

  --Passive
  widget.setText("classlayout.passivetext", concatTableValues(self.classInfo.passive, "\n"))

  --Scaling
  local scalingArray = {{"^green;Amazing^reset;"}, {"^blue;Great^reset;"}, {"^magenta;Good^reset;"}, {"^gray;OK^reset;"}}
  local scalingComp = {amazing = 1, great = 2, good = 3, ok = 4}
  for k,v in ipairs(self.classInfo.scaling) do
    currentIndex = scalingComp[v.textType]
    currentTable = scalingArray[currentIndex]
    table.insert(currentTable, v.text)
    scalingArray[currentIndex] = currentTable
  end
  local scalingText = ""
  for k,v in pairs(scalingArray) do
    if #v > 1 then
      for x,y in ipairs(v) do
        scalingText = scalingText .. y .. "\n"
      end
    end
  end
  widget.setText("classlayout.statscalingtext", scalingText)

end

function removeLayouts()
  widget.setVisible("overviewlayout",false)
  widget.setVisible("statslayout",false)
  widget.setVisible("classeslayout",false)
  widget.setVisible("classlayout",false)
  widget.setVisible("affinitieslayout",false)
  widget.setVisible("affinitylayout",false)
  widget.setVisible("affinitylockedlayout",false)
  widget.setVisible("infolayout",false)
  widget.setVisible("masterylayout",false)
  widget.setVisible("masterylockedlayout",false)
  widget.setVisible("professionlayout",false)
  widget.setVisible("professionslayout",false)
  widget.setVisible("professionlockedlayout",false)
  widget.setVisible("specializationlayout",false)
  widget.setVisible("specializationslayout",false)
  widget.setVisible("specializationlockedlayout",false)
  widget.setVisible("upgradelayout", false)
  widget.setVisible("lorelayout",false)
  widget.setVisible("skillslayout", false)
end

function changeToOverview()
    widget.setText("tabLabel", "Overview")
    widget.setVisible("overviewlayout", true)
    updateOverview(2*self.level*100+100)
end

function changeToStats()
    updateStats()
    widget.setText("tabLabel", "Stats Tab")
    widget.setVisible("statslayout", true)
end

function changeToClasses()
    widget.setText("tabLabel", "Classes Tab")
    if player.currency("classtype") == 0 then
      widget.setVisible("classlayout", false)
      checkClassDescription("default")
      widget.setVisible("classeslayout", true)
      updateTechText("default")
      return
    else
      widget.setVisible("classeslayout", false)
      updateClassTab()
      widget.setVisible("classlayout", true)
    end
end

function changeToAffinities()
    widget.setText("tabLabel", "Affinities Tab")
    if player.currency("affinitytype") == 0 then
      widget.setVisible("affinitylayout", false)
      checkAffinityDescription("default")
      if self.level >= 25 then
        widget.setVisible("affinitieslayout", true)
      else
        widget.setVisible("affinitylockedlayout", true)
      end
      return
    else
      widget.setVisible("affinitieslayout", false)
      updateAffinityTab()
      widget.setVisible("affinitylayout", true)
    end
end

function changeToInfo()
    widget.setText("tabLabel", "Info Tab")
    widget.setVisible("infolayout", true)
    updateInfo()
end

function changeToSpecialization()
    widget.setText("tabLabel", "Specialization Tab")
    --self.specTo = 1
    if self.class == 0 then
      widget.setVisible("specializationlayout", false)
      widget.setVisible("specializationslayout", false)
      widget.setVisible("specializationlockedlayout", true)
    elseif self.spec == 0 then
      updateSpecializationSelect()
      widget.setVisible("specializationlockedlayout", false)
      widget.setVisible("specializationslayout", true)
      widget.setVisible("specializationlayout", false)
    else
      updateSpecializationTab()
      widget.setVisible("specializationlockedlayout", false)
      widget.setVisible("specializationslayout", false)
      widget.setVisible("specializationlayout", true)
    end
end

function changeToProfession()
    widget.setText("tabLabel", "Profession Tab")
    if self.level < 10 then
      widget.setVisible("professionlayout", false)
      widget.setVisible("professionlockedlayout", true)
    else
      widget.setVisible("professionlockedlayout", false)
      if player.currency("proftype") == 0 then
        local money = player.currency("money") or 0
        widget.setText("professionslayout.pixelamount", math.min(money, 1000) .. "/1000")
        widget.setFontColor("professionslayout.pixelamount", money >= 1000 and "white" or "red")
        widget.setButtonEnabled("professionslayout.selectprofession", money >= 1000 and self.profTo > 0 and not root.assetJson("/professions/professionDescriptions.config")[self.profList[self.profTo]].disabled)
        widget.setVisible("professionlayout", false)
        widget.setVisible("professionslayout", true)
      else
        updateProfessionTab()
        widget.setVisible("professionslayout", false)
        widget.setVisible("professionlayout", true)
      end
    end
end

function changeToMastery()
    widget.setText("tabLabel", "Mastery Tab")
    if self.level < 50 and not status.statPositive("ivrpgmasteryunlocked") then
      widget.setVisible("masterylayout", false)
      widget.setVisible("masterylockedlayout", true)
    else
      updateMasteryTab()
      widget.setVisible("masterylockedlayout", false)
      widget.setVisible("masterylayout", true)
      if not status.statPositive("ivrpgmasteryunlocked") then
        status.setPersistentEffects("ivrpgmasteryunlocked", {
          {stat = "ivrpgmasteryunlocked", amount = 1}
        })
      end
    end
end

function changeToUpgrades()
  widget.setText("tabLabel", "Upgrade Tab")
  widget.setVisible("upgradelayout", true)
  updateUpgradeTab()
end

function changeToSkills()
  widget.setText("tabLabel", "Skills Tab")
  widget.setVisible("skillslayout", true)
end

function changeToLore()
  widget.setText("tabLabel", "Lore Tab")
  widget.setVisible("lorelayout", true)
end

function updateProfessionTab()
  --Update the current profession tab with correct info
  if self.profession == 0 then return end
  updateProfessionInfo()
  local profInfo = self.profInfo

  widget.setText("professionlayout.proftitle", profInfo.title)
  widget.setFontColor("professionlayout.proftitle", profInfo.color)
  
  widget.setText("professionlayout.classictext", concatTableValues(profInfo.classic, "\n"))
  widget.setText("professionlayout.benefittext", concatTableValues(profInfo.effects, "\n", "benefit"))
  widget.setText("professionlayout.scalingtext",  concatTableValues(profInfo.scaling, "\n", "scaling-up") .. concatTableValues(profInfo.scaling, "\n", "scaling-down"))

  widget.setText("professionlayout.passiveactive", (not status.statusProperty("ivrpgprofessionpassive", false)) and "Inactive" or "Active")

  widget.setText("professionlayout.passivetext", profInfo.passive.text)
  widget.setText("professionlayout.craftingtext", profInfo.crafting.text)
  widget.setText("professionlayout.craftingtitle", profInfo.title .. " Station")
  widget.setText("professionlayout.uniquetext", profInfo.ability.text)

  widget.setImage("professionlayout.professionicon", profInfo.image)
  widget.setImage("professionlayout.professionicon2", profInfo.image)
end

function checkProfessionDescription(name)
  name = string.gsub(name,"icon","")
  uncheckProfessionIcons(name)
  if (widget.getChecked("professionslayout."..name.."icon")) then
    changeProfessionDescription(name)
    --widget.setButtonEnabled("professionslayout.selectprofession", true)
  else
    changeProfessionDescription("default")
    widget.setButtonEnabled("professionslayout.selectprofession", false)
  end
end

function uncheckProfessionIcons(name)
  for k,v in ipairs(self.profList) do
    if name ~= v and v ~= "default" then
      widget.setChecked("professionslayout." .. v .. "icon", false)
      widget.setFontColor("professionslayout." .. v .. "title", "white")
    end
  end
end

function openProfessionCrafting()
  local profInfo = self.profInfo
  player.giveItem(profInfo.crafting.type, 1)
end

function toggleProfessionPassive()
  status.setStatusProperty("ivrpgprofessionpassive", not status.statusProperty("ivrpgprofessionpassive", false))
end

function changeProfessionDescription(name)
  local textArray = root.assetJson("/professions/professionDescriptions.config")[name]
  local disabledText = (textArray.disabled and name ~= "default") and "\n^red;Not Released Yet!" or ""
  widget.setText("professionslayout.professiondescription", textArray.text .. disabledText) 
  widget.setFontColor("professionslayout." .. name .. "title", textArray.color)
  local enoughMoney = (player.currency("money") or 0) >= 1000
  widget.setButtonEnabled("professionslayout.selectprofession", not textArray.disabled and enoughMoney)
  self.profTo = textArray.profession
  uncheckProfessionIcons(name)
end

function chooseProfession()
  player.addCurrency("proftype", self.profTo)
  player.consumeCurrency("money", 1000)
  self.profession = self.profTo
  updateProfessionInfo()
  changeToProfession()
end

function updateSpecializationSelect()
  self.availableSpecs = self.specList[self.class]
  local currentSpec = self.availableSpecs[self.specTo]

  local topText = "\nUse the arrows to navigate through Specializations for your current Class."
  widget.setText("specializationslayout.subtitle", (self.level < 35 and "^red;Specializations can not be progressed or unlocked until level 35.^reset;" or "Specializations can be unlocked by accomplishing each listed task.") .. topText)

  widget.setText("specializationslayout.spectitle", currentSpec.title)
  if currentSpec.titleColor then
    widget.setFontColor("specializationslayout.spectitle", currentSpec.titleColor)
  end
  local disabled = currentSpec.disabled
  local specDescText = disabled and "^red;Not Released Yet!^reset;\n" or ""
  specDescText = specDescText .. (currentSpec.gender and "^red;" .. currentSpec.gender:gsub("^%l", string.upper) .. " Only^white;\n" or "")
  if currentSpec.gender and currentSpec.gender ~= player.gender() then
    specDescText = specDescText .. "^red;Equip all three 'True Understanding' skills in the Skills Tab (K) to equip!^white;\n"
  end
  widget.setText("specializationslayout.desctext", specDescText .. concatTableValues({currentSpec.description}, "\n\n"))
  --widget.setText("specializationslayout.loretext", concatTableValues(currentSpec.flavor, "\n\n"))
  widget.setText("specializationslayout.weapontext", concatTableValues(currentSpec.weaponText, "\n\n"))

  widget.setText("specializationslayout.unlocktext", currentSpec.unlockText)

  local unlockStatus = currentSpec.unlockStatus
  local unlocked = status.statusProperty(unlockStatus, false)

  if type(unlocked) == "number" and currentSpec.unlockNumber then
    widget.setText("specializationslayout.unlocktext", currentSpec.unlockText .. " " .. math.floor(unlocked*100)/100 .. "/" .. currentSpec.unlockNumber)
  end

  if unlocked ~= true then unlocked = false end
  
  widget.setVisible("specializationslayout.unlocktext", not unlocked)
  local understanding = false
  if unlocked then
    activeSkills = status.statusProperty("ivrpgskills", {})
    if activeSkills.skillbodytrueunderstanding and activeSkills.skillmindtrueunderstanding and activeSkills.skillsoultrueunderstanding then
      understanding = true
    end
  end
  widget.setButtonEnabled("specializationslayout.selectspec", self.level > 34 and (not disabled) and (understanding or not (currentSpec.gender and currentSpec.gender ~= player.gender())))
  widget.setVisible("specializationslayout.selectspec",  unlocked)  
end

function updateSpecializationTab()
  if self.class == 0 or self.spec == 0 then return end
  self.specType = self.specList[self.class][self.spec].name
  updateSpecInfo()
  local specInfo = self.specInfo

  widget.setText("specializationlayout.spectitle", specInfo.title)
  
  widget.setText("specializationlayout.classictext", concatTableValues(specInfo.classic, "\n"))
  
  widget.setText("specializationlayout.effecttext", specInfo.ability.text)
  
  widget.setText("specializationlayout.detrimenttext", concatTableValues(specInfo.effects, "\n", "detriment"))
  widget.setText("specializationlayout.benefittext", concatTableValues(specInfo.effects, "\n", "benefit"))
  
  widget.setText("specializationlayout.specweapontitle", specInfo.weapon.title)
  widget.setText("specializationlayout.specweapontext", concatTableValues(specInfo.weapon.text, "\n"))
  
  widget.setText("specializationlayout.techname", specInfo.tech.title)
  widget.setText("specializationlayout.techtype", specInfo.tech.type .. " Tech")
  widget.setText("specializationlayout.techtext", specInfo.tech.text)
  
  local scalingText = concatTableValues(specInfo.effects, "\n", "scaling-up") .. concatTableValues(specInfo.effects, "\n", "scaling-down")
  widget.setText("specializationlayout.statscalingtext", scalingText == "" and "-" or scalingText )

  if status.statusProperty("ivrpgshapeshift", false) then
    widget.setText("specializationlayout.specweaponicontitle", "Creature")
    local creature = status.statusProperty("ivrpgshapeshiftC", "")
    widget.setText("specializationlayout.specweapontitle", (creature == "" or creature == "giant") and (creature == "giant" and "Giant " or "") .. player.species():gsub("^%l", string.upper) or specInfo.tech.transformNames[creature])
    widget.setText("specializationlayout.specweapontext", concatTableValues(specInfo.tech.transformText[creature], "\n"))
    widget.setText("specializationlayout.detrimenttext", concatTableValues(specInfo.tech.transformBonusText[creature], "\n", "detriment"))
   widget.setText("specializationlayout.benefittext", concatTableValues(specInfo.tech.transformBonusText[creature], "\n", "benefit"))
   widget.setText("specializationlayout.statscalingtext", concatTableValues(specInfo.tech.transformBonusText[creature], "\n", "scaling-up") .. concatTableValues(specInfo.tech.transformBonusText[creature], "\n", "scaling-down"))
  else
    widget.setText("specializationlayout.specweaponicontitle", "Weapon")
  end

  widget.setImage("specializationlayout.techicon2", specInfo.tech.image)
  widget.setImage("specializationlayout.effecticon", specInfo.ability.image)
  widget.setImage("specializationlayout.effecticon2", specInfo.ability.image)
  widget.setImage("specializationlayout.specweaponicon", specInfo.weapon.image)

  local tech = specInfo.tech.name
  if hasValue(player.availableTechs(), tech) then
    widget.setVisible("specializationlayout.unlockbutton", false)
    widget.setVisible("specializationlayout.unlockedtext", true)
  else
    widget.setVisible("specializationlayout.unlockbutton", true)
    widget.setVisible("specializationlayout.unlockedtext", false)
  end
end

function unlockSpecTech()
  local specInfo = self.specInfo
  local tech = specInfo.tech.name
  player.makeTechAvailable(tech)
  player.enableTech(tech)
  updateSpecializationTab()
end

function specRight()
  self.specTo = (self.specTo == #self.availableSpecs) and 1 or self.specTo + 1
  updateSpecializationSelect()
end

function specLeft()
  self.specTo = (self.specTo == 1) and #self.availableSpecs or self.specTo - 1
  updateSpecializationSelect()
end

function chooseSpec()
  player.addCurrency("spectype", self.specTo)
end

function unlockSpecWeapon()
  if self.spec > 0 then
    for _,weapon in ipairs(self.specInfo.weapon.name) do
      player.giveBlueprint(weapon)
    end
  end
end

function unlockSpecLore()
  if self.spec > 0 then
    local loreUnlocks = self.specInfo.loreUnlocks
    if loreUnlocks then
      local currentUnlocks = status.statusProperty("ivrpgloreunlocks", {})
      for lore,title in pairs(loreUnlocks) do
        if not currentUnlocks[lore] then
          currentUnlocks[lore] = true
          sendRadioMessage("Lore Unlocked: " .. title)
        end
      end
      status.setStatusProperty("ivrpgloreunlocks", currentUnlocks)
    end
  end  
end

function unequipSpecialization()
  rescrollSpecialization(self.class, self.spec)
end

function unequipProfession()
  player.consumeCurrency("proftype", self.profession)
  self.profession = 0
  player.interact("OpenCraftingInterface", {config = "/professions/ivrpgfakeui.config"}, player.id())
end


function concatTableValues(table, delim, required)
  local returnV = ""
  local color = true
  local colorSwitch = {}
  colorSwitch[true] = "^white;"
  colorSwitch[false] = "^#d1d1d1;"
  for k,v in ipairs(table) do
    if (required and required == v.textType) or not required then
      returnV = returnV .. (v.textColor and ("^" .. v.textColor .. ";") or colorSwitch[color]) .. (type(v) == "table" and v.text or v) .. "^reset;" .. delim
      color = not color
    end
  end
  if returnV ~= "" and required then
    returnV = (required == "scaling-up" and "^green;Increased^reset;\n" or (required == "scaling-down" and "^red;Decreased^reset;\n" or "")) .. returnV
  end
  return returnV
end

function tableLength(table)
  local length = 0
  for k,v in pairs(table) do
    length = length + 1
  end
  return length
end

function updateUpgradeTab()

  local effectName = "nil"

  if status.statPositive("ivrpguctech") then
    effectName = status.getPersistentEffects("ivrpguctech")[2].stat
    widget.setText("upgradelayout.techname", self.textData.upgrades.tech[effectName].title)
    widget.setText("upgradelayout.techtext", self.textData.upgrades.tech[effectName].description)
    widget.setButtonEnabled("upgradelayout.tech", true)
  else
    widget.setText("upgradelayout.techname", "UNUSED")
    widget.setText("upgradelayout.techtext", "-")
    widget.setButtonEnabled("upgradelayout.tech", false)
  end

  if status.statPositive("ivrpgucweapon") then
    effectName = status.getPersistentEffects("ivrpgucweapon")[2].stat
    widget.setText("upgradelayout.weaponname", self.textData.upgrades.weapon[effectName].title)
    widget.setText("upgradelayout.weapontext", self.textData.upgrades.weapon[effectName].description)
    widget.setButtonEnabled("upgradelayout.weapon", true)
  else
    widget.setText("upgradelayout.weaponname", "UNUSED")
    widget.setText("upgradelayout.weapontext", "-")
    widget.setButtonEnabled("upgradelayout.weapon", false)
  end

  if status.statPositive("ivrpgucaffinity") then
    effectName = status.getPersistentEffects("ivrpgucaffinity")[2].stat
    widget.setText("upgradelayout.affinityname", self.textData.upgrades.affinity[effectName].title)
    widget.setText("upgradelayout.affinitytext", self.textData.upgrades.affinity[effectName].description)
    widget.setButtonEnabled("upgradelayout.affinity", true)
  else
    widget.setText("upgradelayout.affinityname", "UNUSED")
    widget.setText("upgradelayout.affinitytext", "-")
    widget.setButtonEnabled("upgradelayout.affinity", false)
  end

  if status.statPositive("ivrpgucgeneral") then
    effectName = status.getPersistentEffects("ivrpgucgeneral")[2].stat
    widget.setText("upgradelayout.generalname", self.textData.upgrades.general[effectName].title)
    widget.setText("upgradelayout.generaltext", self.textData.upgrades.general[effectName].description)
    widget.setButtonEnabled("upgradelayout.general", true)
  else
    widget.setText("upgradelayout.generalname", "UNUSED")
    widget.setText("upgradelayout.generaltext", "-")
    widget.setButtonEnabled("upgradelayout.general", false)
  end
end

function updateMasteryTab()
  widget.setText("masterylayout.masterypoints", self.mastery)
  widget.setText("masterylayout.xpover", math.max(0, math.min(self.xp - 250000, 250000)))

  if self.mastery < 3 or self.xp < 250000 then
    widget.setButtonEnabled("masterylayout.prestigebutton", false)
  else
    widget.setButtonEnabled("masterylayout.prestigebutton", true)
  end

  if self.mastery < 5 then
    widget.setButtonEnabled("masterylayout.shopbutton", false)
  else
    widget.setButtonEnabled("masterylayout.shopbutton", true)
  end

  if self.mastery == 100 or self.xp < 260000 then
    widget.setButtonEnabled("masterylayout.refinebutton", false)
  else
    widget.setButtonEnabled("masterylayout.refinebutton", true)
  end

  updateChallenges()
end

function updateInfo()
  self.classType = player.currency("classtype")
  self.strengthBonus = 1 + status.stat("ivrpgstrengthscaling")
  self.agilityBonus = 1 + status.stat("ivrpgagilityscaling")
  self.vitalityBonus = 1 + status.stat("ivrpgvitalityscaling")
  self.vigorBonus = 1 + status.stat("ivrpgvigorscaling")
  self.intelligenceBonus = 1 + status.stat("ivrpgintelligencescaling")
  self.enduranceBonus = 1 + status.stat("ivrpgendurancescaling")
  self.dexterityBonus = 1 + status.stat("ivrpgdexterityscaling")

  widget.setText("infolayout.displaystats", 
    "Amount\n" ..
    "^red;" .. math.floor(100*(1 + self.vitality^self.vitalityBonus*.05))/100 .. "^reset;" .. "\n" ..
    "^green;" .. math.floor(100*(1 + self.vigor^self.vigorBonus*.05))/100 .. "\n" ..
    math.floor(status.stat("energyRegenPercentageRate")*100+.5)/100 .. "\n" ..
    math.floor(status.stat("energyRegenBlockTime")*100+.5)/100 .. "^reset;" .. "\n" ..
    "^orange;" .. getStatPercent(status.stat("foodDelta")) .. "^reset;" ..
    "^gray;" .. getStatPercent(status.stat("grit")) ..
    getStatMultiplier(status.stat("fallDamageMultiplier")) ..
    math.floor((1 + self.strength^self.strengthBonus*.05)*100+.5)/100 .. "^reset;" .. "\n" ..
    "^red;" .. (math.floor(10000*status.stat("ivrpgBleedChance"))/100) .. "%\n" ..
    (math.floor(100*status.stat("ivrpgBleedLength"))/100) .. "^reset;" .. "\n" ..
    "\n\nPercent\n" ..
    "^gray;" .. getStatPercent(status.stat("physicalResistance")) .. "^reset;" ..
    "^green;" .. getStatPercent(status.stat("poisonResistance")) .. "^reset;" ..
    "^blue;" .. getStatPercent(status.stat("iceResistance")) .. "^reset;" .. 
    "^red;" .. getStatPercent(status.stat("fireResistance")) .."^reset;" .. 
    "^yellow;" .. getStatPercent(status.stat("electricResistance")) .. "^reset;" ..
    "^magenta;" .. getStatPercent(status.stat("novaResistance")) .. "^reset;" .. 
    "^black;" .. getStatPercent(status.stat("demonicResistance")) .."^reset;" .. 
    "^yellow;" .. getStatPercent(status.stat("holyResistance")) .. "^reset;" ..
    "^green;" .. getStatPercent(status.stat("radioactiveResistance")) .. "^reset;" ..
    "^gray;" .. getStatPercent(status.stat("shadowResistance")) .. "^reset;" ..
    "^magenta;" .. getStatPercent(status.stat("cosmicResistance")) .. "^reset;")

  widget.setText("infolayout.displaystatsFU", 
    "Immunity\n" ..
    "^red;" .. getStatImmunity(status.stat("fireStatusImmunity")) ..
    getStatImmunity(status.stat("lavaImmunity")) ..
    getStatImmunityNoLine(status.stat("biomeheatImmunity")) .. " [" .. getStatImmunityNoLine(status.stat("ffextremeheatImmunity")) .. "]\n" .. "^reset;" ..
    "^blue;" .. getStatImmunity(status.stat("iceStatusImmunity")) ..
    getStatImmunityNoLine(status.stat("biomecoldImmunity")) .. " [" .. getStatImmunityNoLine(status.stat("ffextremecoldImmunity")) .. "]\n" .. 
    getStatImmunity(status.stat("breathProtection")) .. "^reset;" ..
    "^green;" .. getStatImmunity(status.stat("poisonStatusImmunity")) ..
    getStatImmunityNoLine(status.stat("biomeradiationImmunity")) .. " [" .. getStatImmunityNoLine(status.stat("ffextremeradiationImmunity")) .. "]\n" .. "^reset;" ..
    "^yellow;" .. getStatImmunity(status.stat("electricStatusImmunity")) .. "^reset;" ..
    "^gray;" .. getStatImmunity(status.stat("invulnerable")))

  if status.statPositive("ivrpghardcore") then
    widget.setText("infolayout.displayWeapons", concatTableValues(self.classInfo.classic, "\n"))
    widget.setVisible("infolayout.displayWeapons", true)
  else
    widget.setVisible("infolayout.displayWeapons", false)
  end
end

function unlockTech()
  local checked = widget.getChecked("classlayout.techicon1") and 1 or (widget.getChecked("classlayout.techicon2") and 2 or (widget.getChecked("classlayout.techicon3") and 3 or 4))
  local tech = self.classInfo.techs[checked].name
  player.makeTechAvailable(tech)
  player.enableTech(tech)
  unlockTechVisible((tostring(checked)), 2^(checked+1))
end

function hasValue(table, value)
  for index, val in ipairs(table) do
    if value == val then return true end
  end
  return false
end

function unlockTechVisible(tech, amount)
  local check = player.currency("experienceorb") >= amount^2*100
  if check then
    local techName = self.classInfo.techs[tonumber(tech)].name
    if hasValue(player.availableTechs(), techName) then
      widget.setButtonEnabled("classlayout.unlockbutton", false)
      widget.setVisible("classlayout.unlockedtext", true)
    else
      widget.setButtonEnabled("classlayout.unlockbutton", true)
    end
    widget.setVisible("classlayout.reqlvl", false)
  else
    widget.setButtonEnabled("classlayout.unlockbutton", false)
    widget.setVisible("classlayout.reqlvl", true)
    widget.setText("classlayout.reqlvl", "Required Level: " .. math.floor(amount))
  end
  widget.setVisible("classlayout.unlockbutton", true)
end

function updateTechText(name)
  name = string.gsub(name,"techicon","")
  uncheckTechButtons(name)
  if not widget.getChecked("classlayout.techicon1") and not widget.getChecked("classlayout.techicon2") and not widget.getChecked("classlayout.techicon3") and not widget.getChecked("classlayout.techicon4") then
    widget.setText("classlayout.techtext", "Select a skill to read about it and unlock it if possible.")
    widget.setVisible("classlayout.techname", false)
    widget.setVisible("classlayout.techtype", false)
    widget.setVisible("classlayout.reqlvl", false)
    widget.setVisible("classlayout.unlockbutton", false)
    widget.setVisible("classlayout.unlockedtext", false)
    return
  else
    widget.setVisible("classlayout.techname", true)
    widget.setVisible("classlayout.techtype", true)
  end

  for i=1,4 do
    if name == tostring(i) then
      local tech = self.classInfo.techs[i]
      widget.setText("classlayout.techtext", tech.text)
      widget.setText("classlayout.techname", tech.title)
      widget.setText("classlayout.techtype", tech.type .. " Tech")
      unlockTechVisible(name, tech.level)
    end
  end
end

function uncheckTechButtons(name)
  widget.setVisible("classlayout.reqlvl", false)
  widget.setVisible("classlayout.unlockbutton", false)
  widget.setVisible("classlayout.unlockedtext", false)
  for i=1,4 do
    if name ~= tostring(i) then widget.setChecked("classlayout.techicon" .. i, false) end
  end
end

function updateTechImages()
  local className = self.classInfo.name
  for i=1,4 do
    widget.setButtonImages("classlayout.techicon" .. i, {
      base = "/interface/RPGskillbook/techbuttons/" .. className .. i .. ".png",
      hover = "/interface/RPGskillbook/techbuttons/" .. className .. i .. "hover.png",
      pressed = "/interface/RPGskillbook/techbuttons/" .. className .. i .. "pressed.png",
      disabled = "/interface/RPGskillbook/techbuttons/techbuttonbackground.png"
    })
    widget.setButtonCheckedImages("classlayout.techicon" .. i, {
      base = "/interface/RPGskillbook/techbuttons/" .. className .. i .. "pressed.png",
      hover = "/interface/RPGskillbook/techbuttons/" .. className .. i .. "hover.png"
    })
  end
end

function getStatPercent(stat)
  stat = math.floor(stat*10000+.50)/100
  return stat >= 100 and "Immune!\n" or (stat < 0 and stat .. "%\n" or (stat == 0 and "0%\n" or "+" .. stat .. "%\n"))
end

function getStatMultiplier(stat)
  stat = math.floor(stat*100+.5)/100
  return stat <= 0 and "0\n" or (stat .. "\n")
end

function getStatImmunity(stat)
  return tostring(stat >= 1):gsub("^%l",string.upper) .. "\n"
end

function getStatImmunityNoLine(stat)
  return tostring(stat >= 1):gsub("^%l",string.upper)
end

function raiseStat(name)
  player.consumeCurrency("statpoint", 1)
  name = string.gsub(name,"raise","") .. "point"
  player.addCurrency(name, 1)
  updateStats()
end

function checkStatPoints()
  if player.currency("statpoint") == 0 then
    enableStatButtons(false)
  elseif player.currency("statpoint") ~= 0 then
    enableStatButtons(true)
  end
end

function checkStatDescription(name)
  name = string.gsub(name,"icon","")
  uncheckStatIcons(name)
  if (widget.getChecked("statslayout."..name.."icon")) then
    changeStatDescription(name)
  else
    changeStatDescription("default")
  end
end

function checkClassDescription(name)
  name = string.gsub(name,"icon","")
  uncheckClassIcons(name)
  if (widget.getChecked("classeslayout."..name.."icon")) then
    changeClassDescription(name)
    widget.setButtonEnabled("classeslayout.selectclass", true)
  else
    changeClassDescription("default")
    widget.setButtonEnabled("classeslayout.selectclass", false)
  end
end

function updateStats()
  for k,v in pairs(self.statList) do
    if k ~= "default" then
      self[k] = player.currency(k .. "point")
      widget.setText("statslayout." .. k .. "amount", self[k])
    else
      self[k] = 0
    end
  end
  widget.setText("statslayout.statpointsleft", player.currency("statpoint"))
  widget.setText("statslayout.totalstatsamount", addStats())
  checkStatPoints()
end

function addStats()
  return self.strength + self.agility + self.vitality + self.vigor + self.intelligence + self.endurance + self.dexterity
end

function uncheckStatIcons(name)
  for k,v in pairs(self.statList) do
    if name ~= k then
      widget.setChecked("statslayout." .. k .. "icon", false)
    end
  end
end

function uncheckClassIcons(name)
  for k,v in ipairs(self.classList) do
    if name ~= v and v ~= "default" then
      widget.setChecked("classeslayout." .. v .. "icon", false)
      widget.setFontColor("classeslayout." .. v .. "title", "white")
    end
  end
end

function changeStatDescription(name)
  widget.setText("statslayout.statdescription", concatTableValues(self.statList[name], "\n"))
end

function changeClassDescription(name)
  local textArray = root.assetJson("/classes/classDescriptions.config")[name]
  widget.setText("classeslayout.classdescription", textArray.text) 
  widget.setFontColor("classeslayout." .. name .. "title", textArray.color)
  self.classTo = textArray.class
  uncheckClassIcons(name)
end

function enableStatButtons(enable)
  if player.currency("classtype") == 0 then
    enable = false
    widget.setVisible("statslayout.statprevention",true)
  else
    widget.setVisible("statslayout.statprevention",false)
  end
  for k,v in pairs(self.statList) do
    if k ~= "default" then
      widget.setButtonEnabled("statslayout.raise" .. k, self[k] ~= 50 and enable)
    end
  end
end

function chooseClass()
  player.addCurrency("classtype", self.classTo)
  self.class = self.classTo
  updateClassInfo()
  addClassStats()
  changeToClasses()
end

function addClassStats()
  for k,v in pairs(self.classInfo.stats) do
    player.addCurrency(k .. "point", v)
  end
  updateStats()
  uncheckClassIcons("default")
  changeClassDescription("default")
end

function areYouSure(name)
  name = string.gsub(name,"resetbutton","")
  name2 = ""
  if name == "" then name2 = "overviewlayout"
  elseif name == "cl" then name2 = "classlayout" end
  widget.setVisible(name2..".resetbutton"..name, false)
  widget.setVisible(name2..".yesbutton", true)
  widget.setVisible(name2..".nobutton"..name, true)
  widget.setVisible(name2..".areyousure", true)
  --widget.setVisible(name2..".hardcoretext", false)
end

function notSure(name)
  name = string.gsub(name,"nobutton","")
  name2 = ""
  if name == "" then name2 = "overviewlayout"
  elseif name == "cl" then name2 = "classlayout" end
  widget.setVisible(name2..".resetbutton"..name, true)
  widget.setVisible(name2..".yesbutton", false)
  widget.setVisible(name2..".nobutton"..name, false)
  widget.setVisible(name2..".areyousure", false)
  --updateOverview(2*self.level*100+100)
end

function resetSkillBook()
  notSure("nobutton")
  consumeAllRPGCurrency()
  consumeMasteryCurrency()
  removeTechs()
end

function removeTechs()
  for k,v in ipairs(self.classInfo.techs) do
    player.makeTechUnavailable(v.name)
  end
end

function updateClassWeapon()
  if self.class == 0 then return end
  if player.hasCompletedQuest(self.classInfo.weapon.quest) then
    widget.setText("classlayout.classweapontext", concatTableValues(self.classInfo.weapon.text, "\n"))
    widget.setVisible("classlayout.weaponreqlvl", false)
    widget.setVisible("classlayout.unlockquestbutton", false)
    widget.setVisible("classlayout.classweapontext", true)
  elseif self.level < 12 then
    widget.setFontColor("classlayout.weaponreqlvl", "red")
    widget.setText("classlayout.weaponreqlvl", "Required Level: 12")
    widget.setVisible("classlayout.weaponreqlvl", true)
    widget.setVisible("classlayout.unlockquestbutton", false)
    widget.setVisible("classlayout.classweapontext", false)
  else
    widget.setText("classlayout.classweapontext", "Complete the first quest for more information. If you have abandoned the quest, please reuse the button below.")
    widget.setVisible("classlayout.classweapontext", true)
    widget.setVisible("classlayout.weaponreqlvl", false)
    widget.setVisible("classlayout.unlockquestbutton", true)
  end
end

function unlockQuest()
  player.startQuest(self.classInfo.weapon.quest)
end

function chooseAffinity()
  player.addCurrency("affinitytype", self.affinityTo)
  self.affinity = self.affinityTo
  updateAffinityInfo()
  addAffinityStats()
  changeToAffinities()
end

function upgradeAffinity()
  player.addCurrency("affinitytype", 4)
  self.affinity = self.affinity + 4
  addAffinityStats()
  changeToAffinities()
end

function checkAffinityDescription(name)
  name = string.gsub(name,"icon","")
  uncheckAffinityIcons(name)
  if (widget.getChecked("affinitieslayout."..name.."icon")) then
    changeAffinityDescription(name)
    widget.setButtonEnabled("affinitieslayout.selectaffinity", true)
  else
    changeAffinityDescription("default")
    widget.setButtonEnabled("affinitieslayout.selectaffinity", false)
  end
end

function uncheckAffinityIcons(name)
  for k,v in pairs(self.affinityDescriptions) do
    if name ~= k and k ~= "default" then
      widget.setChecked("affinitieslayout." .. k .. "icon", false)
      widget.setFontColor("affinitieslayout." .. k .. "title", "white")
    end
  end
end

function changeAffinityDescription(name)
  local affinity = self.affinityDescriptions[name]
  widget.setText("affinitieslayout.affinitydescription", affinity.text) 
  widget.setFontColor("affinitieslayout." .. name .. "title", affinity.color)
  self.affinityTo = affinity.type
  uncheckAffinityIcons(name)
end

function updateAffinityTab()
  updateAffinityInfo()
  widget.setText("affinitylayout.affinitytitle", self.affinityInfo.title)
  widget.setFontColor("affinitylayout.affinitytitle", self.affinityInfo.color)
  widget.setImage("affinitylayout.affinityicon", self.affinityInfo.image)
  widget.setText("affinitylayout.passivetext", concatTableValues(self.affinityInfo.passive, "\n"))
  widget.setText("affinitylayout.immunitytext", concatTableValues(self.affinityInfo.immunity, "\n"))
  widget.setText("affinitylayout.weaknesstext", concatTableValues(self.affinityInfo.weakness, "\n"))
  widget.setText("affinitylayout.upgradetext", concatTableValues(self.affinityInfo.upgrade, "\n"))
  local statText = ""
  for k,v in pairs(self.affinityInfo.stats) do
    statText = statText .. "+" .. v .. " " .. k:gsub("^%l", string.upper) .. "\n"
  end
  widget.setText("affinitylayout.statscalingtext", statText)
  
  if self.affinity > 4 then
    widget.setVisible("affinitylayout.effecttext", false)
  elseif self.affinity > 0 then
    widget.setVisible("affinitylayout.effecttext", true)
  end

  if status.statPositive("ivrpgaesthetics") then
    widget.setText("affinitylayout.aestheticstoggletext", "Active")
  else
    widget.setText("affinitylayout.aestheticstoggletext", "Inactive")
  end
end

function addAffinityStats()
  for k,v in pairs(self.affinityInfo.stats) do
    addAffintyStatsHelper(k .. "point", v)
  end
  updateStats()
  uncheckAffinityIcons("default")
  changeAffinityDescription("default")
end

function addAffintyStatsHelper(statName, amount)
  local current = 50 - player.currency(statName)
  if current < amount then
    --Adds Stat Points if Bonus Stat is near maxed!
    player.addCurrency("statpoint", amount - current)
  end
  player.addCurrency(statName, amount)
end

function toggleAesthetics()
  if status.statPositive("ivrpgaesthetics") then
    status.clearPersistentEffects("ivrpgAesthetics")
  else
    status.setPersistentEffects("ivrpgAesthetics",
    {
      {stat = "ivrpgaesthetics", amount = 1}
    })
  end
  updateAffinityTab()
end

function toggleHardcore()
  if status.statPositive("ivrpghardcore") then
    status.clearPersistentEffects("ivrpgHardcore")
  else
    status.setPersistentEffects("ivrpgHardcore",
    {
      {stat = "ivrpghardcore", amount = 1}
    })
  end
  updateOverview(2*self.level*100+100)
end

function toggleRallyMode()
  if not status.statusProperty("ivrpgrallymode", false) then
    status.setStatusProperty("ivrpgrallymode", true)
  else
    status.setStatusProperty("ivrpgrallymode", false)
  end
  updateOverview(2*self.level*100+100)
end

function toggleClassAbility()
  if status.statPositive("ivrpgclassability") then
    status.clearPersistentEffects("ivrpgClassAbility")
  else
    status.setPersistentEffects("ivrpgClassAbility",
    {
      {stat = "ivrpgclassability", amount = 1}
    })
  end
  updateClassTab()
end

function consumeAllRPGCurrency()
  player.consumeCurrency("experienceorb", player.currency("experienceorb") - 100)
  player.consumeCurrency("currentlevel", self.level - 1)
  player.consumeCurrency("statpoint", player.currency("statpoint"))
  for k,v in pairs(self.statList) do
    if k ~= "default" then
      player.consumeCurrency(k .. "point", player.currency(k .. "point"))
    end
  end
  rescrollSpecialization(self.class, self.spec)
  player.consumeCurrency("classtype",player.currency("classtype"))
  player.consumeCurrency("affinitytype",player.currency("affinitytype"))
  player.consumeCurrency("proftype",player.currency("proftype"))
  player.consumeCurrency("spectype",player.currency("spectype"))
  status.setStatusProperty("ivrpgskillpoints", 1)
  status.setStatusProperty("ivrpgskills", { })
  startingStats()
  updateStats()
end

function prestige()
  player.consumeCurrency("masterypoint", 3)
  consumeAllRPGCurrency()
  player.addCurrency("statpoint", status.statusProperty("ivrpgextrastatpoints", 0))
end

function purchaseShop()
  player.consumeCurrency("masterypoint", 5)
  player.giveItem("ivrpgmasteryshop")
end

function refine()
  local xp = math.min(self.xp, 500000) - 250000
  local mastery = math.floor(xp/10000)
  player.addCurrency("masterypoint", mastery)
  player.consumeCurrency("experienceorb", 10000*mastery)
end

function updateChallenges()
  if not status.statPositive("ivrpgchallenge1") then
    status.setPersistentEffects("ivrpgchallenge1", {
    -- 1. Defeat 150 Level 4 or higher enemies.
    -- 2. Defeat 100 Level 6 or higher enemies.
    -- 3. Defeat 1 Boss Monster.
    -- 4. Defeat the Erchius Horror without taking damage.
      {stat = "ivrpgchallenge1", amount = math.random(1,3)}
    })
  end
  if not status.statPositive("ivrpgchallenge2") then
    -- 1. Defeat 300 Level 6 or higher enemies.
    -- 2. Defeat 3 Boss Monsters.
    status.setPersistentEffects("ivrpgchallenge2", {
      {stat = "ivrpgchallenge2", amount = math.random(1,2)}
    })
  end
  if not status.statPositive("ivrpgchallenge3") then
    -- 1. Defeat 300 Vault enemies.
    -- 2. Defeat 3 Vault Guardians.
    -- 3. Defeat 5 Boss Monsters.
    -- 4. Deafeat the Heart of Ruin without taking damage.
    status.setPersistentEffects("ivrpgchallenge3", {
      {stat = "ivrpgchallenge3", amount = math.random(1,3)}
    })
  end
  updateChallengesText()
end

function updateChallengesText()
  local challenge1 = status.stat("ivrpgchallenge1")
  local challenge2 = status.stat("ivrpgchallenge2")
  local challenge3 = status.stat("ivrpgchallenge3")

  widget.setText("masterylayout.challenge1", self.challengeText[1][challenge1][1])
  widget.setText("masterylayout.challenge2", self.challengeText[2][challenge2][1])
  widget.setText("masterylayout.challenge3", self.challengeText[3][challenge3][1])

  local prog1 = math.floor(status.statusProperty("ivrpgchallenge1progress", 0))
  local prog2 = math.floor(status.statusProperty("ivrpgchallenge2progress", 0))
  local prog3 = math.floor(status.statusProperty("ivrpgchallenge3progress", 0))

  local maxprog1 = self.challengeText[1][challenge1][2]
  local maxprog2 = self.challengeText[2][challenge2][2]
  local maxprog3 = self.challengeText[3][challenge3][2]

  widget.setText("masterylayout.challenge1progress", (prog1 > maxprog1 and maxprog1 or prog1) .. " / " .. maxprog1)
  widget.setText("masterylayout.challenge2progress", (prog2 > maxprog2 and maxprog2 or prog2) .. " / " .. maxprog2)
  widget.setText("masterylayout.challenge3progress", (prog3 > maxprog3 and maxprog3 or prog3) .. " / " .. maxprog3)

  if prog1 >= maxprog1 then
    widget.setFontColor("masterylayout.challenge1progress", "green")
    widget.setButtonEnabled("masterylayout.challenge1button", true)
  else
    widget.setFontColor("masterylayout.challenge1progress", "red")
    widget.setButtonEnabled("masterylayout.challenge1button", false)
  end

  if prog2 >= maxprog2 then
    widget.setFontColor("masterylayout.challenge2progress", "green")
    widget.setButtonEnabled("masterylayout.challenge2button", true)
  else
    widget.setFontColor("masterylayout.challenge2progress", "red")
    widget.setButtonEnabled("masterylayout.challenge2button", false)
  end

  if prog3 >= maxprog3 then
    widget.setFontColor("masterylayout.challenge3progress", "green")
    widget.setButtonEnabled("masterylayout.challenge3button", true)
  else
    widget.setFontColor("masterylayout.challenge3progress", "red")
    widget.setButtonEnabled("masterylayout.challenge3button", false)
  end

end

function challengeRewards(name)
  local rand = math.random(1,10)
  if name == "challenge1button" then
    status.clearPersistentEffects("ivrpgchallenge1")
    status.setStatusProperty("ivrpgchallenge1progress", 0)
    if rand < 4 then
      player.giveItem({"experienceorb", math.random(1000,2000)})
    elseif rand < 7 then
      player.giveItem({"money", math.random(500,1000)})
      player.giveItem({"experienceorb", math.random(250,500)})
    elseif rand < 9 then
      player.giveItem({"liquidfuel", 500})
      player.giveItem({"experienceorb", math.random(250,500)})
    else
      player.giveItem({"rewardbag", 5})
      player.giveItem({"experienceorb", math.random(250,500)})
    end
  elseif name == "challenge2button" then
    status.clearPersistentEffects("ivrpgchallenge2")
    status.setStatusProperty("ivrpgchallenge2progress", 0)
    if rand < 4 then
      player.giveItem({"experienceorb", math.random(2500,5000)})
    elseif rand < 7 then
      player.giveItem({"money", math.random(1500,2500)})
      player.giveItem({"experienceorb", math.random(500,750)})
    elseif rand < 8 then
      player.giveItem({"masterypoint", 1})
    else
      player.giveItem({"ultimatejuice", math.random(5,10)})
      player.giveItem({"experienceorb", math.random(500,750)})
    end
  elseif name == "challenge3button" then
    status.clearPersistentEffects("ivrpgchallenge3")
    status.setStatusProperty("ivrpgchallenge3progress", 0)
    if rand < 5 then
      player.giveItem({"essence", math.random(500,750)})
    elseif rand < 7 then
      player.giveItem({"masterypoint", 1})
    elseif rand < 10 then
      player.giveItem({"essence", math.random(100,250)})
      player.giveItem({"diamond", math.random(7,12)})
    else
      player.giveItem({"vaultkey", 1})
    end
  end
end

function consumeMasteryCurrency()
  player.consumeCurrency("masterypoint",player.currency("masterypoint"))
  status.clearPersistentEffects("ivrpgmasteryunlocked")
  status.clearPersistentEffects("ivrpgchallenge1")
  status.clearPersistentEffects("ivrpgchallenge2")
  status.clearPersistentEffects("ivrpgchallenge3")
  status.setStatusProperty("ivrpgchallenge1progress", 0)
  status.setStatusProperty("ivrpgchallenge2progress", 0)
  status.setStatusProperty("ivrpgchallenge3progress", 0)
  status.setStatusProperty("ivrpgextrastatpoints", 0)
end

function unequipUpgrade(name)
  name = "ivrpguc" .. name
  local effects = status.getPersistentEffects(name)
  local uc = effects[2].stat or "masterypoint"
  player.giveItem(uc)
  status.setPersistentEffects(name, {
    {stat = name, amount = 0}
  })
end

function updateLoreTab()
  if widget.getChecked("lorelayout.changelogbutton") then
    
  elseif widget.getChecked("lorelayout.lorebutton") then

  elseif widget.getChecked("lorelayout.creditsbutton") then

  else
    widget.setChecked("lorelayout." .. self.lastLoreChecked .. "button", true)
    if self.lastLoreChecked == "lore" then
      changeToLoreText()
    elseif self.lastLoreChecked == "changelog" then
      changeToChangelogText()
    else
      changeToCreditsText()
    end
  end
end

function changeToChangelogText()
  uncheckLoreTabs("changelog")
  local version = self.versionConfig.version
  widget.setVisible("lorelayout.scrollArea.list", true)
  widget.setVisible("lorelayout.backarrow", true)
  widget.setText("lorelayout.title", "RPG Growth " .. version)
  widget.setText("lorelayout.scrollArea.text", "")
  self.logTable = {self.lastLoreChecked}
  buildNewLog()
end

function buildNewLog()
  widget.clearListItems("lorelayout.scrollArea.list")
  widget.setText("lorelayout.scrollArea.text", "")
  local logData = self.versionConfig
  for _,v in ipairs(self.logTable) do
    widget.setText("lorelayout.title", logData[v].title or "^red;Changelog")
    logData = logData[v].children
  end
  if type(logData) == "table" then
    local added = false
    for k,v in (self.lastLoreChecked == "changelog" and pairsByKeys(logData, function(t, a, b) return t[b].version < t[a].version end) or pairsByKeys(logData)) do
      local newListItem = widget.addListItem("lorelayout.scrollArea.list")
      widget.setText("lorelayout.scrollArea.list." .. newListItem .. ".title", v.title)
      widget.setData("lorelayout.scrollArea.list." .. newListItem, k)
      added = true
    end
    if not added then
      widget.setText("lorelayout.scrollArea.text", "^red;Looks like there's nothing here yet!")
    else
      widget.setText("lorelayout.scrollArea.text", "")
    end
  else
    widget.setText("lorelayout.scrollArea.text", changelogTextHelper(tostring(logData)))
  end
  widget.setButtonEnabled("lorelayout.backarrow", #self.logTable > 1)
end

function changelogTextHelper(text)
  --local text = self.versionConfig[self.lastLoreChecked]
  local returnText = ""
  local colorSwitch = {}
  local switch = true
  local maxLength = 73
  colorSwitch[true] = "^white;"
  colorSwitch[false] = "^#d1d1d1;"
  local previousSpace = false
  for s in text:gmatch("[^\r\n]+") do
    local space = string.match(s, "[%s%s%s%s]*") or ""
    if space == previousSpace then
      switch = not switch
    else
      switch = true
    end
    previousSpace = space
    if returnText ~= "" and (space == "" or space == " ") then
      returnText = returnText .. "\n"
    end
    if string.len(s) > maxLength then
      local words = {}
      for word in s:gmatch("%S+") do table.insert(words, word) end
      --sb.logInfo(sb.printJson(words))
      local charCount = string.len(space)
      local line = ""
      for _,word in ipairs(words) do
        charCount = charCount + string.len(word) + (line == "" and 0 or 1)
        if charCount > maxLength then
          charCount = string.len(space) + string.len(word)
          returnText = returnText .. colorSwitch[switch] .. space .. line .. "\n"
          line = word
        else
          if line ~= "" then
            line = line .. " " .. word
          else
            line = word
          end
        end
      end
      returnText = returnText .. colorSwitch[switch] .. space .. line .. "\n"
    else
      returnText = returnText .. colorSwitch[switch] .. s .. "\n"
    end
  end
  return returnText
end

function changeToCreditsText()
  uncheckLoreTabs("credits")
  widget.setVisible("lorelayout.scrollArea.list", true)
  widget.setVisible("lorelayout.backarrow", true)
  widget.setText("lorelayout.title", "Credits")
  widget.setText("lorelayout.scrollArea.text", "")
  self.logTable = {self.lastLoreChecked}
  buildNewLog()
end

function changeToLoreText()
  uncheckLoreTabs("lore")
  widget.setVisible("lorelayout.scrollArea.list", true)
  widget.setVisible("lorelayout.backarrow", true)
  widget.setText("lorelayout.title", "Lore")
  widget.setText("lorelayout.scrollArea.text", "")
  buildNewLore()
end

function uncheckLoreTabs(name)
  self.lastLoreChecked = name
  local tabs = {"lore", "changelog", "credits"}
  for _,tab in ipairs(tabs) do
    if tab ~= name then
      widget.setChecked("lorelayout." .. tab .. "button", false)
    end
  end
end

function mechanicsCheck()
  return (#self.loreTable >= 2 and self.loreTable[2] == "mechanics" and not (#self.loreTable >= 4 and self.loreTable[3] == "enemies"))
end

function changeLoreSelection()
  if self.lastLoreChecked == "lore" then
    local selectedLore = widget.getListSelected("lorelayout.scrollArea.list")
    if selectedLore and type(selectedLore) == "string" then
      local name = widget.getData("lorelayout.scrollArea.list." .. selectedLore)
      local unlocks = status.statusProperty("ivrpgloreunlocks", {})
      if name and (unlocks[name] or mechanicsCheck()) then
        table.insert(self.loreTable, name)
        buildNewLore()
      end
    end
  else
    local selectedNode = widget.getListSelected("lorelayout.scrollArea.list")
    if selectedNode and type(selectedNode) == "string" then
      local name = widget.getData("lorelayout.scrollArea.list." .. selectedNode)
      if name then
        table.insert(self.logTable, name)
        buildNewLog()
      end
    end
  end
end

function buildNewLore()
  widget.clearListItems("lorelayout.scrollArea.list")
  widget.setText("lorelayout.scrollArea.text", "")
  local unlocks = status.statusProperty("ivrpgloreunlocks", {})
  local loreData = self.textData
  for _,v in ipairs(self.loreTable) do
    widget.setText("lorelayout.title", loreData[v].title or "^red;Lore")
    loreData = loreData[v].children
  end
  if type(loreData) == "table" then
    local added = false
    for k,v in pairsByKeys(loreData) do
      local newListItem = widget.addListItem("lorelayout.scrollArea.list")
      widget.setText("lorelayout.scrollArea.list." .. newListItem .. ".title", v.title)
      widget.setData("lorelayout.scrollArea.list." .. newListItem, k)
      widget.setText("lorelayout.scrollArea.list." .. newListItem .. ".subtext", (unlocks[k] or mechanicsCheck()) and "" or "^red;Data Obscured")
      added = true
    end
    if not added then
      widget.setText("lorelayout.scrollArea.text", "^red;Looks like there's nothing here yet!")
    else
      widget.setText("lorelayout.scrollArea.text", "")
    end
  else
    if #self.loreTable == 4 and self.loreTable[4] == "enemyintelligence" then
      loreData = tostring(loreData) .. "\n\n^red;RPG AI " .. (self.versionConfig.RPGAI_version and
        (self.versionConfig.RPGAI_refactorVersion ~= self.versionConfig.refactorVersion and "Version does not match RPG Growth and will be ignored." or
        tostring(self.versionConfig.RPGAI_version) .. " installed. Vanilla monsters will have the following behaviors:^reset; " .. self.versionConfig.RPGAI_text)
        or "not installed. Vanilla monsters will not be affected.")
    end
    widget.setText("lorelayout.scrollArea.text", tostring(loreData))
  end
  widget.setButtonEnabled("lorelayout.backarrow", #self.loreTable > 1)
end

function oneLoreUp()
  if self.lastLoreChecked == "lore" then
    if #self.loreTable > 1 then
      table.remove(self.loreTable)
    end
    buildNewLore()
  else
    if #self.logTable > 1 then
      table.remove(self.logTable)
    end
    buildNewLog()
  end
end

function updateSkillTab()
  if widget.getChecked("skillslayout.bodybutton") then
    buildNewSkill(#self.skillTable > 2)
  elseif widget.getChecked("skillslayout.mindbutton") then
    buildNewSkill(#self.skillTable > 2)
  elseif widget.getChecked("skillslayout.soulbutton") then
    buildNewSkill(#self.skillTable > 2)
  else
    widget.setChecked("skillslayout." .. self.lastSkillChecked .. "button", true)
    changeSkillArea(self.lastSkillChecked)
  end
  local points = status.statusProperty("ivrpgskillpoints", 0)
  widget.setText("skillslayout.skillpoints", points)
  widget.setFontColor("skillslayout.skillpoints", points > 0 and "green" or "red")
end

function changeSkillArea(name)
  name = string.gsub(name,"button","")
  uncheckSkillTabs(name)
  self.lastSkillChecked = name
  self.skillTable = {"skill", self.lastSkillChecked}
  widget.setVisible("skillslayout.scrollArea.list", true)
  widget.setVisible("skillslayout.backarrow", true)
  widget.setText("skillslayout.title", self.lastSkillChecked:sub(1,1):upper() .. self.lastSkillChecked:sub(2))
  widget.setText("skillslayout.scrollArea.text", "")
  buildNewSkill()
end

function uncheckSkillTabs(name)
  local tabs = {"body", "mind", "soul"}
  for _,tab in ipairs(tabs) do
    if tab ~= name then
      widget.setChecked("skillslayout." .. tab .. "button", false)
    end
  end
end

function changeSkillSelection()
  local selectedSkill = widget.getListSelected("skillslayout.scrollArea.list")
  if selectedSkill and type(selectedSkill) == "string" then
    local name = widget.getData("skillslayout.scrollArea.list." .. selectedSkill)
    if name and not self.textData[self.skillTable[1]].children[self.skillTable[2]].children[name].disabled then
      table.insert(self.skillTable, name)
      buildNewSkill()
    end
  end
end

function buildNewSkill(ignoreBuild)
  if not ignoreBuild then
    widget.clearListItems("skillslayout.scrollArea.list")
    widget.setText("skillslayout.scrollArea.text", "")
    widget.setButtonEnabled("skillslayout.equipskill", false)
    widget.setVisible("skillslayout.equipskill", false)
    widget.setButtonEnabled("skillslayout.unequipskill", false)
    widget.setVisible("skillslayout.unequipskill", false)
    widget.setButtonEnabled("skillslayout.upgradeskill", false)
    widget.setVisible("skillslayout.upgradeskill", false)
  end
  local skillName, skillData, title = returnSkillNameAndData()
  local activeSkills = status.statusProperty("ivrpgskills", {})
  widget.setText("skillslayout.title", title or "^red;Body")
  local skillTier = activeSkills[skillName]
  if type(skillData.children) == "string" then
    local text = tostring(skillData.children) .. "\n"
    local bonusText, upgradeAvailable = addSkillText(skillData.requires, skillTier, skillData.tierText)
    text = text .. bonusText
    widget.setText("skillslayout.scrollArea.text", text)
    updateSkillUpgradeButton(activeSkills[skillName], #skillData.tierText, upgradeAvailable)
    -- Add Tiers
  else
    local added = false
    for k,v in pairsByKeys(skillData) do
      local newListItem = widget.addListItem("skillslayout.scrollArea.list")
      widget.setText("skillslayout.scrollArea.list." .. newListItem .. ".title", v.title)
      widget.setData("skillslayout.scrollArea.list." .. newListItem, k)
      local tier = activeSkills[skillName..k]
      local maxTier = #v.tierText
      local cost = tier and skillCost(#v.tierText, tier, v.requires) or 0
      widget.setText("skillslayout.scrollArea.list." .. newListItem .. ".subtext", tier and ("^green;At Tier " .. tier .. " of " .. maxTier .. "^reset; - ^red;Costs " .. cost) or (v.disabled and "^red;Disabled" or "^red;Unequipped"))
      added = true
    end
    if not added then
      widget.setText("skillslayout.scrollArea.text", "^red;Looks like there's nothing here yet!")
    else
      widget.setText("skillslayout.scrollArea.text", "")
    end
  end
  widget.setButtonEnabled("skillslayout.backarrow", #self.skillTable > 2)
end

function addSkillText(requires, currentTier, tierText)
  local returnText = ""
  local available = true
  local bonusText = ""
  local tiers = #tierText

  if not currentTier then currentTier = 0 end
  local count = 1
  for _,text in ipairs(tierText or {}) do
    returnText = returnText .. (count == currentTier and "\n^green;" or "^reset;\n") .. "Tier " .. count .. ": " .. text
    count = count + 1
  end

  if currentTier < tiers then
    requires = requires[currentTier + 1]
  end
  -- Return if at max Tier
  if currentTier == tiers then
    updateSkillEquipButtons(true)
    return returnText, false
  end

  returnText = returnText .. "\n\n^gray;Required For Next Tier^reset;"
  -- Adds Stat Requirements
  count = 1
  for k,v in pairs(requires.stats) do
    if player.currency(k .. "point") < v then
      available = false
      bonusText = "^red;"
    else
      bonusText = "^green;"
    end
    returnText = returnText .. (count == 1 and "\n^reset;Stats: " or "^reset;, ") .. bonusText .. v .. " in " .. k:gsub("^%l", string.upper)
    count = count + 1
  end
  -- Adds Skill Requirements
  count = 1
  local activeSkills = status.statusProperty("ivrpgskills", {})
  for k,v in pairs(requires.skills) do
    local tier = activeSkills[k] or 0
    if tier < v[2] then
      available = false
      bonusText = "^red;"
    else
      bonusText = "^green;"
    end
    returnText = returnText .. (count == 1 and "\n^reset;Skills: " or "^reset;, ") .. bonusText .. v[1] .. " Atleast Tier " .. v[2]
    count = count + 1
  end
  -- Adds Point Requirements
  if requires.points > status.statusProperty("ivrpgskillpoints", 0) then
    available = false
    bonusText = "^red;"
  else
    bonusText = "^green;"
  end
  returnText = returnText .. "\n^reset;Cost: " .. bonusText .. requires.points .. " Skill Points"
  updateSkillEquipButtons(currentTier > 0, available)
  return returnText, available
end

function oneSkillUp()
  if #self.skillTable > 2 then
    table.remove(self.skillTable)
  end
  buildNewSkill()
end

function updateSkillUpgradeButton(tier, tiers, available)
  local upgrade = false
  if tier and tiers > 1 and tier < tiers then
    upgrade = true
  end
  widget.setButtonEnabled("skillslayout.upgradeskill", upgrade and available)
  widget.setVisible("skillslayout.upgradeskill", upgrade)
end

function updateSkillEquipButtons(unequip, available)
  widget.setButtonEnabled("skillslayout.equipskill", not unequip and available)
  widget.setVisible("skillslayout.equipskill", not unequip)
  widget.setButtonEnabled("skillslayout.unequipskill", unequip)
  widget.setVisible("skillslayout.unequipskill", unequip)
end

function skillCost(tiers, currentTier, requires)
  local cost = 0
  for i=1,currentTier do
    cost = cost + requires[i].points
  end
  return cost
end

function returnSkillNameAndData()
  local skillData = self.textData
  local skillName = ""
  local skillTitle = ""
  for _,v in ipairs(self.skillTable) do
    skillName = skillName .. v
    skillData = skillData[v]
    skillTitle = skillTitle .. (skillData.title and (skillTitle == "" and "" or " - ") .. skillData.title or "")
    if type(skillData.children) == "table" then
      skillData = skillData.children
    end
  end
  return skillName, skillData, skillTitle
end

function toggleSkill()
  local activeSkills = status.statusProperty("ivrpgskills", {})
  local skillName, skillData, skillTitle = returnSkillNameAndData()
  local skillTier = activeSkills[skillName]
  local cost = 0
  if skillTier then
    cost = skillCost(#skillData.tierText, skillTier, skillData.requires)
    activeSkills[skillName] = nil
    if skillData.removes then
      for i=skillTier,1,-1 do
        for _,v in ipairs(skillData.removes[i]) do
          removeSkill(v)
          activeSkills[v] = nil
        end
      end
    end
    status.setStatusProperty("ivrpgskillpoints", status.statusProperty("ivrpgskillpoints", 0) + cost)
  else
    cost = skillData.requires[1].points
    activeSkills[skillName] = 1
    status.setStatusProperty("ivrpgskillpoints", status.statusProperty("ivrpgskillpoints", 0) - cost)
  end
  local text = tostring(skillData.children) .. "\n"
  local bonusText, upgradeAvailable = addSkillText(skillData.requires, activeSkills[skillName], skillData.tierText)
  text = text .. bonusText
  widget.setText("skillslayout.scrollArea.text", text)
  updateSkillUpgradeButton(activeSkills[skillName], #skillData.tierText, upgradeAvailable)
  status.setStatusProperty("ivrpgskills", activeSkills)
end

function removeSkill(name)
  local activeSkills = status.statusProperty("ivrpgskills", {})
  local skillData = self.textData["skill"].children[string.sub(name,6,9)].children[string.sub(name,10,-1)]
  local skillTier = activeSkills[name]
  if skillTier then
    local cost = skillCost(#skillData.tierText, skillTier, skillData.requires)
    status.setStatusProperty("ivrpgskillpoints", status.statusProperty("ivrpgskillpoints", 0) + cost)
  end
end

function upgradeSkill()
  local activeSkills = status.statusProperty("ivrpgskills", {})
  local skillName, skillData, skillTitle = returnSkillNameAndData()
  local skillTier = activeSkills[skillName]
  local cost = 0
  activeSkills[skillName] = skillTier + 1
  cost = skillData.requires[skillTier + 1].points
  status.setStatusProperty("ivrpgskillpoints", status.statusProperty("ivrpgskillpoints", 0) - cost)
  local text = tostring(skillData.children) .. "\n"
  local bonusText, upgradeAvailable = addSkillText(skillData.requires, activeSkills[skillName], skillData.tierText)
  text = text .. bonusText
  widget.setText("skillslayout.scrollArea.text", text)
  updateSkillUpgradeButton(activeSkills[skillName], #skillData.tierText, upgradeAvailable)
  status.setStatusProperty("ivrpgskills", activeSkills)
end

function resetSkills()
  status.setStatusProperty("ivrpgskills", {})
  status.setStatusProperty("ivrpgskillpoints", self.level)
end


function toggleFloatingXPBar()
  status.setStatusProperty("ivrpglevelbar", not status.statusProperty("ivrpglevelbar", false))
end