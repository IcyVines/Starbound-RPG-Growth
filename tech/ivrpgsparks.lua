require "/scripts/vec2.lua"
require "/scripts/keybinds.lua"

function init()
	Bind.create("f", printStats)
end

function update(args)

end

function printStats()
	self.id = entity.id()

	self.classType = world.entityCurrency(self.id, "classtype")
	self.strengthBonus = self.classType == 1 and 1.15 or (self.classType == 5 and 1.1 or (self.classType == 4 and 1.05 or 1))
	self.agilityBonus = self.classType == 3 and 1.1 or (self.classType == 5 and 1.1 or (self.classType == 6 and 1.1 or 1))
	self.vitalityBonus = self.classType == 4 and 1.15 or (self.classType == 1 and 1.1 or (self.classType == 6 and 1.05 or 1))
	self.vigorBonus = self.classType == 6 and 1.15 or (self.classType == 2 and 1.1 or 1)
	self.intelligenceBonus = self.classType == 2 and 1.2 or 1
	self.enduranceBonus = self.classType == 1 and 1.1 or (self.classType == 4 and 1.05 or (self.classType == 6 and 1.05 or 1))
	self.dexterityBonus = self.classType == 3 and 1.2 or (self.classType == 5 and 1.15 or (self.classType == 4 and 1.1 or 1))

  	sb.logInfo("Strength Bonus: "..self.strengthBonus)
  	sb.logInfo("Agility Bonus: "..self.agilityBonus)
  	sb.logInfo("Dexterity Bonus: "..self.dexterityBonus)
  	sb.logInfo("Vitality Bonus: "..self.vitalityBonus)
  	sb.logInfo("Vigor Bonus: "..self.vigorBonus)
  	sb.logInfo("Intelligence Bonus: "..self.intelligenceBonus)
  	sb.logInfo("Endurance Bonus: "..self.enduranceBonus)

	self.strength = world.entityCurrency(self.id, "strengthpoint")
	self.agility = world.entityCurrency(self.id,"agilitypoint")
	self.vitality = world.entityCurrency(self.id,"vitalitypoint")
	self.vigor = world.entityCurrency(self.id,"vigorpoint")
	self.intelligence = world.entityCurrency(self.id,"intelligencepoint")
	self.endurance = world.entityCurrency(self.id,"endurancepoint")
	self.dexterity = world.entityCurrency(self.id,"dexteritypoint")

	--[[sb.logInfo("Strength: " .. tostring(self.strength))
	sb.logInfo("Dexterity: " .. tostring(self.dexterity))
	sb.logInfo("Agility: " .. tostring(self.agility))
	sb.logInfo("Intelligence: " .. tostring(self.intelligence))
	sb.logInfo("Endurance: " .. tostring(self.endurance))
	sb.logInfo("Vitality: " .. tostring(self.vitality))
	sb.logInfo("Vigor: " .. tostring(self.vigor))

	sb.logInfo("shieldHealth: " .. status.stat("shieldHealth"))
	sb.logInfo("physicalResistance: " .. status.stat("physicalResistance"))
	sb.logInfo("energyRegenPercentageRate: " .. status.stat("energyRegenPercentageRate"))
	sb.logInfo("energyRegenBlockTime: " .. status.stat("energyRegenBlockTime"))
	sb.logInfo("fallDamageMultiplier: " .. status.stat("fallDamageMultiplier"))
	sb.logInfo("critChance: " .. status.stat("critChance"))
	sb.logInfo("fireTime: " .. status.stat("fireTime"))
	sb.logInfo("poisonResistance: " .. status.stat("poisonResistance"))
	sb.logInfo("fireResistance: " .. status.stat("fireResistance"))
	sb.logInfo("electricResistance: " .. status.stat("electricResistance"))
	sb.logInfo("iceResistance: " .. status.stat("iceResistance"))
	sb.logInfo("shadowResistance: " .. status.stat("shadowResistance"))
	sb.logInfo("cosmicResistance: " .. status.stat("cosmicResistance"))
	sb.logInfo("radioactiveResistance: " .. status.stat("radioactiveResistance"))
	sb.logInfo("grit: " .. status.stat("grit"))
	sb.logInfo("foodDelta: " .. status.stat("foodDelta"))]]

end

function uninit()
 	--tech.setParentDirectives()
end
