require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.id = effect.sourceEntity()

  self.energyRegen = config.getParameter("energyRegenPercent", 0.1)
  self.speedModifier = config.getParameter("speedModifier", 1.2)
  self.jumpModifier = config.getParameter("jumpModifier", 1.2)
  self.blossoming = config.getParameter("blossoming", false)

  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  --animator.setParticleEmitterActive("embers", true)
end


function update(dt)

	if self.blossoming then
		mcontroller.controlModifiers({
			airJumpModifier = self.jumpModifier,
			speedModifier = self.speedModifier
		})
		status.modifyResourcePercentage("energy", dt * self.energyRegen / 5)
	end
  --Effect Expires if Specialization is no longer correct.
  --Must keep this for every Ability, but change the specttype and classtype!!!
  if world.entityCurrency(self.id, "spectype") ~= 3 or world.entityCurrency(self.id, "classtype") ~= 1 then
    effect.expire()
  end

end

function uninit()

end
