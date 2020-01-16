
function init()

end

function update(args)
  local active = false
  targetIds = world.playerQuery(entity.position(), 4)
  if targetIds then
    for _,id in ipairs(targetIds) do
      active = true
    end
  end
  object.setInteractive(active)
end

function onInteraction(args)
  target = args.sourceId
  animator.setAnimationState("bite", "on")
  if target and world.entityExists(target) then
    local position = entity.position()
    position = {position[1] + object.direction()/2, position[2] + 1}
    world.spawnProjectile("invisibleprojectile", position, entity.id(), {0,0}, true, {damageType = "IgnoresDef", damageTeam = {type = "enemy"}, power = world.entityHealth(target)[2]/2 + 1, timeToLive = 0.2})
  end
end

function die()
  animator.setSoundVolume("die", 0.8)
    animator.setSoundPitch("die", 1.2)
  animator.playSound("die")
end