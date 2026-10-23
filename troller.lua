local players = game:GetService("Players")
local runservice = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local replicatedstorage = game:GetService("ReplicatedStorage")
local replicatedfirst = game:GetService("ReplicatedFirst")
local starterplayer = game:GetService("StarterPlayer")
local starterplayerscripts = starterplayer:WaitForChild("StarterPlayerScripts")
local starterguitarget = game:GetService("StarterGui")
local coregui = game:GetService("CoreGui")

local localplayer = players.LocalPlayer
local playergui = localplayer:WaitForChild("PlayerGui")

local screen = Instance.new("ScreenGui")
screen.Name = "advancedremote"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playergui

local frame = Instance.new("Frame")
frame.Name = "main"
frame.Size = UDim2.new(0, 480, 0, 360)
frame.Position = UDim2.new(0.5, -240, 0.5, -180)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderColor3 = Color3.fromRGB(60, 60, 60)
frame.BorderSizePixel = 1
frame.Active = true
frame.Draggable = true
frame.Parent = screen

local topbar = Instance.new("Frame")
topbar.Name = "top"
topbar.Size = UDim2.new(1, 0, 0, 30)
topbar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
topbar.BorderSizePixel = 0
topbar.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "title"
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.Code
title.Text = "scanner"
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topbar

local closebutton = Instance.new("TextButton")
closebutton.Name = "close"
closebutton.Size = UDim2.new(0, 30, 0, 30)
closebutton.Position = UDim2.new(1, -30, 0, 0)
closebutton.BackgroundTransparency = 1
closebutton.Font = Enum.Font.Code
closebutton.Text = "X"
closebutton.TextColor3 = Color3.fromRGB(240, 80, 80)
closebutton.TextSize = 14
closebutton.Parent = topbar

closebutton.MouseButton1Click:Connect(function()
	screen:Destroy()
end)

local sidebar = Instance.new("Frame")
sidebar.Name = "side"
sidebar.Size = UDim2.new(0, 130, 1, -30)
sidebar.Position = UDim2.new(0, 0, 0, 30)
sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
sidebar.BorderSizePixel = 0
sidebar.Parent = frame

local scanbutton = Instance.new("TextButton")
scanbutton.Name = "scanbtn"
scanbutton.Size = UDim2.new(1, -10, 0, 30)
scanbutton.Position = UDim2.new(0, 5, 0, 5)
scanbutton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
scanbutton.BorderColor3 = Color3.fromRGB(70, 70, 70)
scanbutton.Font = Enum.Font.Code
scanbutton.Text = "scanall"
scanbutton.TextColor3 = Color3.fromRGB(220, 220, 220)
scanbutton.TextSize = 12
scanbutton.Parent = sidebar

local firebutton = Instance.new("TextButton")
firebutton.Name = "firebtn"
firebutton.Size = UDim2.new(1, -10, 0, 30)
firebutton.Position = UDim2.new(0, 5, 0, 40)
firebutton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
firebutton.BorderColor3 = Color3.fromRGB(70, 70, 70)
firebutton.Font = Enum.Font.Code
firebutton.Text = "fireall"
firebutton.TextColor3 = Color3.fromRGB(220, 220, 220)
firebutton.TextSize = 12
firebutton.Parent = sidebar

local listscroll = Instance.new("ScrollingFrame")
listscroll.Name = "list"
listscroll.Size = UDim2.new(0, 160, 1, -35)
listscroll.Position = UDim2.new(0, 130, 0, 35)
listscroll.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
listscroll.BorderColor3 = Color3.fromRGB(40, 40, 40)
listscroll.CanvasSize = UDim2.new(0, 0, 0, 0)
listscroll.ScrollBarThickness = 4
listscroll.Parent = frame

local listlayout = Instance.new("UIListLayout")
listlayout.Name = "layout"
listlayout.SortOrder = Enum.SortOrder.LayoutOrder
listlayout.Padding = UDim.new(0, 4)
listlayout.Parent = listscroll

local detailsscroll = Instance.new("ScrollingFrame")
detailsscroll.Name = "details"
detailsscroll.Size = UDim2.new(1, -295, 1, -35)
detailsscroll.Position = UDim2.new(0, 292, 0, 35)
detailsscroll.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
detailsscroll.BorderColor3 = Color3.fromRGB(40, 40, 40)
detailsscroll.CanvasSize = UDim2.new(0, 0, 0, 0)
detailsscroll.ScrollBarThickness = 4
detailsscroll.Parent = frame

