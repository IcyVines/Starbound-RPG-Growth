require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"
require "/scripts/poly.lua"
require "/scripts/drawingutil.lua"
-- engine callbacks
function init()
  --View:init()
  
  self.clickEvents = {}
  self.state = FSM:new()
  self.state:set(splashScreenState)
  self.system = celestial.currentSystem()
  self.pane = pane
  player.addCurrency("skillbookopen", 1)
  --initiating level and xp
  self.xp = player.currency("experienceorb")
  self.level = player.currency("currentlevel")--math.floor(math.sqrt(self.xp/100))
  --initiating stats
  updateStats()
  self.classTo = 0
  self.class = player.currency("classtype")
    --[[
    0: No Class
    1: Knight
    2: Wizard
    3: Ninja
    4: Soldier
    5: Rogue
    6: Explorer
    ]]
  self.affinityTo = 0
  self.affinity = player.currency("affinitytype")
  --[[
    0: No Affinity
    1: Flame
    2: Venom
    3: Frost
    4: Shock
    5: Infernal
    6: Toxic
    7: Cryo 
    8: Arc
    ]]
    --initiating possible Level Change (thus, level currency should not be used in another script!!!)
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
      if checked ~= 0 then unlockTechVisible(("techicon" .. tostring(checked)), 2^(checked+1)) end
    end
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
  end
end

--[[function takeInputEvents()
  local clicks = self.clickEvents
  self.clickEvents = {}
  return clicks
end
--]]

function updateLevel()
  self.xp = player.currency("experienceorb")
  if self.xp < 100 then
    player.addCurrency("experienceorb", 100)
  end
  self.level = player.currency("currentlevel")
  self.newLevel = math.floor(math.sqrt(self.xp/100))
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
  player.addCurrency("strengthpoint",1)
  player.addCurrency("dexteritypoint",1)
  player.addCurrency("intelligencepoint",1)
  player.addCurrency("agilitypoint",1)
  player.addCurrency("endurancepoint",1)
  player.addCurrency("vitalitypoint",1)
  player.addCurrency("vigorpoint",1)
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

--[[function updateLevel()
  self.xp = player.currency("experienceorb")
  if player.currency("currentlevel") == 0 then
    self.level = 1
    player.addCurrency("currentlevel",1)
    player.addCurrency("experienceorb",100 - player.currency("experienceorb"))
    self.xp = player.currency("experienceorb")
    startingStats()
  elseif player.currency("experienceorb") < 100 then
    player.addCurrency("experienceorb",100 - player.currency("experienceorb"))
    self.xp = player.currency("experienceorb")
  else
    self.newLevel = math.floor(math.sqrt(self.xp/100))
    while self.newLevel > self.level do
      player.addCurrency("currentlevel", 1)
      player.addCurrency("statpoint", math.floor(player.currency("currentlevel")/20)+1)
      self.level = self.level+1
    end
  end
  widget.setText("statslayout.statpointsleft",player.currency("statpoint"))
  updateStats()
  self.toNext = 2*self.level*100+100
  updateOverview(self.toNext)
  updateBottomBar(self.toNext)
end]]

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
  if player.currency("classtype") == 0 then
    widget.setText("overviewlayout.classtitle","No Class Yet")
    widget.setImage("overviewlayout.classicon","/objects/class/noclass.png")
  elseif player.currency("classtype") == 1 then
    widget.setText("overviewlayout.classtitle","Knight")
    widget.setImage("overviewlayout.classicon","/objects/class/knight.png")
  elseif player.currency("classtype") == 2 then
    widget.setText("overviewlayout.classtitle","Wizard")
    widget.setImage("overviewlayout.classicon","/objects/class/wizard.png")
  elseif player.currency("classtype") == 3 then
    widget.setText("overviewlayout.classtitle","Ninja")
    widget.setImage("overviewlayout.classicon","/objects/class/ninja.png")
  elseif player.currency("classtype") == 4 then
    widget.setText("overviewlayout.classtitle","Soldier")
    widget.setImage("overviewlayout.classicon","/objects/class/soldier.png")
  elseif player.currency("classtype") == 5 then
    widget.setText("overviewlayout.classtitle","Rogue")
    widget.setImage("overviewlayout.classicon","/objects/class/rogue.png")
  elseif player.currency("classtype") == 6 then
    widget.setText("overviewlayout.classtitle","Explorer")
    widget.setImage("overviewlayout.classicon","/objects/class/explorer.png")
  end
end

