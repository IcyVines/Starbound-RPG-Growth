function init()
  script.setUpdateDelta(1)
  self.wasOnGround = mcontroller.onGround()
  self.experience = world.entityCurrency(entity.id(), "experienceorb")
  calculateLevelTags()
end

function update(dt)
  local animationMod = status.statPositive("ivrpgmeltyblood") and "Melty" or ""
  local creatureMod = status.statusProperty("ivrpgshapeshiftC", "") == "wisper" and "" or status.statusProperty("ivrpgshapeshiftC", "")
  animationMod = animationMod .. creatureMod

  if self.wasOnGround and mcontroller.jumping() and not mcontroller.onGround() then
    self.wasOnGround = false
    animator.burstParticleEmitter("jump" .. animationMod)
  end

  if not mcontroller.onGround() and not mcontroller.groundMovement() then
    self.wasOnGround = false
  end

  if mcontroller.onGround() and not self.wasOnGround then
    self.wasOnGround = true
    animator.burstParticleEmitter("land" .. animationMod)
  end

  if status.statPositive("activeMovementAbilities") or not status.statusProperty("ivrpglevelbar", false) then
    animator.setAnimationState("level", "off")
  else
    animator.setAnimationState("level", "on")
  end
  local experience = world.entityCurrency(entity.id(), "experienceorb")
  if self.experience ~= experience then
    self.experience = experience
    calculateLevelTags()
  end

end

function calculateLevelTags()
  local level = math.floor(math.sqrt(self.experience/100))
  if level == 50 then
    animator.setGlobalTag("level", "50")
  else
    local minExperience = level^2*100
    local maxExperience = (level+1)^2*100
    local percent = math.floor((self.experience - minExperience) / (maxExperience - minExperience) * 50 + 0.5)
    animator.setGlobalTag("level", tostring(percent))
  end
end