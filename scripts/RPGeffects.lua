

function init()
    script.setUpdateDelta(1)
end

function update(dt)

  self.strength = player.currency("strengthpoint")
  widget.setText("statslayout.strengthamount",self.strength)
  self.agility = player.currency("agilitypoint")
  widget.setText("statslayout.agilityamount",self.agility)
  self.vitality = player.currency("vitalitypoint")
  widget.setText("statslayout.vitalityamount",self.vitality)
  self.vigor = player.currency("vigorpoint")
  widget.setText("statslayout.vigoramount",self.vigor)
  self.intelligence = player.currency("intelligencepoint")
  widget.setText("statslayout.intelligenceamount",self.intelligence)
  self.endurance = player.currency("endurancepoint")
  widget.setText("statslayout.enduranceamount",self.endurance)
  self.dexterity = player.currency("dexteritypoint")  
  status.addPersistentEffect( "RPGeffect",
  {

	-- Strength
	{stat = "maxShieldHealth", baseMultiplier = 1 + strength*.02},

	-- Intelligence
	{stat = "energyRegenPercentageRate", baseMultiplier = 1 + .02*intelligence},
	{stat = "energyRegenBlockTime", baseMultiplier = .98*intelligence},

	-- Dexterity

	-- Endurance
	{stat = "protection", baseMultiplier = 1 + endurance*.02},

	-- Vitality
	{stat = "maxHealth", baseMultiplier = 1 + vigor*.02},

	-- Vigor
	{stat = "maxEnergy", baseMultiplier = 1 + intelligence*.02}

  })

  -- Agility
  mcontroller.controlModifiers({
	     speedModifier = 1 + agility*.02,
    	airJumpModifier = 1 + agility*.02
  })

end
