require "/scripts/keybinds.lua"

function init()
  self.active = false
  self.rotations = config.getParameter("rotations", 3)
  self.rotationTime = config.getParameter("rotationTime", 0.2)
  self.flipTime = self.rotations * self.rotationTime
  self.flipTimer = 0
  self.cooldownTime = config.getParameter("cooldownTime", 0)
  self.cooldownTimer = self.cooldownTime
  self.flipMovementParameters = config.getParameter("flipMovementParameters")
  self.jumpDuration = config.getParameter("jumpDuration")
  self.jumpVelocity = config.getParameter("jumpVelocity")
  self.crouchDuration = config.getParameter("crouchDuration")
  self.crouchTimer = 0
  self.projectileTime = config.getParameter("projectileTime", 0.1)
  self.projectileTimer = 0
  self.rechargeTimer = 0
  self.energyUsage = config.getParameter("energyUsage")
  Bind.create("g", attemptActivation)
end

function attemptActivation()
  if self.cooldownTimer == 0
     and not status.statPositive("activeMovementAbilities")
     and status.overConsumeResource("energy", self.energyUsage) then
    self.crouchTimer = self.crouchDuration
    self.jumpTimer = self.jumpDuration
    status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  end
end


function update(args)

  if self.crouchTimer > 0 then
    status.addPersistentEffects("ivrpgswirlingpetal", {{stat = "invulnerable", amount = 1}})
    mcontroller.controlModifiers({
      movementSuppressed = true
    })
    tech.setParentState("Duck")
    self.crouchTimer = math.max(self.crouchTimer - args.dt, 0)
    if self.crouchTimer == 0 then
      self.facingDirection = mcontroller.facingDirection()
      tech.setParentState()
      self.active = true
      animator.playSound("spin", -1)
    end
  end

  if self.active then
    self.flipTimer = self.flipTimer + args.dt
    mcontroller.controlParameters(self.flipMovementParameters)

    if self.projectileTimer == 0 then
      local xPosition = mcontroller.xPosition()
      local yPosition = mcontroller.yPosition()
      world.spawnProjectile("ivrpgdazinggas", {xPosition, yPosition}, entity.id(), {0,0}, false)
      world.spawnProjectile("ivrpgdazinggas", {xPosition, yPosition - 1.5}, entity.id(), {0,0}, false)
      world.spawnProjectile("ivrpgdazinggas", {xPosition, yPosition + 1.5}, entity.id(), {0,0}, false)
      self.projectileTimer = self.projectileTime
    end

    if self.jumpTimer > 0 then
      self.jumpTimer = self.jumpTimer - args.dt
      mcontroller.setVelocity({self.jumpVelocity[1] * self.facingDirection, self.jumpVelocity[2]})
    end
    mcontroller.setRotation(-math.pi * 2 * self.facingDirection * (self.flipTimer / self.rotationTime))
    if self.flipTimer >= self.flipTime or (self.flipTimer > 0.1 and mcontroller.onGround()) then
      reset()
      mcontroller.setRotation(0)
    end
  end

  if self.projectileTimer > 0 then
    self.projectileTimer = math.max(0, self.projectileTimer - args.dt)
  end

  if self.cooldownTimer > 0 then
    self.cooldownTimer = math.max(self.cooldownTimer - args.dt, 0)
    if self.cooldownTimer == 0 then
      animator.playSound("recharge")
      self.rechargeTimer = 0.1
      tech.setParentDirectives("?fade=FF99BB=0.25")
    end
  end

  if self.rechargeTimer > 0 then
    self.rechargeTimer = math.max(self.rechargeTimer - args.dt, 0)
    if self.rechargeTimer == 0 then
      tech.setParentDirectives()
    end
  end
end

function reset()
  self.active = false
  self.cooldownTimer = self.cooldownTime
  self.flipTimer = 0
  animator.stopAllSounds("spin")
  tech.setParentState()
  tech.setToolUsageSuppressed(false)
  status.clearPersistentEffects("weaponMovementAbility")
  status.clearPersistentEffects("ivrpgswirlingpetal")
  tech.setParentDirectives()
end

function uninit()
  reset()
end
