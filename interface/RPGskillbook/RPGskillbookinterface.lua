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
  self.affinity = player.currency("affinitytype")
  --[[
    0: No Affinity
    1: Infernal
    2: Void
    3: Toxic
    4: Arc
    5: Cryo
    6: Aer
    7: Victus 
    8: Kinetic
    ]]
    --initiating possible Level Change (thus, level currency should not be used in another script!!!)
    updateLevel()
end

function dismissed()
  player.consumeCurrency("skillbookopen", player.currency("skillbookopen"))
end

function update(dt)
  if not world.sendEntityMessage(player.id(), "holdingSkillBook"):result() then
    self.pane.dismiss()
  end

  if player.currency("experienceorb") ~= self.xp then
    updateLevel()
  end

  updateStats()
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
  if player.currency("currentlevel") == 0 then
    self.level = 1
    player.addCurrency("currentlevel",1)
    player.addCurrency("experienceorb",100)
    self.xp = player.currency("experienceorb")
    startingStats()
  else
    self.newLevel = math.floor(math.sqrt(self.xp/100))
    while self.newLevel > self.level do
      player.addCurrency("currentlevel", 1)
      player.addCurrency("statpoint", 1)
      self.level = self.level+1
    end
  end
  widget.setText("statslayout.statpointsleft",player.currency("statpoint"))
  updateStats()
  self.toNext = 2*self.level*100+100
  updateOverview(self.toNext)
  updateBottomBar(self.toNext)
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
    widget.setPosition("classlayout.weapontext",{154,240})
    widget.setPosition("classlayout.weapontitle",{89,240})
  end
  if player.currency("classtype") == 0 then
    widget.setText("classlayout.classtitle","No Class Yet")
    widget.setImage("classlayout.classicon","/objects/class/noclass.png")
    widget.setImage("classlayout.effecticon","/objects/class/noclassicon.png")
    widget.setImage("classlayout.effecticon","/objects/class/noclassicon.png")
    widget.setText("classlayout.statincreasetext", "The 'How Are You Here?' Class has a stat bonus with unexpectedness.")
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
    widget.setText("classlayout.statincreasetext", "Strength, Endurance, and Vitality provide\nbetter effects per point increase.")
  elseif player.currency("classtype") == 2 then
    widget.setText("classlayout.classtitle","Wizard")
    widget.setFontColor("classlayout.classtitle","magenta")
    widget.setImage("classlayout.classicon","/objects/class/wizard.png")
    widget.setFontColor("classlayout.effecttext","magenta")
    widget.setText("classlayout.weapontext","+10% (Scales With Intelligence) Damage while using a Wand in either hand without any other weapon equipped. +10% Damage with Staves.")
    widget.setText("classlayout.passivetext","+6% Chance to Freeze, Burn, or Electry monsters on hit. These effects can stack.")
    widget.setText("classlayout.effecttext","While using Wands or Staves, gain +10% Fire, Poison, and Ice Resistance.")
    widget.setImage("classlayout.effecticon","/scripts/wizardaffinity/wizardaffinity.png")
    widget.setImage("classlayout.effecticon2","/scripts/wizardaffinity/wizardaffinity.png")
    widget.setText("classlayout.statincreasetext", "Intelligence and Vigor provide much better effects per point increase.")
  elseif player.currency("classtype") == 3 then
    widget.setText("classlayout.classtitle","Ninja")
    widget.setImage("classlayout.classicon","/objects/class/ninja.png")
    widget.setFontColor("classlayout.classtitle","red")
    widget.setFontColor("classlayout.effecttext","red")
    widget.setText("classlayout.weapontext","+20% Damage while using Throwing Stars, Knives, Kunai, or Daggers, or Snowflake or Titanium Shurikens without any weapons equipped.")
    widget.setText("classlayout.passivetext","+20% Speed and Jump Height. -30% Fall Damage.")
    widget.setText("classlayout.effecttext","During Nighttime, or while Underground, gain +20% Crit Chance and Crit Damage.")
    widget.setImage("classlayout.effecticon","/scripts/ninjacrit/ninjacrit.png")
    widget.setImage("classlayout.effecticon2","/scripts/ninjacrit/ninjacrit.png")
    widget.setText("classlayout.statincreasetext", "Dexterity and Agility provide much better effects per point increase.")
  elseif player.currency("classtype") == 4 then
    widget.setText("classlayout.classtitle","Soldier")
    widget.setFontColor("classlayout.classtitle","orange")
    widget.setFontColor("classlayout.effecttext","orange")
    widget.setImage("classlayout.classicon","/objects/class/soldier.png")
    widget.setText("classlayout.weapontext","+10% Damage while using One-Handed Guns and Bombs, Molotovs, or Thorn Grenades in combination. +10% Damage with Sniper Rifles, Assault Rifles, Shotguns, and Rocket Launchers.")
    widget.setText("classlayout.passivetext","+20% Chance to Stun monsters on hit.")
    widget.setText("classlayout.effecttext","While Health is greater than half, your Food Meter decreases 10% slower.")
    widget.setImage("classlayout.effecticon","/scripts/soldierdiscipline/soldierdiscipline.png")
    widget.setImage("classlayout.effecticon2","/scripts/soldierdiscipline/soldierdiscipline.png")
    widget.setPosition("classlayout.weapontext",{154,251})
    widget.setPosition("classlayout.weapontitle",{89,251})
    widget.setText("classlayout.statincreasetext", "Vitality, Dexterity, Strength, and Endurance provide\nslightly better effects per point increase.")
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
    widget.setText("classlayout.statincreasetext", "Dexterity, Strength, and Agility provide\nbetter effects per point increase.")
  elseif player.currency("classtype") == 6 then
    widget.setText("classlayout.classtitle","Explorer")
    widget.setImage("classlayout.classicon","/objects/class/explorer.png")
    widget.setFontColor("classlayout.classtitle","yellow")
    widget.setFontColor("classlayout.effecttext","yellow")
    widget.setText("classlayout.weapontext","+5% Resistance to all Damage Types while using Grappling Hooks, Rope, Mining Tools, Throwable Light Sources, or Flashlights.")
    widget.setText("classlayout.passivetext","+10% Physical Resistance.")
    widget.setText("classlayout.effecttext","While Energy is greater than half, provide a bright yellow Glow.")
    widget.setImage("classlayout.effecticon","/scripts/explorerglow/explorerglow.png")
    widget.setImage("classlayout.effecticon2","/scripts/explorerglow/explorerglow.png")
    widget.setText("classlayout.statincreasetext", "Vigor, Agility, Endurance, and Vitality provide\nslightly better effects per point increase.")
  end
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
      widget.setVisible("classeslayout", true)
      return
    else
      widget.setVisible("classeslayout", false)
      updateClassTab()
      widget.setVisible("classlayout", true)
    end
