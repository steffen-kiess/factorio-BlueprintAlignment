json = require ("json")

this = {}

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

local function trimleft(s)
   return (s:gsub("^%s*(.-)$", "%1"))
end

function this.new_data()
  local data = {}
  data.Align = { 0, 0 }
  data.Offset = { 0, 0 }
  data.Center = { 0, 0 }
  data.StoreAsLabel = false
  return data
end

local function checked_tonumber(val)
  local number = tonumber(val)
  if number == nil then return 0 end
  return math.floor(number*2 + 0.5) / 2.0
end

function this.cleanup(data_orig)
  local data = this.new_data()

  if data_orig.Align ~= nil then
    data.Align = { checked_tonumber(data_orig.Align[1]), checked_tonumber(data_orig.Align[2]) }
  end
  if data_orig.Offset ~= nil then
    data.Offset = { checked_tonumber(data_orig.Offset[1]), checked_tonumber(data_orig.Offset[2]) }
  end
  if data_orig.Center ~= nil then
    data.Center = { checked_tonumber(data_orig.Center[1]), checked_tonumber(data_orig.Center[2]) }
  end
  if data_orig.StoreAsLabel then
    data.StoreAsLabel = true
  end
  
  return data
end

function this.parse_blueprint(player, blueprint)
  local data = this.new_data()

  local align = 0

  entities = blueprint.get_blueprint_entities()
  if entities ~= nil then
    for _, entity in pairs(entities) do
      if entity.name == 'BlueprintAlignment-Info' then
        jsonStr = entity.alert_parameters.alert_message
        local status, res = pcall(function () return json.decode(jsonStr) end)
        if not status then
          player.print('[BlueprintAlignment] Error parsing JSON: ' .. res)
          return data
        else
          --player.print('[BlueprintAlignment] RES: ' .. serpent.block(res))
          res.Center = { entity.position.x, entity.position.y }
          res.StoreAsLabel = false
          local status2, res2 = pcall(function () return this.cleanup(res) end)
          if not status2 then
            player.print('[BlueprintAlignment] Error checking JSON: ' .. res2)
            return data
          else
            return res2
          end
        end
      end
    end
  end

  label = blueprint.label
  if label == nil then return data end
  local pos = (label:reverse()):find("(", 1, true)
  if pos == nil then return data end
  local str = label:sub(-pos+1)
  pos = str:find(")", 1, true)
  if pos == nil then return data end
  str = str:sub(1,pos-1)
  --player.print ("STR " .. serpent.block(str))

  data.Align = { nil, nil }
  data.StoreAsLabel = true

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
        data.Align[1] = tonumber(value)
      elseif name == "aligny" and tonumber(value) ~= nil then
        data.Align[2] = tonumber(value)
      elseif name == "offsetx" and tonumber(value) ~= nil then
        data.Offset[1] = tonumber(value)
      elseif name == "offsety" and tonumber(value) ~= nil then
        data.Offset[2] = tonumber(value)
      elseif name == "roffsetx" and tonumber(value) ~= nil then
        data.Center[1] = tonumber(value)
      elseif name == "centerx" and tonumber(value) ~= nil then
        data.Center[1] = tonumber(value)
      elseif name == "roffsety" and tonumber(value) ~= nil then
        data.Center[2] = tonumber(value)
      elseif name == "centery" and tonumber(value) ~= nil then
        data.Center[2] = tonumber(value)
      end
    end
  end

  if data.Align[1] == nil then data.Align[1] = align end
  if data.Align[2] == nil then data.Align[2] = align end

  return this.cleanup(data)
end

function Set(t)
  local s = {}
  for _,v in pairs(t) do s[v] = true end
  return s
end

