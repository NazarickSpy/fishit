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

-- Cari Net package dengan aman
local Net
pcall(function()
    Net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
end)

if not Net then
    warn("Net package tidak ditemukan, mencoba alternatif...")
    pcall(function()
        Net = ReplicatedStorage:FindFirstChild("Net")
    end)
end

local Config = {
    BlatantMode = false, NoAnimation = false, FlyEnabled = false, SpeedEnabled = false, NoclipEnabled = false,
    FlySpeed = 50, WalkSpeed = 50, ReelDelay = 0.1, FishingDelay = 0.2, ChargeTime = 0.3,
    MultiCast = false, CastAmount = 3, CastPower = 0.55, CastAngleMin = -0.8, CastAngleMax = 0.8,
    InstantFish = false, AutoSell = false, AutoSellThreshold = 50,
    AutoBuyEventEnabled = false, SelectedEvent = "Wind", AutoBuyCheckInterval = 5,
    AntiAFKEnabled = true, AutoRejoinEnabled = false, AutoRejoinDelay = 5, AntiLagEnabled = false,
    WebhookEnabled = false, WebhookURL = "", WebhookNotifyThreshold = 50
}

local EventList = { "Wind", "Cloudy", "Snow", "Storm", "Radiant", "Shark Hunt" }
local Stats = { StartTime = 0, FishCaught = 0, TotalSold = 0, LastWebhookNotify = 0 }
local FishingActive = false

local AnimationController = { IsDisabled = false, Connection = nil }
local FlyController = { BodyVelocity = nil, BodyGyro = nil, Connection = nil }
local NoclipController = { Connection = nil }
local AutoBuyEventController = { Connection = nil, LastBuyTime = 0 }
local AntiAFKController = { Connection = nil, IdleConnection = nil }
local AutoRejoinController = { Connection = nil }
local AntiLagController = { Enabled = false, OriginalSettings = {} }

