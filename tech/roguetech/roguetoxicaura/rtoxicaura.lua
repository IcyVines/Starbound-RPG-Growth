function init()
  --effect.setParentDirectives("border=3;e8981900;a36809")
  --self.damageProjectileType = config.getParameter("damageProjectileType") or "armorthornburst"
  --self.timeConfig = {
    --timeToLive = 15
  --}
  --self.aura = world.spawnProjectile(self.damageProjectileType, mcontroller.position(), entity.id(), {0, 0}, true, self.timeConfig)
end

function update(dt)
  
end

function uninit()
	--deactivateZone()
end

function deactivateZone()
    if self.aura then
      world.entityQuery(mcontroller.position(), 1,
        {
         withoutEntityId = entity.id(),
         includedTypes = {"projectile"},
         callScript = "removeZone",
         callScriptArgs = {self.aura}
        }
      )
      self.aura = nil
    end
end