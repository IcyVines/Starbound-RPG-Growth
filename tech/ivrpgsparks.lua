require "/scripts/vec2.lua"
require "/scripts/keybinds.lua"

function init()
  isShrunk = false
  self.transformedMovementParameters = config.getParameter("movementParameters")
  self.basePoly = mcontroller.baseParameters().standingPoly
  Bind.create("f", printStats)
end

function update(args)
  if isShrunk then
    mcontroller.controlParameters(self.transformedMovementParameters)
  end
end

function printStats()
  if isShrunk then
    tech.setParentDirectives()
    tech.setParentOffset({0, 0})
    isShrunk = false
  else
    tech.setParentDirectives("scalenearest=0.5")
    tech.setParentOffset({0, positionOffset()})
    isShrunk = true
  end

  --[[self.id = entity.id()

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
  self.dexterity = world.entityCurrency(self.id,"dexteritypoint")]]

end

function positionOffset()
  return minY(self.basePoly) - minY(self.transformedMovementParameters.collisionPoly) + 1.25
end

function minY(poly)
  local lowest = 0
  for _,point in pairs(poly) do
    if point[2] < lowest then
      lowest = point[2]
    end
  end
  return lowest
end

function uninit()
   --tech.setParentDirectives()
end
