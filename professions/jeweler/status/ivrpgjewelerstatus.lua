require "/scripts/ivrpgutil.lua"
require "/scripts/vec2.lua"

function init()
  script.setUpdateDelta(5)
  self.jewelry = config.getParameter("jewelry", {})
  self.id = entity.id()
end

function update(dt)
  --[[for jewel,value in pairs(self.jewelry) do
  	if value.required == status.stat(jewel) then
  		local params = unpack(value.parameters)
  		status[value.status](params)
  	end
  end]]

  local movementAbility = status.statPositive("activeMovementAbilities")

  if status.stat("ivrpghermesanklet") == 2 and mcontroller.falling() and not movementAbility then
  	mcontroller.setYVelocity(math.max(mcontroller.yVelocity(), -10))
  end

  status.setPersistentEffects("ivrpgsoulfireanklet", {{stat = "lavaImmunity", amount = (status.stat("ivrpgsoulfireanklet") == 2 and not movementAbility) and 1 or 0}})
  
  if status.stat("ivrpgriptideanklet") == 2 then
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
  		--sb.logInfo(mcontroller.xVelocity())
  		--sb.logInfo(sb.printJson(mcontroller.baseParameters(), 1))
  	end
  end

end

function uninit()
  status.clearPersistentEffects("ivrpgsoulfireanklet")
end