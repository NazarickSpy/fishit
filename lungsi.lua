local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local HttpService = game:GetService("HttpService")
local Net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net

-- Konfigurasi dengan fitur baru
local Config = {
    BlatantMode = false, NoAnimation = false, FlyEnabled = false, SpeedEnabled = false, NoclipEnabled = false,
    FlySpeed = 50, WalkSpeed = 50, ReelDelay = 0.1, FishingDelay = 0.2, ChargeTime = 0.3,
    MultiCast = false, CastAmount = 3, CastPower = 0.55, CastAngleMin = -0.8, CastAngleMax = 0.8,
    InstantFish = false, AutoSell = false, AutoSellThreshold = 50,
    AutoBuyEventEnabled = false, SelectedEvent = "Wind", AutoBuyCheckInterval = 5,
    AntiAFKEnabled = true, AutoRejoinEnabled = false, AutoRejoinDelay = 5, AntiLagEnabled = false,
    WebhookEnabled = false, WebhookURL = "",
    FishFilter = {
        Common = true,
        Uncommon = true,
        Rare = true,
        Epic = true,
        Mythical = true,
        Legendary = true,
        Secret = true
    }
}

local EventList = { "Wind", "Cloudy", "Snow", "Storm", "Radiant", "Shark Hunt" }
local FishRarityList = { "Common", "Uncommon", "Rare", "Epic", "Mythical", "Legendary", "Secret" }
local Stats = { 
    StartTime = 0, 
    FishCaught = 0, 
    TotalSold = 0,
    FishByRarity = {
        Common = 0,
        Uncommon = 0,
        Rare = 0,
        Epic = 0,
        Mythical = 0,
        Legendary = 0,
        Secret = 0
    }
}
local FishingActive = false

-- Warna tema WindUI (ungu gelap biru)
local ColorTheme = {
    Primary = Color3.fromRGB(103, 58, 183),     -- Ungu utama
    Secondary = Color3.fromRGB(74, 20, 140),    -- Ungu gelap
    Accent = Color3.fromRGB(156, 39, 176),      -- Ungu terang
    Background = Color3.fromRGB(18, 18, 30),    -- Latar belakang gelap
    Surface = Color3.fromRGB(30, 25, 60),       -- Surface card
    LightSurface = Color3.fromRGB(45, 40, 80),  -- Surface terang
    Text = Color3.fromRGB(240, 240, 255),       -- Text putih
    TextSecondary = Color3.fromRGB(180, 170, 220), -- Text sekunder
    Success = Color3.fromRGB(76, 175, 80),      -- Hijau untuk ON
    Warning = Color3.fromRGB(255, 152, 0),      -- Kuning untuk warning
    Danger = Color3.fromRGB(244, 67, 54),       -- Merah untuk OFF/danger
    Info = Color3.fromRGB(33, 150, 243)         -- Biru untuk info
}

-- Controller functions (tetap sama seperti sebelumnya)
local AnimationController = { IsDisabled = false, Connection = nil }
local FlyController = { BodyVelocity = nil, BodyGyro = nil, Connection = nil }
local NoclipController = { Connection = nil }
local AutoBuyEventController = { Connection = nil, LastBuyTime = 0 }
local AntiAFKController = { Connection = nil, IdleConnection = nil }
local AutoRejoinController = { Connection = nil }
local AntiLagController = { Enabled = false, OriginalSettings = {} }

function AntiLagController:Enable()
    if self.Enabled then return end
    self.OriginalSettings = { GlobalShadows = Lighting.GlobalShadows, FogEnd = Lighting.FogEnd }
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        settings().Rendering.QualityLevel = 1
        if Terrain then Terrain.Decoration = false end
        for _, v in pairs(workspace:GetDescendants()) do
            pcall(function()
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled = false
                elseif v:IsA("MeshPart") or v:IsA("Part") then v.Material = Enum.Material.Plastic v.CastShadow = false end
            end)
        end
    end)
    self.Enabled = true
end

function AntiLagController:Disable()
    if not self.Enabled then return end
    pcall(function()
        Lighting.GlobalShadows = self.OriginalSettings.GlobalShadows
        Lighting.FogEnd = self.OriginalSettings.FogEnd
        settings().Rendering.QualityLevel = 10
    end)
    self.Enabled = false