function updateClassTab()
  if player.currency("classtype") ~= 4 then
    --widget.setPosition("classlayout.weapontext",{154,240})
    --widget.setPosition("classlayout.weapontitle",{89,240})
  end
  if player.currency("classtype") == 0 then
    widget.setText("classlayout.classtitle","No Class Yet")
    widget.setImage("classlayout.classicon","/objects/class/noclass.png")
    widget.setImage("classlayout.effecticon","/objects/class/noclassicon.png")
    widget.setImage("classlayout.effecticon2","/objects/class/noclassicon.png")
  elseif player.currency("classtype") == 1 then
    widget.setText("classlayout.classtitle","Knight")
    widget.setFontColor("classlayout.classtitle","blue")
    widget.setImage("classlayout.classicon","/objects/class/knight.png")
    widget.setText("classlayout.weapontext","+20% Damage while using Shortsword and Shield in combination. +20% Damage with Broadswords.")
    widget.setText("classlayout.passivetext","+20% Knockback Resistance.")
    widget.setFontColor("classlayout.effecttext","blue")
    widget.setText("classlayout.effecttext","Perfect Blocks increase Damage by 20% for a short period.")
    widget.setImage("classlayout.effecticon","/scripts/knightblock/knightblock.png")
    widget.setImage("classlayout.effecticon2","/scripts/knightblock/knightblock.png")
    widget.setImage("classlayout.classweaponicon","/objects/class/knight.png")
    widget.setText("classlayout.statscalingtext","^green;Great:^reset;\nStrength\n^blue;Good:^reset;\nEndurance\nVitality")
  elseif player.currency("classtype") == 2 then
    widget.setText("classlayout.classtitle","Wizard")
    widget.setFontColor("classlayout.classtitle","magenta")
    widget.setImage("classlayout.classicon","/objects/class/wizard.png")
    widget.setFontColor("classlayout.effecttext","magenta")
    widget.setText("classlayout.weapontext","+10% Damage while using a Wand in either hand without any other weapon equipped. +10% Damage with Staves.")
    widget.setText("classlayout.passivetext","+6% Chance to Freeze, Burn, or Electry monsters on hit. These effects can stack.")
    widget.setText("classlayout.effecttext","While using Wands or Staves, gain +10% Fire, Poison, and Ice Resistance.")
    widget.setImage("classlayout.effecticon","/scripts/wizardaffinity/wizardaffinity.png")
    widget.setImage("classlayout.effecticon2","/scripts/wizardaffinity/wizardaffinity.png")
    widget.setImage("classlayout.classweaponicon","/objects/class/wizard.png")
    widget.setText("classlayout.statscalingtext","^green;Amazing:^reset;\nIntelligence\n^magenta;Good:^reset;\nVigor")
  elseif player.currency("classtype") == 3 then
    widget.setText("classlayout.classtitle","Ninja")
    widget.setImage("classlayout.classicon","/objects/class/ninja.png")
    widget.setFontColor("classlayout.classtitle","red")
    widget.setFontColor("classlayout.effecttext","red")
    widget.setText("classlayout.weapontext","+20% Damage while using Throwing Stars, Knives, Kunai, or Daggers, or any type of Shuriken without any weapons equipped.")
    widget.setText("classlayout.passivetext","+10% Speed and Jump Height. -10% Fall Damage.")
    widget.setText("classlayout.effecttext","+10% Bleed Chance and 0.4s Bleed Length during Nighttime or while Underground.")
    widget.setImage("classlayout.effecticon","/scripts/ninjacrit/ninjacrit.png")
    widget.setImage("classlayout.effecticon2","/scripts/ninjacrit/ninjacrit.png")
    widget.setImage("classlayout.classweaponicon","/objects/class/ninja.png")
    widget.setText("classlayout.statscalingtext","^green;Amazing:^reset;\nDexterity\n^magenta;Good:^reset;\nAgility")
  elseif player.currency("classtype") == 4 then
    widget.setText("classlayout.classtitle","Soldier")
    widget.setFontColor("classlayout.classtitle","orange")
    widget.setFontColor("classlayout.effecttext","orange")
    widget.setImage("classlayout.classicon","/objects/class/soldier.png")
    widget.setText("classlayout.weapontext","+10% Damage while using One-Handed Guns and Bombs, Molotovs, or Thorn Grenades in combination. +10% Damage with Sniper Rifles, Assault Rifles, and Shotguns.")
    widget.setText("classlayout.passivetext","+10% Chance to Stun monsters on hit. Stun Length depends on damage dealt.")
    widget.setText("classlayout.effecttext","While Energy is full, your Food Meter decreases 10% slower.")
    widget.setImage("classlayout.effecticon","/scripts/soldierdiscipline/soldierdiscipline.png")
    widget.setImage("classlayout.effecticon2","/scripts/soldierdiscipline/soldierdiscipline.png")
    --widget.setPosition("classlayout.weapontext",{154,251})
    --widget.setPosition("classlayout.weapontitle",{89,251})
    widget.setImage("classlayout.classweaponicon","/objects/class/soldier.png")
    widget.setText("classlayout.statscalingtext","^blue;Great:^reset;\nVitality\n^magenta;Good:^reset;\nDexterity\n^gray;OK:^reset;\nStrength\nEndurance")
  elseif player.currency("classtype") == 5 then
    widget.setText("classlayout.classtitle","Rogue")
    widget.setFontColor("classlayout.classtitle","green")
    widget.setFontColor("classlayout.effecttext","green")
    widget.setImage("classlayout.classicon","/objects/class/rogue.png")
    widget.setText("classlayout.weapontext","+20% Damage while dual-wielding One-Handed Weapons.")
    widget.setText("classlayout.passivetext","+20% Chance to Poison monsters on hit.")
    widget.setText("classlayout.effecttext","While your Food Meter is filled at least halfway, gain +20% Poison Resistance.")
    widget.setImage("classlayout.effecticon","/scripts/roguepoison/roguepoison.png")
    widget.setImage("classlayout.effecticon2","/scripts/roguepoison/roguepoison.png")
    widget.setImage("classlayout.classweaponicon","/objects/class/rogue.png")
    widget.setText("classlayout.statscalingtext","^blue;Great:^reset;\nDexterity\n^magenta;Good:^reset;\nStrength\nAgility")
  elseif player.currency("classtype") == 6 then
    widget.setText("classlayout.classtitle","Explorer")
    widget.setImage("classlayout.classicon","/objects/class/explorer.png")
    widget.setFontColor("classlayout.classtitle","yellow")
    widget.setFontColor("classlayout.effecttext","yellow")
    widget.setText("classlayout.weapontext","+10% Resistance to all Damage Types while using Grappling Hooks, Rope, Mining Tools, Throwable Light Sources, or Flashlights.")
    widget.setText("classlayout.passivetext","+10% Physical Resistance.")
    widget.setText("classlayout.effecttext","While Health is greater than half, provide a bright yellow Glow.")
    widget.setImage("classlayout.effecticon","/scripts/explorerglow/explorerglow.png")
    widget.setImage("classlayout.effecticon2","/scripts/explorerglow/explorerglow.png")
    widget.setImage("classlayout.classweaponicon","/objects/class/explorer.png")
    widget.setText("classlayout.statscalingtext","^blue;Great:^reset;\nVigor\n^magenta;Good:^reset;\nAgility\n^gray;OK:^reset;\nVitality\nEndurance")
  end
  updateTechImages()