local detailslayout = Instance.new("UIListLayout")
detailslayout.Name = "dlayout"
detailslayout.SortOrder = Enum.SortOrder.LayoutOrder
detailslayout.Parent = detailsscroll

local itemtable = {}
local selecteditem = nil
local activeconnections = {}

local function clearui(container)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function cleardetails()
	for _, child in ipairs(detailsscroll:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function analyzersource(src)
	local summary = {}
	local lower = string.lower(src)
	if string.find(lower, "remoteserver") or string.find(lower, "fireserver") or string.find(lower, "remotefunction") then
		table.insert(summary, "communicates with server via remotes")
	end
	if string.find(lower, "tween") or string.find(lower, "lerp") or string.find(lower, "renderstepped") then
		table.insert(summary, "handles animations or frame updates")
	end
	if string.find(lower, "uis") or string.find(lower, "inputbegan") or string.find(lower, "mousebutton") then
		table.insert(summary, "handles player inputs or user interface clicks")
	end
	if string.find(lower, "character") or string.find(lower, "humanoid") or string.find(lower, "rootpart") then
		table.insert(summary, "manipulates character physics or attributes")
	end
	if string.find(lower, "leaderstats") or string.find(lower, "coin") or string.find(lower, "cash") or string.find(lower, "score") then
		table.insert(summary, "manages game currency or stats")
	end
	if #summary == 0 then
		table.insert(summary, "executes custom client logic")
	end
	return table.concat(summary, "; ")
end

local function hookevents(dat)
	local obj = dat.instance
	if obj:IsA("RemoteEvent") then
		local conn = obj.OnClientEvent:Connect(function(...)
			table.insert(dat.events, "fired client: " .. table.concat({...}, ", "))
			if selecteditem == dat then
				showdetails(dat)
			end
		end)
		table.insert(activeconnections, conn)
	elseif obj:IsA("BindableEvent") then
		local conn = obj.Event:Connect(function(...)
			table.insert(dat.events, "bindable fired: " .. table.concat({...}, ", "))
			if selecteditem == dat then
				showdetails(dat)
			end
		end)
		table.insert(activeconnections, conn)
	end
end

local function showdetails(data)
	cleardetails()
	local function addline(txt)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -10, 0, 20)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.Code
		lbl.Text = txt
		lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
		lbl.TextSize = 11
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = detailsscroll
		detailsscroll.CanvasSize = UDim2.new(0, 0, 0, detailslayout.AbsoluteContentSize.Y)
	end
	
	local function addbutton(text, callback)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -10, 0, 25)
		btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		btn.BorderColor3 = Color3.fromRGB(70, 70, 70)
		btn.Font = Enum.Font.Code
		btn.Text = text
		btn.TextColor3 = Color3.fromRGB(240, 240, 240)
		btn.TextSize = 11
		btn.Parent = detailsscroll
		btn.MouseButton1Click:Connect(callback)
		detailsscroll.CanvasSize = UDim2.new(0, 0, 0, detailslayout.AbsoluteContentSize.Y)
	end
	
	addline("name: " .. tostring(data.name))
	addline("path: " .. tostring(data.path))
	addline("type: " .. tostring(data.type))
	
	addbutton("copy path", function()
		pcall(function()
			setclipboard(data.path)
		end)
	end)
	
	if data.type == "localscript" or data.type == "modulescript" then
		addbutton("copy source", function()
			pcall(function()
				setclipboard(data.source)
			end)
		end)
	else
		addbutton("fire object", function()
			pcall(function()
				local obj = data.instance
				if obj:IsA("RemoteEvent") then
					obj:FireServer()
				elseif obj:IsA("UnreliableRemoteEvent") then
					obj:FireServer()
				elseif obj:IsA("RemoteFunction") then
					task.spawn(function()
						obj:InvokeServer()
					end)
				elseif obj:IsA("ClickDetector") then
					fireclickdetector(obj, 0, "MouseClick")
				elseif obj:IsA("TouchInterest") then
					local part = obj.Parent
					if part and part:IsA("BasePart") and localplayer.Character and localplayer.Character:FindFirstChild("HumanoidRootPart") then
						firetouchinterest(localplayer.Character.HumanoidRootPart, part, 0)
						firetouchinterest(localplayer.Character.HumanoidRootPart, part, 1)
					end
				end
			end)
		end)
	end
	
	addbutton("clear logs", function()
		data.events = {}
		showdetails(data)
	end)
	
	if data.type == "localscript" or data.type == "modulescript" then
		addline("--- script purpose ---")
		addline("  " .. tostring(data.analysis))
		addline("--- source code ---")
		for _, line in ipairs(data.sourcelines) do
			addline("  " .. tostring(line))
		end
	else
		addline("--- captured activity ---")
		if #data.events == 0 then
			addline("  no activity recorded yet")
		else
			for _, ev in ipairs(data.events) do
				addline("  " .. tostring(ev))
			end
		end
	end
