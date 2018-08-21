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

function this.parse_blueprint(blueprint)
  local data = {}

  local align = 0
  data.Align = { 0, 0 }

  data.Offset = { 0, 0 }

  data.Center = { 0, 0 }
  
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

  return data
end

function Set(t)
  local s = {}
  for _,v in pairs(t) do s[v] = true end
  return s
end

function this.update_blueprint(player, blueprint, data)
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

return this
