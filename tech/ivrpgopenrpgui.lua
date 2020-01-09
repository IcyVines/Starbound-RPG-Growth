require "/scripts/keybinds.lua"

ivrpg_ttShortcut = {
  initialized = false,
  tripleTapTime = 0.23,
  tripleTapTimer = 0,
  tripleTapCount = 0,
  shiftHeld = false
}

function ivrpg_ttShortcut.initialize()
  if not ivrpg_ttShortcut.initialized then
    ivrpg_ttShortcut.initialized = true

    Bind.create("down", function()
      if not ivrpg_ttShortcut.shiftHeld then return end
      ivrpg_ttShortcut.tripleTapTimer = ivrpg_ttShortcut.tripleTapTime
      ivrpg_ttShortcut.tripleTapCount = ivrpg_ttShortcut.tripleTapCount + 1
      if ivrpg_ttShortcut.tripleTapCount == 3 then
        ivrpg_ttShortcut.tripleTapCount = 0
        ivrpg_ttShortcut.tripleTapTimer = 0
        if status.statusProperty("ivrpgskillbookshortcut", true) then
          world.sendEntityMessage(entity.id(), "interact", "ScriptPane", "/interface/RPGskillbook/RPGskillbook.config", entity.id())
        end
      end
    end)

    -- Compatibility 'hack' for older versions of the game; use function input rather than update to update the input values (I know, right?!).
    if input then
      local originalInput = input

      input = function(args)
        ivrpg_ttShortcut.update(args)
        return originalInput(args)
      end
    else
      local originalUpdate = update

      update = function(args)
        ivrpg_ttShortcut.update(args)
        originalUpdate(args)
      end
    end
  end
end

function ivrpg_ttShortcut.update(args)
  ivrpg_ttShortcut.shiftHeld = not args.moves["run"]
  if ivrpg_ttShortcut.tripleTapTimer > 0 then
    ivrpg_ttShortcut.tripleTapTimer = ivrpg_ttShortcut.tripleTapTimer - args.dt
    if ivrpg_ttShortcut.tripleTapTimer <= 0 then
      ivrpg_ttShortcut.tripleTapCount = 0
    end
  end
end