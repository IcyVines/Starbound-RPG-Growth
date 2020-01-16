function removeAura(id)
  if entity.id() == id then
    projectile.die()
  end
end

function init()
  mcontroller.applyParameters({
    collisionEnabled = false
  })
end