end


function removeLayouts()
  widget.setVisible("overviewlayout",false)
  widget.setVisible("statslayout",false)
  widget.setVisible("classeslayout",false)
  widget.setVisible("classlayout",false)
  widget.setVisible("affinitieslayout",false)
  widget.setVisible("infolayout",false)
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
      widget.setVisible("affinitieslayout", true)
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

function updateInfo()
  self.classType = player.currency("classtype")
  self.strengthBonus = self.classType == 1 and 1.15 or (self.classType == 5 and 1.1 or (self.classType == 4 and 1.05 or 1))
  self.agilityBonus = self.classType == 3 and 1.1 or (self.classType == 5 and 1.1 or (self.classType == 6 and 1.1 or 1))
  self.vitalityBonus = self.classType == 4 and 1.15 or (self.classType == 1 and 1.1 or (self.classType == 6 and 1.05 or 1))
  self.vigorBonus = self.classType == 6 and 1.15 or (self.classType == 2 and 1.1 or 1)
  self.intelligenceBonus = self.classType == 2 and 1.2 or 1
  self.enduranceBonus = self.classType == 1 and 1.1 or (self.classType == 4 and 1.05 or (self.classType == 6 and 1.05 or 1))
  self.dexterityBonus = self.classType == 3 and 1.2 or (self.classType == 5 and 1.15 or (self.classType == 4 and 1.1 or 1))

  widget.setText("infolayout.displaystats", 
    "Amount\n" ..
    "^red;" .. math.floor(100*(1 + self.vitality^self.vitalityBonus*.05))/100 .. "^reset;" .. "\n" ..
    "^green;" .. math.floor(100*(1 + self.vigor^self.vigorBonus*.05))/100 .. "\n" ..
    math.floor(status.stat("energyRegenPercentageRate")*100+.5)/100 .. "^reset;" .. "\n" ..
    math.floor(status.stat("energyRegenBlockTime")*100+.5)/100 .. "^reset;" .. "\n" ..
    "^orange;" .. getStatPercent(status.stat("foodDelta")) .. "^reset;" ..
    "^gray;" .. getStatPercent(status.stat("physicalResistance")) .. "^reset;" ..
    "^magenta;" .. getStatPercent(status.stat("poisonResistance")) .. "^reset;" ..
    "^blue;" .. getStatPercent(status.stat("iceResistance")) .. "^reset;" .. 
    "^red;" .. getStatPercent(status.stat("fireResistance")) .."^reset;" .. 
    "^yellow;" .. getStatPercent(status.stat("electricResistance")) .. "^reset;" ..
    "^gray;" .. getStatPercent(status.stat("grit")) ..
    math.floor(status.stat("fallDamageMultiplier")*100+.5)/100 .. "\n" ..    
    math.floor((1 + self.strength^self.strengthBonus*.05)*100+.5)/100 .. "^reset;" .. "\n" ..
    "^red;" .. (math.floor(self.dexterity^self.dexterityBonus*100+.5)/100 + status.stat("ninjaBleed")) .. "%\n" ..
    (math.floor(self.dexterity^self.dexterityBonus*100+.5)/100 + status.stat("ninjaBleed"))/50 .. "^reset;" .. "\n")
end

function unlockTech()
  local classType = player.currency("classtype")
  local checked = widget.getChecked("classlayout.techicon1") and 1 or (widget.getChecked("classlayout.techicon2") and 2 or (widget.getChecked("classlayout.techicon3") and 3 or 4))
  local tech = getTechEnableName(classType, checked)
  player.makeTechAvailable(tech)
  player.enableTech(tech)
  unlockTechVisible(("techicon" .. tostring(checked)), 2^(checked+1))
end

function getTechEnableName(classType, checked)
  if classType == 1 then
    return checked == 1 and "knightbash" or (checked == 2 and "knightslam" or (checked == 3 and "knightarmorsphere" or "knightcharge!"))
  elseif classType == 2 then
    return checked == 1 and "wizardgravitysphere" or (checked == 2 and "wizardhover" or (checked == 3 and "wizardtranslocate" or "wizardmagicshield"))
  elseif classType == 3 then
    return checked == 1 and "ninjaflashjump" or (checked == 2 and "ninjavanishsphere" or (checked == 3 and "ninjaassassinate" or "ninjawallcling"))
  elseif classType == 4 then
    return checked == 1 and "soldiermre" or (checked == 2 and "soldiermarksman" or (checked == 3 and "soldierenergypack" or "soldiermissilestrike"))
  elseif classType == 5 then
    return checked == 1 and "roguepoisondash" or (checked == 2 and "roguetoxiccapsule" or (checked == 3 and "roguecloudjump" or "roguetoxicaura"))
  elseif classType == 6 then
    return checked == 1 and "explorerglide" or (checked == 2 and "explorerenhancedmovement" or (checked == 3 and "explorerdrill" or "explorerenhancedjump"))
  end
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
    local classType = player.currency("classtype")
    local techName = getTechEnableName(classType, tonumber(string.sub(tech,9,9)))
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
  if name == "techicon1" then
    widget.setText("classlayout.techtext", getTechText(1))
    widget.setText("classlayout.techname", getTechName(1))
    widget.setText("classlayout.techtype", getTechType(1) .. " Tech")
    unlockTechVisible(name, 4)
  elseif name == "techicon2" then
    widget.setText("classlayout.techtext",  getTechText(2))
    widget.setText("classlayout.techname", getTechName(2))
    widget.setText("classlayout.techtype", getTechType(2) .. " Tech")
    unlockTechVisible(name, 8)
  elseif name == "techicon3" then
    widget.setText("classlayout.techtext",  getTechText(3))
    widget.setText("classlayout.techname", getTechName(3))
    widget.setText("classlayout.techtype", getTechType(3) .. " Tech")
    unlockTechVisible(name, 16)
  elseif name == "techicon4" then
    widget.setText("classlayout.techtext",  getTechText(4))
    widget.setText("classlayout.techname", getTechName(4))
    widget.setText("classlayout.techtype", getTechType(4) .. " Tech")
    unlockTechVisible(name, 32)
  end
