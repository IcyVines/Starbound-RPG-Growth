function init()
  script.setUpdateDelta(1)
  self.wasOnGround = mcontroller.onGround()
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
end