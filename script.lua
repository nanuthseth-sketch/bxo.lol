-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer
local cam = Workspace.CurrentCamera
local MC_FONT = Enum.Font.Arcade

-- // Color Palettes
local ColorList = {
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(0, 255, 128),
    Color3.fromRGB(255, 60, 60),
    Color3.fromRGB(60, 160, 255),
    Color3.fromRGB(255, 220, 0),
    Color3.fromRGB(180, 60, 255),
}
local fovColorIdx, espColorIdx = 1, 1

-- // Settings Configuration (All features default to OFF)
local Settings = {
    -- Aimbot & Combat
    AimbotEnabled = false,
    AutoFire = false,
    TargetLock = false,
    AutoJump = false,
    TeamCheck = false,
    WallCheck = false,
    Prediction = false,
    FOV = 120,
    FOVVisible = false,
    Smoothness = 0.1,
    MaxDistance = 5000,
    TargetPart = "Head",

    -- Visuals / ESP
    VisualsEnabled = false,
    BoxEnabled = false,
    NameEnabled = false,
    DistanceESPEnabled = false,
    HealthBarEnabled = false,
    SkeletonEnabled = false,
    TracersEnabled = false,

    -- WalkSpeed Macro
    WalkSpeedEnabled = false,
    WalkSpeedVal = 28,

    -- UI Controls
    LockBtnMovable = true,
    WalkSpeedBtnMovable = true,
}

local CurrentTarget = nil
local MobileLockActive = false

-- // Key System UI
local KeyGui = Instance.new("ScreenGui", gethui and gethui() or lp:WaitForChild("PlayerGui"))
KeyGui.Name = "BoxKeySystem"
KeyGui.IgnoreGuiInset = true
KeyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local KeyFrame = Instance.new("Frame", KeyGui)
KeyFrame.Size, KeyFrame.Position = UDim2.new(0, 360, 0, 190), UDim2.new(0.5, -180, 0.5, -95)
KeyFrame.BackgroundColor3, KeyFrame.BackgroundTransparency, KeyFrame.BorderColor3 = Color3.fromRGB(18, 22, 32), 0.25, Color3.fromRGB(70, 90, 130)
KeyFrame.ZIndex = 10
Instance.new("UICorner", KeyFrame).CornerRadius = UDim.new(0, 8)

local KeyTitle = Instance.new("TextLabel", KeyFrame)
KeyTitle.Size, KeyTitle.BackgroundTransparency, KeyTitle.Font, KeyTitle.Text, KeyTitle.TextColor3, KeyTitle.TextSize = UDim2.new(1, 0, 0, 45), 1, MC_FONT, "bxo | Key Authentication", Color3.fromRGB(240, 240, 255), 15
KeyTitle.ZIndex = 11

local KeyBox = Instance.new("TextBox", KeyFrame)
KeyBox.Size, KeyBox.Position, KeyBox.BackgroundColor3, KeyBox.BackgroundTransparency, KeyBox.Font = UDim2.new(1, -40, 0, 38), UDim2.new(0, 20, 0, 55), Color3.fromRGB(12, 16, 26), 0.4, MC_FONT
KeyBox.PlaceholderText, KeyBox.Text, KeyBox.TextColor3, KeyBox.TextSize = "Enter key (bxo.lol@bxo)...", "", Color3.fromRGB(255, 255, 255), 12
KeyBox.ZIndex = 11
Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 4)

local VerifyBtn = Instance.new("TextButton", KeyFrame)
VerifyBtn.Size, VerifyBtn.Position, VerifyBtn.BackgroundColor3, VerifyBtn.Font, VerifyBtn.Text, VerifyBtn.TextColor3, VerifyBtn.TextSize = UDim2.new(1, -40, 0, 38), UDim2.new(0, 20, 0, 115), Color3.fromRGB(45, 70, 120), MC_FONT, "Verify Key", Color3.fromRGB(255, 255, 255), 14
VerifyBtn.ZIndex = 11
Instance.new("UICorner", VerifyBtn).CornerRadius = UDim.new(0, 4)

local verified = false
local function AttemptVerification()
    if KeyBox.Text == "bxo.lol@bxo" then verified = true KeyGui:Destroy()
    else VerifyBtn.Text = "Invalid Key!" VerifyBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40) task.wait(1.2) VerifyBtn.Text = "Verify Key" VerifyBtn.BackgroundColor3 = Color3.fromRGB(45, 70, 120) end
end
VerifyBtn.MouseButton1Click:Connect(AttemptVerification)
KeyBox.FocusLost:Connect(function(enter) if enter then AttemptVerification() end end)
repeat task.wait() until verified

-- // Main GUI Setup
local gui = Instance.new("ScreenGui", gethui and gethui() or lp:WaitForChild("PlayerGui"))
gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn = "GlassyMinecraftUI", true, false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- // FOV Circle
local FOVGuiCircle = Instance.new("Frame", gui)
FOVGuiCircle.Name, FOVGuiCircle.AnchorPoint, FOVGuiCircle.Position = "FOVCircle", Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0.5, 0)
FOVGuiCircle.Size, FOVGuiCircle.BackgroundTransparency, FOVGuiCircle.Visible = UDim2.new(0, Settings.FOV * 2, 0, Settings.FOV * 2), 1, Settings.FOVVisible
FOVGuiCircle.ZIndex = 1
Instance.new("UICorner", FOVGuiCircle).CornerRadius = UDim.new(1, 0)
local FOVStroke = Instance.new("UIStroke", FOVGuiCircle)
FOVStroke.Color, FOVStroke.Thickness = ColorList[fovColorIdx], 1.5

