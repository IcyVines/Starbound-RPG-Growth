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
  self.level = player.currency("currentlevel")
  self.mastery = player.currency("masterypoint")
  --Mastery Conversion: 10000 Experience = 1 Mastery!!
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
  self.specTo = 0
  self.spec = player.currency("spectype")
    --[[
    ]]
  self.profTo = 0
  self.profession = player.currency("proftype")
    --[[
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
    self.quests = {"ivrpgaegisquest", "ivrpgnovaquest", "ivrpgaetherquest", "ivrpgversaquest", "ivrpgsiphonquest", "ivrpgspiraquest"}
    self.classWeaponText = {
      "The Aegis is a broadsword that can be used as a shield. Perfect Blocking triggers the Knight's class ability. Perfect Blocking with the Vital Aegis restores health.",
      "The Nova is a staff that can change elements. The staff cycles between Nova, Fire, Electric, and Ice. Nova weakens enemies to Fire, Electricity, and Ice. Enemies killed by Primed Nova explode.", 
      "The Aether is a shuriken that never runs out and always causes bleeding. Blood Aether tracks enemies and goes through both walls and enemies.", 
      "The Versa is a gun that can fire in two modes. Versa Impact and Ricochet's shotgun blast can be held to increase damage and snipe enemies. Versa Ricochet's bullets bounce and increase in power everytime they do.", 
      "The Siphon is a claw that uses energy to deal massive damage for its finisher. Finishers: Critical Slice causes bleed and fills hunger. Venom Slice causes poison and fills health. Lightning Slice causes static and fills energy.", 
      "The Spira is a one-handed drill with increased speed and infinite use. Hungry Spira draws items closer. Pressing shift while using Ravenous Spira causes no blocks to drop, but fills energy while breaking them."
    }
    --initiating possible Level Change (thus, level currency should not be used in another script!!!)
    self.challengeText = {
      {
        {"Defeat 500 enemies on Tier 4 or higher Planets.", 500},
        {"Defeat 350 enemies on Tier 5 or higher Planets.", 350},
        {"Defeat Kluex.", 1},
        {"Defeat the Erchius Horror without taking damage.", 1}
      },
      {
        {"Defeat 400 enemies on Tier 6 or higher Planets.", 400},
        {"Defeat the Bone Dragon.", 1}
      },
      {
        {"Defeat 400 enemies on Tier 7 or higher Planets (Vaults).", 400},
        {"Defeat 2 Vault Guardians.", 2},
        {"Defeat the Heart of Ruin.", 1},
        {"Deafeat the Heart of Ruin without taking damage.", 1}
      }
    }

    self.hardcoreWeaponText = {
      "Can Currently Equip All Weapons.",
      "The Knight can equip:^green;\nTwo-Handed Melee Weapons\nOne-Handed Melee Weapons ^reset;^red;\n(Not Including Fist Weapons or Whips)\n\nThe Knight cannot dual-wield weapons.",
      "The Wizard can equip:^green;\nStaffs\nWands\nDaggers ^red;(Secondary Hand Only)^reset;\n^green;Erchius Eye, Evil Eye, and Magnorbs.\n\nThe Wizard can dual-wield weapons.^reset;",
      "The Ninja can equip:^green;\nOne-Handed Melee Weapons\nFist Weapons and Whips\nAdaptable Crossbow and Solus Katana\n\nThe Ninja can dual-wield weapons.^reset;",
      "The Soldier can equip:^green;\nTwo-Handed Ranged Weapons.\nOne-Handed Ranged Weapons.\n\n^reset;^red;The Soldier cannot dual-wield weapons.\nThe Soldier cannot wield Wands.\nThe Soldier cannot wield the Erchius Eye.^reset;",
      "The Rogue can equip:^green;\nOne-Handed Melee Weapons.\nOne-Handed Ranged Weapons.\nFist Weapons and Whips\n\nThe Rogue can dual-wield weapons.\n^reset;^red;The Rogue cannot wield Wands.^reset;",
      "The Explorer can equip:^green;\nAny Weapon Type\n\nThe Explorer can dual-wield weapons.^reset;"
    }
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
    if widget.getChecked("bookTabs.2") then
      changeToClasses()
    elseif widget.getChecked("bookTabs.0") then
      changeToOverview()
    end
  end

  if player.currency("affinitytype") ~= self.affinity then
    self.affinity = player.currency("affinitytype")
    if widget.getChecked("bookTabs.3") then
      changeToAffinities()
    elseif widget.getChecked("bookTabs.0") then
      changeToOverview()
    end
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
  end
end

function updateLevel()
  self.xp = player.currency("experienceorb")
  if self.xp < 100 then
    player.addCurrency("experienceorb", 100)
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
    widget.setText("overviewlayout.classtitle","No Class")
    widget.setImage("overviewlayout.classicon","/objects/class/noclass.png")
    widget.setText("overviewlayout.hardcoretext","No Negative Effects")
  elseif player.currency("classtype") == 1 then
    widget.setText("overviewlayout.classtitle","Knight")
    widget.setImage("overviewlayout.classicon","/objects/class/knight.png")
    widget.setText("overviewlayout.hardcoretext","-10% Speed\n-30% Jump Height\n-25% Max Energy")
  elseif player.currency("classtype") == 2 then
    widget.setText("overviewlayout.classtitle","Wizard")
    widget.setImage("overviewlayout.classicon","/objects/class/wizard.png")
    widget.setText("overviewlayout.hardcoretext","-20% Speed\n-20% Jump Height\n-20% Physical Resistance")
  elseif player.currency("classtype") == 3 then
    widget.setText("overviewlayout.classtitle","Ninja")
    widget.setImage("overviewlayout.classicon","/objects/class/ninja.png")
    widget.setText("overviewlayout.hardcoretext","-50% Max Health")
  elseif player.currency("classtype") == 4 then
    widget.setText("overviewlayout.classtitle","Soldier")
    widget.setImage("overviewlayout.classicon","/objects/class/soldier.png")
    widget.setText("overviewlayout.hardcoretext","-10% Jump Height\n-20% Status Resistance")
  elseif player.currency("classtype") == 5 then
    widget.setText("overviewlayout.classtitle","Rogue")
    widget.setImage("overviewlayout.classicon","/objects/class/rogue.png")
    widget.setText("overviewlayout.hardcoretext","+20% Hunger Rate\n-20% Max Health")
  elseif player.currency("classtype") == 6 then
    widget.setText("overviewlayout.classtitle","Explorer")
    widget.setImage("overviewlayout.classicon","/objects/class/explorer.png")
    widget.setText("overviewlayout.hardcoretext","-25% Power Multiplier")
  end

  local affinity = player.currency("affinitytype")
  if affinity == 0 then
    widget.setText("overviewlayout.affinitytitle","No Affinity")
    widget.setImage("overviewlayout.affinityicon","/objects/class/noclass.png")
  elseif affinity == 1 then
    widget.setText("overviewlayout.affinitytitle","Flame")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/flame.png")
  elseif affinity == 2 then
    widget.setText("overviewlayout.affinitytitle","Venom")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/venom.png")
  elseif affinity == 3 then
    widget.setText("overviewlayout.affinitytitle","Frost")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/frost.png")
  elseif affinity == 4 then
    widget.setText("overviewlayout.affinitytitle","Shock")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/shock.png")
  elseif affinity == 5 then
    widget.setText("overviewlayout.affinitytitle","Infernal")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/flame.png")
  elseif affinity == 6 then
    widget.setText("overviewlayout.affinitytitle","Toxic")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/venom.png")
  elseif affinity == 7 then
    widget.setText("overviewlayout.affinitytitle","Cryo")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/frost.png")
  elseif affinity == 8 then
    widget.setText("overviewlayout.affinitytitle","Arc")
    widget.setImage("overviewlayout.affinityicon","/objects/affinity/shock.png")
  end

  if status.statPositive("ivrpghardcore") then
    widget.setText("overviewlayout.hardcoretoggletext", "Active")
    widget.setVisible("overviewlayout.hardcoretext", true)
    widget.setVisible("overviewlayout.hardcoreweapontext", true)
  else
    widget.setText("overviewlayout.hardcoretoggletext", "Inactive")
    widget.setVisible("overviewlayout.hardcoretext", false)
    widget.setVisible("overviewlayout.hardcoreweapontext", false)
  end

end

function updateClassTab()
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
    widget.setImage("classlayout.classweaponicon","/interface/RPGskillbook/weapons/knight.png")
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
    widget.setImage("classlayout.classweaponicon","/interface/RPGskillbook/weapons/wizard.png")
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
    widget.setImage("classlayout.classweaponicon","/interface/RPGskillbook/weapons/ninja.png")
    widget.setText("classlayout.statscalingtext","^green;Amazing:^reset;\nDexterity\n^magenta;Good:^reset;\nAgility")
  elseif player.currency("classtype") == 4 then
    widget.setText("classlayout.classtitle","Soldier")
    widget.setFontColor("classlayout.classtitle","orange")
    widget.setFontColor("classlayout.effecttext","orange")
    widget.setImage("classlayout.classicon","/objects/class/soldier.png")
    widget.setText("classlayout.weapontext","+20% Damage while using One-Handed Guns in combination with Grenades. +10% Damage with Sniper Rifles, Assault Rifles, and Shotguns.")
    widget.setText("classlayout.passivetext","+10% Chance to Stun monsters on hit. Stun Length depends on damage dealt.")
    widget.setText("classlayout.effecttext","+10% Power when Energy is full.\nCancelled when Energy drops below 75%.")
    widget.setImage("classlayout.effecticon","/scripts/soldierdiscipline/soldierdiscipline.png")
    widget.setImage("classlayout.effecticon2","/scripts/soldierdiscipline/soldierdiscipline.png")
    widget.setImage("classlayout.classweaponicon","/interface/RPGskillbook/weapons/soldier.png")
    widget.setText("classlayout.statscalingtext","^blue;Great:^reset;\nVigor\n^magenta;Good:^reset;\nDexterity\n^gray;OK:^reset;\nVitality\nEndurance")
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
    widget.setImage("classlayout.classweaponicon","/interface/RPGskillbook/weapons/rogue.png")
    widget.setText("classlayout.statscalingtext","^blue;Great:^reset;\nDexterity\n^magenta;Good:^reset;\nVigor\nAgility")
  elseif player.currency("classtype") == 6 then
    widget.setText("classlayout.classtitle","Explorer")
    widget.setImage("classlayout.classicon","/objects/class/explorer.png")
    widget.setFontColor("classlayout.classtitle","yellow")
    widget.setFontColor("classlayout.effecttext","yellow")
    widget.setText("classlayout.weapontext","+10% Damage and Resistance while using Grappling Hooks, Rope, Mining Tools, Throwable Light Sources, or Flashlights.")
    widget.setText("classlayout.passivetext","+10% Physical Resistance.")
    widget.setText("classlayout.effecttext","While Health is greater than half, provide a bright yellow Glow.")
    widget.setImage("classlayout.effecticon","/scripts/explorerglow/explorerglow.png")
    widget.setImage("classlayout.effecticon2","/scripts/explorerglow/explorerglow.png")
    widget.setImage("classlayout.classweaponicon","/interface/RPGskillbook/weapons/explorer.png")
    widget.setText("classlayout.statscalingtext","^blue;Great:^reset;\nVitality\n^magenta;Good:^reset;\nAgility\n^gray;OK:^reset;\nVigor\nEndurance")
  end

  if status.statPositive("ivrpgclassability") then
    widget.setText("classlayout.classabilitytoggletext", "Inactive")
  else
    widget.setText("classlayout.classabilitytoggletext", "Active")
  end

  updateClassWeapon()
  updateTechImages()
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
  widget.setVisible("specializationlockedlayout",false)
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
    if self.level < 40 then
      widget.setVisible("specializationlayout", false)
      widget.setVisible("specializationlockedlayout", true)
    else
      updateSpecializationTab()
      widget.setVisible("specializationlockedlayout", false)
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

function updateProfessionTab()
end

function updateSpecializationTab()
end

function updateMasteryTab()
  widget.setText("masterylayout.masterypoints", self.mastery)
  widget.setText("masterylayout.xpover", math.max(0, self.xp - 250000))

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
  --Yea, yea, this should be in its own file that all lua files can import, but I'm lazy, ya' hear?
  self.strengthBonus = self.classType == 1 and 1.15 or 1
  self.agilityBonus = self.classType == 3 and 1.1 or (self.classType == 5 and 1.1 or (self.classType == 6 and 1.1 or 1))
  self.vitalityBonus = self.classType == 4 and 1.05 or (self.classType == 1 and 1.1 or (self.classType == 6 and 1.15 or 1))
  self.vigorBonus = self.classType == 4 and 1.15 or (self.classType == 2 and 1.1 or (self.classType == 5 and 1.1 or (self.classType == 6 and 1.05 or 1)))
  self.intelligenceBonus = self.classType == 2 and 1.2 or 1
  self.enduranceBonus = self.classType == 1 and 1.1 or (self.classType == 4 and 1.05 or (self.classType == 6 and 1.05 or 1))
  self.dexterityBonus = self.classType == 3 and 1.2 or (self.classType == 5 and 1.15 or (self.classType == 4 and 1.1 or 1))

  widget.setText("infolayout.displaystats", 
    "Amount\n" ..
    "^red;" .. math.floor(100*(1 + self.vitality^self.vitalityBonus*.05))/100 .. "^reset;" .. "\n" ..
    "^green;" .. math.floor(100*(1 + self.vigor^self.vigorBonus*.05))/100 .. "\n" ..
    math.floor(status.stat("energyRegenPercentageRate")*100+.5)/100 .. "\n" ..
    math.floor(status.stat("energyRegenBlockTime")*100+.5)/100 .. "^reset;" .. "\n" ..
    "^orange;" .. getStatPercent(status.stat("foodDelta")) .. "^reset;" ..
    "^gray;" .. getStatPercent(status.stat("physicalResistance")) .. "^reset;" ..
    "^magenta;" .. (status.statPositive("poisonStatusImmunity") and "Immune!\n" or getStatPercent(status.stat("poisonResistance"))) .. "^reset;" ..
    "^blue;" .. (status.statPositive("iceStatusImmunity") and "Immune!\n" or getStatPercent(status.stat("iceResistance"))) .. "^reset;" .. 
    "^red;" .. (status.statPositive("fireStatusImmunity") and "Immune!\n" or getStatPercent(status.stat("fireResistance"))) .."^reset;" .. 
    "^yellow;" .. (status.statPositive("electricStatusImmunity") and "Immune!\n" or getStatPercent(status.stat("electricResistance"))) .. "^reset;" ..
    "^gray;" .. getStatPercent(status.stat("grit")) ..
    getStatMultiplier(status.stat("fallDamageMultiplier")) ..  
    math.floor((1 + self.strength^self.strengthBonus*.05)*100+.5)/100 .. "^reset;" .. "\n" ..
    "^red;" .. (math.floor(self.dexterity^self.dexterityBonus*100+.5)/200 + status.stat("ninjaBleed")) .. "%\n" ..
    (math.floor(self.dexterity^self.dexterityBonus*100+.5)/100 + status.stat("ninjaBleed"))/50 .. "^reset;" .. "\n" ..
    "\nStatus:\n" ..
    "^red;" .. getStatImmunity(status.stat("lavaImmunity")) ..
    getStatImmunity(status.stat("biomeheatImmunity")) .. "^reset;" ..
    "^blue;" .. getStatImmunity(status.stat("biomecoldImmunity")) .. "^reset;" ..
    "^green;" .. getStatImmunity(status.stat("biomeradiationImmunity")) .. "^reset;" ..
    "^gray;" .. getStatImmunity(status.stat("tarStatusImmunity")) .. "^reset;" ..
    "^blue;" .. getStatImmunity(status.stat("breathingProtection")) .. "^reset;")

  widget.setText("infolayout.displaystatsFU", 
    "Amount\n" ..
    "^green;" .. (status.statPositive("radioactiveStatusImmunity") and "Immune!\n" or getStatPercent(status.stat("radioactiveResistance"))) .. "^reset;" ..
    "^gray;" .. (status.statPositive("shadowStatusImmunity") and "Immune!\n" or getStatPercent(status.stat("shadowResistance"))) .. "^reset;" ..
    "^magenta;" .. (status.statPositive("cosmicStatusImmunity") and "Immune!\n" or getStatPercent(status.stat("cosmicResistance"))) .. "^reset;" ..
    "\nStatus:\n" ..
    "^red;" .. getStatImmunity(status.stat("ffextremeheatImmunity")) .. "^reset;" .. 
    "^blue;" .. getStatImmunity(status.stat("ffextremecoldImmunity")) .. "^reset;" .. 
   "^green;" ..  getStatImmunity(status.stat("ffextremeradiationImmunity")) .. "^reset;")

  widget.setText("infolayout.displayWeapons", self.hardcoreWeaponText[self.classType+1] .. "\n\n^green;All Classes can use the\nBroken Protectorate Broadsword!\nAll Classes can use Hunting Bows.^reset;")
  if status.statPositive("ivrpghardcore") then
    widget.setVisible("infolayout.displayWeapons", true)
  else
    widget.setVisible("infolayout.displayWeapons", false)
  end
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
    return checked == 1 and "soldiermre" or (checked == 2 and "soldiermarksman" or (checked == 3 and "soldierenergypack" or "soldiertanksphere"))
  elseif classType == 5 then
    return checked == 1 and "roguedeadlystance" or (checked == 2 and "roguetoxicsphere" or (checked == 3 and "rogueescape" or "roguetoxicaura"))
  elseif classType == 6 then
    return checked == 1 and "explorerglide" or (checked == 2 and "explorerenhancedmovement" or (checked == 3 and "explorerdrillsphere" or "explorerenhancedjump"))
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
    return num == 1 and "An upgrade to Sprint, while running, enemies receive damage and knockback. Damage is doubled when holding up a shield. Damage scales with Strength and Run Speed. Energy Cost decreases with higher Agility."
    or (num == 2 and "An upgrade to Double Jump, press [G] (Bind [G] in your Controls) while midair to slam downwards. You take no fall damage upon landing, and cause a small explosion, damaging enemies. Damage scales with Strength and distance fallen from activation."
      or (num == 3 and "An upgrade to Spike Sphere, while transformed, ignore knockback and deal contact damage to enemies." 
        or "An upgrade to Bash. While sprinting, the player receives physical resistance. While damage remains the same, enemies are stunned on hit. Damage scales with Strength and Run Speed. Energy Cost decreases with higher Agility."))
  elseif classType == 2 then
    return num == 1 and "An upgrade to Spike Sphere, while transformed you regen slightly and are affected by low gravity. In addition, hold left click to create a barrier that pushes enemies away, draining energy to do so." 
    or (num == 2 and "Press [Space] while in air to hover towards your cursor. The further your cursor, the faster you move. Your Energy drains while you hover." 
      or (num == 3 and "Press [G] (Bind [G] in your Controls) to teleport to your cursor (if possible). There is a slight cooldown before you can teleport again. Energy Cost depends on Distance and Agility. During Missions (and in your ship), Translocate is Line-of-Sight only!." 
        or "Press [F] to toggle a magical shield that provides invulnerability to you and nearby allies. Drains energy while active, and is toggled off when no energy remains."))
  elseif classType == 3 then
    return num == 1 and "Press [Space] while midair to burst forward. For a short time after jumping, you are invulnerable to damage. As long as you remain in the air with energy remaining, you are invulnerable to fall damage. You may do this twice while midair." 
    or (num == 2 and "Press [F] to morph into an invulnerable spike ball. Energy drains quickly while active. The invulnerability ends when you run out of energy or press [F] while transformed." 
    or (num == 3 and "Press [G] (Bind [G] in your Controls) to vanish. After 2 seconds, you appear at your cursor (if possible). If holding a sharp weapon, slash where you appear. During the cooldown, lose 20% Physical Resistance. Energy Cost depends on Distance and Agility." 
    or "An upgrade to Flash Jump. Cling to walls by moving against them during a jump, and refresh your jumps upon doing so. Press [S] to slide down while clinging. Press [Space] while clinging or sliding to jump. Move away from the wall to get off."))
  elseif classType == 4 then
    return num == 1 and "Press [F] to eat an MRE (Meal Ready to Eat), gaining a bit of food and all your energy. There is a cooldown of 90 seconds before you can do this again. While the cooldown is active, you gain slight health regen, but your overall speed is decreased." 
    or (num == 2 and "Press [G] (Bind [G] in your Controls) to gain extra weapon damage with ranged weapons and decreased energy regen block time: however, speed and resistance are decreased. You can end the effect by pressing [G] again. The cooldown shortens if so." 
      or (num == 3 and "An upgrade to Double Jump, press [Space] to dash in a direction of your choosing. You can slightly change your trajectory while dashing. Dash Duration scales with Agility. You can dash twice in mid-air." 
        or "Press [F] to switch to a slow-moving Spike Sphere. Left click to shoot a missile using some energy. Hold right click to drain your energy in order to shield yourself from damage.\nCreated by SushiSquid!"))
  elseif classType == 5 then
    return num == 1 and "Press [G] (Bind [G] in your Controls) to toggle an ability that increases Physical and Poison Resistance and grants Knockback Immunity. Drains energy while active, and is toggled off when no energy remains." 
    or (num == 2 and "Press [F] to transform into a Spike Sphere. Left click while transformed to shoot out a ring of poison clouds. You are immune to poison while transformed." 
      or (num == 3 and "An upgrade to Double Jump, press [Space] to launch yourself in a direction of your choosing, leaving a cloud of smoke behind that disorients enemies. Disoriented enemies are slowed and do less damage. Defaults to a backwards launch." 
        or "Press [G] (Bind [G] in your Controls) to toggle a toxic field that inflicts enemies with a weakening poison. These enemies take more poison and bleed damage. Drains energy while active, and is toggled off when no energy remains."))
  elseif classType == 6 then
    return num == 1 and "An upgrade to Double Jump, hold [W] to glide forward, slowly losing altitude. You can use your double jump while gliding. Glide energy cost decreases with higher Agility." 
    or (num == 2 and "Press [G] (Bind [G] in your Controls) to switch between Enhanced Airdash and Enhanced Sprint. Enhanced Airdash travels further than Air Dash, and has a shorter cooldown. Enhanced Sprint is faster and costs less energy than Sprint." 
      or (num == 3 and "Press [H] (Bind [H] in your Controls) to transform into a fast Spike Sphere that can jump. Press [F] to drill down at incredible speed, draining your energy. You can drill whether or not you are transformed." 
        or "An upgrade to Glide. Gain another three midair jumps and a wall jump. Midair jumps are 85% as effective. You cling to walls slightly longer than the normal Wall Jump and slide down slower as well. Glide energy cost decreases with higher Agility."))
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
    return num == 1 and "Flash Jump" or (num == 2 and "Vanish Sphere" or (num == 3 and "Shadow Step" or "Wall Cling"))
  elseif classType == 4 then
    widget.setFontColor("classlayout.techname", "orange")
    return num == 1 and "MRE" or (num == 2 and "Marksman" or (num == 3 and "Energize" or "Tank Sphere"))
  elseif classType == 5 then
    widget.setFontColor("classlayout.techname", "green")
    return num == 1 and "Deadly Stance" or (num == 2 and "Toxic Sphere" or (num == 3 and "Escape!" or "Toxic Aura"))
  elseif classType == 6 then
    widget.setFontColor("classlayout.techname", "yellow")
    return num == 1 and "Glide" or (num == 2 and "Enhanced Dash" or (num == 3 and "Drill Sphere" or "Enhanced Glide"))
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

function getStatMultiplier(stat)
  stat = math.floor(stat*100+.5)/100
  return stat <= 0 and "0\n" or (stat .. "\n")
end

function getStatImmunity(stat)
  return tostring(stat >= 1):gsub("^%l",string.upper) .. "\n"
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
    player.addCurrency("vigorpoint", 5)
    player.addCurrency("endurancepoint", 2)
    player.addCurrency("dexteritypoint", 4)
    player.addCurrency("vitalitypoint", 2)
  elseif player.currency("classtype") == 5 then
    --Rogue
    player.addCurrency("agilitypoint", 3)
    player.addCurrency("endurancepoint", 3)
    player.addCurrency("dexteritypoint", 4)
    player.addCurrency("vigorpoint", 3)
  elseif player.currency("classtype") == 6 then
    --Explorer
    player.addCurrency("agilitypoint", 4)
    player.addCurrency("endurancepoint", 2)
    player.addCurrency("vigorpoint", 3)
    player.addCurrency("vitalitypoint", 4)
  end
  updateStats()
  uncheckClassIcons("default")
  changeClassDescription("default")
end

--deprecated, don't use
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
    player.consumeCurrency("endurancepoint", 3)
    player.consumeCurrency("dexteritypoint", 4)
    player.consumeCurrency("vigorpoint", 3)
  elseif player.currency("classtype") == 6 then
    --Explorer
    player.consumeCurrency("agilitypoint", 4)
    player.consumeCurrency("endurancepoint", 2)
    player.consumeCurrency("vitalitypoint", 3)
    player.consumeCurrency("vigorpoint", 4)
  end
  updateStats()
end
--

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

--deprecated, don't use
function resetClass()
  notSure("nobuttoncl")
  consumeClassStats()
  player.consumeCurrency("classtype",player.currency("classtype"))
  changeToClasses()
end
--

function resetSkillBook()
  notSure("nobutton")
  consumeAllRPGCurrency()
  consumeMasteryCurrency()
  removeTechs()
end

function removeTechs()
  if self.class == 3 then
    player.makeTechUnavailable("ninjaassassinate")
    player.makeTechUnavailable("ninjaflashjump")
    player.makeTechUnavailable("ninjawallcling")
    player.makeTechUnavailable("ninjavanishsphere")
  elseif self.class == 2 then
    player.makeTechUnavailable("wizardmagicshield")
    player.makeTechUnavailable("wizardgravitysphere")
    player.makeTechUnavailable("wizardtranslocate")
    player.makeTechUnavailable("wizardhover")
  elseif self.class == 1 then
    player.makeTechUnavailable("knightslam")
    player.makeTechUnavailable("knightbash")
    player.makeTechUnavailable("knightcharge!")
    player.makeTechUnavailable("knightarmorsphere")
  elseif self.class == 5 then
    player.makeTechUnavailable("roguetoxicaura")
    player.makeTechUnavailable("roguetoxicsphere")
    player.makeTechUnavailable("roguedeadlystance")
    player.makeTechUnavailable("rogueescape")
    --Deprecated
    player.makeTechUnavailable("roguepoisondash")
    player.makeTechUnavailable("roguecloudjump")
    player.makeTechUnavailable("roguetoxiccapsule")
  elseif self.class == 4 then
    player.makeTechUnavailable("soldiertanksphere")
    player.makeTechUnavailable("soldierenergypack")
    player.makeTechUnavailable("soldiermarksman")
    player.makeTechUnavailable("soldiermre")
    --Deprecated
    player.makeTechUnavailable("soldiermissilestrike")
  elseif self.class == 6 then
    player.makeTechUnavailable("explorerenhancedjump")
    player.makeTechUnavailable("explorerenhancedmovement")
    player.makeTechUnavailable("explorerdrillsphere")
    player.makeTechUnavailable("explorerglide")
    --Deprecated
    player.makeTechUnavailable("explorerdrill")
  end
end

function updateClassWeapon()
  if self.class == 0 then return end
  if player.hasCompletedQuest(self.quests[self.class]) then
    widget.setText("classlayout.classweapontext", self.classWeaponText[self.class])
    widget.setVisible("classlayout.weaponreqlvl", false)
    widget.setVisible("classlayout.unlockquestbutton", false)
    widget.setVisible("classlayout.classweapontext", true)
  elseif self.level < 15 then
    widget.setFontColor("classlayout.weaponreqlvl", "red")
    widget.setText("classlayout.weaponreqlvl", "Required Level: 15")
    widget.setVisible("classlayout.weaponreqlvl", true)
    widget.setVisible("classlayout.unlockquestbutton", false)
    widget.setVisible("classlayout.classweapontext", false)
  elseif player.hasQuest(self.quests[self.class]) then
    widget.setText("classlayout.classweapontext", "Complete the first quest for more information.")
    widget.setVisible("classlayout.classweapontext", true)
    widget.setVisible("classlayout.weaponreqlvl", false)
    widget.setVisible("classlayout.unlockquestbutton", false)
  else
    widget.setVisible("classlayout.unlockquestbutton", true)
    widget.setVisible("classlayout.weaponreqlvl", false)
    widget.setVisible("classlayout.classweapontext", false)
  end
end

function unlockQuest()
  player.startQuest(self.quests[self.class])
  widget.setVisible("classlayout.unlockquestbutton", false)
  widget.setText("classlayout.classweapontext", "Complete the first quest for more information.")
  widget.setVisible("classlayout.classweapontext", true)
end

function chooseAffinity()
  player.addCurrency("affinitytype", self.affinityTo)
  self.affinity = self.affinityTo
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
    widget.setText("affinitieslayout.affinitydescription", "Flame, the Powerful Affinity. This Affinity grants Fire based Immunities and Resistances, and a Medium Vigor Stat Boost. Provides better Immunities and a Large Strength Stat Boost when upgraded. Be careful, as choosing this Affinity weakens you while Submerged, and makes you weak to Poison.") 
    widget.setFontColor("affinitieslayout.firetitle", "red")
    self.affinityTo = 1
  end
  if name == "poison" then
    widget.setText("affinitieslayout.affinitydescription", "Venom, the Proficient Affinity. This Affinity grants Poison based Immunities and Resistances, and a Small Vigor, Dexterity, and Agility Stat Boost. Provides better Immunities and a Large Dexterity Stat Boost when upgraded. Be careful, as choosing this Affinity lowers your Max Health and makes you weak to Electricity.") 
    widget.setFontColor("affinitieslayout.poisontitle", "green")
    self.affinityTo = 2
  end
  if name == "ice" then
    widget.setText("affinitieslayout.affinitydescription", "Frost, the Protective Affinity. This Affinity grants Ice based Immunities and Resistances, and a Medium Vitality Stat Boost. Provides better Immunities and a Large Endurance Stat Boost when upgraded. Be careful, as choosing this Affinity lowers your Speed and Jump Height, and makes you weak to Fire.") 
    widget.setFontColor("affinitieslayout.icetitle", "blue")
    self.affinityTo = 3
  end
  if name == "electric" then
    widget.setText("affinitieslayout.affinitydescription", "Shock, the Perceptive Affinity. This Affinity grants Electric based Immunities and Resistances, and a Medium Agility Stat Boost. Provides better Immunities and a Large Intelligence Stat Boost when upgraded. Be careful, as choosing this Affinity weakens you while Submerged, and makes you weak to Frost.") 
    widget.setFontColor("affinitieslayout.electrictitle", "yellow")
    self.affinityTo = 4
  end
  if name == "default" then
    widget.setText("affinitieslayout.affinitydescription", "Click an Affinity's icon to see what that Affinity does.")
    uncheckAffinityIcons("default")
    self.affinityTo = 0
  end
end

function updateAffinityTab()
  local affinity = player.currency("affinitytype")
  if affinity == 0 then
    widget.setText("affinitylayout.affinitytitle","No Class Yet")
    widget.setImage("affinitylayout.affinityicon","/objects/class/noclass.png")
  elseif affinity == 1 then
    widget.setText("affinitylayout.affinitytitle","Flame")
    widget.setFontColor("affinitylayout.affinitytitle","red")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/flame.png")

    widget.setText("affinitylayout.passivetext","+10% chance to Sear enemies when dealing damage. Seared enemies have -25% Power and are Burned for the duration of Sear.")
    widget.setText("affinitylayout.statscalingtext","+3 Vigor")

    widget.setText("affinitylayout.immunitytext", "Fire\nHeat")
    widget.setText("affinitylayout.weaknesstext", "-25% Poison Resistance\n-30% Energy while submerged\n-1 HP/s while submerged")
    widget.setText("affinitylayout.upgradetext", "+20% chance to Sear enemies\n+5 Strength\nImmunities Added:\nLava\nExtreme Heat")
  elseif affinity == 2 then
    widget.setText("affinitylayout.affinitytitle","Venom")
    widget.setFontColor("affinitylayout.affinitytitle","green")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/venom.png")

    widget.setText("affinitylayout.passivetext","+10% chance to Toxify enemies when dealing damage. Toxified enemies have -25% Max Health and are Poisoned for the duration of Toxify.")
    widget.setText("affinitylayout.statscalingtext","+1 Vigor\n+1 Dexterity\n+1 Agility")

    widget.setText("affinitylayout.immunitytext", "Poison\nTar")
    widget.setText("affinitylayout.weaknesstext", "-25% Electric Resistance\n-15% Health")
    widget.setText("affinitylayout.upgradetext", "+20% chance to Toxify enemies\n+5 Dexterity\nImmunities Added:\nRadiation\nProto")
  elseif affinity == 3 then
    widget.setText("affinitylayout.affinitytitle","Frost")
    widget.setFontColor("affinitylayout.affinitytitle","blue")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/frost.png")

    widget.setText("affinitylayout.passivetext","+10% chance to Embrittle enemies when dealing damage. Embrittled enemies have -25% Physical Resistance and shatter when killed. This Ice Explosion deals Cold Damage and Frost Slows enemies.")
    widget.setText("affinitylayout.statscalingtext","+3 Vitality")

    widget.setText("affinitylayout.immunitytext", "Wet\nCold")
    widget.setText("affinitylayout.weaknesstext", "-25% Fire Resistance\n-15% Speed\n-15% Jump")
    widget.setText("affinitylayout.upgradetext", "+20% chance to Embrittle enemies\n+5 Endurance\nImmunities Added:\nBreathing\nExtreme Cold")
  elseif affinity == 4 then
    widget.setText("affinitylayout.affinitytitle","Shock")
    widget.setFontColor("affinitylayout.affinitytitle","yellow")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/shock.png")

    widget.setText("affinitylayout.passivetext","+10% chance to Overload enemies when dealing damage. Overloaded enemies have -25% Speed and chain lightning to nearby enemies. This Lightning deals Electric Damage and Electrifies enemies.")
    widget.setText("affinitylayout.statscalingtext","+3 Agility")

    widget.setText("affinitylayout.immunitytext", "Slow\nElectricity")
    widget.setText("affinitylayout.weaknesstext", "-25% Ice Resistance\n-30% Health while submerged\n-1 E/s while submerged")
    widget.setText("affinitylayout.upgradetext", "+20% chance to Overload enemies\n+5 Intelligence\nImmunities Added:\nRadiation\nShadow")
  elseif affinity == 5 then
    widget.setText("affinitylayout.affinitytitle","Infernal")
    widget.setFontColor("affinitylayout.affinitytitle","red")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/flame.png")

    widget.setText("affinitylayout.passivetext","+30% chance to Sear enemies when dealing damage. Seared enemies have -25% Power and are Burned for the duration of Sear.")
    widget.setText("affinitylayout.statscalingtext","+3 Vigor\n+5 Strength")

    widget.setText("affinitylayout.immunitytext", "Fire\nHeat\nLava\nExtreme Heat (Frackin Universe)")
    widget.setText("affinitylayout.weaknesstext", "-25% Poison Resistance\n-30% Energy while submerged\n-1 HP/s while submerged")
    widget.setText("affinitylayout.upgradetext", "Fully Upgraded!")
  elseif affinity == 6 then
    widget.setText("affinitylayout.affinitytitle","Toxic")
    widget.setFontColor("affinitylayout.affinitytitle","green")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/venom.png")

    widget.setText("affinitylayout.passivetext","+30% chance to Toxify enemies when dealing damage. Toxified enemies have -25% Max Health and are Poisoned for the duration of Toxify.")
    widget.setText("affinitylayout.statscalingtext","+1 Vigor\n+1 Agility\n+6 Dexterity")

    widget.setText("affinitylayout.immunitytext", "Poison\nTar\nRadiation\nProto (Frackin Universe)")
    widget.setText("affinitylayout.weaknesstext", "-25% Electric Resistance\n-15% Health")
    widget.setText("affinitylayout.upgradetext", "Fully Upgraded!")
  elseif affinity == 7 then
    widget.setText("affinitylayout.affinitytitle","Cryo")
    widget.setFontColor("affinitylayout.affinitytitle","blue")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/frost.png")

    widget.setText("affinitylayout.passivetext","+30% chance to Embrittle enemies when dealing damage. Embrittled enemies have -25% Physical Resistance and shatter when killed. This Ice Explosion deals Cold Damage and Frost Slows enemies.")
    widget.setText("affinitylayout.statscalingtext","+3 Vitality\n+5 Endurance")

    widget.setText("affinitylayout.immunitytext", "Wet\nCold\nBreathing\nExtreme Cold (Frackin Universe)")
    widget.setText("affinitylayout.weaknesstext", "-25% Fire Resistance\n-15% Speed\n-15% Jump")
    widget.setText("affinitylayout.upgradetext", "Fully Upgraded!")
  elseif affinity == 8 then
    widget.setText("affinitylayout.affinitytitle","Arc")
    widget.setFontColor("affinitylayout.affinitytitle","yellow")
    widget.setImage("affinitylayout.affinityicon","/objects/affinity/shock.png")

    widget.setText("affinitylayout.passivetext","+30% chance to Overload enemies when dealing damage. Overloaded enemies have -25% Speed and chain lightning to nearby enemies. This Lightning deals Electric Damage and Electrifies enemies.")
    widget.setText("affinitylayout.statscalingtext","+3 Agility\n+5 Intelligence")

    widget.setText("affinitylayout.immunitytext", "Slow\nElectricity\nRadiation\nShadow (Frackin Universe)")
    widget.setText("affinitylayout.weaknesstext", "-25% Ice Resistance\n-30% Health while submerged\n-1 E/s while submerged")
    widget.setText("affinitylayout.upgradetext", "Fully Upgraded!")
  end

  if affinity > 4 then
    widget.setVisible("affinitylayout.effecttext", false)
  elseif affinity > 0 then
    widget.setVisible("affinitylayout.effecttext", true)
  end

  if status.statPositive("ivrpgaesthetics") then
    widget.setText("affinitylayout.aestheticstoggletext", "Active")
  else
    widget.setText("affinitylayout.aestheticstoggletext", "Inactive")
  end
end

function addAffinityStats()
  if player.currency("affinitytype") == 1 then
      --Flame
    addAffintyStatsHelper("vigorpoint", 3)
  elseif player.currency("affinitytype") == 2 then
    --Venom
    addAffintyStatsHelper("vigorpoint", 1)
    addAffintyStatsHelper("dexteritypoint", 1)
    addAffintyStatsHelper("agilitypoint", 1)
  elseif player.currency("affinitytype") == 3 then
    --Frost
    addAffintyStatsHelper("vitalitypoint", 3)
  elseif player.currency("affinitytype") == 4 then
    --Shock
    addAffintyStatsHelper("agilitypoint", 3)
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

--Deprecated
function consumeAffinityStats()
  --[[if player.currency("affinitytype") == 1 then
      --Flame
    player.consumeCurrency("vigorpoint", 3)
  elseif player.currency("classtype") == 2 then
    --Venom
    player.consumeCurrency("vigorpoint", 1)
    player.consumeCurrency("vitalitypoint", 1)
    player.consumeCurrency("agilitypoint", 1)
  elseif player.currency("classtype") == 3 then
    --Frost
    player.consumeCurrency("vitalitypoint", 3)
  elseif player.currency("classtype") == 4 then
    --Shock
    player.consumeCurrency("agilitypoint", 3)
  elseif player.currency("cla sstype") == 5 then
    --Infernal
    player.consumeCurrency("strengthpoint", 5)
  elseif player.currency("classtype") == 6 then
    --Toxic
    player.consumeCurrency("dexteritypoint", 5)
  elseif player.currency("classtype") == 7 then
    --Cryo
    player.consumeCurrency("endurancepoint", 5)
  elseif player.currency("classtype") == 8 then
    --Arc
    player.consumeCurrency("intelligencepoint", 5)
  end
  updateStats()]]
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
  player.consumeCurrency("experienceorb", self.xp - 100)
  player.consumeCurrency("currentlevel", self.level - 1)
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
  player.consumeCurrency("proftype",player.currency("proftype"))
  player.consumeCurrency("spectype",player.currency("spectype"))
  startingStats()
  updateStats()
end

function prestige()
  player.consumeCurrency("masterypoint", 3)
  consumeAllRPGCurrency()
  removeDeprecatedTechs()
end

function purchaseShop()
  player.consumeCurrency("masterypoint", 5)
  player.giveItem("ivrpgmasteryshop")
end

function refine()
  local xp = self.xp - 250000
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

  local prog1 = math.floor(status.stat("ivrpgchallenge1progress"))
  local prog2 = math.floor(status.stat("ivrpgchallenge2progress"))
  local prog3 = math.floor(status.stat("ivrpgchallenge3progress"))

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
    status.clearPersistentEffects("ivrpgchallenge1progress")
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
    status.clearPersistentEffects("ivrpgchallenge2progress")
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
    status.clearPersistentEffects("ivrpgchallenge3progress")
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
  status.clearPersistentEffects("ivrpgchallenge1progress")
  status.clearPersistentEffects("ivrpgchallenge2progress")
  status.clearPersistentEffects("ivrpgchallenge3progress")
end

function removeDeprecatedTechs()
  player.makeTechUnavailable("roguecloudjump")
  player.makeTechUnavailable("roguetoxiccapsule")
  player.makeTechUnavailable("roguepoisondash")
  player.makeTechUnavailable("soldiermissilestrike")
  player.makeTechUnavailable("explorerdrill")
end