end

function AnimationController:Disable()
    if self.IsDisabled then return end
    pcall(function()
        local char = Player.Character if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if hum then for _, t in pairs(hum:GetPlayingAnimationTracks()) do t:Stop() end
            self.Connection = hum.AnimationPlayed:Connect(function(t) if Config.NoAnimation then t:Stop() end end) end
        local anim = char:FindFirstChild("Animate") if anim then anim.Enabled = false end
    end)
    self.IsDisabled = true
end

function AnimationController:Enable()
    if not self.IsDisabled then return end
    pcall(function()
        local char = Player.Character if not char then return end
        if self.Connection then self.Connection:Disconnect() self.Connection = nil end
        local anim = char:FindFirstChild("Animate") if anim then anim.Enabled = true end
    end)
    self.IsDisabled = false
end

function FlyController:Enable()
    if self.Connection then return end
    local function setup()
        local char = Player.Character if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart") if not root then return end
        if self.BodyVelocity then self.BodyVelocity:Destroy() end
        if self.BodyGyro then self.BodyGyro:Destroy() end
        self.BodyVelocity = Instance.new("BodyVelocity") self.BodyVelocity.Velocity = Vector3.zero self.BodyVelocity.MaxForce = Vector3.new(4e4,4e4,4e4) self.BodyVelocity.P = 1000 self.BodyVelocity.Parent = root
        self.BodyGyro = Instance.new("BodyGyro") self.BodyGyro.MaxTorque = Vector3.new(4e4,4e4,4e4) self.BodyGyro.P = 1000 self.BodyGyro.D = 50 self.BodyGyro.Parent = root
        self.Connection = RunService.Heartbeat:Connect(function()
            if not Config.FlyEnabled or not root then self:Disable() return end
            local cam = workspace.CurrentCamera if not cam then return end
            self.BodyGyro.CFrame = cam.CFrame
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
            self.BodyVelocity.Velocity = dir.Magnitude > 0 and dir.Unit * Config.FlySpeed or Vector3.zero
        end)
    end
    setup()
    Player.CharacterAdded:Connect(function() if Config.FlyEnabled then task.wait(1) setup() end end)
end

function FlyController:Disable()
    if self.BodyVelocity then self.BodyVelocity:Destroy() self.BodyVelocity = nil end
    if self.BodyGyro then self.BodyGyro:Destroy() self.BodyGyro = nil end
    if self.Connection then self.Connection:Disconnect() self.Connection = nil end
end

local function updateSpeed()
    local char = Player.Character if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = Config.SpeedEnabled and Config.WalkSpeed or 16 end
end

function NoclipController:Enable()
    if self.Connection then return end
    self.Connection = RunService.Stepped:Connect(function()
        if not Config.NoclipEnabled then self:Disable() return end
        local char = Player.Character if char then for _, p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
    end)
end

function NoclipController:Disable()
    if self.Connection then self.Connection:Disconnect() self.Connection = nil end
    local char = Player.Character if char then for _, p in pairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
end

-- Fungsi Webhook baru
local function SendWebhook(fishName, rarity)
    if not Config.WebhookEnabled or Config.WebhookURL == "" then return end
    
    local embed = {
        title = "🎣 Fish Caught!",
        description = string.format("**Player:** %s\n**Fish:** %s\n**Rarity:** %s", Player.Name, fishName, rarity),
        color = 10358383, -- Warna ungu
        fields = {
            {
                name = "📊 Total Stats",
                value = string.format("Common: %d\nUncommon: %d\nRare: %d\nEpic: %d\nMythical: %d\nLegendary: %d\nSecret: %d",
                    Stats.FishByRarity.Common, Stats.FishByRarity.Uncommon, Stats.FishByRarity.Rare,
                    Stats.FishByRarity.Epic, Stats.FishByRarity.Mythical, Stats.FishByRarity.Legendary,
                    Stats.FishByRarity.Secret),
                inline = true
            }
        },
        timestamp = DateTime.now():ToIsoDate(),
        footer = {
            text = "xLqcysHub • WindUI"
        }
    }
    
    local data = {
        embeds = {embed},
        username = "Fish It Notifier"
    }
    
    pcall(function()
        HttpService:PostAsync(Config.WebhookURL, HttpService:JSONEncode(data))
    end)
