require "/scripts/util.lua"

function init()
	self.removed = true
end

function update(dt)
	--sb.logInfo("Quest Test. Oh and dt: " .. dt)
	if status.statPositive("ivrpgmultiplayerxp") then
		if self.removed then
			player.giveItem({ "experienceorb", status.stat("ivrpgmultiplayerxp")})
			self.removed = false
		end
	elseif not self.removed then
		self.removed = true
	end

end
