require "/scripts/util.lua"
require "/scripts/ivrpgutil.lua"

function init()
  if status.isResource("stunned") then
    status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  end
  effect.setParentDirectives("fade=FFFFFF=0.25?border=1;98e81933;68a30933")

  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")

  self.sourceId = effect.sourceEntity()
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.0,
      speedModifier = 0.0,
      airJumpModifier = 0.0,
      movementSuppressed = true,
      facingSuppressed = true,
      jumpingSuppressed = true
  })

  mcontroller.controlParameters({
    collisionEnabled = true
  })

  if status.isResource("stunned") then
    status.setResource("stunned", math.max(status.resource("stunned"), effect.duration()))
  end

  if status.resource("health") == 0 then
    uninit()
  end
end

function uninit()
  effect.setParentDirectives()
  status.setResource("stunned", 0)
  if status.resource("health") <= 0 then
    local targets = friendlyQuery(mcontroller.position(), 20, {}, self.sourceId, true)
    if targets then
      for _,id in ipairs(targets) do
        world.sendEntityMessage(id, "addEphemeralEffect", "regeneration4", math.min(status.resourceMax("health") * 0.01, 5))
      end
    end
  end
end
