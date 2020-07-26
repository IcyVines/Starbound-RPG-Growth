require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.runTimer = 0
  self.runTime = 0
  self.stopTime = 0
  self.slideTimer = 0
  self.runDirection = 0
end


function update(dt)
  --mcontroller.controlParameters({normalGroundFriction = 35})
  --sb.logInfo(sb.printJson(mcontroller.baseParameters()))
  if self.slideTimer == 0 then
    self.previousRunDirection = self.runDirection
    self.runDirection = mcontroller.running() and mcontroller.movingDirection() or 0
    self.runTime = self.runTimer
  end

  local collision = world.lineCollision(vec2.add(mcontroller.position(), {self.previousRunDirection, 1}), vec2.add(mcontroller.position(), {self.previousRunDirection, -1}), {"Block", "Dynamic", "Slippery"})

  if self.slideTimer > 0 or (self.previousRunDirection ~= 0 and self.previousRunDirection ~= self.runDirection) or collision then
    self.slideTimer = self.slideTimer + dt
    if mcontroller.onGround() then mcontroller.addMomentum({self.runTimer * self.previousRunDirection, 0}) end
    self.runTimer = math.max(self.runTimer - dt * self.runTime / self.stopTime, 0)
    if self.slideTimer >= self.stopTime or collision then
      self.slideTimer = 0
      self.runDirection = 0
      self.runTimer = 0
      self.stopTime = 0
    end
  elseif (self.previousRunDirection ~= 0 and self.previousRunDirection == self.runDirection) and not collision then
    self.runTimer = math.min(self.runTimer + dt * 10, 100)
    self.stopTime = math.min(self.stopTime + dt / 5, 3)
    if mcontroller.onGround() then mcontroller.addMomentum({self.runTimer * self.runDirection, 0}) end
  end

  status.setPersistentEffects("ivrpginertia", {{stat = "powerMultiplier", baseMultiplier = 1 + math.min(math.abs(mcontroller.xVelocity()) / 100, 1)}})

  if math.abs(mcontroller.xVelocity()) > 30 and collision then
    animator.playSound("thud")
    --world.spawnProjectile("bouldersmashexplosion", vec2.add(mcontroller.position(), {self.previousRunDirection, 0}), self.id, {0,0}, false, {power = 20, powerMultiplier = status.stat("powerMultiplier")})
  end

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 2 or world.entityCurrency(self.id, "classtype") ~= 1 then
    effect.expire()
  end
end

function reset()
  status.setPrimaryDirectives()
  status.clearPersistentEffects("ivrpginertia")
end

function uninit()
  reset()
end