-- Webhook Function
local function SendWebhook(message)
    if not Config.WebhookEnabled or Config.WebhookURL == "" or Config.WebhookURL == "https://discord.com/api/webhooks/..." then 
        return 
    end
    
    local data = {
        ["content"] = message,
        ["embeds"] = {{
            ["title"] = "xLqcysHub - Fish It",
            ["description"] = message,
            ["color"] = 10181046,
            ["fields"] = {
                {
                    ["name"] = "Fish Caught",
                    ["value"] = tostring(Stats.FishCaught),
                    ["inline"] = true
                },
                {
                    ["name"] = "Total Sold",
                    ["value"] = tostring(Stats.TotalSold),
                    ["inline"] = true
                },
                {
                    ["name"] = "Player",
                    ["value"] = Player.Name,
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = "xLqcysHub • " .. os.date("%Y-%m-%d %H:%M:%S")
            }
        }}
    }
    
    local success, jsonData = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    
    if success then
        pcall(function()
            local response = HttpService:PostAsync(Config.WebhookURL, jsonData)
        end)
    end
end

function AntiLagController:Enable()
    if self.Enabled then return end
    self.OriginalSettings = { 
        GlobalShadows = Lighting.GlobalShadows, 
        FogEnd = Lighting.FogEnd 
    }
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        settings().Rendering.QualityLevel = 1
        if Terrain then 
            Terrain.Decoration = false 
        end
        for _, v in pairs(workspace:GetDescendants()) do
            pcall(function()
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then 
                    v.Enabled = false
                elseif v:IsA("MeshPart") or v:IsA("Part") then 
                    v.Material = Enum.Material.Plastic 
                    v.CastShadow = false 
                end
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
        if Terrain then 
            Terrain.Decoration = true 
        end
    end)
    self.Enabled = false
end

function AnimationController:Disable()
    if self.IsDisabled then return end
    pcall(function()
        local char = Player.Character 
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if hum then 
            for _, t in pairs(hum:GetPlayingAnimationTracks()) do 
                t:Stop() 
            end
            self.Connection = hum.AnimationPlayed:Connect(function(t) 
                if Config.NoAnimation then 
                    t:Stop() 
                end 
            end) 
        end
        local anim = char:FindFirstChild("Animate") 
        if anim then 
            anim.Enabled = false 
        end
    end)
    self.IsDisabled = true
end

function AnimationController:Enable()
    if not self.IsDisabled then return end
    pcall(function()
        local char = Player.Character 
        if not char then return end
        if self.Connection then 
            self.Connection:Disconnect() 
            self.Connection = nil 
        end
        local anim = char:FindFirstChild("Animate") 
        if anim then 
            anim.Enabled = true 
        end
    end)
    self.IsDisabled = false
end

function FlyController:Enable()
    if self.Connection then return end
    local function setup()
        local char = Player.Character 
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart") 
        if not root then return end
        
        if self.BodyVelocity then self.BodyVelocity:Destroy() end
        if self.BodyGyro then self.BodyGyro:Destroy() end
        
        self.BodyVelocity = Instance.new("BodyVelocity") 
        self.BodyVelocity.Velocity = Vector3.zero 
        self.BodyVelocity.MaxForce = Vector3.new(4e4,4e4,4e4) 
        self.BodyVelocity.P = 1000 
        self.BodyVelocity.Parent = root
        
        self.BodyGyro = Instance.new("BodyGyro") 
        self.BodyGyro.MaxTorque = Vector3.new(4e4,4e4,4e4) 
        self.BodyGyro.P = 1000 
        self.BodyGyro.D = 50 
        self.BodyGyro.Parent = root
        
        self.Connection = RunService.Heartbeat:Connect(function()
            if not Config.FlyEnabled or not root or not self.BodyVelocity or not self.BodyGyro then 
                self:Disable() 
                return 
            end
            local cam = workspace.CurrentCamera 
            if not cam then return end
            
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
    Player.CharacterAdded:Connect(function() 
        if Config.FlyEnabled then 
            task.wait(1) 
            setup() 
        end 
    end)
end

function FlyController:Disable()
    if self.BodyVelocity then self.BodyVelocity:Destroy() self.BodyVelocity = nil end
    if self.BodyGyro then self.BodyGyro:Destroy() self.BodyGyro = nil end
    if self.Connection then self.Connection:Disconnect() self.Connection = nil end
end

local function updateSpeed()
    pcall(function()
        local char = Player.Character 
        if char and char:FindFirstChild("Humanoid") then 
            char.Humanoid.WalkSpeed = Config.SpeedEnabled and Config.WalkSpeed or 16 
        end
    end)
end

function NoclipController:Enable()
    if self.Connection then return end
    self.Connection = RunService.Stepped:Connect(function()
        if not Config.NoclipEnabled then 
            self:Disable() 
            return 
        end
        pcall(function()
            local char = Player.Character 
            if char then 
                for _, p in pairs(char:GetDescendants()) do 
                    if p:IsA("BasePart") then 
                        p.CanCollide = false 
                    end 
                end 
            end
        end)
    end)
end

function NoclipController:Disable()
    if self.Connection then 
        self.Connection:Disconnect() 
        self.Connection = nil 
    end
    pcall(function()
        local char = Player.Character 
        if char then 
            for _, p in pairs(char:GetDescendants()) do 
                if p:IsA("BasePart") then 
                    p.CanCollide = true 
                end 
            end 
        end
    end)
end

local function SellAllFish() 
    local success = pcall(function() 
        if Net and Net["RF/SellAllItems"] then
            Net["RF/SellAllItems"]:InvokeServer() 
        end
    end) 
    if success then 
        Stats.TotalSold = Stats.TotalSold + 1 
    end 
    return success 
end

function AutoBuyEventController:PurchaseEvent(event)
    local success, result = pcall(function() 
        if Net and Net["RF/PurchaseWeatherEvent"] then
            return Net["RF/PurchaseWeatherEvent"]:InvokeServer(event) 
        end
        return false
    end)
    return success, result
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
    if self.IdleConnection then 
        self.IdleConnection:Disconnect() 
        self.IdleConnection = nil 
    end
    if self.Connection then 
        task.cancel(self.Connection) 
        self.Connection = nil 
    end
end

function AutoRejoinController:Enable()
    if self.Connection then return end
    pcall(function() 
        self.Connection = game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
            if Config.AutoRejoinEnabled and child.Name == "ErrorPrompt" then
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

if Config.AntiAFKEnabled then 
    AntiAFKController:Enable() 
end

local function ExecuteFishing()
    pcall(function()
        if not Net then
            warn("Net tidak tersedia, tidak bisa fishing")
            return
        end

        if Config.MultiCast then
            for i = 1, Config.CastAmount do
                task.spawn(function()
                    pcall(function() 
                        if Net["RF/ChargeFishingRod"] then
                            Net["RF/ChargeFishingRod"]:InvokeServer() 
                        end
                    end)
                    if Config.ChargeTime > 0 then task.wait(Config.ChargeTime) end
                    local angle = Config.CastAngleMin + (math.random() * (Config.CastAngleMax - Config.CastAngleMin))
                    pcall(function() 
                        if Net["RF/RequestFishingMinigameStarted"] then
                            Net["RF/RequestFishingMinigameStarted"]:InvokeServer(angle, Config.CastPower, os.clock()) 
                        end
                    end)
                    if Config.ReelDelay > 0 then task.wait(Config.ReelDelay) end
                    pcall(function() 
                        if Net["RE/ShakeFish"] then
                            Net["RE/ShakeFish"]:FireServer() 
                            Net["RE/ShakeFish"]:FireServer() 
                        end
                    end)
                    pcall(function() 
                        if Net["RE/FishingCompleted"] then
                            Net["RE/FishingCompleted"]:FireServer() 
                            Net["RE/FishingCompleted"]:FireServer() 
                        end
                    end)
                    Stats.FishCaught = Stats.FishCaught + 1
                    
                    -- Webhook notification
                    if Config.WebhookEnabled and Stats.FishCaught % Config.WebhookNotifyThreshold == 0 and Stats.FishCaught ~= Stats.LastWebhookNotify then
                        SendWebhook(string.format("🎣 Achievement! Reached %d fish caught!", Stats.FishCaught))
                        Stats.LastWebhookNotify = Stats.FishCaught
                    end
                end)
            end
            task.wait(Config.ChargeTime + Config.ReelDelay + 0.05)
        elseif Config.InstantFish then
            pcall(function() 
                if Net["RF/ChargeFishingRod"] then
                    Net["RF/ChargeFishingRod"]:InvokeServer() 
                end
            end)
            local angle = Config.CastAngleMin + (math.random() * (Config.CastAngleMax - Config.CastAngleMin))
            pcall(function() 
                if Net["RF/RequestFishingMinigameStarted"] then
                    Net["RF/RequestFishingMinigameStarted"]:InvokeServer(angle, Config.CastPower, os.clock()) 
                end
            end)
            for i = 1, 3 do 
                pcall(function() 
                    if Net["RE/FishingCompleted"] and Net["RE/ShakeFish"] then
                        Net["RE/FishingCompleted"]:FireServer() 
                        Net["RE/ShakeFish"]:FireServer() 
                    end
                end) 
            end
            Stats.FishCaught = Stats.FishCaught + 1
            
            -- Webhook notification
            if Config.WebhookEnabled and Stats.FishCaught % Config.WebhookNotifyThreshold == 0 and Stats.FishCaught ~= Stats.LastWebhookNotify then
                SendWebhook(string.format("🎣 Achievement! Reached %d fish caught!", Stats.FishCaught))
                Stats.LastWebhookNotify = Stats.FishCaught
            end
        else
            pcall(function() 
                if Net["RF/ChargeFishingRod"] then
                    Net["RF/ChargeFishingRod"]:InvokeServer() 
                end
            end)
            if Config.ChargeTime > 0 then task.wait(Config.ChargeTime) end
            local angle = Config.CastAngleMin + (math.random() * (Config.CastAngleMax - Config.CastAngleMin))
            pcall(function() 
                if Net["RF/RequestFishingMinigameStarted"] then
                    Net["RF/RequestFishingMinigameStarted"]:InvokeServer(angle, Config.CastPower, os.clock()) 
                end
            end)
            if Config.ReelDelay > 0 then task.wait(Config.ReelDelay) end
            pcall(function() 
                if Net["RE/ShakeFish"] then
                    Net["RE/ShakeFish"]:FireServer() 
                    Net["RE/ShakeFish"]:FireServer() 
                end
            end)
            pcall(function() 
                if Net["RE/FishingCompleted"] then
                    Net["RE/FishingCompleted"]:FireServer() 
                    Net["RE/FishingCompleted"]:FireServer() 
                end
            end)
            Stats.FishCaught = Stats.FishCaught + 1
            
            -- Webhook notification
            if Config.WebhookEnabled and Stats.FishCaught % Config.WebhookNotifyThreshold == 0 and Stats.FishCaught ~= Stats.LastWebhookNotify then
                SendWebhook(string.format("🎣 Achievement! Reached %d fish caught!", Stats.FishCaught))
                Stats.LastWebhookNotify = Stats.FishCaught
            end
        end
    end)
end

local function StartBlatantLoop()
    while Config.BlatantMode and task.wait(Config.FishingDelay) do
        if not FishingActive then
            FishingActive = true
            ExecuteFishing()
            if Config.AutoSell and Stats.FishCaught > 0 and Stats.FishCaught % Config.AutoSellThreshold == 0 then 
                SellAllFish() 
            end
            FishingActive = false
        end
    end
end

-- WindHub Style UI
local ScreenGui = Instance.new("ScreenGui") 
ScreenGui.Name = "xLqcysHub" 
ScreenGui.ResetOnSpawn = false 
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 450, 0, 550)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -275)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 8)
TopBarCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "xLqcysHub"
Title.TextColor3 = Color3.fromRGB(170, 85, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(0, 200, 1, 0)
Subtitle.Position = UDim2.new(0, 120, 0, 0)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Fish It Auto Farm"
Subtitle.TextColor3 = Color3.fromRGB(140, 140, 150)
Subtitle.TextSize = 11
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 2)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 25, 0, 25)
MinimizeBtn.Position = UDim2.new(1, -60, 0, 2)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
MinimizeBtn.Text = "_"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 14
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = TopBar

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 6)
MinimizeCorner.Parent = MinimizeBtn

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -20, 0, 30)
TabContainer.Position = UDim2.new(0, 10, 0, 35)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainFrame

