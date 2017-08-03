require "/scripts/keybinds.lua"

function init()
	Bind.create("f", function() sb.logInfo("You pressed the F key!") end)
end

--function uninit()
 	--tech.setParentDirectives()
--end

--function update(args)

--end
