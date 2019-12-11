require "/scripts/vec2.lua"

function init()
  --[[effect.addStatModifierGroup({
    {stat = "physicalResistance", amount = -.25},
    {stat = "poisonResistance", amount = -.25},
    {stat = "iceResistance", amount = -.25},
    {stat = "electricResistance", amount = -.25},
    {stat = "fireResistance", amount = -.25},
    {stat = "novaResistance", amount = -.25},
    {stat = "demonicResistance", amount = -.25},
    {stat = "holyResistance", amount = -.25},
    {stat = "shadowResistance", amount = -.15},
    {stat = "cosmicResistance", amount = -.15},
    {stat = "radiationResistance", amount = -.25}
  })]]
  activateVisualEffects()
  effect.setParentDirectives("fade=770077=0.25")
  self.sourceId = effect.sourceEntity()
  self.id = entity.id()
  self.burstTimer = 0
  self.damageTakenUpdate = 5
  if world.entityExists(self.sourceId) then burstTowardsTether() end
end

function update(dt)
  self.burstTimer = math.max(self.burstTimer - dt, 0)
  mcontroller.controlModifiers({
    airJumpModifier = 0.15,
    speedModifier = 0.15
  })
  if world.entityExists(self.sourceId) then
    mcontroller.controlApproachVelocity(vec2.mul(vec2.norm(world.distance(mcontroller.position(), world.entityPosition(self.sourceId))), -20), 100)
  else
    effect.expire()
  end

  shareDamage()

end

function burstTowardsTether()
  mcontroller.setVelocity(vec2.add(vec2.mul(world.distance(mcontroller.position(), world.entityPosition(self.sourceId)), -4), mcontroller.velocity()))
end

function activateVisualEffects()
  --animator.setParticleEmitterOffsetRegion("bloodparticles", mcontroller.boundBox())
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
  --animator.burstParticleEmitter("smoke")
end

function shareDamage()
  local notifications = nil
  notifications, self.damageTakenUpdate = status.damageTakenSince(self.damageTakenUpdate)
  if notifications then
    for _,notification in ipairs(notifications) do
      if notification.healthLost and notification.healthLost > 0 then
        world.sendEntityMessage(self.sourceId, "shareTetherDamage", notification.healthLost, self.id, notification.sourceEntityId)
      end
    end
  end

end


function uninit()
  
end
