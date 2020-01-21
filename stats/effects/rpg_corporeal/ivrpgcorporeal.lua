function init()
  script.setUpdateDelta(1)
end

function update(dt)
  mcontroller.controlParameters({
    collisionEnabled = true
  })
end
