function removeContact(id)
  if entity.id() == id then
    projectile.die()
  end
end

function update(dt)
  local strength = world.entityCurrency(projectile.sourceEntity(), "strengthpoint") or 1
  projectile.setPower(strength + 14)
end
