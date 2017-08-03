require("/scripts/vec2.lua")

function init()
  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(10)
end

function update(dt)
  self.id = entity.id()
  self.strength = world.entityCurrency(self.id, "strengthpoint")
  self.agility = world.entityCurrency(self.id,"agilitypoint")
  self.vitality = world.entityCurrency(self.id,"vitalitypoint")
  self.vigor = world.entityCurrency(self.id,"vigorpoint")
  self.intelligence = world.entityCurrency(self.id,"intelligencepoint")
  self.endurance = world.entityCurrency(self.id,"endurancepoint")
  self.dexterity = world.entityCurrency(self.id,"dexteritypoint")
  status.setPersistentEffects( "ivrpgstatboosts",
  {

	-- Strength
	--{stat = "maxShieldHealth", baseMultiplier = 1 },--+ self.strength*.02},

	-- Intelligence
	{stat = "energyRegenPercentageRate", baseMultiplier = 1 + .02*self.intelligence},
	{stat = "energyRegenBlockTime", baseMultiplier = .98*self.intelligence},

	-- Dexterity

	-- Endurance
	{stat = "physicalResistance", baseMultiplier = 1 + self.endurance*.02},

	-- Vitality
	{stat = "maxHealth", baseMultiplier = 1 + self.vitality*.02},

	-- Vigor
	{stat = "maxEnergy", baseMultiplier = 1 + self.vigor*.02}

  })

  -- Agility
  mcontroller.controlModifiers({
	     speedModifier = 1 + self.agility*.02,
    	airJumpModifier = 1 + self.agility*.02
  })

end

function uninit()
  status.clearPersistentEffects("ivrpgstatboosts")
end
