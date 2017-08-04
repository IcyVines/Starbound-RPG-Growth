require "/scripts/vec2.lua"
require "/scripts/keybinds.lua"

function init()
	Bind.create("f", printStats)
end

function update(args)

end

function printStats()
	self.id = entity.id()
	self.strength = world.entityCurrency(self.id, "strengthpoint")
	self.agility = world.entityCurrency(self.id,"agilitypoint")
	self.vitality = world.entityCurrency(self.id,"vitalitypoint")
	self.vigor = world.entityCurrency(self.id,"vigorpoint")
	self.intelligence = world.entityCurrency(self.id,"intelligencepoint")
	self.endurance = world.entityCurrency(self.id,"endurancepoint")
	self.dexterity = world.entityCurrency(self.id,"dexteritypoint")

	sb.logInfo("Strength: " .. tostring(self.strength))
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
	sb.logInfo("foodDelta: " .. status.stat("foodDelta"))

end

function uninit()
 	--tech.setParentDirectives()
end
