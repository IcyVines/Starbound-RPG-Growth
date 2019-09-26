
function init()
	script.setUpdateDelta(60)
	self.replace = false
end

function update()
	self.position = entity.position()
	self.direction = object.direction()
	local lightLevel = world.lightLevel(self.position) or 0
	if lightLevel == 0 then
		self.replace = true
		object.smash(true)
	end
	
end

function uninit()
	if self.replace then world.placeObject("ivrpgcainesmimic", self.position, self.direction) end
end