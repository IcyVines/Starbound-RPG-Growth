require "/tech/doubletap.lua"
require "/scripts/keybinds.lua"

function init()

  --dash
  self.airDashing = false
  self.dashDirection = 0
  self.dashTimer = 0
  self.dashCooldownTimer = 0
  self.rechargeEffectTimer = 0
  self.dashControlForce = config.getParameter("dashControlForce")
  self.dashSpeed = config.getParameter("dashSpeed")
  self.dashDuration = config.getParameter("dashDuration")
  self.dashCooldown = config.getParameter("dashCooldown")
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=FFF466FF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)
  --
  --sprint
  self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
  self.sprintControlForce = config.getParameter("sprintControlForce")
  self.sprintSpeedModifier = config.getParameter("sprintSpeedModifier")
  --
  self.groundOnly = config.getParameter("groundOnly")
  self.stopAfterDash = config.getParameter("stopAfterDash")
  --
  self.dashType = status.statusProperty("ivrpgenhanceddash", "sprint")
  changeDashType()
  Bind.create("g", changeDashType)
  Bind.create("jumping", endDashAlt)

  self.doubleTap = DoubleTap:new({"left", "right"}, config.getParameter("maximumDoubleTapTime"), function(dashKey)
      local direction = dashKey == "left" and -1 or 1
      if self.dashType == "dash" then
        if self.dashTimer == 0
          and self.dashCooldownTimer == 0
          and groundValid()
          and not mcontroller.crouching()
          and not status.statPositive("activeMovementAbilities") then  
          startDash(direction)
        end
      else
        if not self.dashDirection
          and groundValid()
          and mcontroller.facingDirection() == direction
          and not mcontroller.crouching()
          and not status.resourceLocked("energy")
          and not status.statPositive("activeMovementAbilities") then
          startSprint(direction)
        end
      end
    end)
end

function changeDashType()
  if not status.statPositive("activeMovementAbilities") and self.dashCooldownTimer == 0 then
    status.removeEphemeralEffect("explorermovement" .. self.dashType)
    status.setStatusProperty("ivrpgenhanceddash", self.dashType)
    self.dashType = self.dashType == "dash" and "sprint" or "dash"
    self.groundOnly = self.dashType == "sprint"
    status.addEphemeralEffect("explorermovement" .. self.dashType, math.huge)
  end
end

function uninit()
  status.clearPersistentEffects("movementAbility")
  status.removeEphemeralEffect("explorermovementsprint")
  status.removeEphemeralEffect("explorermovementdash")
  animator.setAnimationState("dashing", "off")
  animator.setParticleEmitterActive("dashParticles", false)
  tech.setParentDirectives()
end

function update(args)

  self.moreEnhanced = status.statPositive("ivrpgucmoreenhanced")

  if self.moreEnhanced then
    mcontroller.controlModifiers({
      airJumpModifier = 1.25
    })
  end

  if self.dashCooldownTimer > 0 then
    self.dashCooldownTimer = math.max(0, self.dashCooldownTimer - args.dt)
    if self.dashCooldownTimer == 0 then
      self.rechargeEffectTimer = self.rechargeEffectTime
      tech.setParentDirectives(self.rechargeDirectives)
      animator.playSound("recharge")
    end
  end

  if self.rechargeEffectTimer > 0 then
    self.rechargeEffectTimer = math.max(0, self.rechargeEffectTimer - args.dt)
    if self.rechargeEffectTimer == 0 then
      tech.setParentDirectives()
    end
  end
  --
  self.doubleTap:update(args.dt, args.moves)
  --
  if self.dashTimer > 0 and self.dashType == "dash" then
    mcontroller.controlApproachVelocity({self.dashSpeed * self.dashDirection, 0}, self.dashControlForce)
    mcontroller.controlMove(self.dashDirection, true)

    if self.airDashing then
      mcontroller.setYVelocity(0)
    end
    mcontroller.controlModifiers({jumpingSuppressed = true})

    animator.setFlipped(mcontroller.facingDirection() == -1)

    self.dashTimer = math.max(0, self.dashTimer - args.dt)

    if self.dashTimer == 0 then
      endDash()
    end
  end
  --
  if self.dashDirection and self.dashType == "sprint" then
    if args.moves[self.dashDirection > 0 and "right" or "left"]
        and not mcontroller.liquidMovement()
        and not dashBlocked() then

      if mcontroller.facingDirection() == self.dashDirection then
        if status.overConsumeResource("energy", self.energyCostPerSecond * args.dt) then
          mcontroller.controlModifiers({speedModifier = self.sprintSpeedModifier})

          animator.setAnimationState("dashing", "on")
          animator.setParticleEmitterActive("sprintParticles", true)
        else
          endSprint()
        end
      else
        animator.setAnimationState("dashing", "off")
        animator.setParticleEmitterActive("sprintParticles", false)
      end
    else
      endSprint()
    end
  end
end

function groundValid()
  return mcontroller.groundMovement() or not self.groundOnly
end

function dashBlocked()
  return mcontroller.velocity()[1] == 0
end

function startSprint(direction)

  if self.moreEnhanced then
    self.sprintSpeedModifier = config.getParameter("sprintSpeedModifier") + 4.0
    self.sprintControlForce = config.getParameter("sprintControlForce") + 500
  else
    self.sprintSpeedModifier = config.getParameter("sprintSpeedModifier")
    self.sprintControlForce = config.getParameter("sprintControlForce")
  end

  self.dashDirection = direction
  status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  animator.setFlipped(self.dashDirection == -1)
  animator.setAnimationState("dashing", "on")
  animator.setParticleEmitterActive("sprintParticles", true)
end

function endSprint(direction)
  status.clearPersistentEffects("movementAbility")

  if self.stopAfterDash then
    local movementParams = mcontroller.baseParameters()
    local currentVelocity = mcontroller.velocity()
    if math.abs(currentVelocity[1]) > movementParams.runSpeed then
      mcontroller.setVelocity({movementParams.runSpeed * self.dashDirection, 0})
    end
    mcontroller.controlApproachXVelocity(self.dashDirection * movementParams.runSpeed, self.sprintControlForce)
  end

  animator.setAnimationState("dashing", "off")
  animator.setParticleEmitterActive("sprintParticles", false)

  self.dashDirection = nil
end

function startDash(direction)
  self.dashDirection = direction
  if self.moreEnhanced then
    self.dashTimer = self.dashDuration + 0.25
  else
    self.dashTimer = self.dashDuration
  end
  self.airDashing = not mcontroller.groundMovement()
  status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  animator.playSound("startDash")
  animator.setAnimationState("dashing", "on")
  animator.setParticleEmitterActive("dashParticles", true)
end

function endDash()
  status.clearPersistentEffects("movementAbility")
  self.dashTimer = 0
  if self.stopAfterDash then
    local movementParams = mcontroller.baseParameters()
    local currentVelocity = mcontroller.velocity()
    if math.abs(currentVelocity[1]) > movementParams.runSpeed then
      mcontroller.setVelocity({movementParams.runSpeed * self.dashDirection, 0})
    end
    mcontroller.controlApproachXVelocity(self.dashDirection * movementParams.runSpeed, self.dashControlForce)
  end

  self.dashCooldownTimer = self.dashCooldown

  animator.setAnimationState("dashing", "off")
  animator.setParticleEmitterActive("dashParticles", false)
end

function endDashAlt()
  if self.dashTimer > 0 and self.moreEnhanced then
    endDash()
  end
end