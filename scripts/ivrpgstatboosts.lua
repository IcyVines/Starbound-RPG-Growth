
function init()
  local bounds = mcontroller.boundBox()
  script.setUpdateDelta(10)
end

function update(dt)
  self.id = entity.id()
  self.strength = math.floor(world.entityCurrency(self.id, "strengthpoint")^1.1)
  self.agility = math.floor(world.entityCurrency(self.id,"agilitypoint")^1.1)
  self.vitality = math.floor(world.entityCurrency(self.id,"vitalitypoint"))
  self.vigor = math.floor(world.entityCurrency(self.id,"vigorpoint"))
  self.intelligence = math.floor(world.entityCurrency(self.id,"intelligencepoint")^1.1)
  self.endurance = math.floor(world.entityCurrency(self.id,"endurancepoint")^1.1)
  self.dexterity = math.floor(world.entityCurrency(self.id,"dexteritypoint")^1.1)
  self.classType = world.entityCurrency(self.id, "classtype")
  if self.strength > 0 then
    status.setPersistentEffects( "ivrpgstatboosts",
    {

  	-- Strength
      --Increases Shield Health, Damage with melee weapons, and physical resistance
  	{stat = "shieldHealth", effectiveMultiplier = 1 + self.strength*.02},
    {stat = "physicalResistance", amount = self.strength*.0025},
    --still needs melee weapon bonus damage

  	-- Intelligence
  	{stat = "energyRegenPercentageRate", amount = .05*self.intelligence},
  	{stat = "energyRegenBlockTime", amount = -.01*self.intelligence},
    --still needs magic bonus damage

  	-- Dexterity
    {stat = "fallDamageMultiplier", amount = -self.dexterity*.01},
    {stat = "critChance", amount = math.ceil(self.dexterity/1.46)},
    --{stat = "cooldownTimer", amount = -self.dexterity*.1},
    --still needs one-handed weapon bonus damage

  	-- Endurance
  	{stat = "physicalResistance", amount = self.endurance*.005},
    {stat = "poisonResistance", amount = self.endurance*.0025},
    {stat = "fireResistance", amount = self.endurance*.0025},
    {stat = "electricResistance", amount = self.endurance*.0025},
    {stat = "iceResistance", amount = self.endurance*.0025},
    {stat = "shadowResistance", amount = self.endurance*.0025},
    {stat = "cosmicResistance", amount = self.endurance*.0025},
    {stat = "radioactiveResistance", amount = self.endurance*.0025},
    {stat = "grit", amount = self.endurance*.01}, --not tested

    --Agility
    {stat = "fallDamageMultiplier", amount = -self.agility*.005},

  	-- Vitality
  	{stat = "maxHealth", amount = math.floor(self.vitality^1.1*3)},
    {stat = "foodDelta", amount = math.floor(self.vitality^1.1)*.02}, --not tested

  	-- Vigor
  	{stat = "maxEnergy", amount = math.floor(self.vigor^1.1*3)},
    {stat = "energyRegenPercentageRate", amount = .02*math.floor(self.vigor^1.1)}

    })
  end

  -- Agility
  mcontroller.controlModifiers({
    speedModifier = 1 + self.agility*.02,
    airJumpModifier = 1 + self.agility*.005
  })

  updateClassEffects(self.classType)

end

function updateClassEffects(classType)
  if classType == 0 then
    --No Class
    status.clearPersistentEffects("ivrpgclassboosts")
  elseif classType == 1 then
    --Knight
    status.setPersistentEffects("ivrpgclassboosts",
    {


    })
  elseif classType == 2 then
    --Wizard
    status.setPersistentEffects("ivrpgclassboosts",
    {


    })
  elseif classType == 3 then
    --Ninja
    status.setPersistentEffects("ivrpgclassboosts",
    {


    })
  elseif classType == 4 then
    --Soldier
    status.setPersistentEffects("ivrpgclassboosts",
    {


    })
  elseif classType == 5 then
    --Rogue
    status.setPersistentEffects("ivrpgclassboosts",
    {


    })
  elseif classType == 6 then
    --Explorer
    status.setPersistentEffects("ivrpgclassboosts",
    {


    })
  end 
end

function uninit()
  status.clearPersistentEffects("ivrpgstatboosts")
  status.clearPersistentEffects("ivrpgclassboosts")
end
