require "/scripts/keybinds.lua"

function init()
  self.id = entity.id()
  self.active = false
  self.elementMod = 1
  self.elementList = {"fire", "ice", "electric"}
  self.element = self.elementList[self.elementMod]
  self.newMod = {2,3,1}
  self.statusList = {"ivrpgsear", "ivrpgembrittle", "ivrpgoverload"}
  self.borderList = {"bb552233", "2288cc22", "88882233"}
  self.projectileList = {"dragonfirelarge", "iceshockwave", "balllightning"}
  self.projectileList2 = {"molotovflame", "icetrail", "electrictrail"}
  self.charging = false
  self.chargeTimer = 5
  self.cooldownTimer = 0
  Bind.create("Up", toggle)
  Bind.create("primaryFire", action1)
  Bind.create("altFire", action1alt)
end

function toggle()
  self.elementMod = self.newMod[self.elementMod]
  self.element = self.elementList[self.elementMod]
  animator.playSound(self.element .. "Activate")
end

function uninit()
  tech.setParentDirectives()
  --status.removeEphemeralEffect("ivrpgimmaculateshieldstatus")
end

function update(args)
  tech.setParentDirectives("?fade=" .. self.borderList[self.elementMod] .. "=0.5")
  status.setPersistentEffects("ivrpgattune", {
    {stat = self.element .. "StatusImmunity", amount = 1},
    {stat = self.element .. "Resistance", amount = 3},
    {stat = "lavaImmunity", amount = self.element == "fire" and 1 or 0}
  })

  self.dt = args.dt
  self.shiftHeld = not args.moves["run"]
  self.specialHeld = args.moves["special2"]
  if self.specialHeld and self.cooldownTimer == 0 then
    if self.shiftHeld or self.charging then
      charge()
    else
      action2()
    end
  else
    self.charging = false
    self.chargeTimer = 5
  end
  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
end

function action1(skipCheck)
  if (not skipCheck) and world.entityHandItem(self.id, "primary") then return end
  world.spawnProjectile(self.projectileList[self.elementMod], {mcontroller.xPosition(),mcontroller.yPosition()-1}, self.id, world.distance(tech.aimPosition(), mcontroller.position()), false, {powerMultiplier = status.stat("powerMultiplier"), speed = 30})
end

function action1alt()
  if not world.entityHandItem(self.id, "alt") then
    action1(true)
  end
end

function action2()
  world.spawnProjectile(self.projectileList2[self.elementMod], {mcontroller.xPosition(),mcontroller.yPosition()-1}, self.id, world.distance(tech.aimPosition(), mcontroller.position()), false, {powerMultiplier = status.stat("powerMultiplier"), speed = 10})
  cooldown(1)
end

function charge( ... )
  self.charging = true
  self.chargeTimer = self.chargeTimer - self.dt
  if self.chargeTimer == 0 then
    release()
  end
end

function release()
  cooldown(10)
end

function cooldown(time)
  self.cooldownTimer = time
end