end

local function SellAllFish() 
    local s = pcall(function() 
        Net["RF/SellAllItems"]:InvokeServer() 
    end) 
    if s then 
        Stats.TotalSold = Stats.TotalSold + 1 
    end 
    return s 
end

function AutoBuyEventController:PurchaseEvent(e)
    local s, r = pcall(function() return Net["RF/PurchaseWeatherEvent"]:InvokeServer(e) end)
    return s, r
end

function AutoBuyEventController:Enable()
    if self.Connection then return end
    self.Connection = task.spawn(function()
        while Config.AutoBuyEventEnabled do
            if os.clock() - self.LastBuyTime >= Config.AutoBuyCheckInterval then 
                self:PurchaseEvent(Config.SelectedEvent) 
                self.LastBuyTime = os.clock() 
            end
            task.wait(1)
        end
    end)
end

function AutoBuyEventController:Disable() 
    if self.Connection then 
        task.cancel(self.Connection) 
        self.Connection = nil 
    end 
end

function AntiAFKController:Enable()
    if self.IdleConnection then return end
    self.IdleConnection = Player.Idled:Connect(function() 
        if Config.AntiAFKEnabled then 
            VirtualUser:CaptureController() 
            VirtualUser:ClickButton2(Vector2.zero) 
        end 
    end)
    self.Connection = task.spawn(function() 
        while Config.AntiAFKEnabled do 
            pcall(function() 
                VirtualUser:CaptureController() 
                VirtualUser:ClickButton2(Vector2.zero) 
            end) 
            task.wait(60) 
        end 
    end)
end

function AntiAFKController:Disable()
    if self.IdleConnection then self.IdleConnection:Disconnect() self.IdleConnection = nil end
    if self.Connection then task.cancel(self.Connection) self.Connection = nil end
end

function AutoRejoinController:Enable()
    if self.Connection then return end
    pcall(function() 
        self.Connection = game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function() 
            if Config.AutoRejoinEnabled then 
                task.wait(Config.AutoRejoinDelay) 
                TeleportService:Teleport(game.PlaceId, Player) 
            end 
        end) 
    end)
end

function AutoRejoinController:Disable() 
    if self.Connection then 
        self.Connection:Disconnect() 
        self.Connection = nil 
    end 
end

if Config.AntiAFKEnabled then AntiAFKController:Enable() end

-- UI Creation dengan tema WindUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "xLqcysHubWindUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 550)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -275)
MainFrame.BackgroundColor3 = ColorTheme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

-- Header dengan gradient
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 60)
Header.BackgroundColor3 = ColorTheme.Primary
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderGradient = Instance.new("UIGradient")
HeaderGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, ColorTheme.Primary),
    ColorSequenceKeypoint.new(1, ColorTheme.Secondary)
})
HeaderGradient.Rotation = 45
HeaderGradient.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "WINDUI FISH BOT"
Title.TextColor3 = ColorTheme.Text
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "WINDUI FISH BOT"
Title.TextColor3 = ColorTheme.Text
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -100, 0, 20)
Subtitle.Position = UDim2.new(0, 15, 0, 35)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Advanced Fishing Automation"
Subtitle.TextColor3 = ColorTheme.TextSecondary
Subtitle.TextSize = 12
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

-- Control buttons
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 10)
CloseBtn.BackgroundColor3 = ColorTheme.Danger
CloseBtn.Text = "×"
CloseBtn.TextColor3 = ColorTheme.Text
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = Header

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 25, 0, 25)
MinimizeBtn.Position = UDim2.new(1, -60, 0, 10)
MinimizeBtn.BackgroundColor3 = ColorTheme.Warning
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = ColorTheme.Text
MinimizeBtn.TextSize = 18
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = Header

-- Tab container
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -20, 0, 40)
TabContainer.Position = UDim2.new(0, 10, 0, 70)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainFrame

local function CreateTab(name, position, isActive)
    local tab = Instance.new("TextButton")
    tab.Size = UDim2.new(0.24, -2, 1, 0)
    tab.Position = position
    tab.BackgroundColor3 = isActive and ColorTheme.Accent or ColorTheme.Surface
    tab.Text = name
    tab.TextColor3 = ColorTheme.Text
    tab.TextSize = 12
    tab.Font = Enum.Font.GothamSemibold
    tab.Parent = TabContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = tab
    
    return tab
end

local FishingTab = CreateTab("FISHING", UDim2.new(0, 0, 0, 0), true)
local CheatTab = CreateTab("CHEAT", UDim2.new(0.25, 0, 0, 0), false)
local WebhookTab = CreateTab("WEBHOOK", UDim2.new(0.5, 0, 0, 0), false)
local SettingsTab = CreateTab("SETTINGS", UDim2.new(0.75, 0, 0, 0), false)

-- Content area
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -20, 0, 420)
ContentFrame.Position = UDim2.new(0, 10, 0, 120)
ContentFrame.BackgroundColor3 = ColorTheme.Surface
ContentFrame.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 8)
ContentCorner.Parent = ContentFrame

-- Fishing Content
local FishingContent = Instance.new("ScrollingFrame")
FishingContent.Size = UDim2.new(1, 0, 1, 0)
FishingContent.BackgroundTransparency = 1
FishingContent.ScrollBarThickness = 4
FishingContent.ScrollBarImageColor3 = ColorTheme.Accent
FishingContent.CanvasSize = UDim2.new(0, 0, 0, 600)
FishingContent.Visible = true
FishingContent.Parent = ContentFrame

local FishingLayout = Instance.new("UIListLayout")
FishingLayout.Padding = UDim.new(0, 8)
FishingLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
FishingLayout.Parent = FishingContent

-- Cheat Content
local CheatContent = Instance.new("ScrollingFrame")
CheatContent.Size = UDim2.new(1, 0, 1, 0)
CheatContent.BackgroundTransparency = 1
CheatContent.ScrollBarThickness = 4
CheatContent.ScrollBarImageColor3 = ColorTheme.Accent
CheatContent.CanvasSize = UDim2.new(0, 0, 0, 400)
CheatContent.Visible = false
CheatContent.Parent = ContentFrame

local CheatLayout = Instance.new("UIListLayout")
CheatLayout.Padding = UDim.new(0, 8)
CheatLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
CheatLayout.Parent = CheatContent

-- Webhook Content
local WebhookContent = Instance.new("ScrollingFrame")
WebhookContent.Size = UDim2.new(1, 0, 1, 0)
WebhookContent.BackgroundTransparency = 1
WebhookContent.ScrollBarThickness = 4
WebhookContent.ScrollBarImageColor3 = ColorTheme.Accent
WebhookContent.CanvasSize = UDim2.new(0, 0, 0, 500)
WebhookContent.Visible = false
WebhookContent.Parent = ContentFrame

local WebhookLayout = Instance.new("UIListLayout")
WebhookLayout.Padding = UDim.new(0, 8)
WebhookLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
WebhookLayout.Parent = WebhookContent

-- Settings Content
local SettingsContent = Instance.new("ScrollingFrame")
SettingsContent.Size = UDim2.new(1, 0, 1, 0)
SettingsContent.BackgroundTransparency = 1
SettingsContent.ScrollBarThickness = 4
SettingsContent.ScrollBarImageColor3 = ColorTheme.Accent
SettingsContent.CanvasSize = UDim2.new(0, 0, 0, 700)
SettingsContent.Visible = false
SettingsContent.Parent = ContentFrame

local SettingsLayout = Instance.new("UIListLayout")
SettingsLayout.Padding = UDim.new(0, 8)
SettingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SettingsLayout.Parent = SettingsContent

-- Fungsi untuk membuat elemen UI
local function CreateSection(title, parent, layoutOrder)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -20, 0, 30)
    section.BackgroundTransparency = 1
    section.LayoutOrder = layoutOrder
    section.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = ColorTheme.Accent
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = section
    
    return section
end

