function init()
	self.velocity = effect.duration() or 10
  mcontroller.setYVelocity(self.velocity)
  effect.modifyDuration(-(self.velocity - 0.2))
end

function update(dt)
	mcontroller.controlApproachYVelocity(-self.velocity, 200)
end