local function MakeDraggable(obj, movableCheckFunc)
    local dragging, dragStart, startPos = false, nil, nil
    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if not movableCheckFunc or movableCheckFunc() then
                dragging, dragStart, startPos = true, input.Position, obj.AbsolutePosition
            end
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            obj.Position = UDim2.new(0, startPos.X + delta.X, 0, startPos.Y + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

local NotificationContainer = Instance.new("Frame", gui)
NotificationContainer.Size, NotificationContainer.Position, NotificationContainer.BackgroundTransparency = UDim2.new(0, 200, 1, 0), UDim2.new(1, -210, 0, 80), 1
NotificationContainer.ZIndex = 25

local function ShowSideNotification(msg)
    local NotifCard = Instance.new("Frame", NotificationContainer)
    NotifCard.Size, NotifCard.Position, NotifCard.BackgroundColor3, NotifCard.BackgroundTransparency = UDim2.new(1, 0, 0, 36), UDim2.new(1, 20, 0, #NotificationContainer:GetChildren() * 42), Color3.fromRGB(15, 20, 30), 0.35
    NotifCard.ZIndex = 26
    Instance.new("UICorner", NotifCard).CornerRadius = UDim.new(0, 6)
    local txt = Instance.new("TextLabel", NotifCard)
    txt.Size, txt.BackgroundTransparency, txt.Font, txt.Text, txt.TextColor3, txt.TextSize, txt.TextXAlignment = UDim2.new(1, -10, 1, 0), 1, MC_FONT, msg, Color3.fromRGB(80, 255, 150), 13, Enum.TextXAlignment.Left
    txt.ZIndex = 27
    NotifCard:TweenPosition(UDim2.new(0, 0, 0, #NotificationContainer:GetChildren() * 42), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
    task.delay(2.5, function() if NotifCard and NotifCard.Parent then NotifCard:Destroy() end end)
end
ShowSideNotification("Key Verified Successfully!")

-- // Main Window
local MainFrame = Instance.new("Frame", gui)
MainFrame.Size, MainFrame.Position, MainFrame.BackgroundColor3, MainFrame.BackgroundTransparency, MainFrame.Active = UDim2.new(0, 500, 0, 350), UDim2.new(0.5, -250, 0.5, -175), Color3.fromRGB(18, 22, 32), 0.45, true
MainFrame.ZIndex = 10
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
MakeDraggable(MainFrame)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size, Title.Position, Title.BackgroundTransparency, Title.Font, Title.Text, Title.TextColor3, Title.TextSize = UDim2.new(1, -45, 0, 30), UDim2.new(0, 15, 0, 0), 1, MC_FONT, "bxo | Premium Suite", Color3.fromRGB(240, 240, 255), 16
Title.ZIndex = 11

local MinimizeBtn = Instance.new("TextButton", MainFrame)
MinimizeBtn.Size, MinimizeBtn.Position, MinimizeBtn.BackgroundColor3, MinimizeBtn.Font, MinimizeBtn.Text, MinimizeBtn.TextColor3, MinimizeBtn.TextSize = UDim2.new(0, 26, 0, 24), UDim2.new(1, -32, 0, 3), Color3.fromRGB(30, 40, 60), MC_FONT, "-", Color3.fromRGB(255, 255, 255), 16
MinimizeBtn.ZIndex = 11
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 4)

local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size, Sidebar.Position, Sidebar.BackgroundColor3, Sidebar.BackgroundTransparency = UDim2.new(0, 135, 1, -55), UDim2.new(0, 0, 0, 32), Color3.fromRGB(10, 14, 22), 0.55
Sidebar.ZIndex = 11

local ContentPanel = Instance.new("Frame", MainFrame)
ContentPanel.Size, ContentPanel.Position, ContentPanel.BackgroundColor3, ContentPanel.BackgroundTransparency = UDim2.new(1, -140, 1, -55), UDim2.new(0, 138, 0, 32), Color3.fromRGB(12, 16, 26), 0.6
ContentPanel.ZIndex = 11

local StatusFooter = Instance.new("TextLabel", MainFrame)
StatusFooter.Size, StatusFooter.Position, StatusFooter.BackgroundColor3, StatusFooter.Font, StatusFooter.Text, StatusFooter.TextColor3, StatusFooter.TextSize = UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 1, -20), Color3.fromRGB(8, 11, 18), MC_FONT, " Status: Active | FPS: 60", Color3.fromRGB(120, 200, 140), 10
StatusFooter.ZIndex = 12

local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    Sidebar.Visible, ContentPanel.Visible, StatusFooter.Visible = not isMinimized, not isMinimized, not isMinimized
    MinimizeBtn.Text = isMinimized and "+" or "-"
    MainFrame.Size = isMinimized and UDim2.new(0, 500, 0, 32) or UDim2.new(0, 500, 0, 350)
end)

-- // Tabs & Pages
local Pages, Tabs = {}, {}
local function CreatePage(name)
    local Page = Instance.new("ScrollingFrame", ContentPanel)
    Page.Name, Page.Size, Page.Position, Page.BackgroundTransparency, Page.AutomaticCanvasSize = name.."Page", UDim2.new(1, -10, 1, -10), UDim2.new(0, 5, 0, 5), 1, Enum.AutomaticSize.Y
    Page.Visible = false
    Page.ZIndex = 12
    Pages[name] = Page
    return Page
end
CreatePage("Aimbot") CreatePage("Visuals") CreatePage("Settings")

local function SwitchTab(tabName)
    for name, page in pairs(Pages) do page.Visible = (name == tabName) end
    for name, btn in pairs(Tabs) do
        btn.BackgroundColor3 = (name == tabName) and Color3.fromRGB(45, 70, 120) or Color3.fromRGB(15, 20, 30)
    end
end

for i, name in ipairs({"Aimbot", "Visuals", "Settings"}) do
    local TabBtn = Instance.new("TextButton", Sidebar)
    TabBtn.Size, TabBtn.Position, TabBtn.BackgroundColor3, TabBtn.Font, TabBtn.Text, TabBtn.TextColor3, TabBtn.TextSize = UDim2.new(1, -10, 0, 32), UDim2.new(0, 5, 0, (i - 1) * 38 + 10), (i == 1) and Color3.fromRGB(45, 70, 120) or Color3.fromRGB(15, 20, 30), MC_FONT, " " .. name, Color3.fromRGB(255, 255, 255), 14
    TabBtn.ZIndex = 12
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 4)
    Tabs[name] = TabBtn
    TabBtn.MouseButton1Click:Connect(function() SwitchTab(name) end)