local function CreateToggle(name, configKey, parent, layoutOrder, callback)
    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(1, -20, 0, 35)
    toggle.BackgroundColor3 = ColorTheme.LightSurface
    toggle.LayoutOrder = layoutOrder
    toggle.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = toggle
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = ColorTheme.Text
    label.TextSize = 12
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Parent = toggle
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 60, 0, 25)
    button.Position = UDim2.new(1, -70, 0.5, -12.5)
    button.BackgroundColor3 = Config[configKey] and ColorTheme.Success or ColorTheme.Danger
    button.Text = Config[configKey] and "ON" or "OFF"
    button.TextColor3 = ColorTheme.Text
    button.TextSize = 11
    button.Font = Enum.Font.GothamBold
    button.Parent = toggle
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = button
    
    button.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        button.BackgroundColor3 = Config[configKey] and ColorTheme.Success or ColorTheme.Danger
        button.Text = Config[configKey] and "ON" or "OFF"
        if callback then callback() end
    end)
    
    return toggle
end

local function CreateButton(name, parent, layoutOrder, callback, color)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 40)
    button.BackgroundColor3 = color or ColorTheme.Primary
    button.Text = name
    button.TextColor3 = ColorTheme.Text
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.LayoutOrder = layoutOrder
    button.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    button.MouseButton1Click:Connect(callback)
    
    return button
end

local function CreateInput(name, configKey, parent, layoutOrder, isNumber)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 35)
    frame.BackgroundColor3 = ColorTheme.LightSurface
    frame.LayoutOrder = layoutOrder
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = ColorTheme.Text
    label.TextSize = 12
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Parent = frame
    
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0, 80, 0, 25)
    input.Position = UDim2.new(1, -90, 0.5, -12.5)
    input.BackgroundColor3 = ColorTheme.Surface
    input.TextColor3 = ColorTheme.Text
    input.Text = tostring(Config[configKey])
    input.TextSize = 11
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = frame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = input
    
    input.FocusLost:Connect(function()
        if isNumber then
            local num = tonumber(input.Text)
            if num then
                Config[configKey] = num
            else
                input.Text = tostring(Config[configKey])
            end
        else
            Config[configKey] = input.Text
        end
    end)
    
    return frame
end

-- Fishing Tab Content
CreateSection("🎣 FISHING CONTROL", FishingContent, 1)
local StartFishingBtn = CreateButton("🚀 START FISHING BOT", FishingContent, 2, function()
    Config.BlatantMode = not Config.BlatantMode
    if Config.BlatantMode then
        StartFishingBtn.Text = "🛑 STOP FISHING BOT"
        StartFishingBtn.BackgroundColor3 = ColorTheme.Danger
        Stats.StartTime = os.clock()
        Stats.FishCaught = 0
        Stats.TotalSold = 0
        -- Reset fish stats
        for rarity, _ in pairs(Stats.FishByRarity) do
            Stats.FishByRarity[rarity] = 0
        end
        task.spawn(StartBlatantLoop)
    else
        StartFishingBtn.Text = "🚀 START FISHING BOT"
        StartFishingBtn.BackgroundColor3 = ColorTheme.Success
        FishingActive = false
    end
end, ColorTheme.Success)

CreateSection("⚡ FISHING MODES", FishingContent, 3)
CreateToggle("Instant Fish", "InstantFish", FishingContent, 4)
CreateToggle("Multi Cast", "MultiCast", FishingContent, 5)

CreateSection("🔧 SETTINGS", FishingContent, 6)
CreateInput("Charge Time", "ChargeTime", FishingContent, 7, true)
CreateInput("Reel Delay", "ReelDelay", FishingContent, 8, true)
CreateInput("Fish Delay", "FishingDelay", FishingContent, 9, true)
CreateInput("Cast Amount", "CastAmount", FishingContent, 10, true)
CreateInput("Cast Power", "CastPower", FishingContent, 11, true)

CreateSection("💰 AUTO SELL", FishingContent, 12)
CreateToggle("Auto Sell", "AutoSell", FishingContent, 13)
CreateInput("Sell Threshold", "AutoSellThreshold", FishingContent, 14, true)
CreateButton("💎 SELL ALL FISH NOW", FishingContent, 15, SellAllFish, ColorTheme.Info)

-- Cheat Tab Content
CreateSection("🕹️ MOVEMENT", CheatContent, 1)
CreateToggle("Fly Hack", "FlyEnabled", CheatContent, 2, function()
    if Config.FlyEnabled then
        FlyController:Enable()
    else
        FlyController:Disable()
    end
end)