local function CreateTab(name, position)
    local Tab = Instance.new("TextButton")
    Tab.Size = UDim2.new(0.23, 0, 1, 0)
    Tab.Position = position
    Tab.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Tab.Text = name
    Tab.TextColor3 = Color3.fromRGB(200, 200, 200)
    Tab.TextSize = 11
    Tab.Font = Enum.Font.GothamSemibold
    Tab.Parent = TabContainer
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Tab
    
    return Tab
end

local FishingTab = CreateTab("Fishing", UDim2.new(0, 0, 0, 0))
local CheatTab = CreateTab("Cheat", UDim2.new(0.25, 0, 0, 0))
local EventTab = CreateTab("Event", UDim2.new(0.5, 0, 0, 0))
local WebhookTab = CreateTab("Webhook", UDim2.new(0.75, 0, 0, 0))

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -20, 0, 470)
ContentFrame.Position = UDim2.new(0, 10, 0, 70)
ContentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ContentFrame.BorderSizePixel = 0
ContentFrame.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 8)
ContentCorner.Parent = ContentFrame

local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.ScrollBarThickness = 6
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 800)
ScrollingFrame.Parent = ContentFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.Parent = ScrollingFrame

local function CreateSection(title, order)
    local Section = Instance.new("Frame")
    Section.Size = UDim2.new(1, -20, 0, 0)
    Section.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    Section.LayoutOrder = order
    Section.AutomaticSize = Enum.AutomaticSize.Y
    Section.Parent = ScrollingFrame
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Section
    
    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, 8)
    Padding.PaddingBottom = UDim.new(0, 8)
    Padding.PaddingLeft = UDim.new(0, 10)
    Padding.PaddingRight = UDim.new(0, 10)
    Padding.Parent = Section
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 0, 20)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Color3.fromRGB(170, 85, 255)
    TitleLabel.TextSize = 12
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Section
    
    return Section