end

function changeToAffinities()
    widget.setText("tabLabel", "Affinities Tab")
    widget.setVisible("affinitieslayout", true)
end

function changeToInfo()
    widget.setText("tabLabel", "Info Tab")
    widget.setVisible("infolayout", true)
    updateInfo()
end

function updateInfo()
  widget.setText("infolayout.display", 
    "Stat:                               Amount\n" ..
    "Physical Resistance:     " .. getStatPercent(status.stat("physicalResistance")) ..
    "Poison Resistance:        " .. getStatPercent(status.stat("poisonResistance")) ..
    "Frost Resistance:         " .. getStatPercent(status.stat("iceResistance")) ..
    "Fire Resistance:            " .. getStatPercent(status.stat("fireResistance")) ..
    "Electric Resistance:      " .. getStatPercent(status.stat("electricResistance")) ..
    "Bonus Health:               " .. status.stat("maxHealth") .. "\n" ..
    "Bonus Energy:               " .. status.stat("maxEnergy") .. "\n" ..
    "Fall Damage Multiplier:    " .. status.stat("fallDamageMultiplier") .. "\n" ..
    --"Bonus Speed: " .. getStatPercent(status.stat("speed")) ..
    --"Bonus Jump Height: " .. getStatPercent(status.stat("jumpHeight")) ..
    "Knockback Resistance:   " .. getStatPercent(status.stat("grit")) ..
    "Shield Health Bonus:         " .. getStatPercent(status.stat("shieldHealth")) ..
    "Energy Recharge Rate:       " .. getStatPercent(status.stat("energyRegenPercentageRate")) ..
    "Energy Recharge Delay:         " .. status.stat("energyRegenBlockTime") .. "\n" ..
    "Bleed Chance:                  " .. player.currency("dexteritypoint") + status.stat("ninjaBleed") .. "%\n" ..
    "Bleed Length:                  " .. (player.currency("dexteritypoint") + status.stat("ninjaBleed"))/50 .. "\n" ..
    "Hunger:                       " .. getStatPercent(status.stat("foodDelta")))
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

function startingStats()
  player.addCurrency("strengthpoint",1)
  player.addCurrency("dexteritypoint",1)
  player.addCurrency("intelligencepoint",1)
  player.addCurrency("agilitypoint",1)
  player.addCurrency("endurancepoint",1)
  player.addCurrency("vitalitypoint",1)
  player.addCurrency("vigorpoint",1)
end

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
  if name == "agility" then widget.setText("statslayout.statdescription", "Significantly Increases Speed.\nIncreases Jump Height.\nSlightly Decreases Fall Damage.") end
  if name == "vitality" then widget.setText("statslayout.statdescription", "Significantly Decreases Hunger Rate.\nIncreases Max Health.") end
  if name == "vigor" then widget.setText("statslayout.statdescription", "Significantly Increases Energy Recharge Rate.\nIncreases Max Energy.") end
  if name == "intelligence" then widget.setText("statslayout.statdescription", "Greatly Increases Energy Recharge Rate.\nGreatly Increases Staff Damage.\nDecreases Energy Recharge Delay.") end
  if name == "endurance" then widget.setText("statslayout.statdescription", "Increases Knockback Resistance.\nModerately Increases All Other Resistances.\nSlightly Increases Physical Resistance.") end
  if name == "dexterity" then widget.setText("statslayout.statdescription", "Increases One-Handed Weapon (Not Wands) Damage.\n Increases Gun and Bow Damage.\nIncreases Critical Chance and Critical Damage.\nDecreases Fall Damage.") end
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
  updateStats()
end

  --pane.playSound(self.sounds.dispatch, -1)
  --pane.stopAllSounds(self.sounds.dispatch)
  --widget.setFontColor("connectingLabel", config.getParameter("errorColor"))

