-- NEVA HUB '
-- Load Compkiller UI
local Compkiller = loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/CompKiller/refs/heads/main/src/source.luau"))();

-- Create Notification
local Notifier = Compkiller.newNotify();

-- Create Config Manager
local ConfigManager = Compkiller:ConfigManager({
	Directory = "NEVA HUB-UI",
	Config = "NEVA HUB-Config"
});

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

-- LOCAL PLAYER & CHARACTER
local player = Players.LocalPlayer
local char, root, humanoid
local antiStunConnection = nil

local function updateCharacter()
    char = player.Character or player.CharacterAdded:Wait()
    root = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
end

updateCharacter()
player.CharacterAdded:Connect(function()
    task.wait(1)
    updateCharacter()
end)

-- SCRIPT-WIDE STATES & VARIABLES
local godConnection, aimConnection
local espEnabled = false
local espConnections = {}
local boostJumpEnabled = false
local isTeleporting = false
local invisibleEnabled = false
local aimbotEnabled = false
local godModeEnabled = false

---------------------------------------------------
--[[           FUNCTION DEFINITIONS            ]]--
---------------------------------------------------

-- TELEPORT / MOVEMENT FUNCTIONS
local doorPositions = {
    Vector3.new(-466, -1, 220), Vector3.new(-466, -2, 116), Vector3.new(-466, -2, 8),
    Vector3.new(-464, -2, -102), Vector3.new(-351, -2, -100), Vector3.new(-354, -2, 5),
    Vector3.new(-354, -2, 115), Vector3.new(-358, -2, 223)
}

local function getNearestDoor()
    if not root then return nil end
    local closest, minDist = nil, math.huge
    for _, door in ipairs(doorPositions) do
        local dist = (root.Position - door).Magnitude
        if dist < minDist then
            minDist = dist
            closest = door
        end
    end
    return closest
end

local function teleportToSky()
    if not root then updateCharacter() end
    local door = getNearestDoor()
    if door and root then
        TweenService:Create(root, TweenInfo.new(1.2), { CFrame = CFrame.new(door) }):Play()
        task.wait(1.3)
        root.CFrame = root.CFrame + Vector3.new(0, 200, 0)
    end
end

local function teleportToGround()
    if not root then updateCharacter() end
    if root then
        root.CFrame = root.CFrame - Vector3.new(0, 50, 0)
    end
end

-- COMBAT / PLAYER STATE FUNCTIONS
function setGodMode(on)
    if not humanoid then updateCharacter() end
    if not humanoid then return end

    godModeEnabled = on
    
    if on then
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge
        if godConnection then godConnection:Disconnect() end
        godConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if humanoid.Health < math.huge then
                humanoid.Health = math.huge
            end
        end)
    else
        if godConnection then godConnection:Disconnect() end
        godConnection = nil
        pcall(function()
            humanoid.MaxHealth = 100
            humanoid.Health = 100
        end)
    end
end

local aimbotRange = 100

local function getClosestAimbotTarget()
    if not root then return nil end

    local closestPlayer, shortestDist = nil, aimbotRange
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid") and p.Character.Humanoid.Health > 0 then
            local targetHRP = p.Character.HumanoidRootPart
            local dist = (root.Position - targetHRP.Position).Magnitude
            
            if dist < shortestDist then
                closestPlayer = p
                shortestDist = dist
            end
        end
    end
    return closestPlayer
end

local function toggleAimbot(state)
    aimbotEnabled = state
    
    if state then
        aimConnection = RunService.Heartbeat:Connect(function()
            local target = getClosestAimbotTarget()
            if target and target.Character and char and root and humanoid then
                local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
                if targetHrp then
                    root.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetHrp.Position.X, root.Position.Y, targetHrp.Position.Z))
                end
            end
        end)
    else
        if aimConnection then
            aimConnection:Disconnect()
            aimConnection = nil
        end
    end
end

UserInputService.JumpRequest:Connect(function()
    if boostJumpEnabled and humanoid and root then
        root.AssemblyLinearVelocity = Vector3.new(0, 100, 0)
        local gravityConn
        gravityConn = RunService.Stepped:Connect(function()
            if not char or not root or not humanoid or not boostJumpEnabled then
                gravityConn:Disconnect()
                return
            end

            if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                root.Velocity = Vector3.new(root.Velocity.X, math.clamp(root.Velocity.Y, -20, 150), root.Velocity.Z)
            elseif humanoid.FloorMaterial ~= Enum.Material.Air then
                gravityConn:Disconnect()
            end
        end)
    end
end)

-- VISUALS FUNCTIONS
function setInvisible(on)
    if not char then updateCharacter() end
    if not char then return end
    
    invisibleEnabled = on
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = on and 1 or part.Parent:IsA("Accessory") and part.Parent.Handle.Transparency or 0
        elseif part:IsA("Decal") then
            part.Transparency = on and 1 or 0
        end
    end