end

local function CreateToggle(name, configKey, order, parent, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, 0, 0, 30)
    ToggleFrame.BackgroundTransparency = 1
    ToggleFrame.LayoutOrder = order
    ToggleFrame.Parent = parent
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(1, 0, 1, 0)
    ToggleButton.BackgroundColor3 = Config[configKey] and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(180, 60, 60)
    ToggleButton.Text = name .. ": " .. (Config[configKey] and "ON" or "OFF")
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 12
    ToggleButton.Font = Enum.Font.GothamSemibold
    ToggleButton.Parent = ToggleFrame
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = ToggleButton
    
    ToggleButton.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        ToggleButton.BackgroundColor3 = Config[configKey] and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(180, 60, 60)
        ToggleButton.Text = name .. ": " .. (Config[configKey] and "ON" or "OFF")
        if callback then 
            pcall(callback) 
        end
    end)
    
    return ToggleButton
end

local function CreateTextBox(name, configKey, order, parent)
    local TextBoxFrame = Instance.new("Frame")
    TextBoxFrame.Size = UDim2.new(1, 0, 0, 50)
    TextBoxFrame.BackgroundTransparency = 1
    TextBoxFrame.LayoutOrder = order
    TextBoxFrame.Parent = parent
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 20)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.TextSize = 11
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = TextBoxFrame
    
    local TextBox = Instance.new("TextBox")
    TextBox.Size = UDim2.new(1, 0, 0, 25)
    TextBox.Position = UDim2.new(0, 0, 0, 22)
    TextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    TextBox.Text = tostring(Config[configKey])
    TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextBox.TextSize = 11
    TextBox.Font = Enum.Font.Gotham
    TextBox.ClearTextOnFocus = false
    TextBox.Parent = TextBoxFrame
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = TextBox
    
    TextBox.FocusLost:Connect(function()
        local value = tonumber(TextBox.Text)
        if value then
            Config[configKey] = value
        else
            TextBox.Text = tostring(Config[configKey])
        end
    end)
    
    return TextBox