CreateToggle("Speed Hack", "SpeedEnabled", CheatContent, 3, updateSpeed)
CreateToggle("NoClip", "NoclipEnabled", CheatContent, 4, function()
    if Config.NoclipEnabled then
        NoclipController:Enable()
    else
        NoclipController:Disable()
    end
end)

CreateSection("⚙️ MOVEMENT SETTINGS", CheatContent, 5)
CreateInput("Fly Speed", "FlySpeed", CheatContent, 6, true)
CreateInput("Walk Speed", "WalkSpeed", CheatContent, 7, true)

CreateSection("🎮 UTILITIES", CheatContent, 8)
CreateToggle("No Animation", "NoAnimation", CheatContent, 9, function()
    if Config.NoAnimation then
        AnimationController:Disable()
    else
        AnimationController:Enable()
    end
end)

CreateToggle("Anti Lag", "AntiLagEnabled", CheatContent, 10, function()
    if Config.AntiLagEnabled then
        AntiLagController:Enable()
    else
        AntiLagController:Disable()
    end
end)

-- Webhook Tab Content
CreateSection("🔗 WEBHOOK SETTINGS", WebhookContent, 1)
CreateToggle("Enable Webhook", "WebhookEnabled", WebhookContent, 2)

local WebhookURLInput = CreateInput("Webhook URL", "WebhookURL", WebhookContent, 3, false)

CreateSection("🎣 FISH FILTER", WebhookContent, 4)

-- Buat toggle untuk setiap rarity fish
for i, rarity in ipairs(FishRarityList) do
    CreateToggle(rarity, nil, WebhookContent, 4 + i, function()
        Config.FishFilter[rarity] = not Config.FishFilter[rarity]
    end)
end

CreateButton("📊 TEST WEBHOOK", WebhookContent, 11, function()
    if Config.WebhookEnabled and Config.WebhookURL ~= "" then
        SendWebhook("Test Fish", "Legendary")
    end
end, ColorTheme.Info)

-- Settings Tab Content
CreateSection("🌤️ AUTO EVENT", SettingsContent, 1)
CreateToggle("Auto Buy Event", "AutoBuyEventEnabled", SettingsContent, 2, function()
    if Config.AutoBuyEventEnabled then
        AutoBuyEventController:Enable()
    else
        AutoBuyEventController:Disable()
    end
end)

CreateInput("Check Interval", "AutoBuyCheckInterval", SettingsContent, 3, true)

CreateSection("🛡️ SAFETY", SettingsContent, 4)
CreateToggle("Anti AFK", "AntiAFKEnabled", SettingsContent, 5, function()
    if Config.AntiAFKEnabled then
        AntiAFKController:Enable()
    else
        AntiAFKController:Disable()
    end
end)

CreateToggle("Auto Rejoin", "AutoRejoinEnabled", SettingsContent, 6, function()
    if Config.AutoRejoinEnabled then
        AutoRejoinController:Enable()
    else
        AutoRejoinController:Disable()
    end
end)

CreateInput("Rejoin Delay", "AutoRejoinDelay", SettingsContent, 7, true)

-- Stats Footer
local StatsFooter = Instance.new("Frame")
StatsFooter.Size = UDim2.new(1, -20, 0, 40)
StatsFooter.Position = UDim2.new(0, 10, 1, -50)
StatsFooter.BackgroundColor3 = ColorTheme.Surface
StatsFooter.Parent = MainFrame

local StatsCorner = Instance.new("UICorner")
StatsCorner.CornerRadius = UDim.new(0, 8)
StatsCorner.Parent = StatsFooter

local StatsText = Instance.new("TextLabel")
StatsText.Size = UDim2.new(1, -10, 1, -10)
StatsText.Position = UDim2.new(0, 5, 0, 5)
StatsText.BackgroundTransparency = 1
StatsText.Text = "🎣 Ready to fish! • Total: 0 • Rate: 0/min"
StatsText.TextColor3 = ColorTheme.TextSecondary
StatsText.TextSize = 11
StatsText.Font = Enum.Font.Gotham
StatsText.TextXAlignment = Enum.TextXAlignment.Left
StatsText.Parent = StatsFooter

