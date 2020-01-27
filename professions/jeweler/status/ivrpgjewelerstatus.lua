require "/scripts/ivrpgutil.lua"
require "/scripts/vec2.lua"

function init()
  script.setUpdateDelta(5)
  self.id = entity.id()
  local jewelry = config.getParameter("jewelry", {})
  local blueprints = {}
  for _,mat in ipairs(jewelry.materials) do
    for _,t in ipairs(jewelry.types) do
      table.insert(blueprints, "ivrpg" .. mat .. t)
    end
  end
  for _,suf in ipairs(jewelry.names) do
    table.insert(blueprints, "ivrpg" .. suf)
  end
  world.sendEntityMessage(self.id, "giveBlueprint", blueprints)
end

function update(dt)
  local movementAbility = status.statPositive("activeMovementAbilities")
  local time = world.timeOfDay()

  status.setPersistentEffects("ivrpgjewelereffects", {
    {stat = "lavaImmunity", amount = (status.stat("ivrpgsoulfireanklet") == 2) and 1 or 0},
    {stat = "fireStatusImmunity", amount = (status.stat("ivrpgsapphirebelt") == 1) and 1 or 0},
    {stat = "electricStatusImmunity", amount = (status.stat("ivrpgfluxring") == 2) and 1 or 0},
    {stat = "iceStatusImmunity", amount = (status.stat("ivrpgrubybelt") == 1) and 1 or 0},
    {stat = "poisonStatusImmunity", amount = (status.stat("ivrpgpurifyingpendant") == 1) and 1 or 0},
    {stat = "demonicStatusImmunity", amount = (status.stat("ivrpgsaintlycharm") == 1) and 1 or 0},
    {stat = "holyStatusImmunity", amount = (status.stat("ivrpgemeraldbelt") == 1) and 1 or 0},
    {stat = "protection", amount = (status.stat("ivrpgmemorylocket") == 1) and 5 or 0},
    {stat = "ivrpgvigorscaling", amount = (status.stat("ivrpgmechanicalwatch") == 1) and 0.05 or 0},
    {stat = "ivrpgintelligencescaling", amount = (status.stat("ivrpghitechwatch") == 1) and 0.05 or 0},
    {stat = "ivrpgdexterityscaling", amount = (status.stat("ivrpgeaglesearring") == 2) and 0.05 or 0},
    {stat = "powerMultiplier", amount = ((status.stat("ivrpgdusksearring") == 2 and time > 0.5) or (status.stat("ivrpgdawnsearring") == 2 and time < 0.5)) and 0.25 or 0}
  })

  if status.stat("ivrpgsolarpoweredwatch") == 1 then
    status.modifyResource("energy", 3 * dt)
  end

  if status.stat("ivrpgspitefulring") == 2 then
    status.addEphemeralEffect("thorns", 2, self.id)
  end
  
  if status.stat("ivrpghermesanklet") == 2 then
    if mcontroller.falling() and not movementAbility then
      mcontroller.setYVelocity(math.max(mcontroller.yVelocity(), -30))
    end
    status.addEphemeralEffect("nofalldamage", 1)
  elseif status.stat("ivrpgriptideanklet") == 2 then
  	mcontroller.controlParameters({
  		liquidForce = 150,
  		liquidFriction = 6,
  		liquidImpedance = 0.1,
  		liquidJumpProfile = {
  			jumpSpeed = 50
  		}
  	})

  	if isInLiquid() then
  		local xVel = mcontroller.xVelocity()
  		local neg = xVel < 0 and -1 or 1
  		mcontroller.setXVelocity(neg * math.min(math.abs(xVel + xVel / 2), 50))
  	end
  end

end

function uninit()
  status.clearPersistentEffects("ivrpgjewelereffects")
end