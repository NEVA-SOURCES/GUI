-- CREDITS SERVER V1 YOUTUBE - SERVER

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
local gui
local godConnection, aimConnection
local espEnabled = false
local espConnections = {}
local boostJumpEnabled = false
local teleportGui
local isTeleporting = false

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
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = on and 1 or part.Parent:IsA("Accessory") and part.Parent.Handle.Transparency or 0
        elseif part:IsA("Decal") then
            part.Transparency = on and 1 or 0
        end
    end
}

local function toggleESP(state)
    espEnabled = state
    if state then
        local function applyHighlight(character)
            if not character or character:FindFirstChild("ServerV1ESP") then return end
            local h = Instance.new("Highlight")
            h.Name = "ServerV1ESP"
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
                local h = p.Character:FindFirstChild("ServerV1ESP")
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
        StarterGui:SetCore("SendNotification", { Title = "Server Hop", Text = "No other servers found.", Duration = 3 })
    end
end

---------------------------------------------------
--[[                       ]]--
---------------------------------------------------

local function applyRainbowEffect(textLabel)
    local hue = 0
    RunService.Heartbeat:Connect(function()
        hue = (hue + 0.01) % 1
        textLabel.TextColor3 = Color3.fromHSV(hue, 1, 1)
    end)
end

-- NEW: Teleport Pop-Up GUI
local function createTeleportGUI()
    teleportGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    teleportGui.Name = "TeleportControl"
    teleportGui.ResetOnSpawn = false
    teleportGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    teleportGui.Enabled = false -- Start hidden

    local mainFrame = Instance.new("Frame", teleportGui)
    mainFrame.Size = UDim2.new(0, 120, 0, 80) -- Smaller frame
    mainFrame.Position = UDim2.new(0.5, -60, 0.5, -40) -- Centered
    mainFrame.BackgroundColor3 = Color3.fromRGB(23, 24, 28)
    mainFrame.BackgroundTransparency = 0.3
    mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
    mainFrame.BorderSizePixel = 1
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    local mainCorner = Instance.new("UICorner", mainFrame)
    mainCorner.CornerRadius = UDim.new(0, 4)

    local titleBar = Instance.new("TextLabel", mainFrame)
    titleBar.Size = UDim2.new(1, 0, 0, 25) -- Smaller title bar
    titleBar.BackgroundColor3 = Color3.fromRGB(15, 16, 20)
    titleBar.BackgroundTransparency = 0
    titleBar.Text = "TELEPORTATION"
    titleBar.Font = Enum.Font.SourceSansBold
    titleBar.TextSize = 16 -- Smaller text
    titleBar.TextColor3 = Color3.new(1, 1, 1)
    titleBar.TextXAlignment = Enum.TextXAlignment.Center
    applyRainbowEffect(titleBar)
    
    local titleCorner = Instance.new("UICorner", titleBar)
    titleCorner.CornerRadius = UDim.new(0, 4)

    local teleportButton = Instance.new("TextButton", mainFrame)
    teleportButton.Size = UDim2.new(0.8, 0, 0, 30) -- Adjusted size to be 80% width
    
    -- This line is corrected to properly center the button horizontally.
    teleportButton.Position = UDim2.new(0.1, 0, 0, titleBar.Size.Y.Offset + (mainFrame.Size.Y.Offset - titleBar.Size.Y.Offset - teleportButton.Size.Y.Offset) / 2)
    
    teleportButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    teleportButton.TextColor3 = Color3.new(1, 1, 1)
    teleportButton.Font = Enum.Font.SourceSansSemibold
    teleportButton.TextSize = 14 -- Smaller text
    teleportButton.Text = "SKY"
    local btnCorner = Instance.new("UICorner", teleportButton)
    btnCorner.CornerRadius = UDim.new(0, 4)
    applyRainbowEffect(teleportButton)

    teleportButton.MouseButton1Click:Connect(function()
        isTeleporting = not isTeleporting
        if isTeleporting then
            teleportToSky()
            teleportButton.Text = "GROUND" -- Change text to STOP when active
            
        else
            teleportToGround()
            teleportButton.Text = "SKY" -- Change text back to START when inactive
            
        end
    end)
end