end

function getTechText(num)
  local classType = player.currency("classtype")
  if classType == 1 then
    return num == 1 and "An upgrade to Sprint, while running, enemies receive damage and knockback. Damage is doubled when holding up a shield. Damage scales with Strength and Run Speed."
    or (num == 2 and "An upgrade to Double Jump, press [G] while midair to slam downwards. You take no fall damage upon landing, and cause a small explosion, damaging enemies. Damage scales with Strength and distance fallen from activation."
      or (num == 3 and "An upgrade to Spike Sphere, while transformed, ignore knockback and deal contact damage to enemies." 
        or "An upgrade to Bash. While sprinting, the player receives physical resistance. While damage remains the same, enemies are stunned on hit. Damage scales with Strength and Run Speed."))
  elseif classType == 2 then
    return num == 1 and "An upgrade to Spike Sphere, while transformed you regen slightly and are affected by low gravity. In addition, toggle a barrier that pushes enemies away by pressing [G]." 
    or (num == 2 and "Press [Space] while in air to hover towards your cursor. The further your cursor, the faster you move. Your Energy drains while you hover." 
      or (num == 3 and "Press [W] to teleport to your cursor. There is a slight cooldown before you can teleport again." 
        or "Press [F] to negate all damage for a short time. Energy does not recharge while this effect is active. You can prematurely end the effect by pressing [F] again. The cooldown shortens if so."))
  elseif classType == 3 then
    return num == 1 and "Press [Space] while midair to burst forward. For a short time after jumping, you are invulnerable to damage. As long as you remain in the air with energy remaining, you are invulnerable to fall damage. You may do this twice while midair." 
    or (num == 2 and "Press [F] to morph into an invulnerable spike ball. Energy drains quickly while moving. The transformation ends if you run out of energy or press [F] while transformed." 
    or (num == 3 and "Press [W] to vanish out of existence. After 2 seconds, you appear where your cursor points. If holding a sharp weapon, slash where you appear. Slash damage scales with Power Modifier and Weapon DPS. This costs 20 Health." 
    or "An upgrade to Flash Jump. Cling to walls by moving against them during a jump, and refresh your jumps upon doing so. Press [S] to slide down while clinging. Press [Space] while clinging or sliding to jump. Move away from the wall to get off."))
  elseif classType == 4 then
    return num == 1 and "Press [F] to eat an MRE (Meal Ready to Eat), gaining a bit of food. There is a cooldown of 90 seconds before you can do this again." 
    or (num == 2 and "Press [G] to gain improved weapon damage with ranged weapons and decreased energy regen block time: however, speed and resistance are decreased. You can prematurely end the effect by pressing [G] again. The cooldown shortens if so." 
      or (num == 3 and "An upgrade to Double Jump, press [W] to instantly refill energy and gain a slight jump boost for a short period. You can prematurely end this effect, but cooldown is not shortened if so." 
        or "Press [F] to call down a missile strike from your cursor's location. Upon exploding, the missile releases a carpet of fire that sticks to the ground. Try not to kill yourself..."))
  elseif classType == 5 then
    return num == 1 and "An upgrade to Air Dash, distance is improved. In addition, a trail of toxic clouds is left behind. The damage from the toxic clouds scale with your Poison Resistance and Power Multiplier. Deals massive damage if immune to Poison." 
    or (num == 2 and "Press [F] to gain +33% Physical Resistance and Poison Immunity but lose health for a short period. You can prematurely end the effect by pressing [F] again. If so, you emit a ring of toxic clouds whose damage scales with Power Multiplier and Time Passed." 
      or (num == 3 and "An upgrade to Double Jump, press [W] to create a cloudy platform beneath you. The cloud disappears after 5 seconds." 
        or "Press [G] to deal toxic damage with all weapons for a short time. Toxic damage deals more damage than poison damage. You can prematurely end the effect by pressing [G] again. The cooldown shortens if so."))
  elseif classType == 6 then
    return num == 1 and "An upgrade to Double Jump, hold [W] to glide forward, slowly losing altitude. You can use your double jump while gliding." 
    or (num == 2 and "Press [G] to switch between Enhanced Airdash and Enhanced Sprint. Enhanced Airdash travels further than Air Dash, and has a shorter cooldown. Enhanced Sprint is faster and costs less energy than Sprint." 
      or (num == 3 and "Hold [F] to drill downwards at incredible speed, draining your energy." 
        or "An upgrade to Glide. Gain another three midair jumps and a wall jump. Midair jumps are 85% as effective. You cling to walls slightly longer than the normal Wall Jump and slide down slower as well. "))
  end
end

function getTechName(num)
  local classType = player.currency("classtype")
  if classType == 1 then
    widget.setFontColor("classlayout.techname", "blue")
    return num == 1 and "Bash" or (num == 2 and "Slam" or (num == 3 and "Armor Sphere" or "Charge!"))
  elseif classType == 2 then
    widget.setFontColor("classlayout.techname", "magenta")
    return num == 1 and "Gravity Sphere" or (num == 2 and "Hover" or (num == 3 and "Translocate" or "Magic Shield"))
  elseif classType == 3 then
    widget.setFontColor("classlayout.techname", "red")
    return num == 1 and "Flash Jump" or (num == 2 and "Vanish Sphere" or (num == 3 and "Assassinate" or "Wall Cling"))
  elseif classType == 4 then
    widget.setFontColor("classlayout.techname", "orange")
    return num == 1 and "MRE" or (num == 2 and "Marksman" or (num == 3 and "Energy Pack" or "Missile Strike"))
  elseif classType == 5 then
    widget.setFontColor("classlayout.techname", "green")
    return num == 1 and "Poison Dash" or (num == 2 and "Toxic Capsule" or (num == 3 and "Cloud Jump" or "Toxic Aura"))
  elseif classType == 6 then
    widget.setFontColor("classlayout.techname", "yellow")
    return num == 1 and "Glide" or (num == 2 and "Enhanced Dash" or (num == 3 and "Drill" or "Enhanced Glide"))
  end
