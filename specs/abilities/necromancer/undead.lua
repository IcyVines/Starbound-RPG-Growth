require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()
  removeAllAfflictions()
  status.modifyResourcePercentage("health", 1)
  effect.addStatModifierGroup({
  	{stat = "ivrpgundead", amount = 1},
  	{stat = "powerMultiplier", effectiveMultiplier = 2},
  	{stat = "maxHealth", effectiveMultiplier = 2},
    {stat = "armor", effectiveMultiplier = 2},
    {stat = "holyResistance", amount = -1},
    {stat = "demonicResistance", amount = 3},
    {stat = "demonicStatusImmunity", amount = 1}
  })
  effect.setParentDirectives("fade=80709510=0.75")
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", true)
end

function removeAllAfflictions()
  ephStats = util.map(status.activeUniqueStatusEffectSummary(),
    function (elem)
      return elem[1]
    end)

  for _,v in pairs(ephStats) do
    if v ~= "ivrpgundead" then
      status.removeEphemeralEffect(v)
    end
  end
end

function update(dt)
end

function uninit()
	status.modifyResourcePercentage("health", -1)
	world.spawnProjectile("reapeddamageprojectile", mcontroller.position(), self.id)
end
