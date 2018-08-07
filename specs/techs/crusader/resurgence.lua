require "/tech/doubletap.lua"

function init()
  self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
  self.dashControlForce = config.getParameter("dashControlForce")
  self.dashSpeedModifier = config.getParameter("dashSpeedModifier")
  self.groundOnly = config.getParameter("groundOnly")
  self.stopAfterDash = config.getParameter("stopAfterDash")
  self.cooldownTime = config.getParameter("cooldownTime")
  self.speedTime = config.getParameter("speedTime")
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=a8a323FF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)
  self.damageUpdate = 5
  self.cooldownTimer = 0
  self.rechargeEffectTimer = 0
  self.id = entity.id()
  self.doubleTap = DoubleTap:new({"left", "right"}, config.getParameter("maximumDoubleTapTime"), function(dashKey)
      local direction = dashKey == "left" and -1 or 1
      if not self.dashDirection
          and groundValid()
          and mcontroller.facingDirection() == direction
          and not mcontroller.crouching()
          and not status.resourceLocked("energy")
          and not status.statPositive("activeMovementAbilities") then

        startDash(direction)
      end
    end)
end

function uninit()
  status.clearPersistentEffects("movementAbility")
  status.removeEphemeralEffect("crusaderbashattack")
  status.removeEphemeralEffect("ivrpgresurgencecooldown")
  animator.setAnimationState("dashing", "off")
  animator.setParticleEmitterActive("dashParticles", false)
end

function update(args)
  self.doubleTap:update(args.dt, args.moves)

  if self.dashDirection then
    if args.moves[self.dashDirection > 0 and "right" or "left"]
        and not mcontroller.liquidMovement()
        and not dashBlocked() then

      local agility = world.entityCurrency(entity.id(), "agilitypoint")
      if mcontroller.facingDirection() == self.dashDirection then
        if status.overConsumeResource("energy", (self.energyCostPerSecond - (agility^2 / 75.0)) * args.dt) then
          mcontroller.controlModifiers({speedModifier = self.dashSpeedModifier})

          animator.setAnimationState("dashing", "on")
          animator.setParticleEmitterActive("dashParticles", true)
        else
          endDash()
        end
      else
        animator.setAnimationState("dashing", "off")
        animator.setParticleEmitterActive("dashParticles", false)
      end
    else
      endDash()
    end
  end

  if self.cooldownTimer + self.speedTime > self.cooldownTime then
    mcontroller.controlModifiers({
      speedModifier = 1.5
    })
  end

  checkResurgence()

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(self.cooldownTimer - args.dt, 0)
    if self.cooldownTimer == 0 then
      tech.setParentDirectives(self.rechargeDirectives)
      animator.playSound("recharge")
      self.rechargeEffectTimer = self.rechargeEffectTime
    end
  end

  if self.rechargeEffectTimer > 0 then
    self.rechargeEffectTimer = math.max(self.rechargeEffectTimer - args.dt, 0)
    if self.rechargeEffectTimer == 0 then
      tech.setParentDirectives()
    end
  end

end

function checkResurgence()
  local notifications = nil
  notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate)
  if notifications then
    for _,notification in pairs(notifications) do
      if notification.healthLost > status.resource("health") then
        if self.cooldownTimer == 0 then
          self.cooldownTimer = self.cooldownTime
          status.addEphemeralEffect("ivrpgresurgencecooldown", self.cooldownTime)
          status.modifyResourcePercentage("health", 1)
          status.modifyResourcePercentage("energy", 1)
          local vigor = world.entityCurrency(self.id, "vigorpoint")
          world.spawnProjectile("ivrpgresurgenceexplosion", mcontroller.position(), self.id, {0,0}, true, {power = 5 * vigor^1.05, knockback = 50})
        end
      end
    end
  end
end

function groundValid()
  return mcontroller.groundMovement() or not self.groundOnly
end

function dashBlocked()
  return mcontroller.velocity()[1] == 0
end

function startDash(direction)
  self.dashDirection = direction
  status.setPersistentEffects("movementAbility", {
    {stat = "activeMovementAbilities", amount = 1},
    {stat = "grit", amount = 1}
  })
  status.addEphemeralEffect("crusaderbashattack", math.huge)
  animator.setFlipped(self.dashDirection == -1)
  animator.setAnimationState("dashing", "on")
  animator.setParticleEmitterActive("dashParticles", true)
end

function endDash(direction)
  status.clearPersistentEffects("movementAbility")
  status.removeEphemeralEffect("crusaderbashattack")

  if self.stopAfterDash then
    local movementParams = mcontroller.baseParameters()
    local currentVelocity = mcontroller.velocity()
    if math.abs(currentVelocity[1]) > movementParams.runSpeed then
      mcontroller.setVelocity({movementParams.runSpeed * self.dashDirection, 0})
    end
    mcontroller.controlApproachXVelocity(self.dashDirection * movementParams.runSpeed, self.dashControlForce)
  end

  animator.setAnimationState("dashing", "off")
  animator.setParticleEmitterActive("dashParticles", false)

  self.dashDirection = nil
end