end

-- Fishing Tab Content
local FishingSection = CreateSection("Fishing Controls", 1)
local StartFishingBtn = CreateToggle("Start Fishing", "BlatantMode", 1, FishingSection, function()
    if Config.BlatantMode then
        Stats.StartTime = os.clock()
        Stats.FishCaught, Stats.TotalSold = 0, 0
        task.spawn(StartBlatantLoop)
    else
        FishingActive = false
    end
end)

local FishingOptionsSection = CreateSection("Fishing Options", 2)
CreateToggle("Instant Fish", "InstantFish", 1, FishingOptionsSection)
CreateToggle("Multi Cast", "MultiCast", 2, FishingOptionsSection)
CreateToggle("Auto Sell", "AutoSell", 3, FishingOptionsSection)
CreateToggle("No Animation", "NoAnimation", 4, FishingOptionsSection, function()
    if Config.NoAnimation then
        AnimationController:Disable()
    else
        AnimationController:Enable()
    end
end)

local SellButtonFrame = Instance.new("Frame")
SellButtonFrame.Size = UDim2.new(1, 0, 0, 35)
SellButtonFrame.BackgroundTransparency = 1
SellButtonFrame.LayoutOrder = 5
SellButtonFrame.Parent = FishingOptionsSection

local SellButton = Instance.new("TextButton")
SellButton.Size = UDim2.new(1, 0, 1, 0)
SellButton.BackgroundColor3 = Color3.fromRGB(85, 85, 255)
SellButton.Text = "Sell All Fish Now"
SellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SellButton.TextSize = 12
SellButton.Font = Enum.Font.GothamSemibold
SellButton.Parent = SellButtonFrame

local SellCorner = Instance.new("UICorner")
SellCorner.CornerRadius = UDim.new(0, 6)
SellCorner.Parent = SellButton

SellButton.MouseButton1Click:Connect(SellAllFish)

local FishingSettingsSection = CreateSection("Fishing Settings", 3)
CreateTextBox("Charge Time", "ChargeTime", 1, FishingSettingsSection)
CreateTextBox("Reel Delay", "ReelDelay", 2, FishingSettingsSection)
CreateTextBox("Fishing Delay", "FishingDelay", 3, FishingSettingsSection)
CreateTextBox("Cast Amount", "CastAmount", 4, FishingSettingsSection)
CreateTextBox("Auto Sell Threshold", "AutoSellThreshold", 5, FishingSettingsSection)
CreateTextBox("Cast Power", "CastPower", 6, FishingSettingsSection)

-- Cheat Tab Content
local MovementSection = CreateSection("Movement Cheats", 1)
CreateToggle("Fly", "FlyEnabled", 1, MovementSection, function()
    if Config.FlyEnabled then
        FlyController:Enable()
    else
        FlyController:Disable()
    end
end)

CreateToggle("Speed Hack", "SpeedEnabled", 2, MovementSection, updateSpeed)
CreateToggle("Noclip", "NoclipEnabled", 3, MovementSection, function()
    if Config.NoclipEnabled then
        NoclipController:Enable()
    else
        NoclipController:Disable()
    end
end)