end

function getTechType(num)
  local classType = player.currency("classtype")
  if classType == 1 then
    return num == 1 and "Body" or (num == 2 and "Leg" or (num == 3 and "Head" or "Body"))
  elseif classType == 2 then
    return num == 1 and "Head" or (num == 2 and "Leg" or (num == 3 and "Body" or "Head"))
  elseif classType == 3 then
    return num == 1 and "Leg" or (num == 2 and "Head" or (num == 3 and "Body" or "Leg"))
  elseif classType == 4 then
    return num == 1 and "Head" or (num == 2 and "Body" or (num == 3 and "Leg" or "Head"))
  elseif classType == 5 then
    return num == 1 and "Body" or (num == 2 and "Head" or (num == 3 and "Leg" or "Body"))
  elseif classType == 6 then
    return num == 1 and "Leg" or (num == 2 and "Body" or (num == 3 and "Head" or "Leg"))
  end
end

function uncheckTechButtons(name)
  widget.setVisible("classlayout.reqlvl", false)
  widget.setVisible("classlayout.unlockbutton", false)
  widget.setVisible("classlayout.unlockedtext", false)
  if name ~= "techicon1" then widget.setChecked("classlayout.techicon1", false) end
  if name ~= "techicon2" then widget.setChecked("classlayout.techicon2", false) end
  if name ~= "techicon3" then widget.setChecked("classlayout.techicon3", false) end
  if name ~= "techicon4" then widget.setChecked("classlayout.techicon4", false) end
end

function updateTechImages()
  local classType = player.currency("classtype")
  local className = ""
  if classType == 1 then
    className = "knight"
  elseif classType == 2 then
    className = "wizard"
  elseif classType == 3 then
    className = "ninja"
  elseif classType == 4 then
    className = "soldier"
  elseif classType == 5 then
    className = "rogue"
  elseif classType == 6 then
    className = "explorer"
  end
  widget.setButtonImages("classlayout.techicon1", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "1.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "1hover.png",
    pressed = "/interface/RPGskillbook/techbuttons/" .. className .. "1pressed.png",
    disabled = "/interface/RPGskillbook/techbuttons/techbuttonbackground.png"
  })
  widget.setButtonCheckedImages("classlayout.techicon1", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "1pressed.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "1hover.png"
  })
  widget.setButtonImages("classlayout.techicon2", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "2.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "2hover.png",
    pressed = "/interface/RPGskillbook/techbuttons/" .. className .. "2pressed.png",
    disabled = "/interface/RPGskillbook/techbuttons/techbuttonbackground.png"
  })
  widget.setButtonCheckedImages("classlayout.techicon2", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "2pressed.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "2hover.png"
  })
  widget.setButtonImages("classlayout.techicon3", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "3.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "3hover.png",
    pressed = "/interface/RPGskillbook/techbuttons/" .. className .. "3pressed.png",
    disabled = "/interface/RPGskillbook/techbuttons/techbuttonbackground.png"
  })
  widget.setButtonCheckedImages("classlayout.techicon3", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "3pressed.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "3hover.png"
  })
  widget.setButtonImages("classlayout.techicon4", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "4.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "4hover.png",
    pressed = "/interface/RPGskillbook/techbuttons/" .. className .. "4pressed.png",
    disabled = "/interface/RPGskillbook/techbuttons/techbuttonbackground.png"
  })
  widget.setButtonCheckedImages("classlayout.techicon4", {
    base = "/interface/RPGskillbook/techbuttons/" .. className .. "4pressed.png",
    hover = "/interface/RPGskillbook/techbuttons/" .. className .. "4hover.png"
  })
end

function getStatPercent(stat)
  stat = math.floor(stat*10000+.50)/100
  return stat >= 100 and "Immune!\n" or (stat < 0 and stat .. "%\n" or (stat == 0 and "0%\n" or "+" .. stat .. "%\n"))
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

--[[function startingStats()
  player.addCurrency("strengthpoint",1)
  player.addCurrency("dexteritypoint",1)
  player.addCurrency("intelligencepoint",1)
  player.addCurrency("agilitypoint",1)
  player.addCurrency("endurancepoint",1)
  player.addCurrency("vitalitypoint",1)
  player.addCurrency("vigorpoint",1)
end]]

function updateStats()
  self.strength = player.currency("strengthpoint")
  widget.setText("statslayout.strengthamount",self.strength)
  self.agility = player.currency("agilitypoint")
  widget.setText("statslayout.agilityamount",self.agility)
  self.vitality = player.currency("vitalitypoint")
  widget.setText("statslayout.vitalityamount",self.vitality)
  self.vigor = player.currency("vigorpoint")
  widget.setText("statslayout.vigoramount",self.vigor)
  self.intelligence = player.currency("intelligencepoint")
  widget.setText("statslayout.intelligenceamount",self.intelligence)
  self.endurance = player.currency("endurancepoint")
  widget.setText("statslayout.enduranceamount",self.endurance)
  self.dexterity = player.currency("dexteritypoint")
  widget.setText("statslayout.dexterityamount",self.dexterity)
  widget.setText("statslayout.statpointsleft",player.currency("statpoint"))
  widget.setText("statslayout.totalstatsamount", addStats())
  checkStatPoints()
end

function addStats()
  return self.strength+self.agility+self.vitality+self.vigor+self.intelligence+self.endurance+self.dexterity
end