function this.update_blueprint_label(player, blueprint, data_old, data)
  label = blueprint.label
  if label == nil then label = "" end
  local pos = (label:reverse()):find("(", 1, true)
  local prefix, str, suffix
  if pos == nil then
    prefix = label
    str = ""
    suffix = ""
  else
    prefix = label:sub(0,-pos-1)
    if prefix:sub(-1, -1) == ' ' then
      prefix = prefix:sub(1, -2)
    end
    str = label:sub(-pos+1)
    pos = str:find(")", 1, true)
    if pos == nil then
      prefix = label
      str = ""
      suffix = ""
    else
      suffix = str:sub(pos+1)
      str = str:sub(1,pos-1)
    end
  end
  --player.print ("STR " .. serpent.block(prefix) .. " " .. serpent.block(str) .. " " .. serpent.block(suffix))

  local resultStr = ""
  knownKeys = Set({"align", "alignx", "aligny", "offsetx", "offsety", "roffsetx", "roffsety", "centerx", "centery"})
  for part in gsplit(str, ',') do
    -- player.print ("S " .. serpent.block(part))
    if trim(part) ~= '' then
      pos = part:find("=")
      if pos == nil then
        resultStr = resultStr .. ", " .. trimleft(part)
      else
        local name = part:sub(1,pos-1)
        local value = part:sub(pos+1)
        name = trim (name)
        -- player.print ("SN " .. serpent.block(name))
        -- player.print ("SV " .. serpent.block(value))
        if not knownKeys[name] then
          resultStr = resultStr .. ", " .. name .. "=" .. value
        end
      end
    end
  end
  if data.StoreAsLabel then
    if data.Align[1] == data.Align[2] then
      if data.Align[1] ~= 0 then
        resultStr = resultStr .. ", align=" .. tostring(data.Align[1])
      end
    else
      if data.Align[1] ~= 0 then
        resultStr = resultStr .. ", alignx=" .. tostring(data.Align[1])
      end
      if data.Align[2] ~= 0 then
        resultStr = resultStr .. ", aligny=" .. tostring(data.Align[2])
      end
    end
    if data.Center[1] ~= 0 then
      resultStr = resultStr .. ", centerx=" .. tostring(data.Center[1])
    end
    if data.Center[2] ~= 0 then
      resultStr = resultStr .. ", centery=" .. tostring(data.Center[2])
    end
    if data.Offset[1] ~= 0 then
      resultStr = resultStr .. ", offsetx=" .. tostring(data.Offset[1])
    end
    if data.Offset[2] ~= 0 then
      resultStr = resultStr .. ", offsety=" .. tostring(data.Offset[2])
    end
  end
  if #resultStr ~= 0 then resultStr = resultStr:sub(3) end -- Remove ", " at the beginning

  local newLabel
  if resultStr == '' then
    newLabel = prefix .. suffix
  else
    newLabel = prefix .. " (" .. resultStr .. ")" .. suffix
  end

  --player.print ("Label: " .. serpent.block(label) .. " => " .. serpent.block(newLabel))
  blueprint.label = newLabel
end

function this.update_blueprint_entity(player, blueprint, data_old, data)
  -- Only store an entity if StoreAsLabel is false and either Align[1] or Align[2] is nonzero
  local storeAsEntity = (not data['StoreAsLabel']) and (data.Align[1] ~= 0 or data.Align[2] ~= 0)
  
  entities = blueprint.get_blueprint_entities()
  idx = nil
  maxId = 0
  if entities ~= nil then
    for index, entity in pairs(entities) do
      maxId = math.max(maxId, entity.entity_number)
      if entity.name == 'BlueprintAlignment-Info' then
        idx = index
        break
      end
    end
  else
    entities = {}
  end
  -- Return if StoreAsLabel is true and there is no existing BlueprintAlignment-Info
  if idx == nil and not storeAsEntity then return end

  if not storeAsEntity then
    -- Delete an existing BlueprintAlignment-Info
    table.remove(entities, idx)
    blueprint.set_blueprint_entities(entities)
    return
  end

  if idx == nil then
    idx = #entities + 1
    entities[idx] = {
      name = "BlueprintAlignment-Info",
      entity_number = maxId + 1,
      alert_parameters = {
        short_alert = false,
        show_on_map = false,
      },
    }
  end
  --player.print(serpent.block(entities[idx]))
  entities[idx].position = data.Center
  jsonObj = table.deepcopy(data)
  jsonObj['StoreAsLabel'] = nil
  jsonObj['Center'] = nil
  jsonStr = json.encode(jsonObj)
  --player.print(serpent.block(jsonStr))
  entities[idx].alert_parameters.alert_message = jsonStr
  blueprint.set_blueprint_entities(entities)
end

function this.update_blueprint(player, blueprint, data_old, data)
  if data['StoreAsLabel'] or data_old['StoreAsLabel'] then
    this.update_blueprint_label(player, blueprint, data_old, data)
  end
  this.update_blueprint_entity(player, blueprint, data_old, data)
end

return this
