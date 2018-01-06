require "/scripts/util.lua"

function init()

end

function update(dt)
	--sb.logInfo("Quest Test. Oh and dt: " .. dt)
	if status.statPositive("ivrpgmultiplayerxp") then
		player.giveItem({ "experienceorb", status.stat("ivrpgmultiplayerexp")})
	end
end
