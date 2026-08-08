local F3XLIB = {
  info = {
    HDAdmin = {
      prefix = ";",
      hasRCS = false
    },
    F3X = {
      hasF3X = false,
      hasSE = false,
      isPlus = false
    }
  }
}

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

function F3XLIB.getChar(plr)
  return plr.Character or plr.CharacterAdded:Wait()
end

function F3XLIB.getHDPrefix()
  local HDAdmin = RS:FindFirstChild("HDAdminHDClient")
  if not HDAdmin then return nil end

  local config = HDAdmin:FindFirstChild("Settings") or HDAdmin:FindFirstChild("Config") or HDAdmin:FindFirstChild("Configuration")
  if not config then return nil end

  local prefix = config:FindFirstChild("Prefix")
  if prefix then
    if prefix:IsA("StringValue") then
      return prefix.Value
    elseif type(prefix) == "string" then
      return prefix
    end
  end

  return nil
end

function F3XLIB.getRCS()
  local HDAdmin = RS:FindFirstChild("HDAdminHDClient")
  if not HDAdmin then return nil end
  local Signals = HDAdmin:FindFirstChild("Signals")
  if not Signals then return nil end
  return Signals:FindFirstChild("RequestCommandSilent") or Signals:FindFirstChild("RequestCommandModification")
end

function F3XLIB.getAllF3X()
  local f3x = {}

  local backpack = player:FindFirstChild("Backpack")
  if backpack then
    for _, obj in ipairs(backpack:GetChildren()) do
      if obj:IsA("Tool") then
        local syncAPI = obj:FindFirstChild("SyncAPI")
        if syncAPI and syncAPI:FindFirstChild("ServerEndpoint") then
          table.insert(f3x, obj)
        end
      end
    end
  end

  local char = F3XLIB.getChar(player)
  if char then
    for _, obj in ipairs(char:GetChildren()) do
      if obj:IsA("Tool") then
        local syncAPI = obj:FindFirstChild("SyncAPI")
        if syncAPI and syncAPI:FindFirstChild("ServerEndpoint") then
          table.insert(f3x, obj)
        end
      end
    end
  end

  return f3x
end

function F3XLIB.getF3X()
  local f3xTable = F3XLIB.getAllF3X()
  if f3xTable and #f3xTable > 0 then
    return f3xTable[1]
  end
  return nil
end

function F3XLIB.tryGetF3X()
  local f3xTable = F3XLIB.getAllF3X()
  if f3xTable and #f3xTable > 0 then
    return f3xTable[1]
  end

  if F3XLIB.info.HDAdmin.hasRCS then
    local HDrequest = F3XLIB.getRCS()
    local commands = {"btools", "f3x", "buildingtools"}
    for _, cmd in ipairs(commands) do
      HDrequest:InvokeServer(F3XLIB.info.HDAdmin.prefix .. cmd)
      task.wait(0.5)
      f3xTable = F3XLIB.getAllF3X()
      if f3xTable and #f3xTable > 0 then
        return f3xTable[1]
      end
    end
  end

  return nil
end

function F3XLIB.getSE(f3x)
  if not f3x then return nil end
  local syncAPI = f3x:FindFirstChild("SyncAPI")
  if not syncAPI then return nil end
  return syncAPI:FindFirstChild("ServerEndpoint")
end

function F3XLIB.isF3XPlus(f3x)
  if not f3x then return false end
  if f3x.Name == "Building Tools+" or f3x.Name:find("+") ~= nil then
    return true
  end
  local tools = f3x:FindFirstChild("Tools")
  if tools and tools:FindFirstChild("Transformation") then
    return true
  end
  return false
end


local prefix = F3XLIB.getHDPrefix()
if prefix then
  F3XLIB.info.HDAdmin.prefix = prefix
end
local HDrequest = F3XLIB.getRCS()
if HDrequest then
  F3XLIB.info.HDAdmin.hasRCS = true
end

local f3x = F3XLIB.getF3X()
local se
if f3x then
  F3XLIB.info.F3X.hasF3X = true
  F3XLIB.info.F3X.isPlus = F3XLIB.isF3XPlus(f3x)
  se = F3XLIB.getSE(f3x)
  if se then
    F3XLIB.info.F3X.hasSE = true
  end
end


function F3XLIB.refresh()
  local newPrefix = F3XLIB.getHDPrefix()
  if newPrefix then
    F3XLIB.info.HDAdmin.prefix = newPrefix
  end
  HDrequest = F3XLIB.getRCS()
  if HDrequest then
    F3XLIB.info.HDAdmin.hasRCS = true
  else
    F3XLIB.info.HDAdmin.hasRCS = false
  end

  f3x = F3XLIB.getF3X()
  se = nil
  if f3x then
    F3XLIB.info.F3X.hasF3X = true
    F3XLIB.info.F3X.isPlus = F3XLIB.isF3XPlus(f3x)
    se = F3XLIB.getSE(f3x)
    if se then
      F3XLIB.info.F3X.hasSE = true
    else
      F3XLIB.info.F3X.hasSE = false
    end
  else
    F3XLIB.info.F3X.hasF3X = false
    F3XLIB.info.F3X.hasSE = false
    F3XLIB.info.F3X.isPlus = false
  end
end


function F3XLIB.execHD(cmd)
  if not F3XLIB.info.HDAdmin.hasRCS then return false end
  HDrequest:InvokeServer(F3XLIB.info.HDAdmin.prefix .. cmd)
  return true
