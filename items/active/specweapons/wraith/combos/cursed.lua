function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())

  script.setUpdateDelta(5)
  self.damageTypes = {"poison","fire", "demonic"}
  self.tickDamagePercentage = 0.025
  self.instantDamagePercentage = 0.125
  self.durationTimer = 5.0
  self.tickTime = 1.0
  self.tickTimer = self.tickTime
  self.random = math.random(1,5)
  self.applied = false
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  self.durationTimer = self.durationTimer - dt
  if self.durationTimer <= 0 then effect.expire() end

  if self.random == 1 then 
    damageOverTime(dt)
  elseif self.random == 2 then
    instantDamage()
  elseif self.random == 3 then
    applySlow()
    effect.setParentDirectives(string.format("fade=5588DD=%.1f", (self.tickTimer + 4) * 0.2))
  elseif self.random == 4 then
    if not self.applied then armorDebuff() end
    effect.setParentDirectives(string.format("fade=AA88AA=%.1f", (self.tickTimer + 4) * 0.2))
  else
    if not self.applied then
      self.durationTimer = 2.5
      self.applied = true
    end
    hover()
  end
end

function uninit()
  effect.setParentDirectives()
end

function damageOverTime(dt)
  animator.setParticleEmitterActive("drips", true)
  local random = math.random(1,3)
  dotDamageType = self.damageTypes[random]

  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
      damageSourceKind = dotDamageType,
      sourceEntityId = entity.id()
    })
  end

  effect.setParentDirectives(string.format("fade=AA88CC=%.1f", self.tickTimer * 0.4))
end

function instantDamage()
  status.applySelfDamageRequest({
    damageType = "IgnoresDef",
    damage = math.floor(status.resourceMax("health") * self.instantDamagePercentage) + 1,
    damageSourceKind = "electric",
    sourceEntityId = effect.sourceEntity()
  })

  effect.expire()
end

function applySlow()
  if not self.applied then
    effect.addStatModifierGroup({
      {stat = "jumpModifier", amount = -0.3}
    })
  end
  mcontroller.controlModifiers({
    groundMovementModifier = 0.4,
    speedModifier = 0.5,
    airJumpModifier = 0.7
  })
  self.applied = true
end

function armorDebuff()
  effect.addStatModifierGroup({
    {stat = "physicalResistance", amount = -0.1},
    {stat = "demonicResistance", amount = -0.75},
    {stat = "poisonResistance", amount = -0.5},
    {stat = "fireResistance", amount = -0.25},
    {stat = "electricResistance", amount = -0.15},
    {stat = "iceResistance", amount = -0.2},
    {stat = "shadowResistance", amount = -0.5}
  })
  self.applied = true
end

function hover()
  mcontroller.controlApproachVelocity({0,5 * math.max(self.tickTimer, 0)}, 2000)
end