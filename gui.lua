alignment_attribute = require ("alignment_attribute")
mod_gui = require("mod-gui")
require ("util")
require ("serpent")
require ("mod-gui")


local function get_cache(player)
  local cache = global.per_player_info
  if cache == nil then
    cache = {}
    global.per_player_info = cache
  end
  
  local index = player.index
  local player_cache = cache[index]
  if player_cache == nil then
    player_cache = {}
    cache[index] = player_cache
  end

  return player_cache
end

-- Reset player info when a new player is created
script.on_event(defines.events.on_player_created, function (event)
  local index = event.player_index

  local cache = global.per_player_info
  if cache == nil then
    cache = {}
    global.per_player_info = cache
  end

  cache[index] = {}

  --local player = game.players[event.player_index]
  --player.print('DDD')
end)

local function create_text_field(data)
  cache = data.cache
  caption = data.caption
  name = data.name
  index = data.index

  gui = cache.gui
  gui.table.add{type='label', caption=caption}
  info = {allow_half=data.allow_half, name=name, index=index}
  info.last_value = tostring(cache.gui.attr[name][index])
  info.element = gui.table.add{type='textfield'}
  info.element.text = info.last_value
  return info
end

local function create_checkbox_field(data)
  cache = data.cache
  caption = data.caption
  name = data.name

  gui = cache.gui
  gui.table.add{type='label', caption=caption}
  info = {name=name}
  info.element = gui.table.add{type='checkbox', state=cache.gui.attr[name]}
  return info
end

local function close_bp_al_gui(player)
  local cache = get_cache(player)
  --player.print ("close_bp_al_gui")
  if cache.button ~= nil then
    cache.button.tooltip = "Open the Blueprint Alignment GUI"
  end
  if cache.gui == nil then
    return
  end
  if cache.gui.root ~= nil then
    cache.gui.root.destroy()
  end
  cache.gui = nil
end

-- If this function is below open_bp_gui() factorio (0.16.51) will crash when open_bp_gui() calls close_bp_gui()
local function close_bp_gui(player)
  --player.print ("close_bp_gui")
  local cache = get_cache(player)
  cache.suppress_reopen = nil
  close_bp_al_gui(player)
  if cache.button ~= nil then
    cache.button.destroy()
  end
  cache.button = nil
end

local function open_bp_al_gui(player)
  local cache = get_cache(player)
  if cache.item == nil then
    -- For some reason open_bp_al_gui() has beed called while there is no blueprint selected
    player.print ("[BlueprintAlignment] Warning: No blueprint found")
    return
  end
  if not cache.item.valid_for_read then
    -- For some reason open_bp_al_gui() has beed called with an invalid item
    player.print ("[BlueprintAlignment] Warning: Blueprint not valid")
    return
  end
  if cache.gui ~= nil then
    close_bp_al_gui(player)
  end
  --player.print ("open_bp_al_gui")
  cache.gui = {}
  cache.button.tooltip = "Close the Blueprint Alignment GUI"
  cache.gui.attr_old = alignment_attribute.parse_blueprint(player, cache.item)
  cache.gui.attr = table.deepcopy(cache.gui.attr_old)
  cache.gui.root = player.gui.left.add{type='frame', name='BlueprintAlignment_Gui', caption='Blueprint alignment'}
  cache.gui.table = cache.gui.root.add{type='table', column_count=2}
  cache.gui.text = {}
  cache.gui.checkbox = {}
  cache.gui.text.align_x = create_text_field{cache=cache, caption='Alignment X', name='Align', index=1}
  cache.gui.text.align_y = create_text_field{cache=cache, caption='Alignment Y', name='Align', index=2}
  cache.gui.text.center_x = create_text_field{cache=cache, caption='Center X', allow_half=true, name='Center', index=1}
  cache.gui.text.center_y = create_text_field{cache=cache, caption='Center Y', allow_half=true, name='Center', index=2}
  cache.gui.text.offset_x = create_text_field{cache=cache, caption='Offset X', allow_half=true, name='Offset', index=1}
  cache.gui.text.offset_y = create_text_field{cache=cache, caption='Offset Y', allow_half=true, name='Offset', index=2}
  cache.gui.checkbox.store_as_label = create_checkbox_field{cache=cache, caption='Store as label', name='StoreAsLabel'}
end

local function open_bp_gui(player)
  local cache = get_cache(player)
  cache.suppress_reopen = nil
  if cache.gui ~= nil or cache.button ~= nil then
    close_bp_gui(player)
  end
  --player.print ("open_bp_gui " .. serpent.block(cache.item))
  cache.button = mod_gui.get_button_flow(player).add{type = "sprite-button", name = "BlueprintAlignment_Button", tooltip = "Open the Blueprint Alignment GUI", sprite = "item/blueprint", style = "mod_gui_button"}
  if cache.isopen then
    open_bp_al_gui(player)
  end
