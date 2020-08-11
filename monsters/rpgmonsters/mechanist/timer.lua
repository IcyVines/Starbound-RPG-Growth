local monsterOldInit = init
local monsterOldUpdate = update

function init()
	self.rpg_timer = 60
  monsterOldInit()
end

function update(dt)
	self.rpg_timer = self.rpg_timer - dt
	if self.rpg_timer <= 0 then
		monster.setDropPool(nil)
	  --monster.setDeathParticleBurst(nil)
	  monster.setDeathSound("break")
	  --self.deathBehavior = nil
	  self.shouldDie = true
	  --status.setPrimaryDirectives(string.format("?multiply=ffffff%02x", 0))
	  status.setResource("health", 0)
	  --mcontroller.translate({0, -100000})
	end
  monsterOldUpdate(dt)
end