function uncheckStatIcons(name)
  if name ~= "strength" then widget.setChecked("statslayout.strengthicon", false) end
  if name ~= "agility" then widget.setChecked("statslayout.agilityicon", false) end
  if name ~= "vitality" then widget.setChecked("statslayout.vitalityicon", false) end
  if name ~= "vigor" then widget.setChecked("statslayout.vigoricon", false) end
  if name ~= "intelligence" then widget.setChecked("statslayout.intelligenceicon", false) end
  if name ~= "endurance" then widget.setChecked("statslayout.enduranceicon", false) end
  if name ~= "dexterity" then widget.setChecked("statslayout.dexterityicon", false) end
end

function uncheckClassIcons(name)
  if name ~= "knight" then
    widget.setChecked("classeslayout.knighticon", false)
    widget.setFontColor("classeslayout.knighttitle", "white")
  end
  if name ~= "wizard" then
    widget.setChecked("classeslayout.wizardicon", false)
    widget.setFontColor("classeslayout.wizardtitle", "white")
  end
  if name ~= "ninja" then
    widget.setChecked("classeslayout.ninjaicon", false)
    widget.setFontColor("classeslayout.ninjatitle", "white")
  end
  if name ~= "soldier" then
    widget.setChecked("classeslayout.soldiericon", false)
    widget.setFontColor("classeslayout.soldiertitle", "white")
  end
  if name ~= "rogue" then
    widget.setChecked("classeslayout.rogueicon", false)
    widget.setFontColor("classeslayout.roguetitle", "white")
  end
  if name ~= "explorer" then
    widget.setChecked("classeslayout.explorericon", false)
    widget.setFontColor("classeslayout.explorertitle", "white")
  end
end

function changeStatDescription(name)
  if name == "strength" then widget.setText("statslayout.statdescription", "Greatly Increases Shield Health.\nSignificantly Increases Two-Handed Melee Damage.\nMinimally Increases Physical Resistance.") end
  if name == "agility" then widget.setText("statslayout.statdescription", "Significantly Increases Speed.\nIncreases Jump Height.\nDecreases Fall Damage.") end
  if name == "vitality" then widget.setText("statslayout.statdescription", "Significantly Increases Max Health.\nDecreases Hunger Rate.") end
  if name == "vigor" then widget.setText("statslayout.statdescription", "Significantly Increases Max Energy.\nGreatly Increases Energy Recharge Rate.") end
  if name == "intelligence" then widget.setText("statslayout.statdescription", "Greatly Increases Energy Recharge Rate.\nGreatly Increases Staff Damage.\nDecreases Energy Recharge Delay.\nSlightly Increases Wand Damage.") end
  if name == "endurance" then widget.setText("statslayout.statdescription", "Increases Knockback Resistance.\nIncreases Physical Resistance.\nModerately Increases All Other Resistances.") end
  if name == "dexterity" then widget.setText("statslayout.statdescription", "Increases Gun and Bow Damage.\nIncreases Bleed Chance and Bleed Length.\nSlightly Increases One-Handed Weapon Damage.\nSlightly Decreases Fall Damage.") end
  if name == "default" then widget.setText("statslayout.statdescription", "Click a stat's icon to see what occurs\nwhen that stat is raised.") end
end

function changeClassDescription(name)
  if name == "knight" then
    widget.setText("classeslayout.classdescription", "The Knight is a melee tank with a focus on swords and shields. Great for players who want to survive many hits and deal moderate damage.") 
    widget.setFontColor("classeslayout.knighttitle", "blue")
    self.classTo = 1
  end
  if name == "wizard" then
    widget.setText("classeslayout.classdescription", "The Wizard is a ranged dps character with a focus on wands and staffs. Great for players who want to maximize damage and ability use.") 
    widget.setFontColor("classeslayout.wizardtitle", "magenta")
    self.classTo = 2
  end
  if name == "ninja" then
    widget.setText("classeslayout.classdescription", "The Ninja is a evasive dps character with a focus on thrown weapons. Great for players who enjoy fast, technical play and doing massive damage at the cost of materials.") 
    widget.setFontColor("classeslayout.ninjatitle", "red")
    self.classTo = 3
  end
  if name == "soldier" then
    widget.setText("classeslayout.classdescription", "The Soldier is a ranged tank with a focus on guns. Great for players who want to maximize distance and stay alive.") 
    widget.setFontColor("classeslayout.soldiertitle", "orange")
    self.classTo = 4
  end
  if name == "rogue" then
    widget.setText("classeslayout.classdescription", "The Rogue is a melee dps character with a focus on one-handed weapons. Great for players who enjoy afflicting status and getting up close.") 
    widget.setFontColor("classeslayout.roguetitle", "green")
    self.classTo = 5
  end
  if name == "explorer" then
    widget.setText("classeslayout.classdescription", "The Explorer is a evasive tank character with a focus on grappling hooks and lighting up the way. Great for players who prefer to run away from encounters and explore.") 
    widget.setFontColor("classeslayout.explorertitle", "yellow")
    self.classTo = 6
  end
  if name == "default" then
    widget.setText("classeslayout.classdescription", "Click a Class' icon to see how that Class plays.")
    uncheckClassIcons("default")
    self.classTo = 0
  end
end

function enableStatButtons(enable)
  if player.currency("classtype") == 0 then
    enable = false
    widget.setVisible("statslayout.statprevention",true)
  else
    widget.setVisible("statslayout.statprevention",false)
  end
  widget.setButtonEnabled("statslayout.raisestrength", self.strength ~= 50 and enable)
  widget.setButtonEnabled("statslayout.raisedexterity", self.dexterity ~= 50 and enable)
  widget.setButtonEnabled("statslayout.raiseendurance", self.endurance ~= 50 and enable)
  widget.setButtonEnabled("statslayout.raiseintelligence", self.intelligence ~= 50 and enable)
  widget.setButtonEnabled("statslayout.raisevigor", self.vigor ~= 50 and enable)
  widget.setButtonEnabled("statslayout.raisevitality", self.vitality ~= 50 and enable)
  widget.setButtonEnabled("statslayout.raiseagility", self.agility ~= 50 and enable)
end

function chooseClass()
  player.addCurrency("classtype", self.classTo)
  self.class = self.classTo
  addClassStats()
  changeToClasses()