end

script.on_event(defines.events.on_gui_click, function (event)
  local player = game.players[event.player_index]
  local cache = get_cache(player)
  if event.element == cache.button then
    if cache.gui then
      cache.isopen = nil
      close_bp_al_gui(player)
    else
      cache.isopen = true
      open_bp_al_gui(player)
    end
  end
end)

local function is_valid_number(str, allow_half)
  for i = 1, #str do
    local c = str:sub(i,i)
    if c < '0' or c > '9' then
      if c == '-' then
        if i ~= 1 then return false end
      elseif allow_half and c == '.' then
        if i == #str then
          -- '.' at end of string is ok
        elseif i + 1 == #str then
          -- '.' at second-to-last is ok if last char is '0' or '5'
          local c2 = str:sub(i+1,i+1)
          if c2 ~= '0' and c2 ~= '5' then
            return false
          end
        else
          -- everywhere else '.' is not allowed
          return false
        end
      else
        return false
      end
    end
  end
  return true
end

local function check_number(info)
  if not info.last_value then
    info.last_value = ''
  end
  if not is_valid_number(info.element.text, info.allow_half) then
    info.element.text = info.last_value
    return false
  elseif info.last_value ~= info.element.text then
    info.last_value = info.element.text
    return true
  else
    return false
  end
end

local function update_blueprint(player)
  --player.print('update_blueprint ' .. serpent.block(cache.gui.attr))
  local cache = get_cache(player)
  item = cache.item

  if item == nil then
    player.print ("[BlueprintAlignment] Warning: No blueprint found in update_blueprint()")
    return
  end
  if not item.valid_for_read then
    player.print ("[BlueprintAlignment] Warning: Blueprint not valid in update_blueprint()")
    return
  end

  --player.print('Update 1')
  -- suppress open_bp_gui and close_bp_gui while updating the blueprint
  cache.suppress_reopen = item

  -- Update the blueprint
  --player.print('Update 2')
  alignment_attribute.update_blueprint(player, item, cache.gui.attr_old, cache.gui.attr)
  cache.gui.attr_old = table.deepcopy(cache.gui.attr)

  -- Reopen the blueprint GUI
  if not player.blueprint_to_setup.valid_for_read then
    --player.print('Update 3')

    -- Recreate blueprint to update Blueprint UI
    local blueprint = item
    copy_entities = blueprint.get_blueprint_entities()
    copy_tiles = blueprint.get_blueprint_tiles()
    copy_label = blueprint.label
    copy_label_color = blueprint.label_color
    copy_allow_manual_label_change = blueprint.allow_manual_label_change
    copy_blueprint_icons = blueprint.blueprint_icons
    -- copy_entities[#copy_entities + 1] = {
    --   name = "BlueprintAlignment-Info",
    --   entity_number = #copy_entities + 1,
    --   position = { 0, 0 },
    --   alert_parameters = {
    --     short_alert = false,
    --     show_on_map = false,
    --     alert_message = 'FooBar',
    --   },
    -- }
    blueprint.set_stack{ name = blueprint.name }
    blueprint.set_blueprint_entities(copy_entities)
    blueprint.set_blueprint_tiles(copy_tiles)
    if copy_label ~= nil then blueprint.label = copy_label end
    if copy_label_color ~= nil then blueprint.label_color = copy_label_color end
    blueprint.allow_manual_label_change = copy_allow_manual_label_change
    if copy_entities ~= nil or copy_tiles ~= nil then -- When the blueprint is empty, the icons cannot be copied
      blueprint.blueprint_icons = copy_blueprint_icons
    end

    -- Opening the GUI twice avoids problems with attach-notes mod
    player.opened = item
    player.opened = item
  end
  
  cache.suppress_reopen = nil
  --player.print('Update 4')
end

script.on_event(defines.events.on_gui_text_changed, function (event)
  local player = game.players[event.player_index]
  local cache = get_cache(player)
  if cache.gui == nil then return end

  if cache.gui.text then
    for _, el in pairs(cache.gui.text) do
      if el and el.element == event.element then
        name = el.name
        index = el.index
        local text = event.element.text
        --player.print('Update ' .. name .. ' ' .. index .. ' to ' .. serpent.block(text))
        if check_number(el) then
          if text == '' then
            --cache.gui.attr[name][index] = nil
            cache.gui.attr[name][index] = 0
          else
            local number = tonumber(text)
            if number ~= nil then
              cache.gui.attr[name][index] = number
            end
          end
          --player.print(serpent.block(cache.gui.attr))
          --cache.item.label = cache.item.label .. 'X'
          update_blueprint(player)
        end
        return
      end
    end
  end
end)