local function createV1Menu()
    if gui then gui:Destroy() end

    gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    gui.Name = "ServerV1Menu"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local mainFrame = Instance.new("Frame", gui)
    local originalSize = UDim2.new(0, 160, 0, 280) -- Smaller original size
    mainFrame.Size = originalSize
    mainFrame.Position = UDim2.new(0.05, 0, 0.5, -140) -- Adjusted position
    mainFrame.BackgroundColor3 = Color3.fromRGB(23, 24, 28)
    mainFrame.BackgroundTransparency = 0.3
    mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
    mainFrame.BorderSizePixel = 1
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    local mainCorner = Instance.new("UICorner", mainFrame)
    mainCorner.CornerRadius = UDim.new(0, 4)

    local titleBar = Instance.new("TextLabel", mainFrame)
    titleBar.Size = UDim2.new(1, 0, 0, 30) -- Smaller height for title
    titleBar.BackgroundColor3 = Color3.fromRGB(15, 16, 20)
    titleBar.BackgroundTransparency = 0
    titleBar.Text = "Server v1"
    titleBar.Font = Enum.Font.SourceSansBold
    titleBar.TextSize = 20 -- Slightly smaller title
    titleBar.TextColor3 = Color3.new(1, 1, 1)
    titleBar.TextXAlignment = Enum.TextXAlignment.Center
    
    local titleCorner = Instance.new("UICorner", titleBar)
    titleCorner.CornerRadius = UDim.new(0, 4)

    local contentFrame = Instance.new("ScrollingFrame", mainFrame)
    contentFrame.Size = UDim2.new(1, -10, 1, -35) -- Adjusted size
    contentFrame.Position = UDim2.new(0, 5, 0, 30) -- Adjusted position
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 3
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local listLayout = Instance.new("UIListLayout", contentFrame)
    listLayout.Padding = UDim.new(0, 5) -- Reduced padding
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- MINIMIZE BUTTON
    local minimized = false
    local minimizeButton = Instance.new("TextButton", titleBar)
    minimizeButton.Size = UDim2.new(0, 18, 0, 18) -- Smaller minimize button
    minimizeButton.Position = UDim2.new(1, -22, 0.5, -9) -- Adjusted position
    minimizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    minimizeButton.Text = "–"
    minimizeButton.Font = Enum.Font.SourceSansBold
    minimizeButton.TextSize = 14 -- Smaller text
    minimizeButton.TextColor3 = Color3.new(1,1,1)
    local minimizeCorner = Instance.new("UICorner", minimizeButton)
    minimizeCorner.CornerRadius = UDim.new(0, 3)
    
    minimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        contentFrame.Visible = not minimized
        minimizeButton.Text = minimized and "+" or "–"
        
        local targetSize = minimized and UDim2.new(0, 160, 0, 30) or originalSize -- Adjusted for new title bar height
        TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = targetSize}):Play()
    end)

    applyRainbowEffect(titleBar)
    
    local currentLayoutOrder = 1
    local function createCategory(title)
        local categoryLabel = Instance.new("TextLabel", contentFrame)
        categoryLabel.Size = UDim2.new(1, 0, 0, 20) -- Smaller category label
        categoryLabel.Text = title
        categoryLabel.Font = Enum.Font.SourceSansBold
        categoryLabel.TextSize = 15 -- Smaller text
        categoryLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        categoryLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        categoryLabel.BackgroundTransparency = 0.5
        categoryLabel.TextXAlignment = Enum.TextXAlignment.Center
        categoryLabel.LayoutOrder = currentLayoutOrder
        currentLayoutOrder = currentLayoutOrder + 1
        
        local categoryCorner = Instance.new("UICorner", categoryLabel)
        categoryCorner.CornerRadius = UDim.new(0, 4)

        applyRainbowEffect(categoryLabel)
        return categoryLabel
    end

    local function createToggleButton(name, parent, callback)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1, 0, 0, 25) -- Smaller container for toggle
        container.BackgroundTransparency = 1
        container.LayoutOrder = currentLayoutOrder
        currentLayoutOrder = currentLayoutOrder + 1

        local label = Instance.new("TextLabel", container)
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Text = name
        label.Font = Enum.Font.SourceSansSemibold
        label.TextSize = 14 -- Smaller text
        label.TextColor3 = Color3.new(1, 1, 1)
        label.BackgroundTransparency = 1
        label.TextXAlignment = Enum.TextXAlignment.Left
        applyRainbowEffect(label)

        local switch = Instance.new("TextButton", container)
        switch.Size = UDim2.new(0, 35, 0, 18) -- Smaller switch
        switch.Position = UDim2.new(1, -40, 0.5, -9) -- Adjusted position
        switch.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        switch.Text = ""
        local switchCorner = Instance.new("UICorner", switch)
        switchCorner.CornerRadius = UDim.new(0.5, 0)

        local nub = Instance.new("Frame", switch)
        nub.Size = UDim2.new(0, 14, 0, 14) -- Smaller nub
        nub.Position = UDim2.new(0, 2, 0.5, -7) -- Adjusted position
        nub.BackgroundColor3 = Color3.new(1, 1, 1)
        local nubCorner = Instance.new("UICorner", nub)
        nubCorner.CornerRadius = UDim.new(0.5, 0)

        local state = false
        switch.MouseButton1Click:Connect(function()
            state = not state
            callback(state)
            local nubPos = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7) -- Adjusted nub position
            local switchColor = state and Color3.fromRGB(0, 255, 127) or Color3.fromRGB(70, 70, 70)
            TweenService:Create(nub, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Position = nubPos }):Play()
            TweenService:Create(switch, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { BackgroundColor3 = switchColor }):Play()
        end)
    end
    
    local function createOneShotButton(name, parent, callback)
        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(1, 0, 0, 25) -- Smaller button
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
        btn.BackgroundTransparency = 1
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.SourceSansSemibold
        btn.TextSize = 14 -- Smaller text
        btn.Text = name
        btn.LayoutOrder = currentLayoutOrder
        currentLayoutOrder = currentLayoutOrder + 1
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 4)
        applyRainbowEffect(btn)

        btn.MouseButton1Click:Connect(callback)
    end
    
    -- CREATE UI ELEMENTS
    -- Player Settings
    createCategory("PLAYER SETTINGS")
    createToggleButton("Godmode", contentFrame, setGodMode)
    createToggleButton("Aimbot", contentFrame, toggleAimbot)
    createToggleButton("Jump Boost", contentFrame, function(state) boostJumpEnabled = state end)

    -- Visual Settings
    createCategory("VISUALS SETTINGS")
    createToggleButton("ESP", contentFrame, toggleESP)
    createToggleButton("Invisible", contentFrame, setInvisible)

    -- Steal Settings
    createCategory("STEAL SETTING")
    createOneShotButton("Start Steal", contentFrame, function()
        if teleportGui then
            teleportGui.Enabled = not teleportGui.Enabled
        end
    end)
    
    -- World Settings
    createCategory("WORLD SETTINGS")
    createOneShotButton("Change Server", contentFrame, serverHop)
end

-- Initialize Menus
createTeleportGUI()
createV1Menu()


