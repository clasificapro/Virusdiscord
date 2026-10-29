--[[
    Troller Script - MODO CLIENTE (Con Debug de obediencia)
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

local function killSelf()
    local hum = getLocalHumanoid()
    if hum then 
        hum.Health = 0 
        print("[Troller Client] ¡Orden ejecutada: Me he suicidado!")
    else
        warn("[Troller Client] No se encontró Humanoid para matar.")
    end
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

local function applyCommandLocally(cmdName, text)
    print("[Troller Client] Aplicando comando local:", cmdName)
    if cmdName == "kill" then
        killSelf()
    elseif cmdName == "fr" then
        freezeSelf()
    elseif cmdName == "unfr" then
        unfreezeSelf()
    -- Agrega aquí las demás acciones si las necesitas
    end
end

local function processCloudCommand(message)
    if not message or message == "" then return end
    print("[Troller Client] Mensaje recibido de la nube:", message)
    
    if message:sub(1, #PREFIX) ~= PREFIX then return end

    local body = message:sub(#PREFIX + 1)
    local args = splitArgs(body)
    if #args == 0 then return end

    local cmdName = args[1]:lower()
    local targetName, restStart = parseTargetForCmd(args, cmdName)

    if targetName == NO_TARGET then 
        warn("[Troller Client] Objetivo no encontrado en el servidor.")
        return 
    end

    local iAmTarget = false
    if not targetName then
        iAmTarget = true -- Si no pone nick, afecta a todos / o al cliente
    else
        for _, p in ipairs(getPlayersByName(targetName)) do
            if p == LocalPlayer then 
                iAmTarget = true; 
                break 
            end
        end
    end

    if not iAmTarget then 
        print("[Troller Client] El comando no era para mí (Objetivo: " .. tostring(targetName) .. ")")
        return 
    end

    applyCommandLocally(cmdName, "")
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

print("[Troller] Cliente conectado a la nube y escuchando...")