script.on_event(defines.events.on_gui_checked_state_changed, function (event)
  local player = game.players[event.player_index]
  local cache = get_cache(player)
  if cache.gui == nil then return end

  if cache.gui.checkbox then
    for _, el in pairs(cache.gui.checkbox) do
      if el and el.element == event.element then
        name = el.name
        local checked = event.element.state
        --player.print('Update ' .. name .. ' to ' .. serpent.block(checked))
        cache.gui.attr[name] = checked
        update_blueprint(player)
        return
      end
    end
  end
end)

script.on_event(defines.events.on_gui_opened, function (event)
  local player = game.players[event.player_index]
  --player.print ("GO " .. event.tick .. " " .. serpent.block(event.gui_type) .. " " .. serpent.block(event.item) .. " " .. serpent.block(player.blueprint_to_setup.valid_for_read))
  if event.gui_type == defines.gui_type.item then
    local item = event.item
    if item == nil and player.blueprint_to_setup.valid_for_read then
      item = player.blueprint_to_setup
    end
    if item ~= nil and item.type ~= "blueprint" then
      item = nil
    end
    local cache = get_cache(player)
    cache.item = item
    if item ~= nil then
      if cache.suppress_reopen ~= item then
        open_bp_gui(player)
      end
    end
  end
end)

script.on_event(defines.events.on_gui_closed, function (event)
  local player = game.players[event.player_index]
  --player.print ("GC " .. event.tick .. " " .. serpent.block(event.gui_type) .. " " .. serpent.block(event.item))
  local cache = get_cache(player)
  if event.gui_type == defines.gui_type.item and cache.item ~= nil then
    if cache.suppress_reopen ~= cache.item then
      close_bp_gui(player)
      cache.item = nil
    end
  end
end)



local function shift_blueprint(player, blueprint)
  local data_old = alignment_attribute.parse_blueprint(player, blueprint)
  if data_old.Align[1] == 0 and data_old.Align[2] == 0 then
    return 0
  end
  if not data_old.StoreAsLabel and data_old.Center[1] == 0 and data_old.Center[2] == 0 then
    return 0
  end
  
  data = table.deepcopy(data_old)
  if data.StoreAsLabel then
    data.StoreAsLabel = false
    alignment_attribute.update_blueprint(player, blueprint, data_old, data)
  end
  
  shiftX = math.floor(-data.Center[1])
  shiftY = math.floor(-data.Center[2])
  if shiftX ~= 0 or shiftY ~= 0 then
    entities = blueprint.get_blueprint_entities()
    if entities ~= nil then
      for _, entity in pairs(entities) do
        entity.position.x = entity.position.x + shiftX
        entity.position.y = entity.position.y + shiftY
      end
      blueprint.set_blueprint_entities(entities)
    end
    tiles = blueprint.get_blueprint_tiles()
    if tiles ~= nil then
      for _, entity in pairs(tiles) do
        entity.position.x = entity.position.x + shiftX
        entity.position.y = entity.position.y + shiftY
      end
      blueprint.set_blueprint_tiles(tiles)
    end
  end
  
  return 1
end

commands.add_command("alignment-center", "Shift the blueprint in the player's hand (or all blueprints in a book) so that the alignment center is at (0,0). Also makes sure all alignment information is stored as entities, not as labels", function(event)
  local player = game.players[event.player_index]
  --player.print("alignment-center")
  if not player.cursor_stack.valid_for_read then
    player.print("No blueprint or blueprint book found in the player's hand")
    return
  end
  local item = player.cursor_stack

  --player.print(item.type)
  if item.type == 'blueprint' then
    local mod = shift_blueprint(player, item)
    if mod ~= 0 then
      player.print("Blueprint modified")
    else
      player.print("Blueprint not modified")
    end
  elseif item.type == 'blueprint-book' then
    local inventory = item.get_inventory(defines.inventory.item_main)
    mod = 0
    count = 0
    for i = 1, #inventory do
      if inventory[i].valid_for_read then
        count = count + 1
        mod = mod + shift_blueprint(player, inventory[i])
      end
    end
    player.print(serpent.block(mod) .. " / " .. serpent.block(count) .. " blueprints modified")
  else
    player.print("No blueprint or blueprint book found in the player's hand")
  end
end)
