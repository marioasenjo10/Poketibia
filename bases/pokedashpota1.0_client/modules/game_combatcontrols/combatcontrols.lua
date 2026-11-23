combatControlsButton = nil
combatControlsWindow = nil
fightOffensiveBox = nil
fightBalancedBox = nil
fightDefensiveBox = nil
fightModeRadioGroup = nil

function init()
  combatControlsButton = modules.client_topmenu.addRightGameToggleButton('combatControlsButton', 'Estado de combate', '/images/topmenu/combat', toggle)
  combatControlsButton:setOn(true)
  combatControlsWindow = g_ui.loadUI('combatcontrols', modules.game_interface.getRightPanel())
  combatControlsWindow:disableResize()

  fightOffensiveBox = combatControlsWindow:recursiveGetChildById('fightOffensiveBox')
  fightBalancedBox = combatControlsWindow:recursiveGetChildById('fightBalancedBox')
  fightDefensiveBox = combatControlsWindow:recursiveGetChildById('fightDefensiveBox')

  fightModeRadioGroup = UIRadioGroup.create()
  fightModeRadioGroup:addWidget(fightOffensiveBox)
  fightModeRadioGroup:addWidget(fightBalancedBox)
  fightModeRadioGroup:addWidget(fightDefensiveBox)

  connect(fightModeRadioGroup, { onSelectionChange = onSetFightMode })
  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
    onFightModeChange = update,
    onChaseModeChange = update,
    onSafeFightChange = update,
    onWalk = check,
    onAutoWalk = check
  })

  if g_game.isOnline() then
    online()
  end

  combatControlsWindow:setup()
end

function terminate()
  if g_game.isOnline() then
    offline()
  end

  fightModeRadioGroup:destroy()
  combatControlsWindow:destroy()
  combatControlsButton:destroy()

  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
    onFightModeChange = update,
    onChaseModeChange = update,
    onSafeFightChange = update,
    onWalk = check,
    onAutoWalk = check
  })
end

function update()
  local fightMode = g_game.getFightMode()
  if fightMode == FightOffensive then
    fightModeRadioGroup:selectWidget(fightOffensiveBox)
  elseif fightMode == FightBalanced then
    fightModeRadioGroup:selectWidget(fightBalancedBox)
  else
    fightModeRadioGroup:selectWidget(fightDefensiveBox)
  end
end

function check()
  if modules.client_options.getOption('autoChaseOverride') then
    if g_game.isAttacking() and g_game.getChaseMode() == ChaseOpponent then
      g_game.setChaseMode(DontChase)
    end
  end
end

function online()
  local player = g_game.getLocalPlayer()
  if player then
    local char = g_game.getCharacterName()

    local lastCombatControls = g_settings.getNode('LastCombatControls')

    if not table.empty(lastCombatControls) then
      if lastCombatControls[char] then
        g_game.setFightMode(lastCombatControls[char].fightMode)
      end
    end
    -- sin PvP y sin perseguir (el pokemon ya persigue al objetivo)
    g_game.setChaseMode(DontChase)
    g_game.setSafeFight(true)
  end

  update()
end

function offline()
  local lastCombatControls = g_settings.getNode('LastCombatControls')
  if not lastCombatControls then
    lastCombatControls = {}
  end

  local player = g_game.getLocalPlayer()
  if player then
    local char = g_game.getCharacterName()
    lastCombatControls[char] = {
      fightMode = g_game.getFightMode()
    }

    -- save last combat control settings
    g_settings.setNode('LastCombatControls', lastCombatControls)
  end
end

function toggle()
  if combatControlsButton:isOn() then
    combatControlsWindow:close()
    combatControlsButton:setOn(false)
  else
    combatControlsWindow:open()
    combatControlsButton:setOn(true)
  end
end

function onSetFightMode(self, selectedFightButton)
  if selectedFightButton == nil then return end
  local buttonId = selectedFightButton:getId()
  local fightMode
  if buttonId == 'fightOffensiveBox' then
    fightMode = FightOffensive
  elseif buttonId == 'fightBalancedBox' then
    fightMode = FightBalanced
  else
    fightMode = FightDefensive
  end
  g_game.setFightMode(fightMode)
end

function onMiniWindowClose()
  combatControlsButton:setOn(false)
end
