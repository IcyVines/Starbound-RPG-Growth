require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = projectile.sourceEntity()
  --animator.setParticleEmitterOffsetRegion("sparks", mcontroller.boundBox())
  --animator.setParticleEmitterActive("sparks", true)
end

function update(dt)

end

function uninit()
  world.spawnMonster("bunnycritter", mcontroller.position(), {damageTeamType = "ghostly"})
end
