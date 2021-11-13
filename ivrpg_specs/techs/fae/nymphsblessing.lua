require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/keybinds.lua"
require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  self.jumpsLeft = config.getParameter("multiJumpCount")
  self.rechargeEffectTimer = 0
  self.dashTimer = 0
  self.dashCooldownTimer = 0

  self.dashControlForce = config.getParameter("dashControlForce")
  self.dashSpeed = config.getParameter("dashSpeed")
  self.dashDuration = config.getParameter("dashDuration")
  self.dashCooldown = config.getParameter("dashCooldown")

  self.rechargeDirectives = config.getParameter("rechargeDirectives", "?fade=FF991AFF=0.25")
  self.rechargeEffectTime = config.getParameter("rechargeEffectTime", 0.1)

  self.vDirectionLocked = 0
  self.hDirectionLocked = 0
  self.previousFace = 1

  self.crouchTimer = 0
  self.damageUpdate = 1
  self.position = mcontroller.position()

  animator.setParticleEmitterOffsetRegion("hoverParticles", mcontroller.boundBox())
  animator.scaleTransformationGroup("wings", {2, 2})

  refreshJumps()
  Bind.create({jumping = true, onGround = false, liquidPercentage = 0}, doMultiJump)
end

function uninit()
  status.clearPersistentEffects("movementAbility")
  status.clearPersistentEffects("ivrpgrooted")
  animator.setAnimationState("dashing", "off")
  animator.setAnimationState("hover", "off")
  animator.setParticleEmitterActive("dashParticles", false)
  animator.resetTransformationGroup("wings")
  tech.setParentDirectives()
  tech.setParentState()
end

function update(args)

  local jumpActivated = args.moves["jump"] and not self.lastJump
  self.lastJump = args.moves["jump"]
  self.shiftHeld = not args.moves["run"]
  self.dt = args.dt
  self.float = args.moves["up"]
  self.crouch = args.moves["down"]

  --Find Directional Input
  self.hDirection = 0
  self.vDirection = 0
  local lrInput
  if args.moves["left"] and not args.moves["right"] then
    self.hDirection = -1
    lrInput = "left"
  elseif args.moves["right"] and not args.moves["left"] then
    self.hDirection = 1
    lrInput = "right"
  end
  if args.moves["up"] and not args.moves["down"] then
    self.vDirection = 1
  elseif args.moves["down"] and not args.moves["up"] then
    self.vDirection = -1
  end

  if self.dashTimer > 0 then
    if self.vDirectionLocked == 0 or self.hDirectionLocked == 0 then
      mcontroller.setVelocity({self.dashSpeed * self.hDirectionLocked, self.dashSpeed * self.vDirectionLocked})
    else
      mcontroller.setVelocity({self.dashSpeed/1.41 * self.hDirectionLocked, self.dashSpeed/1.41 * self.vDirectionLocked})
    end
    mcontroller.controlMove(self.hDirectionLocked, true)
    mcontroller.controlModifiers({
      jumpingSuppressed = true,
      gravityEnabled = false
    })
    self.dashTimer = math.max(0, self.dashTimer - args.dt)
    if self.dashTimer <= 0 or mcontroller.groundMovement() or mcontroller.liquidMovement() then
      endDash()
    end
  end

  animator.setFlipped(mcontroller.facingDirection() == -1)

  if self.float and canFloat() then
    mcontroller.setXVelocity(util.clamp(mcontroller.xVelocity(), self.hDirection == 1 and 0 or -15, self.hDirection == -1 and 0 or 15))
    mcontroller.controlApproachYVelocity(0, self.dashControlForce * 0.75)
    tech.setParentState("Fly")
    animator.setAnimationState("hover", "on")
    local targets = enemyQuery(mcontroller.position(), 10, {includedTypes = {"monster"}}, entity.id(), true)
    if targets then
      for _,id in ipairs(targets) do
        local health = world.entityHealth(id)
        if world.entityExists(id) and health and (health[1] < status.resourceMax("health") or health[1] < health[2]/3) then
          world.sendEntityMessage(id, "makeFriendly", 2, entity.id())
        end
      end
    end
  else
    tech.setParentState()
    animator.setAnimationState("hover", "off")
  end

  if mcontroller.crouching() or (self.rooted and self.crouch) then
    self.crouchTimer = self.crouchTimer + self.dt
    if self.crouchTimer >= 3 or self.rooted then
      if not self.rooted then self.position = mcontroller.position() end
      self.rooted = true
      status.setPersistentEffects("ivrpgrooted", {
        {stat = "grit", amount = 3}
      })
      mcontroller.setPosition(self.position)
      status.addEphemeralEffect("regeneration2", 0.25)
      tech.setParentState("Duck")
    end
  else
    self.crouchTimer = 0
    self.rooted = false
    tech.setParentState()
    status.clearPersistentEffects("ivrpgrooted")
  end

  --animator.setGlobalTag("flipped", mcontroller.facingDirection() == -1 and "?flipx" or "")

  if mcontroller.groundMovement() or mcontroller.liquidMovement() then
    refreshJumps()
    --status.removeEphemeralEffect("nofalldamage")
  end

