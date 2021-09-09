require "/scripts/vec2.lua"

function update()
  local rune = animationConfig.animationParameter("rune")
  if rune then
    localAnimator.spawnParticle(rune)
  end
end