end

function addClassStats()
  if player.currency("classtype") == 1 then
      --Knight
    player.addCurrency("strengthpoint", 5)
    player.addCurrency("endurancepoint", 4)
    player.addCurrency("vitalitypoint", 3)
    player.addCurrency("vigorpoint", 1)
  elseif player.currency("classtype") == 2 then
    --Wizard
    player.addCurrency("intelligencepoint", 7)
    player.addCurrency("vigorpoint", 6)
  elseif player.currency("classtype") == 3 then
    --Ninja
    player.addCurrency("agilitypoint", 5)
    player.addCurrency("dexteritypoint", 6)
    player.addCurrency("intelligencepoint", 2)
  elseif player.currency("classtype") == 4 then
    --Soldier
    player.addCurrency("vitalitypoint", 5)
    player.addCurrency("endurancepoint", 2)
    player.addCurrency("dexteritypoint", 4)
    player.addCurrency("strengthpoint", 2)
  elseif player.currency("classtype") == 5 then
    --Rogue
    player.addCurrency("agilitypoint", 3)
    player.addCurrency("endurancepoint", 2)
    player.addCurrency("dexteritypoint", 3)
    player.addCurrency("strengthpoint", 3)
    player.addCurrency("vigorpoint", 2)
  elseif player.currency("classtype") == 6 then
    --Explorer
    player.addCurrency("agilitypoint", 4)
    player.addCurrency("endurancepoint", 2)
    player.addCurrency("vitalitypoint", 3)
    player.addCurrency("vigorpoint", 4)
  end
  updateStats()
  uncheckClassIcons("default")
  changeClassDescription("default")
end

function consumeClassStats()
  if player.currency("classtype") == 1 then
      --Knight
    player.consumeCurrency("strengthpoint", 5)
    player.consumeCurrency("endurancepoint", 4)
    player.consumeCurrency("vitalitypoint", 3)
    player.consumeCurrency("vigorpoint", 1)
  elseif player.currency("classtype") == 2 then
    --Wizard
    player.consumeCurrency("intelligencepoint", 7)
    player.consumeCurrency("vigorpoint", 6)
  elseif player.currency("classtype") == 3 then
    --Ninja
    player.consumeCurrency("agilitypoint", 5)
    player.consumeCurrency("dexteritypoint", 6)
    player.consumeCurrency("intelligencepoint", 2)
  elseif player.currency("classtype") == 4 then
    --Soldier
    player.consumeCurrency("vitalitypoint", 5)
    player.consumeCurrency("endurancepoint", 2)
    player.consumeCurrency("dexteritypoint", 4)
    player.consumeCurrency("strengthpoint", 2)
  elseif player.currency("classtype") == 5 then
    --Rogue
    player.consumeCurrency("agilitypoint", 3)
    player.consumeCurrency("endurancepoint", 2)
    player.consumeCurrency("dexteritypoint", 3)
    player.consumeCurrency("strengthpoint", 3)
    player.consumeCurrency("vigorpoint", 2)
  elseif player.currency("classtype") == 6 then
    --Explorer
    player.consumeCurrency("agilitypoint", 4)
    player.consumeCurrency("endurancepoint", 2)
    player.consumeCurrency("vitalitypoint", 3)
    player.consumeCurrency("vigorpoint", 4)
  end
  updateStats()
end

function areYouSure(name)
  name = string.gsub(name,"resetbutton","")
  name2 = ""
  if name == "" then name2 = "overviewlayout"
  elseif name == "cl" then name2 = "classlayout" end
  --sb.logInfo(name.."test"..name2)
  widget.setVisible(name2..".resetbutton"..name, false)
  widget.setVisible(name2..".yesbutton", true)
  widget.setVisible(name2..".nobutton"..name, true)
  widget.setVisible(name2..".areyousure", true)  
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
end

function resetClass()
  notSure("nobuttoncl")
  consumeClassStats()
  player.consumeCurrency("classtype",player.currency("classtype"))
  changeToClasses()
end

function resetSkillBook()
  notSure("nobutton")
  player.consumeCurrency("experienceorb", self.xp)
  player.consumeCurrency("currentlevel", self.level)
  player.consumeCurrency("statpoint", player.currency("statpoint"))
  player.consumeCurrency("strengthpoint",player.currency("strengthpoint"))
  player.consumeCurrency("agilitypoint",player.currency("agilitypoint"))
  player.consumeCurrency("vitalitypoint",player.currency("vitalitypoint"))
  player.consumeCurrency("vigorpoint",player.currency("vigorpoint"))
  player.consumeCurrency("intelligencepoint",player.currency("intelligencepoint"))
  player.consumeCurrency("endurancepoint",player.currency("endurancepoint"))
  player.consumeCurrency("dexteritypoint",player.currency("dexteritypoint"))
  player.consumeCurrency("classtype",player.currency("classtype"))
  player.consumeCurrency("affinitytype",player.currency("affinitytype"))
  removeTechs()
  updateStats()
end

function removeTechs()
  player.makeTechUnavailable("ninjaassassinate")
  player.makeTechUnavailable("ninjaflashjump")
  player.makeTechUnavailable("ninjawallcling")
  player.makeTechUnavailable("ninjavanishsphere")
  player.makeTechUnavailable("wizardmagicshield")
  player.makeTechUnavailable("wizardgravitysphere")
  player.makeTechUnavailable("wizardtranslocate")
  player.makeTechUnavailable("wizardhover")
  player.makeTechUnavailable("knightslam")
  player.makeTechUnavailable("knightbash")
  player.makeTechUnavailable("knightcharge")
  player.makeTechUnavailable("knightarmorsphere")
  player.makeTechUnavailable("roguetoxicaura")
  player.makeTechUnavailable("roguecloudjump")
  player.makeTechUnavailable("roguetoxiccapsule")
  player.makeTechUnavailable("roguepoisondash")
  player.makeTechUnavailable("soldiermissilestrike")
  player.makeTechUnavailable("soldierenergypack")
  player.makeTechUnavailable("soldiermarksman")
  player.makeTechUnavailable("soldiermre")
  player.makeTechUnavailable("explorerenhancedjump")
  player.makeTechUnavailable("explorerenhancedmovement")
  player.makeTechUnavailable("explorerdrill")
  player.makeTechUnavailable("explorerglide")
