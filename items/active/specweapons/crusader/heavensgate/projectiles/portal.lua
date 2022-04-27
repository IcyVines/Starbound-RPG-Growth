function init()
	local a = config.getParameter("animationCycle", 0)
	
	message.setHandler("timeToLive", function(_, isLocal, n, min)
		if isLocal then
			local v = n + a
			if min then v = math.min(projectile.timeToLive(), v) end
			projectile.setTimeToLive(v)
		end
	end)
end