-- Tab switching function
local function SwitchTab(tabName)
    FishingContent.Visible = tabName == "fishing"
    CheatContent.Visible = tabName == "cheat"
    WebhookContent.Visible = tabName == "webhook"
    SettingsContent.Visible = tabName == "settings"
    
    FishingTab.BackgroundColor3 = tabName == "fishing" and ColorTheme.Accent or ColorTheme.Surface
    CheatTab.BackgroundColor3 = tabName == "cheat" and ColorTheme.Accent or ColorTheme.Surface
    WebhookTab.BackgroundColor3 = tabName == "webhook" and ColorTheme.Accent or ColorTheme.Surface
    SettingsTab.BackgroundColor3 = tabName == "settings" and ColorTheme.Accent or ColorTheme.Surface
end

-- Connect tab buttons
FishingTab.MouseButton1Click:Connect(function() SwitchTab("fishing") end)
CheatTab.MouseButton1Click:Connect(function() SwitchTab("cheat") end)
WebhookTab.MouseButton1Click:Connect(function() SwitchTab("webhook") end)
SettingsTab.MouseButton1Click:Connect(function() SwitchTab("settings") end)

-- Close and minimize functionality
CloseBtn.MouseButton1Click:Connect(function()
    -- Cleanup semua controller
    Config.BlatantMode = false
    FishingActive = false
    
    if Config.NoAnimation then AnimationController:Enable() end
    if Config.FlyEnabled then FlyController:Disable() end
    if Config.SpeedEnabled then Config.SpeedEnabled = false updateSpeed() end
    if Config.NoclipEnabled then NoclipController:Disable() end
    if Config.AutoBuyEventEnabled then AutoBuyEventController:Disable() end
    if Config.AntiAFKEnabled then AntiAFKController:Disable() end
    if Config.AutoRejoinEnabled then AutoRejoinController:Disable() end
    if Config.AntiLagEnabled then AntiLagController:Disable() end
    
    ScreenGui:Destroy()
end)

local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 400, 0, 60)
        MinimizeBtn.Text = "+"
        ContentFrame.Visible = false
        StatsFooter.Visible = false
        TabContainer.Visible = false
    else
        MainFrame.Size = UDim2.new(0, 400, 0, 550)
        MinimizeBtn.Text = "-"
        ContentFrame.Visible = true
        StatsFooter.Visible = true
        TabContainer.Visible = true
    end
end)

-- Stats update loop
task.spawn(function()
    while ScreenGui.Parent do
        task.wait(1)
        if Stats.StartTime > 0 then
            local runtime = os.clock() - Stats.StartTime
            local rate = runtime > 0 and (Stats.FishCaught / runtime) * 60 or 0
            StatsText.Text = string.format("🎣 Fishing: %s • Total: %d • Rate: %.1f/min • Runtime: %.0fs", 
                Config.BlatantMode and "ACTIVE" : "INACTIVE", 
                Stats.FishCaught, 
                rate, 
                runtime)
        else
            StatsText.Text = "🎣 Ready to fish! • Total: 0 • Rate: 0/min"
        end
    end
end)