end

function doMultiJump()
  if not canMultiJump() then
    return
  end
  --mcontroller.controlJump(true)
  startDash()
  --animator.burstParticleEmitter("jumpParticles")
  self.jumpsLeft = self.jumpsLeft - 1
  --animator.playSound("multiJumpSound")
end

function canMultiJump()
  return self.jumpsLeft > 0
      and not mcontroller.jumping()
      and not mcontroller.canJump()
      and not mcontroller.liquidMovement()
      and not status.statPositive("activeMovementAbilities")
      and math.abs(world.gravity(mcontroller.position())) > 0
end

function canFloat()
  return not mcontroller.jumping()
      and not mcontroller.canJump()
      and not mcontroller.liquidMovement()
      and not status.statPositive("activeMovementAbilities")
      and status.overConsumeResource("energy", self.dt * 10)
end

function refreshJumps()
  self.jumpsLeft = config.getParameter("multiJumpCount")
end

function startDash()
  self.vDirectionLocked = (not self.shiftHeld and self.vDirection == 0) and 1 or self.vDirection
  self.hDirectionLocked = self.hDirection
  self.dashTimer = self.dashDuration
  status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  mcontroller.setVelocity({0, 0})
  animator.playSound("startDash")
  animator.setAnimationState("dashing", "on")
  animator.setParticleEmitterActive("dashParticles", true)
  spawnSmoke()
end

function endDash()
  status.clearPersistentEffects("movementAbility")
  local movementParams = mcontroller.baseParameters()
  local currentVelocity = mcontroller.velocity()
  animator.setAnimationState("dashing", "off")
  animator.setParticleEmitterActive("dashParticles", false)
end

function spawnSmoke()
  world.spawnProjectile("ivrpgdazinggas", {mcontroller.xPosition()+1, mcontroller.yPosition()+1}, entity.id(), {0,0}, false, {})
  world.spawnProjectile("ivrpgdazinggas", {mcontroller.xPosition()-1, mcontroller.yPosition()+1}, entity.id(), {0,0}, false, {})
  world.spawnProjectile("ivrpgdazinggas", {mcontroller.xPosition()+1, mcontroller.yPosition()-1}, entity.id(), {0,0}, false, {})
  world.spawnProjectile("ivrpgdazinggas", {mcontroller.xPosition()-1, mcontroller.yPosition()-1}, entity.id(), {0,0}, false, {})
end

function updateDamageTaken()
  local notifications = nil
  notifications, self.damageUpdate = status.damageTakenSince(self.damageUpdate or 3)
  if self.crouchTimer > 0 and notifications then
    for _,notification in pairs(notifications) do
      if notification.healthLost > 0 then
        self.crouchTimer = 0
      end
    end
  end
end