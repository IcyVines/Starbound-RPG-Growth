function init()
  script.setUpdateDelta(1)
  local colors = config.getParameter("colors", {})
  animator.setGlobalTag("color", colors[status.statusProperty("ivrpg_npcShield_element", "none")])
end

function update(dt)
  local armor = status.statusProperty("ivrpg_npcShield_tag", "0")
  local sound = status.statusProperty("ivrpg_npcShield_sound", false)
  if sound then
    animator.playSound(sound)
    status.setStatusProperty("ivrpg_npcShield_sound", false)
  end
  animator.setGlobalTag("armor", armor)
end

function uninit()
  
end
