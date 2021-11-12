require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  self.regenTimer = 0
  self.gravityTimer = 0
  self.gravityTime = config.getParameter("gravityTime", 1)
  self.regenTime = config.getParameter("regenTime", 5)
  self.movementParams = mcontroller.baseParameters()
  animator.setParticleEmitterOffsetRegion("feathers", mcontroller.boundBox())
end


function update(dt)

  local oldGravityMultiplier = self.movementParams.gravityMultiplier or 1
  local newGravityMultiplier = 0.25 * oldGravityMultiplier

  if mcontroller.jumping() then
    self.gravityTimer = self.gravityTime
  end

  if self.gravityTimer > 0 then
    self.gravityTimer = math.max(self.gravityTimer - dt, 0)
    animator.setParticleEmitterActive("feathers", true)
    mcontroller.controlParameters({
      gravityMultiplier = newGravityMultiplier
    })
  else
    animator.setParticleEmitterActive("feathers", false)
  end
  
  if not mcontroller.onGround() and not isInLiquid() then
    self.regenTimer = self.regenTimer + dt
  else
    self.regenTimer = 0
  end

  if self.regenTimer >= self.regenTime then
    status.addEphemeralEffect("regeneration4", 1)
  end

  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 4 or world.entityCurrency(self.id, "classtype") ~= 1 then
    effect.expire()
  end
end

function reset()
  animator.setParticleEmitterActive("feathers", false)
  --status.clearPersistentEffects("ivrpgbetweenworlds")
  --animator.stopAllSounds("ghostly")
  status.setPrimaryDirectives()
end

function isInLiquid()
  local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
  return world.liquidAt(mouthposition)
  --[[return (world.liquidAt(mouthPosition)) and
    ((mcontroller.liquidId()== 1) or 
    (mcontroller.liquidId()== 5) or 
    (mcontroller.liquidId()== 6) or 
    (mcontroller.liquidId()== 12) or 
    (mcontroller.liquidId()== 43) or 
    (mcontroller.liquidId()== 55) or 
    (mcontroller.liquidId()== 58) or
    (mcontroller.liquidId()== 60) or 
    (mcontroller.liquidId()== 69))]]
end

function uninit()
  reset()
end