end
SwitchTab("Aimbot")

local function AddToggle(page, name, default, callback)
    local ToggleBtn = Instance.new("TextButton", page)
    ToggleBtn.Size, ToggleBtn.Position, ToggleBtn.BackgroundColor3, ToggleBtn.BackgroundTransparency, ToggleBtn.Font = UDim2.new(1, -10, 0, 24), UDim2.new(0, 5, 0, #page:GetChildren() * 28 + 15), default and Color3.fromRGB(30, 80, 60) or Color3.fromRGB(20, 25, 38), 0.4, MC_FONT
    ToggleBtn.Text, ToggleBtn.TextColor3, ToggleBtn.TextSize, ToggleBtn.TextXAlignment = " " .. name .. ": " .. (default and "ON" or "OFF"), Color3.fromRGB(220, 230, 245), 12, Enum.TextXAlignment.Left
    ToggleBtn.ZIndex = 13
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)
    local state = default
    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        ToggleBtn.BackgroundColor3 = state and Color3.fromRGB(30, 80, 60) or Color3.fromRGB(20, 25, 38)
        ToggleBtn.Text = " " .. name .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)
end

-- // Populate Aimbot Tab (All default to OFF)
AddToggle(Pages["Aimbot"], "Enable Aimbot", Settings.AimbotEnabled, function(v) Settings.AimbotEnabled = v end)
AddToggle(Pages["Aimbot"], "Auto Fire (0.04s)", Settings.AutoFire, function(v) Settings.AutoFire = v end)
AddToggle(Pages["Aimbot"], "Target Lock", Settings.TargetLock, function(v) Settings.TargetLock = v end)
AddToggle(Pages["Aimbot"], "Auto Jump", Settings.AutoJump, function(v) Settings.AutoJump = v end)
AddToggle(Pages["Aimbot"], "Prediction", Settings.Prediction, function(v) Settings.Prediction = v end)
AddToggle(Pages["Aimbot"], "Team Check", Settings.TeamCheck, function(v) Settings.TeamCheck = v end)
AddToggle(Pages["Aimbot"], "Wall Check", Settings.WallCheck, function(v) Settings.WallCheck = v end)
AddToggle(Pages["Aimbot"], "FOV Circle", Settings.FOVVisible, function(v) Settings.FOVVisible = v end)

-- FOV Color Swatch Box
local FOVColorRowY = #Pages["Aimbot"]:GetChildren() * 28 + 15
local FOVColorLabel = Instance.new("TextLabel", Pages["Aimbot"])
FOVColorLabel.Size, FOVColorLabel.Position, FOVColorLabel.BackgroundTransparency, FOVColorLabel.Font, FOVColorLabel.Text, FOVColorLabel.TextColor3, FOVColorLabel.TextSize, FOVColorLabel.TextXAlignment = UDim2.new(1, -45, 0, 24), UDim2.new(0, 5, 0, FOVColorRowY), 1, MC_FONT, " FOV Circle Color (Tap)", Color3.fromRGB(220, 230, 245), 12, Enum.TextXAlignment.Left
FOVColorLabel.ZIndex = 13