local PerformanceSection = CreateSection("Performance", 2)
CreateToggle("Anti Lag", "AntiLagEnabled", 1, PerformanceSection, function()
    if Config.AntiLagEnabled then
        AntiLagController:Enable()
    else
        AntiLagController:Disable()
    end
end)

local CheatSettingsSection = CreateSection("Cheat Settings", 3)
CreateTextBox("Fly Speed", "FlySpeed", 1, CheatSettingsSection)
CreateTextBox("Walk Speed", "WalkSpeed", 2, CheatSettingsSection)

-- Event Tab Content
local AutoBuySection = CreateSection("Auto Buy Event", 1)
local AutoBuyToggle = CreateToggle("Auto Buy Event", "AutoBuyEventEnabled", 1, AutoBuySection, function()
    if Config.AutoBuyEventEnabled then
        AutoBuyEventController:Enable()
    else
        AutoBuyEventController:Disable()
    end
end)

local EventSelectionSection = CreateSection("Event Selection", 2)
for i, event in ipairs(EventList) do
    local eventBtn = CreateToggle(event, "", i, EventSelectionSection, function()
        Config.SelectedEvent = event
    end)
end

local UtilitySection = CreateSection("Utility", 3)
CreateToggle("Anti AFK", "AntiAFKEnabled", 1, UtilitySection, function()
    if Config.AntiAFKEnabled then
        AntiAFKController:Enable()
    else
        AntiAFKController:Disable()
    end
end)

CreateToggle("Auto Rejoin", "AutoRejoinEnabled", 2, UtilitySection, function()
    if Config.AutoRejoinEnabled then
        AutoRejoinController:Enable()
    else
        AutoRejoinController:Disable()
    end
end)

CreateTextBox("Auto Buy Interval", "AutoBuyCheckInterval", 3, UtilitySection)

-- Webhook Tab Content
local WebhookSection = CreateSection("Discord Webhook", 1)
CreateToggle("Webhook Enabled", "WebhookEnabled", 1, WebhookSection)

local WebhookURLSection = CreateSection("Webhook URL", 2)
local URLFrame = Instance.new("Frame")
URLFrame.Size = UDim2.new(1, 0, 0, 70)
URLFrame.BackgroundTransparency = 1
URLFrame.LayoutOrder = 1
URLFrame.Parent = WebhookURLSection

local URLLabel = Instance.new("TextLabel")
URLLabel.Size = UDim2.new(1, 0, 0, 20)
URLLabel.BackgroundTransparency = 1
URLLabel.Text = "Webhook URL"
URLLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
URLLabel.TextSize = 11
URLLabel.Font = Enum.Font.Gotham
URLLabel.TextXAlignment = Enum.TextXAlignment.Left
URLLabel.Parent = URLFrame

local URLTextBox = Instance.new("TextBox")
URLTextBox.Size = UDim2.new(1, 0, 0, 25)
URLTextBox.Position = UDim2.new(0, 0, 0, 22)
URLTextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
URLTextBox.PlaceholderText = "https://discord.com/api/webhooks/..."
URLTextBox.Text = Config.WebhookURL
URLTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
URLTextBox.TextSize = 11
URLTextBox.Font = Enum.Font.Gotham
URLTextBox.ClearTextOnFocus = false
URLTextBox.Parent = URLFrame

local URLCorner = Instance.new("UICorner")
URLCorner.CornerRadius = UDim.new(0, 6)
URLCorner.Parent = URLTextBox

URLTextBox.FocusLost:Connect(function()
    Config.WebhookURL = URLTextBox.Text
end)

CreateTextBox("Notify Every X Fish", "WebhookNotifyThreshold", 3, WebhookURLSection)

local TestWebhookFrame = Instance.new("Frame")
TestWebhookFrame.Size = UDim2.new(1, 0, 0, 35)
TestWebhookFrame.BackgroundTransparency = 1
TestWebhookFrame.LayoutOrder = 4
TestWebhookFrame.Parent = WebhookURLSection

local TestWebhookButton = Instance.new("TextButton")
TestWebhookButton.Size = UDim2.new(1, 0, 1, 0)
TestWebhookButton.BackgroundColor3 = Color3.fromRGB(170, 85, 255)
TestWebhookButton.Text = "Test Webhook"
TestWebhookButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TestWebhookButton.TextSize = 12
TestWebhookButton.Font = Enum.Font.GothamSemibold
TestWebhookButton.Parent = TestWebhookFrame