end

local function toggleESP(state)
    espEnabled = state
    if state then
        local function applyHighlight(character)
            if not character or character:FindFirstChild("NEVA HUBESP") then return end
            local h = Instance.new("Highlight")
            h.Name = "NEVA HUBESP"
            h.FillColor = Color3.fromRGB(255, 50, 50)
            h.OutlineColor = Color3.new(1, 1, 1)
            h.FillTransparency = 0.5
            h.OutlineTransparency = 0
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = character
        end

        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                applyHighlight(p.Character)
            end
        end
        
        table.insert(espConnections, Players.PlayerAdded:Connect(function(newP)
            newP.CharacterAdded:Connect(function(char)
                if espEnabled then applyHighlight(char) end
            end)
        end))
        
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player then
                table.insert(espConnections, p.CharacterAdded:Connect(function(char)
                    if espEnabled then applyHighlight(char) end
                end))
            end
        end
    else
        for _, c in ipairs(espConnections) do c:Disconnect() end
        espConnections = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                local h = p.Character:FindFirstChild("NEVA HUBESP")
                if h then h:Destroy() end
            end
        end
    end
end

-- WORLD / SERVER FUNCTIONS
local function serverHop()
    local placeId = game.PlaceId
    local servers = {}
    local success, response = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if success and response and response.data then
        for _, server in ipairs(response.data) do
            if server.playing and server.maxPlayers and server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(servers, server.id)
            end
        end
    end
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(placeId, servers[math.random(1, #servers)])
    else
        Notifier.new({
            Title = "Server Hop",
            Content = "No other servers found!",
            Duration = 3,
            Icon = "rbxassetid://72028320244858"
        });
    end
end

---------------------------------------------------
--[[              UI CREATION                  ]]--
---------------------------------------------------

-- Loading UI
Compkiller:Loader("rbxassetid://72028320244858", 2.5).yield();

-- Creating Window
local Window = Compkiller.new({
	Name = "NEVA HUB",
	Keybind = "LeftAlt",
	Logo = "rbxassetid://72028320244858",
	Scale = Compkiller.Scale.Window,
	TextSize = 15,
});

-- Welcome Notification
Notifier.new({
	Title = "NEVA HUB",
	Content = "Welcome! Script loaded successfully!",
	Duration = 5,
	Icon = "rbxassetid://72028320244858"
});

-- Watermark
local Watermark = Window:Watermark();

Watermark:AddText({
	Icon = "user",
	Text = "NEVA HUB",
});

Watermark:AddText({
	Icon = "clock",
	Text = Compkiller:GetDate(),
});

local Time = Watermark:AddText({
	Icon = "timer",
	Text = "TIME",
});

task.spawn(function()
	while true do task.wait()
		Time:SetText(Compkiller:GetTimeNow());
	end
end)

Watermark:AddText({
	Icon = "server",
	Text = Compkiller.Version,
});

-- Creating Main Category
Window:DrawCategory({
	Name = "Player Features"
});

-- Creating Main Tab
local MainTab = Window:DrawTab({
	Name = "Player Settings",
	Icon = "user",
	EnableScrolling = true
});

-- Player Settings Section
local PlayerSection = MainTab:DrawSection({
	Name = "Player Settings",
	Position = 'left'	
});

PlayerSection:AddToggle({
	Name = "God Mode",
	Flag = "GodMode",
	Default = false,
	Callback = function(value)
		setGodMode(value)
	end,
});

PlayerSection:AddToggle({
	Name = "Aimbot",
	Flag = "Aimbot",
	Default = false,
	Callback = function(value)
		toggleAimbot(value)
	end,
});

PlayerSection:AddToggle({
	Name = "Jump Boost",
	Flag = "JumpBoost",
	Default = false,
	Callback = function(value)
		boostJumpEnabled = value
	end,
});

PlayerSection:AddSlider({
	Name = "Aimbot Range",
	Min = 50,
	Max = 500,
	Default = 100,
	Round = 0,
	Flag = "AimbotRange",
	Callback = function(value)
		aimbotRange = value
	end
});
-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local espEnabled = false
local espConnections = {}
local espElements = {}

local function createESP(player)
    if not player.Character or player.Character:FindFirstChild("ESP") then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP"
    highlight.FillColor = Color3.fromRGB(255, 50, 50)
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = player.Character

    local nameTag = Instance.new("BillboardGui")
    nameTag.Size = UDim2.new(0, 100, 0, 50)
    nameTag.Adornee = player.Character:WaitForChild("Head")
    nameTag.AlwaysOnTop = true

    local nameLabel = Instance.new("TextLabel", nameTag)
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextScaled = true

    nameTag.Parent = player.Character

    espElements[player.UserId] = {highlight, nameTag}
end

local function removeESP(player)
    if espElements[player.UserId] then
        for _, element in ipairs(espElements[player.UserId]) do
            element:Destroy()
        end
        espElements[player.UserId] = nil
    end
end

local function toggleOPESP(state)
    espEnabled = state
    if state then
        for _, player in pairs(Players:GetPlayers()) do
            createESP(player)
        end

        espConnections[#espConnections + 1] = Players.PlayerAdded:Connect(function(newPlayer)
            newPlayer.CharacterAdded:Connect(function()
                if espEnabled then
                    createESP(newPlayer)
                end
            end)
        end)

        for _, player in pairs(Players:GetPlayers()) do
            player.CharacterAdded:Connect(function()
                if espEnabled then
                    createESP(player)
                end
            end)
        end
    else
        for _, connection in ipairs(espConnections) do
            connection:Disconnect()
        end
        espConnections = {}
        for _, player in pairs(Players:GetPlayers()) do
            removeESP(player)
        end
    end
end



PlayerSection:AddToggle({
    Name = "OP ESP",
    Flag = "OPESP",
    Default = false,
    Callback = function(value)
        toggleOPESP(value)
    end,
})

-- Visual Settings Section
local VisualSection = MainTab:DrawSection({
	Name = "Visual Settings",
	Position = 'right'
});
-------

PlayerSection:AddParagraph({
    Title = "Join Our Discord!",
    Content = "Join the NEVA HUB community for updates and support! Click the button below to copy the invite link."
})

PlayerSection:AddButton({
    Name = "Copy Discord Link",
    Callback = function()
        setclipboard("https://discord.gg/8s8PEXz6XC")
        Notifier.new({
            Title = "Link Copied",
            Content = "Discord invite link has been copied to your clipboard!",
            Duration = 3,
            Icon = "rbxassetid://72028320244858"
        })
    end,
}) 
---

VisualSection:AddToggle({
	Name = "ESP",
	Flag = "ESP",
	Default = false,
	Callback = function(value)
		toggleESP(value)
	end,
});

VisualSection:AddToggle({
	Name = "Invisible",
	Flag = "Invisible",
	Default = false,
	Callback = function(value)
		setInvisible(value)
	end,
});
    -- Bypass Speed (Safe Version)

local bypassSpeedEnabled = false
local bypassSpeedValue = 6
local lastStepTime = 0

RunService.RenderStepped:Connect(function()
    if bypassSpeedEnabled and tick() - lastStepTime > 0.2 and root and humanoid then
        local dir = humanoid.MoveDirection
        if dir.Magnitude > 0 then
            lastStepTime = tick()
            local moveDist = math.clamp(bypassSpeedValue, 4, 10)
            local target = root.Position + dir.Unit * moveDist
            local tween = TweenService:Create(root, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {CFrame = CFrame.new(target)})
            tween:Play()
        end
    end
end)

-- Add this to your VisualSection in the UI
VisualSection:AddToggle({
    Name = "Bypass Speed",
    Flag = "BypassSpeedToggle",
    Default = false,
    Callback = function(value)
        bypassSpeedEnabled = value
    end,
})

VisualSection:AddSlider({
    Name = "Bypass Speed Value",
    Min = 4,
    Max = 10,
    Default = 6,
    Round = 0,
    Flag = "BypassSpeedSlider",
    Callback = function(value)
        bypassSpeedValue = value
    end,
})
-- Teleport/Steal Category
Window:DrawCategory({
	Name = "Teleport & Steal"
});

-- Teleport Tab
local TeleportTab = Window:DrawTab({
	Name = "Teleport",
	Icon = "move",
	EnableScrolling = true
});

-- Teleport Section
local TeleportSection = TeleportTab:DrawSection({
	Name = "Teleport Controls",
	Position = 'left'
});

TeleportSection:AddButton({
	Name = "Teleport to Sky",
	Callback = function()
		teleportToSky()
		Notifier.new({
			Title = "Teleport",
			Content = "Teleported to sky!",
			Duration = 2,
			Icon = "rbxassetid://72028320244858"
		});
	end,
});

TeleportSection:AddButton({
	Name = "Teleport to Ground",
	Callback = function()
		teleportToGround()
		Notifier.new({
			Title = "Teleport",
			Content = "Teleported to ground!",
			Duration = 2,
			Icon = "rbxassetid://72028320244858"
		});
	end,
});

-- Steal Section
local StealSection = TeleportTab:DrawSection({
	Name = "Steal Features",
	Position = 'right'
});

local stealActive = false
StealSection:AddToggle({
	Name = "Auto Steal",
	Flag = "AutoSteal",
	Default = false,
	Callback = function(value)
		stealActive = value
		if value then
			-- Auto steal loop
			task.spawn(function()
				while stealActive do
					teleportToSky()
					task.wait(3)
					if stealActive then
						teleportToGround()
						task.wait(2)
					end
				end
			end)
		end
	end,
});

StealSection:AddParagraph({
	Title = "Auto Steal Info",
	Content = "Enable Auto Steal to automatically\nteleport between sky and ground\nfor stealing items!"
});

-- World Category
Window:DrawCategory({
	Name = "World Features"
});

-- World Tab
local WorldTab = Window:DrawTab({
	Name = "World",
	Icon = "globe",
	EnableScrolling = true
});

-- World Section
local WorldSection = WorldTab:DrawSection({
	Name = "Server Settings",
	Position = 'left'
});

WorldSection:AddButton({
	Name = "Server Hop",
	Callback = function()
		serverHop()
	end,
});

WorldSection:AddButton({
	Name = "Rejoin Server",
	Callback = function()
		TeleportService:Teleport(game.PlaceId, player)
	end,
});

-- Info Section
local InfoSection = WorldTab:DrawSection({
	Name = "Script Information",
	Position = 'right'
});

InfoSection:AddParagraph({
	Title = "NEVA HUB",
	Content = "Version: 1.0\nCreated by: NEVA "
});

-- Settings Tab
local SettingsTab = Window:DrawTab({
	Icon = "settings-3",
	Name = "Settings",
	Type = "Single",
	EnableScrolling = true
});

local ThemeTab = Window:DrawTab({
	Icon = "paintbrush",
	Name = "Themes",
	Type = "Single"
});

local Settings = SettingsTab:DrawSection({
	Name = "UI Settings",
});

Settings:AddToggle({
	Name = "Alway Show Frame",
	Default = false,
	Callback = function(v)
		Window.AlwayShowTab = v;
	end,
});

Settings:AddColorPicker({
	Name = "Highlight",
	Default = Compkiller.Colors.Highlight,
	Callback = function(v)
		Compkiller.Colors.Highlight = v;
		Compkiller:RefreshCurrentColor();
	end,
});

Settings:AddColorPicker({
	Name = "Toggle Color",
	Default = Compkiller.Colors.Toggle,
	Callback = function(v)
		Compkiller.Colors.Toggle = v;
		
		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "Drop Color",
	Default = Compkiller.Colors.DropColor,
	Callback = function(v)
		Compkiller.Colors.DropColor = v;

		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "Risky",
	Default = Compkiller.Colors.Risky,
	Callback = function(v)
		Compkiller.Colors.Risky = v;

		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "Mouse Enter",
	Default = Compkiller.Colors.MouseEnter,
	Callback = function(v)
		Compkiller.Colors.MouseEnter = v;

		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "Block Color",
	Default = Compkiller.Colors.BlockColor,
	Callback = function(v)
		Compkiller.Colors.BlockColor = v;

		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "Background Color",
	Default = Compkiller.Colors.BGDBColor,
	Callback = function(v)
		Compkiller.Colors.BGDBColor = v;

		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "Block Background Color",
	Default = Compkiller.Colors.BlockBackground,
	Callback = function(v)
		Compkiller.Colors.BlockBackground = v;

		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "Stroke Color",
	Default = Compkiller.Colors.StrokeColor,
	Callback = function(v)
		Compkiller.Colors.StrokeColor = v;

		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "High Stroke Color",
	Default = Compkiller.Colors.HighStrokeColor,
	Callback = function(v)
		Compkiller.Colors.HighStrokeColor = v;

		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "Switch Color",
	Default = Compkiller.Colors.SwitchColor,
	Callback = function(v)
		Compkiller.Colors.SwitchColor = v;

		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddColorPicker({
	Name = "Line Color",
	Default = Compkiller.Colors.LineColor,
	Callback = function(v)
		Compkiller.Colors.LineColor = v;

		Compkiller:RefreshCurrentColor(v);
	end,
});

Settings:AddButton({
	Name = "Get Theme",
	Callback = function()
		print(Compkiller:GetTheme())
		
		Notifier.new({
			Title = "Notification",
			Content = "Copied Them Color to your clipboard",
			Duration = 5,
			Icon = "rbxassetid://72028320244858"
		});
	end,
});

ThemeTab:DrawSection({
	Name = "UI Themes"
}):AddDropdown({
	Name = "Select Theme",
	Default = "Default",
	Values = {
		"Default",
		"Dark Green",
		"Dark Blue",
		"Purple Rose",
		"Skeet"
	},
	Callback = function(v)
		Compkiller:SetTheme(v)
	end,
})

-- Creating Config Tab --
local ConfigUI = Window:DrawConfig({
	Name = "Config",
	Icon = "folder",
	Config = ConfigManager
});

ConfigUI:Init();