local FOVColorBox = Instance.new("TextButton", Pages["Aimbot"])
FOVColorBox.Size, FOVColorBox.Position, FOVColorBox.BackgroundColor3, FOVColorBox.BorderColor3, FOVColorBox.Text = UDim2.new(0, 32, 0, 22), UDim2.new(1, -38, 0, FOVColorRowY + 1), ColorList[fovColorIdx], Color3.fromRGB(255, 255, 255), ""
FOVColorBox.ZIndex = 13
Instance.new("UICorner", FOVColorBox).CornerRadius = UDim.new(0, 4)
FOVColorBox.MouseButton1Click:Connect(function()
    fovColorIdx = (fovColorIdx % #ColorList) + 1
    FOVColorBox.BackgroundColor3 = ColorList[fovColorIdx]
    FOVStroke.Color = ColorList[fovColorIdx]
    ShowSideNotification("FOV Color Changed")
end)

-- FOV Radius Slider
local FOVRowY = #Pages["Aimbot"]:GetChildren() * 28 + 20
local FOVText = Instance.new("TextLabel", Pages["Aimbot"])
FOVText.Size, FOVText.Position, FOVText.BackgroundTransparency, FOVText.Font, FOVText.Text, FOVText.TextColor3, FOVText.TextSize, FOVText.TextXAlignment = UDim2.new(1, -10, 0, 18), UDim2.new(0, 5, 0, FOVRowY), 1, MC_FONT, "FOV Radius: " .. Settings.FOV .. " / 300", Color3.fromRGB(220, 230, 245), 12, Enum.TextXAlignment.Left
FOVText.ZIndex = 13

local FOVBarBtn = Instance.new("TextButton", Pages["Aimbot"])
FOVBarBtn.Size, FOVBarBtn.Position, FOVBarBtn.BackgroundColor3, FOVBarBtn.BackgroundTransparency, FOVBarBtn.BorderColor3, FOVBarBtn.Font, FOVBarBtn.Text, FOVBarBtn.TextColor3, FOVBarBtn.TextSize = UDim2.new(1, -10, 0, 20), UDim2.new(0, 5, 0, FOVRowY + 20), Color3.fromRGB(20, 25, 38), 0.4, Color3.fromRGB(60, 80, 115), MC_FONT, "- 10                           + 10", Color3.fromRGB(180, 200, 230), 11
FOVBarBtn.ZIndex = 13
FOVBarBtn.MouseButton1Click:Connect(function()
    Settings.FOV = (Settings.FOV >= 300) and 10 or (Settings.FOV + 10)
    FOVText.Text = "FOV Radius: " .. Settings.FOV .. " / 300"
end)

-- Shoot Distance
local DistRowY = #Pages["Aimbot"]:GetChildren() * 28 + 25
local DistText = Instance.new("TextLabel", Pages["Aimbot"])
DistText.Size, DistText.Position, DistText.BackgroundTransparency, DistText.Font, DistText.Text, DistText.TextColor3, DistText.TextSize, DistText.TextXAlignment = UDim2.new(1, -10, 0, 18), UDim2.new(0, 5, 0, DistRowY), 1, MC_FONT, "Shoot Distance: " .. Settings.MaxDistance .. "m / 30000m", Color3.fromRGB(220, 230, 245), 12, Enum.TextXAlignment.Left
DistText.ZIndex = 13

local DistBarBtn = Instance.new("TextButton", Pages["Aimbot"])
DistBarBtn.Size, DistBarBtn.Position, DistBarBtn.BackgroundColor3, DistBarBtn.BackgroundTransparency, DistBarBtn.BorderColor3, DistBarBtn.Font, DistBarBtn.Text, DistBarBtn.TextColor3, DistBarBtn.TextSize = UDim2.new(1, -10, 0, 20), UDim2.new(0, 5, 0, DistRowY + 20), Color3.fromRGB(20, 25, 38), 0.4, Color3.fromRGB(60, 80, 115), MC_FONT, "- 500m                     + 500m", Color3.fromRGB(180, 200, 230), 11
DistBarBtn.ZIndex = 13
DistBarBtn.MouseButton1Click:Connect(function()
    Settings.MaxDistance = (Settings.MaxDistance >= 30000) and 100 or (Settings.MaxDistance + 500)
    DistText.Text = "Shoot Distance: " .. Settings.MaxDistance .. "m / 30000m"
end)

-- // Populate Visuals Tab (All default to OFF)
AddToggle(Pages["Visuals"], "Enable Visuals", Settings.VisualsEnabled, function(v) Settings.VisualsEnabled = v end)
AddToggle(Pages["Visuals"], "Box (Enemy)", Settings.BoxEnabled, function(v) Settings.BoxEnabled = v end)
AddToggle(Pages["Visuals"], "Name (Enemy)", Settings.NameEnabled, function(v) Settings.NameEnabled = v end)
AddToggle(Pages["Visuals"], "Distance (Enemy)", Settings.DistanceESPEnabled, function(v) Settings.DistanceESPEnabled = v end)
AddToggle(Pages["Visuals"], "Health Bar (Enemy)", Settings.HealthBarEnabled, function(v) Settings.HealthBarEnabled = v end)
AddToggle(Pages["Visuals"], "Skeleton (Enemy)", Settings.SkeletonEnabled, function(v) Settings.SkeletonEnabled = v end)
AddToggle(Pages["Visuals"], "Tracers (Enemy)", Settings.TracersEnabled, function(v) Settings.TracersEnabled = v end)

-- ESP Color Swatch
local ESPColorRowY = #Pages["Visuals"]:GetChildren() * 28 + 15
local ESPColorLabel = Instance.new("TextLabel", Pages["Visuals"])
ESPColorLabel.Size, ESPColorLabel.Position, ESPColorLabel.BackgroundTransparency, ESPColorLabel.Font, ESPColorLabel.Text, ESPColorLabel.TextColor3, ESPColorLabel.TextSize, ESPColorLabel.TextXAlignment = UDim2.new(1, -45, 0, 24), UDim2.new(0, 5, 0, ESPColorRowY), 1, MC_FONT, " ESP Elements Color (Tap)", Color3.fromRGB(220, 230, 245), 12, Enum.TextXAlignment.Left
ESPColorLabel.ZIndex = 13

local ESPColorBox = Instance.new("TextButton", Pages["Visuals"])
ESPColorBox.Size, ESPColorBox.Position, ESPColorBox.BackgroundColor3, ESPColorBox.BorderColor3, ESPColorBox.Text = UDim2.new(0, 32, 0, 22), UDim2.new(1, -38, 0, ESPColorRowY + 1), ColorList[espColorIdx], Color3.fromRGB(255, 255, 255), ""
ESPColorBox.ZIndex = 13
Instance.new("UICorner", ESPColorBox).CornerRadius = UDim.new(0, 4)
ESPColorBox.MouseButton1Click:Connect(function()
    espColorIdx = (espColorIdx % #ColorList) + 1
    ESPColorBox.BackgroundColor3 = ColorList[espColorIdx]
    ShowSideNotification("ESP Color Changed")
end)

-- // Populate Settings Tab (WalkSpeed Controls)
local SettingsPage = Pages["Settings"]

local LoadWalkSpeedBtn = Instance.new("TextButton", SettingsPage)
LoadWalkSpeedBtn.Size, LoadWalkSpeedBtn.Position, LoadWalkSpeedBtn.BackgroundColor3, LoadWalkSpeedBtn.Font, LoadWalkSpeedBtn.Text, LoadWalkSpeedBtn.TextColor3, LoadWalkSpeedBtn.TextSize = UDim2.new(1, -10, 0, 28), UDim2.new(0, 5, 0, 10), Color3.fromRGB(20, 25, 38), MC_FONT, "Load WalkSpeed: OFF", Color3.fromRGB(240, 240, 255), 12
LoadWalkSpeedBtn.ZIndex = 13
Instance.new("UICorner", LoadWalkSpeedBtn).CornerRadius = UDim.new(0, 4)

local SpeedLabel = Instance.new("TextLabel", SettingsPage)
SpeedLabel.Size, SpeedLabel.Position, SpeedLabel.BackgroundTransparency, SpeedLabel.Font, SpeedLabel.Text, SpeedLabel.TextColor3, SpeedLabel.TextSize, SpeedLabel.TextXAlignment = UDim2.new(1, -10, 0, 16), UDim2.new(0, 5, 0, 43), 1, MC_FONT, "WalkSpeed Value", Color3.fromRGB(180, 195, 220), 11, Enum.TextXAlignment.Left
SpeedLabel.ZIndex = 13

local SpeedBox = Instance.new("TextBox", SettingsPage)
SpeedBox.Size, SpeedBox.Position, SpeedBox.BackgroundColor3, SpeedBox.Font, SpeedBox.Text, SpeedBox.TextColor3, SpeedBox.TextSize = UDim2.new(1, -10, 0, 26), UDim2.new(0, 5, 0, 61), Color3.fromRGB(12, 16, 26), MC_FONT, tostring(Settings.WalkSpeedVal), Color3.fromRGB(255, 255, 255), 12
SpeedBox.ZIndex = 13
Instance.new("UICorner", SpeedBox).CornerRadius = UDim.new(0, 4)
SpeedBox.FocusLost:Connect(function()
    local val = tonumber(SpeedBox.Text)
    if val then
        Settings.WalkSpeedVal = val
        ShowSideNotification("WalkSpeed Set to " .. val)
    end
end)

AddToggle(SettingsPage, "Lock Btn: Freeze/Free", Settings.LockBtnMovable, function(v) Settings.LockBtnMovable = v end)
AddToggle(SettingsPage, "WalkSpeed Btn: Freeze/Free", Settings.WalkSpeedBtnMovable, function(v) Settings.WalkSpeedBtnMovable = v end)

-- // Toggle UI Button
local ToggleUIBtn = Instance.new("TextButton", gui)
ToggleUIBtn.Size, ToggleUIBtn.Position, ToggleUIBtn.BackgroundColor3, ToggleUIBtn.Font, ToggleUIBtn.Text, ToggleUIBtn.TextColor3, ToggleUIBtn.TextSize = UDim2.new(0, 95, 0, 28), UDim2.new(0, 20, 0, 160), Color3.fromRGB(15, 20, 32), MC_FONT, "Toggle UI", Color3.fromRGB(240, 240, 255), 13
ToggleUIBtn.ZIndex = 15
MakeDraggable(ToggleUIBtn)
ToggleUIBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

-- // Movable / Freezable Mobile Lock Button
local MobileLockBtn = Instance.new("TextButton", gui)
MobileLockBtn.Size, MobileLockBtn.Position, MobileLockBtn.BackgroundColor3, MobileLockBtn.Font, MobileLockBtn.Text, MobileLockBtn.TextColor3, MobileLockBtn.TextSize = UDim2.new(0, 65, 0, 65), UDim2.new(1, -135, 0, 170), Color3.fromRGB(20, 25, 35), MC_FONT, "LOCK", Color3.fromRGB(255, 255, 255), 14
MobileLockBtn.ZIndex = 15
Instance.new("UICorner", MobileLockBtn).CornerRadius = UDim.new(0, 12)

MakeDraggable(MobileLockBtn, function() return Settings.LockBtnMovable end)

MobileLockBtn.Activated:Connect(function()
    MobileLockActive = not MobileLockActive
    if not MobileLockActive then CurrentTarget = nil end
    ShowSideNotification(MobileLockActive and "Mobile Lock Active" or "Unlocked")
end)

-- // Movable / Freezable Floating WalkSpeed Button
local WalkSpeedBtn = Instance.new("TextButton", gui)
WalkSpeedBtn.Size, WalkSpeedBtn.Position, WalkSpeedBtn.BackgroundColor3, WalkSpeedBtn.Font, WalkSpeedBtn.Text, WalkSpeedBtn.TextColor3, WalkSpeedBtn.TextSize = UDim2.new(0, 140, 0, 48), UDim2.new(0.5, -70, 0, 120), Color3.fromRGB(15, 20, 32), MC_FONT, "▶ WalkSpeed", Color3.fromRGB(255, 255, 255), 15
WalkSpeedBtn.ZIndex = 15
Instance.new("UICorner", WalkSpeedBtn).CornerRadius = UDim.new(0, 10)

MakeDraggable(WalkSpeedBtn, function() return Settings.WalkSpeedBtnMovable end)

local function ToggleWalkSpeedFeature()
    Settings.WalkSpeedEnabled = not Settings.WalkSpeedEnabled
    LoadWalkSpeedBtn.BackgroundColor3 = Settings.WalkSpeedEnabled and Color3.fromRGB(30, 80, 60) or Color3.fromRGB(20, 25, 38)
    LoadWalkSpeedBtn.Text = "Load WalkSpeed: " .. (Settings.WalkSpeedEnabled and "ON" or "OFF")
    WalkSpeedBtn.Text = Settings.WalkSpeedEnabled and "⏸ WalkSpeed" or "▶ WalkSpeed"
    WalkSpeedBtn.BackgroundColor3 = Settings.WalkSpeedEnabled and Color3.fromRGB(40, 100, 60) or Color3.fromRGB(15, 20, 32)
    ShowSideNotification("WalkSpeed " .. (Settings.WalkSpeedEnabled and "Enabled" or "Disabled"))
end

WalkSpeedBtn.Activated:Connect(ToggleWalkSpeedFeature)
LoadWalkSpeedBtn.MouseButton1Click:Connect(ToggleWalkSpeedFeature)

-- // Fully Functional WalkSpeed & Movement Macro Loop (RenderStepped)
RunService.RenderStepped:Connect(function(dt)
    if Settings.WalkSpeedEnabled then
        pcall(function()
            local char = lp.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if hum then
                hum.WalkSpeed = Settings.WalkSpeedVal
            end
            if root and hum and hum.MoveDirection.Magnitude > 0 then
                root.CFrame = root.CFrame + (hum.MoveDirection * (Settings.WalkSpeedVal * dt * 1.5))
            end
        end)
    end
end)

-- // Aimbot Target Search
local function GetClosestTarget()
    local closestTarget, shortestDistance = nil, math.huge
    local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character then
            if Settings.TeamCheck and player.Team and lp.Team and player.Team == lp.Team then continue end
            local char = player.Character
            local hum = char:FindFirstChild("Humanoid")
            local targetPart = char:FindFirstChild(Settings.TargetPart) or char:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and targetPart then
                local evalPos = targetPart.Position
                if Settings.Prediction and char:FindFirstChild("HumanoidRootPart") then
                    evalPos = evalPos + (char.HumanoidRootPart.AssemblyLinearVelocity * ((evalPos - cam.CFrame.Position).Magnitude / 2500))
                end
                if (evalPos - cam.CFrame.Position).Magnitude <= Settings.MaxDistance then
                    local screenPos, onScreen = cam:WorldToViewportPoint(evalPos)
                    if onScreen and screenPos.Z > 0 then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if dist <= Settings.FOV and dist < shortestDistance then
                            shortestDistance, closestTarget = dist, targetPart
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

-- // ESP Setup & Bounding Box Logic
local boxes = {}

local function makeBox()
	local box = Instance.new("Frame", gui)
	box.BackgroundTransparency, box.BorderSizePixel = 1, 0
    box.ZIndex = 5
	
	local stroke = Instance.new("UIStroke", box)
	stroke.Color, stroke.Thickness = ColorList[espColorIdx], 1.5

	local barBg = Instance.new("Frame", box)
	barBg.Name, barBg.BackgroundColor3, barBg.BorderSizePixel = "BarBg", Color3.new(0, 0, 0), 0
    barBg.ZIndex = 5

	local bar = Instance.new("Frame", barBg)
	bar.Name, bar.AnchorPoint, bar.BackgroundColor3, bar.BorderSizePixel = "Bar", Vector2.new(0, 1), Color3.fromRGB(80, 200, 80), 0
    bar.ZIndex = 6

	local dist = Instance.new("TextLabel", box)
	dist.Name, dist.BackgroundTransparency, dist.TextColor3, dist.TextStrokeTransparency, dist.TextSize, dist.Font = "Dist", 1, Color3.new(1, 1, 1), 0, 12, MC_FONT
    dist.ZIndex = 6

    local nameLbl = Instance.new("TextLabel", box)
    nameLbl.Name, nameLbl.BackgroundTransparency, nameLbl.TextColor3, nameLbl.TextStrokeTransparency, nameLbl.TextSize, nameLbl.Font = "NameLbl", 1, Color3.new(1, 1, 1), 0, 13, MC_FONT
    nameLbl.ZIndex = 6

    local tracer = Instance.new("Frame", box)
    tracer.Name, tracer.AnchorPoint, tracer.BackgroundColor3, tracer.BorderSizePixel = "Tracer", Vector2.new(0, 0.5), ColorList[espColorIdx], 0
    tracer.ZIndex = 4

    for i = 1, 5 do
        local b = Instance.new("Frame", box)
        b.Name, b.AnchorPoint, b.BackgroundColor3, b.BorderSizePixel = "Bone" .. i, Vector2.new(0, 0.5), ColorList[espColorIdx], 0
        b.ZIndex = 4
    end

	return box
end

local function getRect(char)
	local cf, size = char:GetBoundingBox()
	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	for x = -1, 1, 2 do
		for y = -1, 1, 2 do
			for z = -1, 1, 2 do
				local corner = cf * CFrame.new(size.X/2 * x, size.Y/2 * y, size.Z/2 * z)
				local pos, onScreen = cam:WorldToViewportPoint(corner.Position)
				if pos.Z < 0 then return nil end
				minX, minY = math.min(minX, pos.X), math.min(minY, pos.Y)
				maxX, maxY = math.max(maxX, pos.X), math.max(maxY, pos.Y)
			end
		end
	end
	return minX, minY, maxX - minX, maxY - minY
end

local function DrawBone(frame, p1, p2, color)
    local dist = (p2 - p1).Magnitude
    frame.Size, frame.Position, frame.Rotation, frame.BackgroundColor3, frame.Visible = UDim2.new(0, dist, 0, 1.5), UDim2.new(0, p1.X, 0, p1.Y), math.deg(math.atan2(p2.Y - p1.Y, p2.X - p1.X)), color, true
end

-- // Main Render Loop (Live FPS, Target Lock, Aimbot & ESP)
local lastNotifiedTargetName = nil
local frameCount = 0
local fpsTimer = 0

RunService.RenderStepped:Connect(function(dt)
    -- Live FPS Counter Update
    frameCount = frameCount + 1
    fpsTimer = fpsTimer + dt
    if fpsTimer >= 1 then
        local currentFPS = math.floor(frameCount / fpsTimer)
        StatusFooter.Text = " Status: Active | FPS: " .. currentFPS
        frameCount = 0
        fpsTimer = 0
    end

    FOVGuiCircle.Visible = Settings.FOVVisible
    FOVGuiCircle.Size = UDim2.new(0, Settings.FOV * 2, 0, Settings.FOV * 2)

    if MobileLockActive then
        -- Validate current target (auto-switch if dead or respawned)
        if CurrentTarget and CurrentTarget.Parent then
            local hum = CurrentTarget.Parent:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then
                CurrentTarget = nil
            end
        else
            CurrentTarget = nil
        end

        if not CurrentTarget then
            CurrentTarget = GetClosestTarget()
        end
        
        if CurrentTarget and CurrentTarget.Parent then
            local targetPlayer = Players:GetPlayerFromCharacter(CurrentTarget.Parent)
            local targetName = targetPlayer and targetPlayer.Name or CurrentTarget.Parent.Name
            
            MobileLockBtn.BackgroundColor3 = Color3.fromRGB(15, 60, 35)
            MobileLockBtn.Text = "LOCKED"
            
            if lastNotifiedTargetName ~= targetName then
                lastNotifiedTargetName = targetName
                ShowSideNotification("Locked: " .. targetName)
            end

            if Settings.AimbotEnabled then
                local targetPos = CurrentTarget.Position
                if Settings.Prediction and CurrentTarget.Parent:FindFirstChild("HumanoidRootPart") then
                    local rootPart = CurrentTarget.Parent.HumanoidRootPart
                    local distToCam = (targetPos - cam.CFrame.Position).Magnitude
                    targetPos = targetPos + (rootPart.AssemblyLinearVelocity * (distToCam / 2500))
                end
                cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, targetPos), 1 - Settings.Smoothness)
            end

            if Settings.AutoFire then
                pcall(function()
                    local char = lp.Character
                    local tool = char and char:FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                end)
            end
        else
            MobileLockBtn.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
            MobileLockBtn.Text = "LOCK"
            lastNotifiedTargetName = nil
        end
    else
        CurrentTarget = nil
        MobileLockBtn.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
        MobileLockBtn.Text = "LOCK"
        lastNotifiedTargetName = nil
    end

    if Settings.AutoJump then
        pcall(function()
            local char = lp.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.FloorMaterial ~= Enum.Material.Air then hum.Jump = true end
        end)
    end

    -- Visuals ESP Render Loop
    local currentESPColor = ColorList[espColorIdx]
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp then
			if Settings.TeamCheck and plr.Team and lp.Team and plr.Team == lp.Team then
				if boxes[plr] then boxes[plr].Visible = false end
				continue
			end

			local char = plr.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
			local box = boxes[plr]

			if Settings.VisualsEnabled and hum and root and hum.Health > 0 then
				local x, y, w, h = getRect(char)
				if x then
					box = box or makeBox()
					boxes[plr] = box
					box.Visible = true
					box.Position = UDim2.fromOffset(x, y)
					box.Size = UDim2.fromOffset(w, h)

                    box.UIStroke.Enabled = Settings.BoxEnabled
                    box.UIStroke.Color = currentESPColor

                    local barBg = box.BarBg
                    if Settings.HealthBarEnabled then
                        barBg.Visible = true
                        barBg.Position = UDim2.new(0, -6, 0, 0)
                        barBg.Size = UDim2.new(0, 3, 1, 0)
                        local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        barBg.Bar.Position = UDim2.new(0, 0, 1, 0)
                        barBg.Bar.Size = UDim2.new(1, 0, pct, 0)
                    else
                        barBg.Visible = false
                    end

                    local distLbl = box.Dist
                    if Settings.DistanceESPEnabled then
                        distLbl.Visible = true
					    local d = math.floor((root.Position - cam.CFrame.Position).Magnitude)
					    distLbl.Position = UDim2.new(0, 0, 1, 2)
					    distLbl.Size = UDim2.new(1, 0, 0, 14)
					    distLbl.Text = "[" .. d .. "m]"
                    else
                        distLbl.Visible = false
                    end

                    local nameLbl = box.NameLbl
                    if Settings.NameEnabled then
                        nameLbl.Visible = true
                        nameLbl.Text = plr.Name
                        nameLbl.Position = UDim2.new(0, 0, 0, -18)
                        nameLbl.Size = UDim2.new(1, 0, 0, 16)
                    else
                        nameLbl.Visible = false
                    end

                    local tracer = box.Tracer
                    if Settings.TracersEnabled then
                        tracer.Visible = true
                        local rootScreen = cam:WorldToViewportPoint(root.Position)
                        local p1 = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                        local p2 = Vector2.new(rootScreen.X, rootScreen.Y)
                        DrawBone(tracer, p1, p2, currentESPColor)
                    else
                        tracer.Visible = false
                    end

                    if Settings.SkeletonEnabled then
                        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
                        local lArm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
                        local rArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
                        local lLeg = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")
                        local rLeg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")

                        if head and torso and lArm and rArm and lLeg and rLeg then
                            local pHead = cam:WorldToViewportPoint(head.Position)
                            local pTorso = cam:WorldToViewportPoint(torso.Position)
                            local pLArm = cam:WorldToViewportPoint(lArm.Position)
                            local pRArm = cam:WorldToViewportPoint(rArm.Position)
                            local pLLeg = cam:WorldToViewportPoint(lLeg.Position)
                            local pRLeg = cam:WorldToViewportPoint(rLeg.Position)

                            if pHead.Z > 0 and pTorso.Z > 0 and pLArm.Z > 0 and pRArm.Z > 0 and pLLeg.Z > 0 and pRLeg.Z > 0 then
                                local boxAbsPos = box.AbsolutePosition
                                local function convertToLocal(v2)
                                    return Vector2.new(v2.X - boxAbsPos.X, v2.Y - boxAbsPos.Y)
                                end

                                DrawBone(box.Bone1, convertToLocal(Vector2.new(pHead.X, pHead.Y)), convertToLocal(Vector2.new(pTorso.X, pTorso.Y)), currentESPColor)
                                DrawBone(box.Bone2, convertToLocal(Vector2.new(pTorso.X, pTorso.Y)), convertToLocal(Vector2.new(pLArm.X, pLArm.Y)), currentESPColor)
                                DrawBone(box.Bone3, convertToLocal(Vector2.new(pTorso.X, pTorso.Y)), convertToLocal(Vector2.new(pRArm.X, pRArm.Y)), currentESPColor)
                                DrawBone(box.Bone4, convertToLocal(Vector2.new(pTorso.X, pTorso.Y)), convertToLocal(Vector2.new(pLLeg.X, pLLeg.Y)), currentESPColor)
                                DrawBone(box.Bone5, convertToLocal(Vector2.new(pTorso.X, pTorso.Y)), convertToLocal(Vector2.new(pRLeg.X, pRLeg.Y)), currentESPColor)
                            else
                                for i = 1, 5 do
                                    local bObj = box:FindFirstChild("Bone" .. i)
                                    if bObj then bObj.Visible = false end
                                end
                            end
                        else
                            for i = 1, 5 do
                                local boneObj = box:FindFirstChild("Bone" .. i)
                                if boneObj then boneObj.Visible = false end
                            end
                        end
                    else
                        for i = 1, 5 do
                            local boneObj = box:FindFirstChild("Bone" .. i)
                            if boneObj then boneObj.Visible = false end
                        end
                    end
				elseif box then
					box.Visible = false
				end
			elseif box then
				box.Visible = false
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	if boxes[plr] then boxes[plr]:Destroy() boxes[plr] = nil end
end)