end

local function scanobjects()
	for _, conn in ipairs(activeconnections) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	activeconnections = {}
	
	itemtable = {}
	clearui(listscroll)
	cleardetails()
	
	local function inspect(parent)
		for _, child in ipairs(parent:GetChildren()) do
			local matched = false
			local tp = ""
			if child:IsA("RemoteEvent") or child:IsA("UnreliableRemoteEvent") then
				matched = true
				tp = "remoteevent"
			elseif child:IsA("RemoteFunction") then
				matched = true
				tp = "remotefunction"
			elseif child:IsA("BindableEvent") or child:IsA("BindableFunction") then
				matched = true
				tp = "bindable"
			elseif child:IsA("ClickDetector") then
				matched = true
				tp = "clickdetector"
			elseif child:IsA("TouchInterest") or (child:IsA("Part") and child:FindFirstChildWhichIsA("TouchInterest")) then
				matched = true
				tp = "touchinterest"
			elseif child:IsA("LocalScript") then
				matched = true
				tp = "localscript"
			elseif child:IsA("ModuleScript") then
				matched = true
				tp = "modulescript"
			end
			
			if matched then
				local src = ""
				local analysis = ""
				local lines = {}
				if tp == "localscript" or tp == "modulescript" then
					pcall(function()
						if decompile then
							src = decompile(child)
						else
							src = "-- decompiler unavailable"
						end
					end)
					analysis = analyzersource(src)
					for line in string.gmatch(src, "[^\r\n]+") do
						table.insert(lines, line)
					end
				end
				
				local entry = {
					instance = child,
					name = child.Name,
					path = child:GetFullName(),
					type = tp,
					events = {},
					source = src,
					sourcelines = lines,
					analysis = analysis
				}
				table.insert(itemtable, entry)
				hookevents(entry)
			end
			
			pcall(function()
				if #child:GetChildren() > 0 and not child:IsA("Player") then
					inspect(child)
				end
			end)
		end
	end
	
	inspect(workspace)
	inspect(replicatedstorage)
	inspect(replicatedfirst)
	inspect(playergui)
	inspect(coregui)
	inspect(starterplayerscripts)
	inspect(starterguitarget)
	inspect(starterplayer)
	inspect(players)
	
	for _, dat in ipairs(itemtable) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, -10, 0, 45)
		card.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
		card.BorderColor3 = Color3.fromRGB(50, 50, 50)
		card.Parent = listscroll
		
		local cardbtn = Instance.new("TextButton")
		cardbtn.Size = UDim2.new(1, 0, 1, 0)
		cardbtn.BackgroundTransparency = 1
		cardbtn.Font = Enum.Font.Code
		cardbtn.Text = dat.name .. "\n[" .. dat.type .. "]"
		cardbtn.TextColor3 = Color3.fromRGB(200, 200, 200)
		cardbtn.TextSize = 11
		cardbtn.Parent = card
		
		cardbtn.MouseButton1Click:Connect(function()
			selecteditem = dat
			showdetails(dat)
		end)
	end
	
	listscroll.CanvasSize = UDim2.new(0, 0, 0, listlayout.AbsoluteContentSize.Y)
end

local function fireobjects()
	for _, dat in ipairs(itemtable) do
		pcall(function()
			local obj = dat.instance
			if obj:IsA("RemoteEvent") then
				obj:FireServer()
			elseif obj:IsA("UnreliableRemoteEvent") then
				obj:FireServer()
			elseif obj:IsA("RemoteFunction") then
				task.spawn(function()
					obj:InvokeServer()
				end)
			elseif obj:IsA("ClickDetector") then
				fireclickdetector(obj, 0, "MouseClick")
			elseif obj:IsA("TouchInterest") then
				local part = obj.Parent
				if part and part:IsA("BasePart") and localplayer.Character and localplayer.Character:FindFirstChild("HumanoidRootPart") then
					firetouchinterest(localplayer.Character.HumanoidRootPart, part, 0)
					firetouchinterest(localplayer.Character.HumanoidRootPart, part, 1)
				end
			end
		end)
		task.wait(0.01)
	end
	
	if selecteditem then
		showdetails(selecteditem)
	end
end

scanbutton.MouseButton1Click:Connect(scanobjects)
firebutton.MouseButton1Click:Connect(fireobjects)
scanobjects()
										
