--[[ 
  SlimSpy.lua 
  A lightweight remote-event spy with export and tidy GUI 
]]

-- CONFIG
getgenv().SlimSpyMaxLogs = 500  -- maximum retained entries

-- SERVICES
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- GLOBAL STATE
local logs = {}    -- { {Name, DebugId, Args, ScriptText} }
local gui, entriesContainer, detailText

-- UTILITIES

-- Safe JSON encode
local http = game:GetService("HttpService")
local function encode(t) return http:JSONEncode(t) end

-- Generate Lua snippet for args
local function genArgsCode(args)
    local parts = {}
    for i,v in ipairs(args) do
        parts[i] = typeof(v) == "string" and ("%q"):format(v)
                 or typeof(v) == "number" and tostring(v)
                 or typeof(v) == "Instance" and ("game.%s"):format(v:GetFullName():gsub("%%","%%%%"))
                 or "nil"
    end
    return "local args = {" .. table.concat(parts,", ") .. "}
-- then: remote:FireServer(unpack(args))"
end

-- Log a remote event
local function addLog(name, id, args)
    if #logs >= getgenv().SlimSpyMaxLogs then
        table.remove(logs,1)
        -- remove first UI entry
        if entriesContainer:FindFirstChild("Entry0") then
            entriesContainer.Entry0:Destroy()
        end
        -- renumber existing entries
        for i, child in ipairs(entriesContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child.Name = "Entry" .. i
            end
        end
    end
    local scriptText = genArgsCode(args)
    local entry = {Name=name, DebugId=id, Args=args, Script=scriptText}
    table.insert(logs, entry)

    -- UI: add button
    local btn = Instance.new("TextButton")
    btn.Name = "Entry" .. #logs
    btn.Size = UDim2.new(1, 0, 0, 24)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.BorderSizePixel = 0
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.TextColor3 = Color3.fromRGB(230, 230, 230)
    btn.Text = string.format("[%d] %s", id, name)
    btn.Parent = entriesContainer

    btn.MouseButton1Click:Connect(function()
        detailText.Text = ("[%d] %s

%s"):format(id, name, scriptText)
    end)
end

-- EXPORT
local function exportLogs()
    local out = {}
    for _,e in ipairs(logs) do
        table.insert(out, {
            Name    = e.Name,
            DebugId = e.DebugId,
            Script  = e.Script
        })
    end
    local ok,err = pcall(function()
        writefile("DeltaWorkspace_RemoteLogs.txt", encode(out))
    end)
    if ok then
        warn("SlimSpy: Logs exported.")
    else
        warn("SlimSpy export failed:", err)
    end
end

-- BUILD GUI
do
    gui = Instance.new("ScreenGui")
    gui.Name = "SlimSpy"
    gui.ResetOnSpawn = false
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    local main = Instance.new("Frame", gui)
    main.Size = UDim2.new(0, 500, 0, 350)
    main.Position = UDim2.new(0, 200, 0, 150)
    main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    main.BorderSizePixel = 0

    -- Left panel: entries scroll
    entriesContainer = Instance.new("ScrollingFrame", main)
    entriesContainer.Name = "Entries"
    entriesContainer.Size = UDim2.new(0, 180, 1, -40)
    entriesContainer.Position = UDim2.new(0, 0, 0, 0)
    entriesContainer.BackgroundTransparency = 1
    entriesContainer.BorderSizePixel = 0
    entriesContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    entriesContainer.ScrollBarThickness = 6

    local layout = Instance.new("UIListLayout", entriesContainer)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)

    -- Right panel: details + export button
    local right = Instance.new("Frame", main)
    right.Size = UDim2.new(1, -180, 1, -40)
    right.Position = UDim2.new(0, 180, 0, 0)
    right.BackgroundTransparency = 1

    detailText = Instance.new("TextLabel", right)
    detailText.Name = "Detail"
    detailText.Size = UDim2.new(1, -10, 1, -50)
    detailText.Position = UDim2.new(0, 5, 0, 5)
    detailText.TextWrapped = true
    detailText.TextXAlignment = Enum.TextXAlignment.Left
    detailText.TextYAlignment = Enum.TextYAlignment.Top
    detailText.BackgroundTransparency = 1
    detailText.TextColor3 = Color3.fromRGB(230, 230, 230)
    detailText.Font = Enum.Font.SourceSans
    detailText.TextSize = 14
    detailText.Text = "Select a log entry..."

    -- Export button
    local btn = Instance.new("TextButton", main)
    btn.Name = "ExportButton"
    btn.Size = UDim2.new(0, 120, 0, 30)
    btn.Position = UDim2.new(1, -130, 1, -35)
    btn.Text = "Export Logs"
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.BorderSizePixel = 0

    btn.MouseButton1Click:Connect(exportLogs)
end

-- HOOK __namecall to intercept FireServer on RemoteEvent
do
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local old = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and typeof(self) == "Instance" and self:IsA("RemoteEvent") then
            local dbg = game:GetDebugId(self)
            local args = {...}
            addLog(self.Name, dbg, args)
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end

warn("SlimSpy ready—capture RemoteEvent:FireServer calls!")
