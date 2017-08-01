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

  self.sounds = config.getParameter("sounds")
  self.color = "white"
  self.pane = pane
  
  self.mpos = {0,0}

  self.xp = 0
  self.level = 1
  self.strength = 0
  self.intelligence = 0
  self.dexterity = 0
  self.endurance = 0
  self.agility = 0
  self.vitality = 0
  self.vigor = 0
  self.class = 0
    --[[
    0: No Class
    1: Knight
    2: Ninja
    3: Rogue
    4: Wizard
    5: Soldier
    6: Explorer
    ]]
  self.affinity = 0
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
    updateBottomBar()

end

function dismissed()
  for soundName,sound in pairs(self.sounds) do
    if soundName ~= "success" then
      pane.stopAllSounds(sound)
    end
  end
  player.consumeCurrency("skillbookopen", player.currency("skillbookopen"))
end

function update(dt)
  if not world.sendEntityMessage(player.id(), "holdingSkillBook"):result() then
    self.pane.dismiss()
  end

  if player.currency("experienceorb") ~= self.xp then
    updateBottomBar()
  end

  if player.currency("statpoint") == 0 then
    enableStatButtons(false)
  elseif player.currency("statpoint") ~= 0 then
    enableStatButtons(true)
  end

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

function updateBottomBar()
  self.xp = player.currency("experienceorb")
  self.level = math.floor(math.sqrt(self.xp/100))
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
  name = string.gsub(name,"raise","") .. "point"
  --player.addCurrency(name)
  changeStatDescription(name)
end

function checkStatDescription(name)
  name = string.gsub(name,"icon","")
  uncheckStatIcons(name)
  changeStatDescription(name)
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
  widget.setText("statslayout.statdescription", name)
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
  player.consumeCurrency("statpoint", player.currency("statpoint"))
end

  --pane.playSound(self.sounds.dispatch, -1)
  --pane.stopAllSounds(self.sounds.dispatch)
  --widget.setFontColor("connectingLabel", config.getParameter("errorColor"))

