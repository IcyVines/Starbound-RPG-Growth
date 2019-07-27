function init()
  effect.setParentDirectives("border=1;BF330033;BF330033")
  effect.addStatModifierGroup({
    {stat = "powerMultiplier", effectiveMultiplier = 0.75}
  })
  self.length = effect.duration()
  self.sourceId = effect.sourceEntity()
  self.doubled = false
  if self.sourceId then
    self.message = world.sendEntityMessage(self.sourceId, "hasStat", "ivrpgucvikingfuneral")
  end
end

function update(dt)
  if effect.duration() and world.liquidAt({mcontroller.xPosition(), mcontroller.yPosition() - 1}) then
    effect.expire()
  end
  status.addEphemeralEffect("burning", effect.duration())
  if self.message:result() and not self.doubled then
    effect.modifyDuration(self.length)
    status.addEphemeralEffect("burning", effect.duration())
    self.doubled = true
  end

end

function uninit()
  
end
