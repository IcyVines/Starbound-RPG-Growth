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

  self.class = player.currency("classtype")
    --[[
    0: No Class
    1: Knight
    2: Ninja
    3: Rogue
    4: Wizard
    5: Soldier
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
    7: Aqua
    8: Herba
    ]]

    --initiating possible Level Change
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

  checkStatPoints()

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
  end
end


function takeInputEvents()
  local clicks = self.clickEvents
  self.clickEvents = {}
  return clicks
end

function updateLevel()
  self.xp = player.currency("experienceorb")
  if self.xp < 100 then
    player.consumeCurrency("experienceorb",self.xp)
    player.addCurrency("experienceorb",100)
    self.xp = 100
    self.level = 1
    player.addCurrency("currentlevel",1)
  else
    self.newLevel = math.floor(math.sqrt(self.xp/100))
    while self.newLevel > self.level do
      player.addCurrency("currentlevel", 1)
      player.addCurrency("statpoint", 1)
      self.level = self.level+1
    end
    widget.setText("statslayout.statpointsleft",player.currency("statpoint"))
    updateStats()
  end
  updateBottomBar()
end

function updateBottomBar()
  self.toNext = 2*self.level*100+100
  widget.setText("levelLabel", "Level " .. tostring(self.level))
  widget.setText("xpLabel",tostring(math.floor((self.xp-self.level^2*100))) .. "/" .. tostring(self.toNext))
  widget.setProgress("experiencebar",(self.xp-self.level^2*100)/self.toNext)
end

function removeLayouts()
  widget.setVisible("overviewlayout",false)
  widget.setVisible("statslayout",false)
  widget.setVisible("classeslayout",false)
  widget.setVisible("affinitieslayout",false)
end

function changeToOverview()
    widget.setText("tabLabel", "Overview")
    widget.setVisible("overviewlayout", true)
end

function changeToStats()
    updateStats()
    widget.setText("tabLabel", "Stats Tab")
    widget.setVisible("statslayout", true)
end

function changeToClasses()
    widget.setText("tabLabel", "Classes Tab")
    widget.setVisible("classeslayout", true)
end

function changeToAffinities()
    widget.setText("tabLabel", "Affinities Tab")
    widget.setVisible("affinitieslayout", true)
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

function changeStatDescription(name)
  if name == "strength" then widget.setText("statslayout.statdescription", "Each point in Strength increases your Block Meter by 1 and damage with all Melee Weapons by 2%.") end
  if name == "agility" then widget.setText("statslayout.statdescription", "Each point in Agility increases Speed by 3% and Jump Height by 1%.") end
  if name == "vitality" then widget.setText("statslayout.statdescription", "Each point in Vitality increases Max Health by 2.") end
  if name == "vigor" then widget.setText("statslayout.statdescription", "Each point in Vigor increases Max Energy by 2.") end
  if name == "intelligence" then widget.setText("statslayout.statdescription", "Each point in Intelligence increases Energy Recharge Rate by 1% and damage with Magic Weapons by 2%.") end
  if name == "endurance" then widget.setText("statslayout.statdescription", "Each point in Endurance increases Resistance to all damage by 2%.") end
  if name == "dexterity" then widget.setText("statslayout.statdescription", "Each point in Dexterity increases damage with all One-Handed Weapons, Guns, Bows, and Thrown Weapons by 2%.") end
  if name == "default" then widget.setText("statslayout.statdescription", "Click a stat's icon to see what occurs when that stat is raised.") end
end

function enableStatButtons(enable)
  widget.setButtonEnabled("statslayout.raisestrength", enable)
  widget.setButtonEnabled("statslayout.raisedexterity", enable)
  widget.setButtonEnabled("statslayout.raiseendurance", enable)
  widget.setButtonEnabled("statslayout.raiseintelligence", enable)
  widget.setButtonEnabled("statslayout.raisevigor", enable)
  widget.setButtonEnabled("statslayout.raisevitality", enable)
  widget.setButtonEnabled("statslayout.raiseagility", enable)
end


function resetSkillBook()
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

