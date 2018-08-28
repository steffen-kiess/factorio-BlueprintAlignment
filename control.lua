alignment_attribute = require ("alignment_attribute")
require ("gui")


require ("util")
-- require ("serpent")

-- Find an empty temporary item stack somewhere
local function find_empty_stack(player)
  local inventory = player.get_main_inventory()
  for i = 1, #inventory do
    if not inventory[i].valid_for_read then
      return inventory[i]
    end
  end
  -- No free place in inventory, create item on ground
  -- Search for free position to avoid creating an item on a belt
  for x = -10,10 do
    for y = -10,10 do
      local count = player.surface.count_entities_filtered{position={x=player.position.x+x,y=player.position.y+y}}
      --player.print(x .. " " .. y .. " " .. count)
      if count == 0 then
        local entity = player.surface.create_entity{name = "item-on-ground", position = player.position, force=player.force, stack={name="BlueprintAlignment-blueprint-holder"}}
        if entity ~= nil and entity.valid then
          return entity.stack
        else
          player.print ("item-on-ground entity creation failed")
          return nil
        end
      end
    end
  end
  -- Fall back to where the player stands. This will fail when the player is on a belt
  local entity = player.surface.create_entity{name = "item-on-ground", position = player.position, force=player.force, stack={name="BlueprintAlignment-blueprint-holder"}}
  if entity ~= nil and entity.valid then
    return entity.stack
  end
  player.print ("Failed to find free inventory slot and item-on-ground entity creation failed")
  return nil
end


-- If this is an aligned build request, intercept the build request and force it to the properly aligned position
script.on_event(defines.events.on_put_item, function (event)
  local player = game.players[event.player_index]
  -- player.print ("PI " .. event.tick .. " " .. serpent.block(event.position) .. " " .. serpent.block(event.shift_build) .. " " .. serpent.block(event.created_by_moving) .. " " .. serpent.block(event.direction))

  -- Get the blueprint which was used, return if no blueprint was used
  if not player.cursor_stack.valid_for_read then
    return
  end
  local blueprint
  if player.cursor_stack.type == "blueprint" then
    blueprint = player.cursor_stack
  elseif player.cursor_stack.type == "blueprint-book" then
    blueprint = player.cursor_stack.get_inventory(defines.inventory.item_main)[player.cursor_stack.active_index]
  else
    return
  end

  -- Parse the blueprint label (search for last () block), return if none found
  --player.print ("BP " .. serpent.block(blueprint.label))
  parsed = alignment_attribute.parse_blueprint(player, blueprint)

  local globaloffsetx = settings.global["BlueprintAlignment-global-offset-x"].value
  local globaloffsety = settings.global["BlueprintAlignment-global-offset-y"].value

  if parsed.Align[1] == 0 and parsed.Align[2] == 0 then return end

  if parsed.Align[1] == 0 then parsed.Align[1] = 0.5 end
  if parsed.Align[2] == 0 then parsed.Align[2] = 0.5 end

  local offsetx = parsed.Offset[1] + globaloffsetx
  local offsety = parsed.Offset[2] + globaloffsety

  if event.direction == 0 then
    offsetx = offsetx - parsed.Center[1]
    offsety = offsety - parsed.Center[2]
  elseif event.direction == 2 then
    offsetx = offsetx + parsed.Center[2]
    offsety = offsety - parsed.Center[1]
  elseif event.direction == 4 then
    offsetx = offsetx + parsed.Center[1]
    offsety = offsety + parsed.Center[2]
  elseif event.direction == 6 then
    offsetx = offsetx - parsed.Center[2]
    offsety = offsety + parsed.Center[1]
  end  

  -- player.print ("ALIGN: " .. serpent.block(parsed.Align[1]) .. " " .. serpent.block(parsed.Align[2]) .. " " .. serpent.block(offsetx) .. " " .. serpent.block(offsety))

  -- Build the blueprint, properly aligned

  local pos = table.deepcopy(event.position)
  pos.x = math.floor((pos.x - offsetx) / parsed.Align[1] + 0.5) * parsed.Align[1] + offsetx
  pos.y = math.floor((pos.y - offsety) / parsed.Align[2] + 0.5) * parsed.Align[2] + offsety

  local ghosts = player.cursor_stack.build_blueprint({
    surface = player.surface,
    force = player.force,
    position = pos,
    force_build = event.shift_build,
    direction = event.direction,
  })
  -- Raise on_build_entity for all created (ghost) entities. This will also remove the BlueprintAlignment-Info ghost (and hopefully similar ghosts from other mods)
  for _, entity in pairs(ghosts) do
    script.raise_event(defines.events.on_built_entity, { created_entity = entity, player_index = player.index, stack = nil })
  end

  -- Suppress the normal blueprint building by replacing the blueprint with a temporary item
  local stack = find_empty_stack(player)
  if stack == nil then
    return nil
  end
  stack.set_stack({name = "BlueprintAlignment-blueprint-holder", count = 1})
  stack.get_inventory(defines.inventory.item_main)[1].swap_stack(player.cursor_stack)
  stack.swap_stack(player.cursor_stack)
end)

-- Replace the temporary item by the blueprint
script.on_event(defines.events.on_player_cursor_stack_changed, function (event)
  local player = game.players[event.player_index]

  if player.cursor_stack.valid_for_read and player.cursor_stack.name == "BlueprintAlignment-blueprint-holder" then
    local stack = find_empty_stack(player)
    if stack == nil then
      return nil
    end

    stack.swap_stack(player.cursor_stack)
    player.cursor_stack.swap_stack(stack.get_inventory(defines.inventory.item_main)[1])
    stack.set_stack(nil)
  end
end)


script.on_event(defines.events.on_built_entity, function (event)
  local entity = event.created_entity
  --local player = game.players[event.player_index]
  --player.print ('BUILDT ' .. serpent.block(event.tick) .. ' ' .. entity.type .. ' ' .. serpent.block(event.stack))
  --if entity.valid and entity.type == "entity-ghost" then
  --  player.print ('BUILD ' .. entity.ghost_name)
  --end
  if entity.valid and entity.type == "entity-ghost" and entity.ghost_name == "BlueprintAlignment-Info" then
    entity.destroy()
    --player.print ('Removing ghost')
  end
end)
