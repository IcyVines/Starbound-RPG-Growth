require "/scripts/util.lua"

function init()
  quest.setCompletionText("RPG Growth is phasing out the usage of this quest. Please do not worry that it has been completed.")
  quest.setFailureText("RPG Growth is phasing out the usage of this quest. Please do not worry that it has been failed.")
  quest.fail()
end

function update(dt)
  
end
