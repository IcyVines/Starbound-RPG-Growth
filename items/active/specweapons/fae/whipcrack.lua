require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"
require "/items/active/weapons/weapon.lua"

-- whip primary attack
WhipCrack = WeaponAbility:new()

function WhipCrack:init()
  self.damageConfig.baseDamage = self.chainDps * self.fireTime

  self.weapon:setStance(self.stances.idle)
  animator.setAnimationState("attack", "idle")
  activeItem.setScriptedAnimationParameter("chains", nil)

  self.cooldownTimer = self:cooldownTime()

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end

  self.projectileConfig = self.projectileConfig or {}

  self.chain = config.getParameter("chain")
end

-- Ticks on every update regardless if this is the active ability
function WhipCrack:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.fireMode == "primary" and self:canStartAttack() then
    self:setState(self.windup)
  end
end

function WhipCrack:canStartAttack()
  return not self.weapon.currentAbility and self.cooldownTimer == 0
end

-- State: windup
function WhipCrack:windup()
  self.weapon:setStance(self.stances.windup)

  animator.setAnimationState("attack", "windup")

  util.wait(self.stances.windup.duration)

  self:setState(self.extend)
end

-- State: extend
function WhipCrack:extend()
  self.weapon:setStance(self.stances.extend)

  animator.setAnimationState("attack", "extend")
  animator.playSound("swing")

  util.wait(self.stances.extend.duration)

  animator.setAnimationState("attack", "fire")
  self:setState(self.fire)
end

-- State: fire
function WhipCrack:fire()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  local chainStartPos = vec2.add(mcontroller.position(), activeItem.handPosition(self.chain.startOffset))
  local chainLength = world.magnitude(chainStartPos, activeItem.ownerAimPosition())
  chainLength = math.min(self.chain.length[2], math.max(self.chain.length[1], chainLength))

  self.chain.endOffset = vec2.add(self.chain.startOffset, {chainLength, 0})
  local collidePoint = world.lineCollision(chainStartPos, vec2.add(mcontroller.position(), activeItem.handPosition(self.chain.endOffset)))
  if collidePoint then
    chainLength = world.magnitude(chainStartPos, collidePoint) - 0.25
    if chainLength < self.chain.length[1] then
      animator.setAnimationState("attack", "idle")
      return
    else
      self.chain.endOffset = vec2.add(self.chain.startOffset, {chainLength, 0})
    end
  end

  local chainEndPos = vec2.add(mcontroller.position(), activeItem.handPosition(self.chain.endOffset))

  activeItem.setScriptedAnimationParameter("chains", {self.chain})

  animator.resetTransformationGroup("endpoint")
  animator.translateTransformationGroup("endpoint", self.chain.endOffset)
  animator.burstParticleEmitter("crack")
  animator.playSound("crack")

  self.projectileConfig.power = self:crackDamage()
  self.projectileConfig.powerMultiplier = activeItem.ownerPowerMultiplier()
  self.projectileConfig.actionOnReap = {
    {
      action = "config",
      ["file"] = "/items/active/specweapons/fae/whipcrack/poisonexplosionknockback.config"
    }
  }

  local projectileAngle = vec2.withAngle(self.weapon.aimAngle)
  if self.weapon.aimDirection < 0 then projectileAngle[1] = -projectileAngle[1] end

  world.spawnProjectile(
    self.projectileType,
    chainEndPos,
    activeItem.ownerEntityId(),
    projectileAngle,
    false,
    self.projectileConfig
  )

  local targets = enemyQuery(chainEndPos, 1, {}, activeItem.ownerEntityId(), true)

  local progress = self.stances.fire.duration
  while (self.fireMode == "primary" and (collidePoint or self:pullToTarget(targets)) and chainLength > 2) or progress > 0 do
    if self.damageConfig.baseDamage > 0 then
      self.weapon:setDamage(self.damageConfig, {self.chain.startOffset, {self.chain.endOffset[1] + 0.75, self.chain.endOffset[2]}}, self.fireTime)
    end

    progress = progress - self.dt

    if (collidePoint or self:pullToTarget(targets)) and self.fireMode == "primary" then
      mcontroller.controlApproachVelocity(vec2.mul(world.distance(chainEndPos, mcontroller.position()), 5), 1000)
      status.setPersistentEffects("ivrpgwcrysantha", {
        {stat = "activeMovementAbilities", amount = 1},
        {stat = "fallDamageMultiplier", effectiveMultiplier = 0}
      })
    end

    chainStartPos = vec2.add(mcontroller.position(), activeItem.handPosition(self.chain.startOffset))
    chainLength = world.magnitude(chainStartPos, chainEndPos)
    chainLength = math.min(self.chain.length[2] + 10, math.max(self.chain.length[1], chainLength))
    self.chain.endOffset = vec2.add(self.chain.startOffset, {chainLength, 0})
    activeItem.setScriptedAnimationParameter("chains", {self.chain})
    animator.resetTransformationGroup("endpoint")
    animator.translateTransformationGroup("endpoint", self.chain.endOffset)

    local aimAngle, aimDirection = activeItem.aimAngleAndDirection(self.weapon.aimOffset, chainEndPos)
    --self.weapon.aimAngle = vec2.angle(world.distance(chainEndPos, chainStartPos)) * self.weapon.aimDirection
    self.weapon.aimAngle = aimAngle
    self.weapon.aimDirection = aimDirection

    coroutine.yield()
  end

  if self.fireMode == "primary" and not activeItem.callOtherHandScript("rpg_triggerFinisher", self.weapon.aimAngle) then
    -- Fist Weapon that does not have our finisher script enabled. Try to call its finisher anyway.
    activeItem.callOtherHandScript("triggerComboAttack", 3)
  end

  animator.setAnimationState("attack", "idle")
  activeItem.setScriptedAnimationParameter("chains", nil)

  self.cooldownTimer = self:cooldownTime()
end

function WhipCrack:cooldownTime()
  status.clearPersistentEffects("ivrpgwcrysantha")
  return self.fireTime - (self.stances.windup.duration + self.stances.extend.duration + self.stances.fire.duration)
end

function WhipCrack:uninit(unloaded)
  self.weapon:setDamage()
  status.clearPersistentEffects("ivrpgwcrysantha")
  activeItem.setScriptedAnimationParameter("chains", nil)
end

function WhipCrack:chainDamage()
  return (self.chainDps * self.fireTime) * config.getParameter("damageLevelMultiplier")
end

function WhipCrack:crackDamage()
  return (self.crackDps * self.fireTime) * config.getParameter("damageLevelMultiplier")
end

function WhipCrack:pullToTarget(targets)
  if not targets or #targets == 0 then
    return false
  end

  for _,id in ipairs(targets) do
    if world.entityExists(id) then
      return true
    end
  end
end