function trigger()
  projectile.die()
end

function init()
  self.timer = 1
  self.modTimer = 0
  self.power = projectile.power()
  self.mod = (math.floor(self.modTimer)%2)*2 - 1
  self.x = 1
  self.y = 0
end

function update(dt)
  if self.timer > 0 then
    mcontroller.approachVelocity({0,0}, 100)
    self.timer = math.max(self.timer-dt, 0)
    if self.timer == 0 then
      self.modTimer = 0
      self.mod = (math.floor(self.modTimer)%2)*2 - 1
      self.rotation = mcontroller.rotation()
    end
  else
    --mcontroller.approachVelocity({self.x * self.mod, self.y * self.mod}, 1)
    mcontroller.approachVelocityAlongAngle(self.rotation, self.mod, 1)
  end

  local mod = (math.floor(self.modTimer)%2)*2 - 1
  if self.mod ~= mod then
    self.mod = mod
    self.bonus = 100
    mcontroller.setVelocity({0,0})
  else
    self.bonus = 1
  end
  
  local timerMod = dt
  if self.modTimer < 4 then
    timerMod = dt
  elseif self.modTimer < 9 then
    timerMod = dt*2
  else
    timerMod = dt*3
  end
  self.modTimer = self.modTimer + timerMod
end

function powerUp(power, powerMultiplier)
  powerMultiplier = (powerMultiplier > projectile.powerMultiplier()) and powerMultiplier/projectile.powerMultiplier() or 1
  projectile.setPower(self.power * powerMultiplier * (1 + power/2))
end