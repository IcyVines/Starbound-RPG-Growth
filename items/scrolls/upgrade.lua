function init()
  self.rpg_levelRequirements = root.assetJson("/ivrpgLevelRequirements.config")
  if player.currency("experienceorb") < self.rpg_levelRequirements.affinityUpgrade^2 * 100 then return end
  self.statType = {"strength", "dexterity", "endurance", "intelligence"}
  self.statName = "agilitypoint" --default, set to agility just in case
  self.affinity = player.currency("affinitytype")
end

function activate(fireMode, shiftHeld)
  if item.name() == "ivrpgscrollinfernal" and self.affinity == 1 then
    self.statName = "strengthpoint"
  elseif item.name() == "ivrpgscrolltoxic" and self.affinity == 2 then
    self.statName = "dexteritypoint"
  elseif item.name() == "ivrpgscrollcryo" and self.affinity == 3 then
    self.statName = "endurancepoint"
  elseif item.name() == "ivrpgscrollarc" and self.affinity == 4 then
    self.statName = "intelligencepoint"
  else
    --No Upgrade!!
    return
  end
  player.addCurrency("affinitytype", 4)
  addStatPoints()
  item.consume(1)
end

function uninit()
end

function addStatPoints()
  self.current = 50 - player.currency(self.statName)
  if self.current < 5 then
    --Adds Stat Points if Bonus Stat is near maxed!
    player.addCurrency("statpoint", 5 - self.current)
  end
  player.addCurrency(self.statName, 5)
end