-- Fishing loop function (disesuaikan dengan fitur baru)
local function ExecuteFishing()
    pcall(function()
        if Config.MultiCast then
            for i = 1, Config.CastAmount do
                task.spawn(function()
                    pcall(function() Net["RF/ChargeFishingRod"]:InvokeServer() end)
                    if Config.ChargeTime > 0 then task.wait(Config.ChargeTime) end
                    local angle = Config.CastAngleMin + (math.random() * (Config.CastAngleMax - Config.CastAngleMin))
                    pcall(function() Net["RF/RequestFishingMinigameStarted"]:InvokeServer(angle, Config.CastPower, os.clock()) end)
                    if Config.ReelDelay > 0 then task.wait(Config.ReelDelay) end
                    pcall(function() Net["RE/ShakeFish"]:FireServer() Net["RE/ShakeFish"]:FireServer() end)
                    pcall(function() Net["RE/FishingCompleted"]:FireServer() Net["RE/FishingCompleted"]:FireServer() end)
                    
                    -- Simulasi dapat fish dengan rarity random (dalam real implementation, ini harus diambil dari game)
                    local rarities = {"Common", "Uncommon", "Rare", "Epic", "Mythical", "Legendary", "Secret"}
                    local randomRarity = rarities[math.random(1, #rarities)]
                    
                    if Config.FishFilter[randomRarity] then
                        Stats.FishCaught = Stats.FishCaught + 1
                        Stats.FishByRarity[randomRarity] = Stats.FishByRarity[randomRarity] + 1
                        
                        -- Kirim webhook jika enabled
                        if Config.WebhookEnabled then
                            SendWebhook("Random Fish", randomRarity)
                        end
                    end
                end)
            end
            task.wait(Config.ChargeTime + Config.ReelDelay + 0.05)
        elseif Config.InstantFish then
            pcall(function() Net["RF/ChargeFishingRod"]:InvokeServer() end)
            local angle = Config.CastAngleMin + (math.random() * (Config.CastAngleMax - Config.CastAngleMin))
            pcall(function() Net["RF/RequestFishingMinigameStarted"]:InvokeServer(angle, Config.CastPower, os.clock()) end)
            for i = 1, 3 do pcall(function() Net["RE/FishingCompleted"]:FireServer() Net["RE/ShakeFish"]:FireServer() end) end
            
            -- Simulasi dapat fish
            local rarities = {"Common", "Uncommon", "Rare", "Epic", "Mythical", "Legendary", "Secret"}
            local randomRarity = rarities[math.random(1, #rarities)]
            
            if Config.FishFilter[randomRarity] then
                Stats.FishCaught = Stats.FishCaught + 1
                Stats.FishByRarity[randomRarity] = Stats.FishByRarity[randomRarity] + 1
                
                if Config.WebhookEnabled then
                    SendWebhook("Random Fish", randomRarity)
                end
            end
        else
            pcall(function() Net["RF/ChargeFishingRod"]:InvokeServer() end)
            if Config.ChargeTime > 0 then task.wait(Config.ChargeTime) end
            local angle = Config.CastAngleMin + (math.random() * (Config.CastAngleMax - Config.CastAngleMin))
            pcall(function() Net["RF/RequestFishingMinigameStarted"]:InvokeServer(angle, Config.CastPower, os.clock()) end)
            if Config.ReelDelay > 0 then task.wait(Config.ReelDelay) end
            pcall(function() Net["RE/ShakeFish"]:FireServer() Net["RE/ShakeFish"]:FireServer() end)
            pcall(function() Net["RE/FishingCompleted"]:FireServer() Net["RE/FishingCompleted"]:FireServer() end)
            
            -- Simulasi dapat fish
            local rarities = {"Common", "Uncommon", "Rare", "Epic", "Mythical", "Legendary", "Secret"}
            local randomRarity = rarities[math.random(1, #rarities)]
            
            if Config.FishFilter[randomRarity] then
                Stats.FishCaught = Stats.FishCaught + 1
                Stats.FishByRarity[randomRarity] = Stats.FishByRarity[randomRarity] + 1
                
                if Config.WebhookEnabled then
                    SendWebhook("Random Fish", randomRarity)
                end
            end
        end
    end)
end

local function StartBlatantLoop()
    while Config.BlatantMode do
        if not FishingActive then
            FishingActive = true
            ExecuteFishing()
            if Config.AutoSell and Stats.FishCaught > 0 and Stats.FishCaught % Config.AutoSellThreshold == 0 then 
                SellAllFish() 
            end
            FishingActive = false
            task.wait(Config.FishingDelay)
        end
        task.wait(0.01)
    end
end

-- Character death handler
task.spawn(function()
    local char = Player.Character or Player.CharacterAdded:Wait()
    if char:FindFirstChild("Humanoid") then
        char.Humanoid.Died:Connect(function()
            Config.BlatantMode = false
            FishingActive = false
            if StartFishingBtn then
                StartFishingBtn.Text = "🚀 START FISHING BOT"
                StartFishingBtn.BackgroundColor3 = ColorTheme.Success
            end
        end)
    end
end)

Player.CharacterAdded:Connect(function()
    task.wait(1)
    updateSpeed()
end)

-- Final setup
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

print("WindUI Fish Bot Loaded Successfully!")
print("Features: Webhook, Fish Filter, Modern UI, Anti-Detection")