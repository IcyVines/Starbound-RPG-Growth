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

  self.xp = player.currency("experienceorb")
  --self.level = sqrt(self.xp/100)
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

  self.state:update(dt)
end

function updateBookTab()
  if widget.getChecked("bookTabs.0") then
    widget.setText("tabLabel", "Overview")
  elseif widget.getChecked("bookTabs.1") then
    widget.setText("tabLabel", "Stats Tab")
  elseif widget.getChecked("bookTabs.2") then
    widget.setText("tabLabel", "Classes Tab")
  elseif widget.getChecked("bookTabs.3") then
    widget.setText("tabLabel", "Affinities Tab")
  end
end


function takeInputEvents()
  local clicks = self.clickEvents
  self.clickEvents = {}
  return clicks
end


  --pane.playSound(self.sounds.dispatch, -1)
  --pane.stopAllSounds(self.sounds.dispatch)
  --widget.setFontColor("connectingLabel", config.getParameter("errorColor"))