end

function F3XLIB.execF3X(...)
  if not se then
    f3x = F3XLIB.tryGetF3X()
    if f3x then
      se = F3XLIB.getSE(f3x)
    end
  end
  if not se then return nil end
  return se:InvokeServer(...)
end


function F3XLIB.create(shape, cf, parent)
  shape = shape or "Normal"
  parent = parent or workspace
  if not se then return nil end
  return se:InvokeServer("CreatePart", shape, cf, parent)
end

function F3XLIB.createTool(cf, parent)
  parent = parent or workspace
  if not se then return nil end
  return se:InvokeServer("CreatePart", "Tool", cf, parent)
end

function F3XLIB.remove(obj)
  if not obj then return false end
  if not se then return false end
  if type(obj) == "table" then
    return se:InvokeServer("Remove", obj)
  end
  return se:InvokeServer("Remove", {obj})
end

function F3XLIB.move(part, cf)
  if not part or not cf then return false end
  if not se then return false end
  return se:InvokeServer("SyncMove", {
    {Part = part, CFrame = cf}
  })
end

function F3XLIB.setAnchor(part, anchored)
  if not part then return false end
  if not se then return false end
  return se:InvokeServer("SyncAnchor", {
    {Part = part, Anchored = anchored}
  })
end

function F3XLIB.setCollision(part, canCollide)
  if not part then return false end
  if not se then return false end
  return se:InvokeServer("SyncCollision", {
    {Part = part, CanCollide = canCollide}
  })
end

function F3XLIB.setColor(part, color, unionColoring)
  if not part or not color then return false end
  if not se then return false end
  unionColoring = unionColoring or true
  return se:InvokeServer("SyncColor", {
    {Part = part, Color = color, UnionColoring = unionColoring}
  })
end

function F3XLIB.resize(part, size, cf)
  if not part or not size then return false end
  if not se then return false end
  cf = cf or part.CFrame
  return se:InvokeServer("SyncResize", {
    {Part = part, Size = size, CFrame = cf}
  })
end

function F3XLIB.weld(part1, part2, lead)
  if not part1 or not part2 then return false end
  if not se then return false end
  lead = lead or part1
  return se:InvokeServer("CreateWelds", {part1, part2}, lead)
end

function F3XLIB.setName(part, name)
  if not part or not name then return false end
  if not se then return false end
  return se:InvokeServer("SetName", {part}, name)
end

function F3XLIB.setTexture(part, textureId)
  if not part or not textureId then return false end
  if not se then return false end
  return se:InvokeServer("SyncMesh", {
    {Part = part, TextureId = "rbxassetid://" .. textureId}
  })
end

function F3XLIB.addMesh(part)
  if not part then return false end
  if not se then return false end
  return se:InvokeServer("CreateMeshes", {
    {Part = part}
  })
end

function F3XLIB.setMesh(part, meshId)
  if not part or not meshId then return false end
  if not se then return false end
  return se:InvokeServer("SyncMesh", {
    {Part = part, MeshId = "rbxassetid://" .. meshId}
  })
end

function F3XLIB.meshResize(part, scale)
  if not part or not scale then return false end
  if not se then return false end
  return se:InvokeServer("SyncMesh", {
    {Part = part, Scale = scale}
  })
end

function F3XLIB.setMeshColor(part, color)
  if not part or not color then return false end
  if not se then return false end
  return se:InvokeServer("SyncMesh", {
    {Part = part, VertexColor = color}
  })
end

function F3XLIB.setLocked(part, locked)
  if not part then return false end
  if not se then return false end
  return se:InvokeServer("SetLocked", {part}, locked)
end

function F3XLIB.addDecoration(part, decorationType)
  if not part or not decorationType then return false end
  if not se then return false end
  return se:InvokeServer("CreateDecorations", {
    {Part = part, DecorationType = decorationType}
  })
end

function F3XLIB.setDecoration(part, decorationType, properties)
  if not part or not decorationType then return false end
  if not se then return false end
  local args = {Part = part, DecorationType = decorationType}
  for k, v in pairs(properties) do
    args[k] = v
  end
  return se:InvokeServer("SyncDecorate", {args})
end

function F3XLIB.addFire(part)
  return F3XLIB.addDecoration(part, "Fire")
end

function F3XLIB.setFire(part, size, heat, color, secondaryColor)
  return F3XLIB.setDecoration(part, "Fire", {
    Size = size,
    Heat = heat,
    Color = color,
    SecondaryColor = secondaryColor
  })
end

function F3XLIB.addParticleEmitter(part)
  return F3XLIB.addDecoration(part, "ParticleEmitter")
end

function F3XLIB.setParticleEmitter(part, properties)
  return F3XLIB.setDecoration(part, "ParticleEmitter", properties)
end

function F3XLIB.addSmoke(part)
  return F3XLIB.addDecoration(part, "Smoke")
end

function F3XLIB.addSparkles(part)
  return F3XLIB.addDecoration(part, "Sparkles")
end

function F3XLIB.addSelectionBox(part)
  return F3XLIB.addDecoration(part, "SelectionBox")
end

function F3XLIB.extractImageFromDecal(decalId)
  if not decalId then return nil end
  if not se then return nil end
  return se:InvokeServer("ExtractImageFromDecal", tostring(decalId))
end

return F3XLIB
