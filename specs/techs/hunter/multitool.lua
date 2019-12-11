require "/scripts/keybinds.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"
require "/tech/doubletap.lua"

function init()
  self.id = entity.id()
  --self.active = false
  self.elementMod = 1
  self.elementList = {"fire", "electric", "nova"}
  self.element = self.elementList[self.elementMod]
  self.newMod = {2,3,1}
  --self.statusList = {"ivrpgsear", "ivrpgnovastatus", "ivrpgoverload"}
  self.cooldownTimer = 5

  self.transformFadeTimer = 0
  self.transformFadeTime = config.getParameter("transformFadeTime", 0.3)
  self.directives = ""

  self.grenadeConfig = config.getParameter("grenadeConfig", {})
  self.grenadeCooldownTimer = 6
  self.grenadeRechargeDirectives = config.getParameter("rechargeDirectives", "?fade=99CC99FF=0.25")

  self.airDashing = false
  self.dashDirection = 0
  self.dashTimer = 0
  self.dashCooldownTimer = 0
  self.rechargeEffectTimer = 0

  self.dashControlForce = config.getParameter("dashControlForce")
  self.dashSpeed = config.getParameter("dashSpeed")
  self.dashDuration = config.getParameter("dashDuration")
  self.dashCooldown = config.getParameter("dashCooldown")
  self.stopAfterDash = config.getParameter("stopAfterDash")
  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=CCCCFFFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)

  self.doubleTap = DoubleTap:new({"left", "right"}, config.getParameter("maximumDoubleTapTime"), function(dashKey)
      if self.dashTimer == 0
          and self.dashCooldownTimer == 0
          and not mcontroller.crouching()
          and not status.statPositive("activeMovementAbilities") then

        startDash(dashKey == "left" and -1 or 1)
      end
    end)

  animator.setAnimationState("dashing", "off")

  Bind.create("specialTwo", toggle)
end

function toggle()
  if not self.shiftHeld then
    if self.grenadeCooldownTimer == 0 and (not status.statPositive("activeMovementAbilities")) and status.overConsumeResource("energy", 50) then lobSmoke() end
    return
  end
  if status.statPositive("activeMovementAbilities") then return end
  self.elementMod = self.newMod[self.elementMod]
  self.element = self.elementList[self.elementMod]
  animator.playSound(self.element .. "Activate")
end

function lobSmoke()
  self.grenadeConfig.powerMultiplier = status.stat("powerMultiplier")
  self.grenadeConfig.power = 20
  self.grenadeConfig.speed = 40
  self.grenadeCooldownTimer = 6
  world.spawnProjectile("ivrpghuntersmoke" .. self.element, mcontroller.position(), self.id, world.distance(tech.aimPosition(), mcontroller.position()), false, self.grenadeConfig)
end

function uninit()
  tech.setParentDirectives()
  status.setStatusProperty("ivrpgmultitoolenergy", nil)
  status.clearPersistentEffects("movementAbility")
  --status.removeEphemeralEffect("ivrpgimmaculateshieldstatus")
end

function update(args)
  --self.directives = "?fade=" .. self.borderList[self.elementMod] .. "=0.25"

  self.dt = args.dt
  self.shiftHeld = not args.moves["run"]
  self.specialHeld = args.moves["special2"]
  self.hDirection = args.moves["left"] and -1 or (args.moves["right"] and 1 or 0)
  self.vDirection = args.moves["up"] and 1 or (args.moves["down"] and -1 or 0)

  status.setStatusProperty("ivrpgmultitoolenergy", self.element)

  --self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  --updateTransformFade(self.dt)

  -- Dodging

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

  self.doubleTap:update(args.dt, args.moves)

  if self.dashTimer > 0 then
    mcontroller.controlApproachVelocity({self.dashSpeed * self.dashDirection, 0}, self.dashControlForce)
    mcontroller.controlMove(self.dashDirection, true)

    if self.airDashing then
      mcontroller.setYVelocity(0)
    end
    --mcontroller.controlModifiers({jumpingSuppressed = true})

    animator.setFlipped(mcontroller.facingDirection() == -1)

    self.dashTimer = math.max(0, self.dashTimer - args.dt)

    if self.dashTimer == 0 then
      endDash()
    end
  end

  -- End Dodging

  if self.grenadeCooldownTimer > 0 then
    self.grenadeCooldownTimer = math.max(0, self.grenadeCooldownTimer - args.dt)
    if self.grenadeCooldownTimer == 0 then
      self.rechargeEffectTimer = self.rechargeEffectTime
      tech.setParentDirectives(self.grenadeRechargeDirectives)
      animator.playSound("rechargeGrenade")
    end
  end

end

function startDash(direction)
  self.dashDirection = direction
  self.dashTimer = self.dashDuration
  self.airDashing = not mcontroller.groundMovement()
  status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}, {stat = "invulnerable", amount = 1}})
  status.addEphemeralEffect("ivrpgcamouflage", 0.25, self.id)
  if self.element == "electric" then
    status.addEphemeralEffect("energyregen", 0.25, self.id)
    status.addEphemeralEffect("glow", 2, self.id)
  elseif self.element == "nova" then
    status.addEphemeralEffect("ivrpgcamouflage", 1, self.id)
    status.addEphemeralEffect("lowgrav", 3, self.id)
  else
    status.addEphemeralEffect("rage", 1, self.id)
    status.addEphemeralEffect("runboost", 2, self.id)
  end
  animator.playSound("startDash")
  animator.setAnimationState("dashing", "on")
  animator.setParticleEmitterActive(self.element .. "DashParticles", true)
end

function endDash()
  status.clearPersistentEffects("movementAbility")

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
  animator.setParticleEmitterActive(self.element .. "DashParticles", false)
end
