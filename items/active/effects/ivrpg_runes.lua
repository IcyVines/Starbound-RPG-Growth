require "/scripts/vec2.lua"

function update()
  local rune = animationConfig.animationParameter("rune")
  if rune then
    localAnimator.spawnParticle(rune)
  end
  localAnimator.clearDrawables()
  local barrier = animationConfig.animationParameter("barrier")
  if barrier then
    localAnimator.addDrawable({image = "/items/active/weapons/ivrpg_grimoire/abilities/greater/barrier_front"..barrier.modifier..tostring(barrier.frame), position = barrier.position}, "Player+1")
    localAnimator.addDrawable({image = "/items/active/weapons/ivrpg_grimoire/abilities/greater/barrier_back"..barrier.modifier..tostring(barrier.frame).."?flipy?flipx", position = vec2.add(barrier.position, {0,-0.25})}, "Player-1")
  end
end