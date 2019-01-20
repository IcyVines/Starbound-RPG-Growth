function trigger()
  projectile.die()
end

function init()
	self.timer = 1
	self.modTimer = 0
	self.power = projectile.power()
	self.mod = (math.floor(self.modTimer)%2)*2 - 1
	self.power = 1
	self.x = 1
	self.y = 0
end

function update(dt)
	if self.timer > 0 then
		mcontroller.approachVelocity({0,0}, 100)
		self.timer = math.max(self.timer-dt, 0)
		if self.timer == 0 then
			self.modTimer = 0
			self.mod = (math.floor(self.modTimer)%2)*2 - 1
		end
	else
		mcontroller.approachVelocity({self.x * self.mod, self.y * self.mod}, 1)
	end

	local mod = (math.floor(self.modTimer)%2)*2 - 1
	if self.mod ~= mod then
		self.mod = mod
		mcontroller.setVelocity({0,0})
	end
	self.modTimer = self.modTimer + dt
end

function powerUp(power)
	projectile.setPower(self.power * (1 + power/2))
end