local TestCorner = Instance.new("UICorner")
TestCorner.CornerRadius = UDim.new(0, 6)
TestCorner.Parent = TestWebhookButton

TestWebhookButton.MouseButton1Click:Connect(function()
    SendWebhook("🔧 Webhook test successful! xLqcysHub is working properly.")
end)

-- Stats Frame
local StatsFrame = Instance.new("Frame")
StatsFrame.Size = UDim2.new(1, -20, 0, 30)
StatsFrame.Position = UDim2.new(0, 10, 1, -40)
StatsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
StatsFrame.BorderSizePixel = 0
StatsFrame.Parent = MainFrame

local StatsCorner = Instance.new("UICorner")
StatsCorner.CornerRadius = UDim.new(0, 6)
StatsCorner.Parent = StatsFrame

local StatsText = Instance.new("TextLabel")
StatsText.Size = UDim2.new(1, -10, 1, 0)
StatsText.Position = UDim2.new(0, 10, 0, 0)
StatsText.BackgroundTransparency = 1
StatsText.Text = "Fish: 0 | Sold: 0 | 0/min"
StatsText.TextColor3 = Color3.fromRGB(170, 170, 180)
StatsText.TextSize = 11
StatsText.Font = Enum.Font.Gotham
StatsText.TextXAlignment = Enum.TextXAlignment.Left
StatsText.Parent = StatsFrame

-- Tab Switching
local function SwitchTab(tabName)
    ScrollingFrame.CanvasPosition = Vector2.new(0, 0)
    
    FishingTab.BackgroundColor3 = tabName == "Fishing" and Color3.fromRGB(80, 50, 150) or Color3.fromRGB(40, 40, 50)
    CheatTab.BackgroundColor3 = tabName == "Cheat" and Color3.fromRGB(80, 50, 150) or Color3.fromRGB(40, 40, 50)
    EventTab.BackgroundColor3 = tabName == "Event" and Color3.fromRGB(80, 50, 150) or Color3.fromRGB(40, 40, 50)
    WebhookTab.BackgroundColor3 = tabName == "Webhook" and Color3.fromRGB(80, 50, 150) or Color3.fromRGB(40, 40, 50)
end

FishingTab.MouseButton1Click:Connect(function() SwitchTab("Fishing") end)
CheatTab.MouseButton1Click:Connect(function() SwitchTab("Cheat") end)
EventTab.MouseButton1Click:Connect(function() SwitchTab("Event") end)
WebhookTab.MouseButton1Click:Connect(function() SwitchTab("Webhook") end)

-- Button Functionality
CloseBtn.MouseButton1Click:Connect(function()
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

local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame.Size = UDim2.new(0, 450, 0, 30)
        MinimizeBtn.Text = "+"
        ContentFrame.Visible = false
        TabContainer.Visible = false
        StatsFrame.Visible = false
    else
        MainFrame.Size = UDim2.new(0, 450, 0, 550)
        MinimizeBtn.Text = "_"
        ContentFrame.Visible = true
        TabContainer.Visible = true
        StatsFrame.Visible = true
    end
end)

-- Stats Update Loop
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        task.wait(0.5)
        local runtime = os.clock() - Stats.StartTime
        local fishPerMinute = runtime > 0 and (Stats.FishCaught / runtime) * 60 or 0
        StatsText.Text = string.format("Fish: %d | Sold: %d | %.1f/min", Stats.FishCaught, Stats.TotalSold, fishPerMinute)
    end
end)

-- Character Handling
task.spawn(function()
    local char = Player.Character or Player.CharacterAdded:Wait()
    if char:FindFirstChild("Humanoid") then
        char.Humanoid.Died:Connect(function()
            Config.BlatantMode = false
            FishingActive = false
        end)
    end
end)

Player.CharacterAdded:Connect(function()
    task.wait(1)
    updateSpeed()
end)

-- Auto start AntiAFK
if Config.AntiAFKEnabled then
    AntiAFKController:Enable()
end

ScreenGui.Parent = Player:WaitForChild("PlayerGui")

warn("xLqcysHub loaded successfully!")
warn("Net available: " .. tostring(Net ~= nil))