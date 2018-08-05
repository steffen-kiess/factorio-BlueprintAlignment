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
  -- TODO: handle this somehow by finding another free slot somewhere
  player.print ("Failed to find free inventory slot")
  return nil
end


local function gsplit(s,sep)
  local lasti, done, g = 1, false, s:gmatch('(.-)'..sep..'()')
  return function()
    if done then
      return
    end
    local v,i = g()
    if s == '' or sep == '' then
      done = true
      return s
    end
    if v == nil then
      done = true
      return s:sub(lasti)
    end
    lasti = i
    return v
  end
end

local function trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
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
  label = blueprint.label
  if label == nil then return end
  local pos = (label:reverse()):find("(", 1, true)
  if pos == nil then return end
  local str = label:sub(-pos+1)
  pos = str:find(")", 1, true)
  if pos == nil then return end
  str = str:sub(1,pos-1)
  --player.print ("STR " .. serpent.block(str))

  local globaloffsetx = 1
  local globaloffsety = 1

  local align = nil
  local alignx = nil
  local aligny = nil

  local offsetx = 0
  local offsety = 0

  local roffsetx = 0
  local roffsety = 0

  for part in gsplit(str, ',') do
    -- player.print ("S " .. serpent.block(part))
    pos = part:find("=")
    if pos ~= nil then
      local name = part:sub(1,pos-1)
      local value = part:sub(pos+1)
      name = trim (name)
      -- player.print ("SN " .. serpent.block(name))
      -- player.print ("SV " .. serpent.block(value))
      if name == "align" and tonumber(value) ~= nil then
        align = tonumber(value)
      elseif name == "alignx" and tonumber(value) ~= nil then
        alignx = tonumber(value)
      elseif name == "aligny" and tonumber(value) ~= nil then
        aligny = tonumber(value)
      elseif name == "offsetx" and tonumber(value) ~= nil then
        offsetx = tonumber(value)
      elseif name == "offsety" and tonumber(value) ~= nil then
        offsety = tonumber(value)
      elseif name == "roffsetx" and tonumber(value) ~= nil then
        roffsetx = tonumber(value)
      elseif name == "roffsety" and tonumber(value) ~= nil then
        roffsety = tonumber(value)
      end
    end
  end

  if alignx == nil then alignx = align end
  if aligny == nil then aligny = align end

  if alignx == nil and aligny == nil then return end

  if alignx == nil then alignx = 0.5 end
  if aligny == nil then aligny = 0.5 end

  offsetx = offsetx + globaloffsetx
  offsety = offsety + globaloffsety

  if event.direction == 0 then
    offsetx = offsetx - roffsetx
    offsety = offsety - roffsety
  elseif event.direction == 2 then
    offsetx = offsetx + roffsety
    offsety = offsety - roffsetx
  elseif event.direction == 4 then
    offsetx = offsetx + roffsetx
    offsety = offsety + roffsety
  elseif event.direction == 6 then
    offsetx = offsetx - roffsety
    offsety = offsety + roffsetx
  end  

  -- player.print ("ALIGN: " .. serpent.block(alignx) .. " " .. serpent.block(aligny) .. " " .. serpent.block(offsetx) .. " " .. serpent.block(offsety))

  -- Build the blueprint, properly aligned

  local pos = table.deepcopy(event.position)
  pos.x = math.floor((pos.x - offsetx) / alignx + 0.5) * alignx + offsetx
  pos.y = math.floor((pos.y - offsety) / aligny + 0.5) * aligny + offsety

  player.cursor_stack.build_blueprint({
    surface = player.surface,
    force = player.force,
    position = pos,
    force_build = event.shift_build,
    direction = event.direction,
  })


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