end

function chooseAffinity()
  player.addCurrency("affinitytype", self.affinityTo)
  self.affinity = self.affinityTo
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
  if name ~= "fire" then
    widget.setChecked("affinitieslayout.fireicon", false)
    widget.setFontColor("affinitieslayout.firetitle", "white")
  end
  if name ~= "ice" then
    widget.setChecked("affinitieslayout.iceicon", false)
    widget.setFontColor("affinitieslayout.icetitle", "white")
  end
  if name ~= "electric" then
    widget.setChecked("affinitieslayout.electricicon", false)
    widget.setFontColor("affinitieslayout.electrictitle", "white")
  end
  if name ~= "poison" then
    widget.setChecked("affinitieslayout.poisonicon", false)
    widget.setFontColor("affinitieslayout.poisontitle", "white")
  end
end

function changeAffinityDescription(name)
  if name == "fire" then
    widget.setText("affinitieslayout.affinitydescription", "Bend fire to your will.") 
    widget.setFontColor("affinitieslayout.firetitle", "red")
    self.affinityTo = 1
  end
  if name == "ice" then
    widget.setText("affinitieslayout.affinitydescription", "Bend ice to your will.") 
    widget.setFontColor("affinitieslayout.icetitle", "blue")
    self.affinityTo = 2
  end
  if name == "electric" then
    widget.setText("affinitieslayout.affinitydescription", "Bend lightning to your will.") 
    widget.setFontColor("affinitieslayout.electrictitle", "yellow")
    self.affinityTo = 3
  end
  if name == "poison" then
    widget.setText("affinitieslayout.affinitydescription", "Bend poison to your will.") 
    widget.setFontColor("affinitieslayout.poisontitle", "green")
    self.affinityTo = 4
  end
  if name == "default" then
    widget.setText("affinitieslayout.affinitydescription", "Click an Affinity's icon to see what that Affinity does.")
    uncheckAffinityIcons("default")
    self.affinityTo = 0
  end
end

function updateAffinityTab()
end

function addAffinityStats()
  --[[if player.currency("classtype") == 1 then
      --Flame
    player.addCurrency("strengthpoint", 5)
    player.addCurrency("endurancepoint", 4)
    player.addCurrency("vitalitypoint", 3)
    player.addCurrency("vigorpoint", 1)
  elseif player.currency("classtype") == 2 then
    --Venom
    player.addCurrency("intelligencepoint", 7)
    player.addCurrency("vigorpoint", 6)
  elseif player.currency("classtype") == 3 then
    --Frost
    player.addCurrency("agilitypoint", 5)
    player.addCurrency("dexteritypoint", 6)
    player.addCurrency("intelligencepoint", 2)
  elseif player.currency("classtype") == 4 then
    --Shock
    player.addCurrency("vitalitypoint", 5)
    player.addCurrency("endurancepoint", 2)
    player.addCurrency("dexteritypoint", 4)
    player.addCurrency("strengthpoint", 2)
  elseif player.currency("classtype") == 5 then
    --Infernal
    player.addCurrency("agilitypoint", 3)
    player.addCurrency("endurancepoint", 2)
    player.addCurrency("dexteritypoint", 3)
    player.addCurrency("strengthpoint", 3)
    player.addCurrency("vigorpoint", 2)
  elseif player.currency("classtype") == 6 then
    --Toxic
    player.addCurrency("agilitypoint", 4)
    player.addCurrency("endurancepoint", 2)
    player.addCurrency("vitalitypoint", 3)
    player.addCurrency("vigorpoint", 4)
  end
  updateStats()
  uncheckClassIcons("default")
  changeClassDescription("default")]]
end

function consumeAffinityStats()
  --[[if player.currency("classtype") == 1 then
      --Knight
    player.consumeCurrency("strengthpoint", 5)
    player.consumeCurrency("endurancepoint", 4)
    player.consumeCurrency("vitalitypoint", 3)
    player.consumeCurrency("vigorpoint", 1)
  elseif player.currency("classtype") == 2 then
    --Wizard
    player.consumeCurrency("intelligencepoint", 7)
    player.consumeCurrency("vigorpoint", 6)
  elseif player.currency("classtype") == 3 then
    --Ninja
    player.consumeCurrency("agilitypoint", 5)
    player.consumeCurrency("dexteritypoint", 6)
    player.consumeCurrency("intelligencepoint", 2)
  elseif player.currency("classtype") == 4 then
    --Soldier
    player.consumeCurrency("vitalitypoint", 5)
    player.consumeCurrency("endurancepoint", 2)
    player.consumeCurrency("dexteritypoint", 4)
    player.consumeCurrency("strengthpoint", 2)
  elseif player.currency("classtype") == 5 then
    --Rogue
    player.consumeCurrency("agilitypoint", 3)
    player.consumeCurrency("endurancepoint", 2)
    player.consumeCurrency("dexteritypoint", 3)
    player.consumeCurrency("strengthpoint", 3)
    player.consumeCurrency("vigorpoint", 2)
  elseif player.currency("classtype") == 6 then
    --Explorer
    player.consumeCurrency("agilitypoint", 4)
    player.consumeCurrency("endurancepoint", 2)
    player.consumeCurrency("vitalitypoint", 3)
    player.consumeCurrency("vigorpoint", 4)
  end
  updateStats()]]
end


  --pane.playSound(self.sounds.dispatch, -1)
  --pane.stopAllSounds(self.sounds.dispatch)
  --widget.setFontColor("connectingLabel", config.getParameter("errorColor"))

