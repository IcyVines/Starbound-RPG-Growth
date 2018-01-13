require "/scripts/util.lua"

function init()
	--self.removed = true
end

function update(dt)
	--sb.logInfo("Quest Test. Oh and dt: " .. dt)
	--[[if status.statPositive("ivrpgmultiplayerxp") then
		if self.removed then
			player.giveItem({ "experienceorb", status.stat("ivrpgmultiplayerxp")})
			self.removed = false
		end
	elseif not self.removed then
		self.removed = true
	end

	--admin
	if player.isAdmin() then
		if not status.statPositive("admin") then status.addPersistentEffect("ivrpgadmin", {stat = "admin", amount = 1}) end
	else
		status.clearPersistentEffects("ivrpgadmin")
	end]]

end
