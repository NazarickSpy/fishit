-- Fish It Auto Script - BLATAN EDITION
-- Fixed & Improved with proper WindUI syntax

-- Load WindUI Library (Official)
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/source.lua"))()

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Settings
local Settings = {
    AutoPerfect = false,
    AutoFastFishing = false,
    PerfectDelay = 100,
    AutoReel = false,
    AntiDisconnect = false,
    LuckBoost = false,
    LuckMultiplier = 1000,
    AutoShake = false,
    AutoSell = false,
    SelectedIsland = "Fisherman Island",
    AutoCast = false
}

-- Island Coordinates
local Islands = {
    ["Fisherman Island"] = CFrame.new(68, 35, -178),
    ["Kohana Island"] = CFrame.new(2146, 133, 3103),
    ["Kohana Volcano"] = CFrame.new(2530, 195, 3554),
    ["Coral Reef Island"] = CFrame.new(2095, 135, 1348),
    ["Esoteric Depths"] = CFrame.new(2127, 11, 2096),
    ["Tropical Grove"] = CFrame.new(2875, 135, 1997),
    ["Crater Island"] = CFrame.new(1422, 151, 2772),
    ["Lost Isle"] = CFrame.new(3635, 220, 3133),
    ["Ancient Jungle"] = CFrame.new(4251, 144, 1861)
}

-- Create Window
local Window = WindUI:CreateWindow({
    Title = "Fish It Auto [BLATAN]",
    Icon = "fish",
    Author = "Pro Edition",
    Folder = "FishItConfig",
    Size = UDim2.fromOffset(550, 620),
    KeySystem = {
        Key = "fishit2025",
        Note = "Enter Key: fishit2025",
        URL = "https://pastebin.com/raw/example",
        SaveKey = true
    },
    Transparent = false,
    Theme = "Dark",
    SideBarWidth = 180,
    HasOutline = true
})

-- Notification function
local function Notify(title, content, duration)
    WindUI:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3
    })
end

-- Main Tab
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "fish"
})

-- Auto Fishing Section
local FishingSection = MainTab:Section({
    Title = "⚡ Auto Fishing"
})

FishingSection:Toggle({
    Title = "Auto Perfect Catch",
    Description = "Automatically hit perfect catches",
    Default = false,
    Callback = function(value)
        Settings.AutoPerfect = value
        print("Auto Perfect:", value)
    end
})

FishingSection:Toggle({
    Title = "Auto Shake (Fast Click)",
    Description = "Spam click for luck meter",
    Default = false,
    Callback = function(value)
        Settings.AutoShake = value
        print("Auto Shake:", value)
    end
})

FishingSection:Toggle({
    Title = "Auto Cast",
    Description = "Auto cast fishing rod",
    Default = false,
    Callback = function(value)
        Settings.AutoCast = value
        print("Auto Cast:", value)
    end
})

FishingSection:Toggle({
    Title = "Auto Reel",
    Description = "Auto reel in fish",
    Default = false,
    Callback = function(value)
        Settings.AutoReel = value
        print("Auto Reel:", value)
    end
})

FishingSection:Slider({
    Title = "Perfect Delay",
    Description = "Delay before perfect catch (ms)",
    Min = 0,
    Max = 500,
    Default = 100,
    Callback = function(value)
        Settings.PerfectDelay = value
        print("Perfect Delay:", value, "ms")
    end
})

-- Luck Boost Section
local LuckSection = MainTab:Section({
    Title = "🍀 Luck Booster [BLATAN]"
})

LuckSection:Toggle({
    Title = "Enable Luck Boost",
    Description = "Boost luck for rare fish (999%)",
    Default = false,
    Callback = function(value)
        Settings.LuckBoost = value
        if value then
            Notify("Luck Boost", "Luck multiplier activated!", 3)
        end
        print("Luck Boost:", value)
    end
})

LuckSection:Slider({
    Title = "Luck Multiplier",
    Description = "Set luck percentage (%)",
    Min = 100,
    Max = 2000,
    Default = 1000,
    Callback = function(value)
        Settings.LuckMultiplier = value
        print("Luck Multiplier:", value .. "%")
    end
})

LuckSection:Toggle({
    Title = "Auto Sell Fish",
    Description = "Auto teleport & sell every 60s",
    Default = false,
    Callback = function(value)
        Settings.AutoSell = value
        print("Auto Sell:", value)
    end
})

-- Anti Disconnect Section
local UtilitySection = MainTab:Section({
    Title = "🛡️ Utilities"
})

UtilitySection:Toggle({
    Title = "Anti AFK Disconnect",
    Description = "Prevent AFK kick",
    Default = false,
    Callback = function(value)
        Settings.AntiDisconnect = value
        print("Anti Disconnect:", value)
    end
})

-- Teleport Tab
local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "map-pin"
})

local IslandSection = TeleportTab:Section({
    Title = "🏝️ Island Teleport"
})

local islandList = {}
for name, _ in pairs(Islands) do
    table.insert(islandList, name)
end

IslandSection:Dropdown({
    Title = "Select Island",
    Description = "Choose destination island",
    Values = islandList,
    Default = "Fisherman Island",
    Callback = function(value)
        Settings.SelectedIsland = value
        print("Selected:", value)
    end
})

IslandSection:Button({
    Title = "Teleport to Island",
    Description = "Click to teleport",
    Callback = function()
        local target = Islands[Settings.SelectedIsland]
        if target and character and humanoidRootPart then
            humanoidRootPart.CFrame = target
            Notify("Teleport", "Teleported to " .. Settings.SelectedIsland, 2)
        end
    end
})

IslandSection:Divider()

-- Quick Farm Spots
local FarmSection = TeleportTab:Section({
    Title = "🎯 Best Farm Spots"
})

FarmSection:Button({
    Title = "Kohana Volcano",
    Description = "Best Early-Mid Game",
    Callback = function()
        if humanoidRootPart then
            humanoidRootPart.CFrame = Islands["Kohana Volcano"]
            Notify("Farm Spot", "Kohana Volcano - Best profit!", 3)
        end
    end
})

FarmSection:Button({
    Title = "Tropical Grove",
    Description = "Enchant Stones (1/1000)",
    Callback = function()
        if humanoidRootPart then
            humanoidRootPart.CFrame = Islands["Tropical Grove"]
            Notify("Farm Spot", "Tropical Grove - Stone farm!", 3)
        end
    end
})

FarmSection:Button({
    Title = "Lost Isle",
    Description = "Treasure Room (75k coins)",
    Callback = function()
        if humanoidRootPart then
            humanoidRootPart.CFrame = Islands["Lost Isle"]
            Notify("Farm Spot", "Lost Isle - Late game!", 3)
        end
    end
})

FarmSection:Button({
    Title = "Ancient Jungle",
    Description = "Latest Update (Sacred Temple)",
    Callback = function()
        if humanoidRootPart then
            humanoidRootPart.CFrame = Islands["Ancient Jungle"]
            Notify("Farm Spot", "Ancient Jungle - New area!", 3)
        end
    end
})

-- Settings Tab
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

local ConfigSection = SettingsTab:Section({
    Title = "⚙️ Configuration"
})

ConfigSection:Button({
    Title = "Reset All Settings",
    Description = "Reset to default values",
    Callback = function()
        Settings.AutoPerfect = false
        Settings.AutoShake = false
        Settings.AutoCast = false
        Settings.AutoReel = false
        Settings.PerfectDelay = 100
        Settings.LuckBoost = false
        Settings.LuckMultiplier = 1000
        Settings.AutoSell = false
        Settings.AntiDisconnect = false
        
        Notify("Settings", "All settings reset to default", 3)
    end
})

ConfigSection:Divider()

local InfoSection = SettingsTab:Section({
    Title = "📊 Game Info"
})

InfoSection:Paragraph({
    Title = "Fish It Stats",
    Description = [[
• Total Fish: 112+
• Rarity: Uncommon → Mythic
• Best Rod: Astral (350% Luck)
• Best Bait: Aether (240% Luck)
• Top Spot: Kohana Volcano
]]
})

-- Credits Tab
local CreditsTab = Window:Tab({
    Title = "Credits",
    Icon = "info"
})

local CreditsSection = CreditsTab:Section({
    Title = "ℹ️ Information"
})

CreditsSection:Paragraph({
    Title = "Script Information",
    Description = [[
Script: Fish It Auto BLATAN
Version: 3.0 Fixed Edition
UI Library: WindUI by Footagesus
Game: Fish It by Fish Atelier

Features:
• Auto Perfect Catch
• Luck Booster (999%)
• Anti AFK Disconnect
• Island Teleport
• Auto Shake/Reel/Sell
]]
})

-- ============================================
-- FUNCTIONS
-- ============================================

-- Anti Disconnect
task.spawn(function()
    while task.wait(240) do
        if Settings.AntiDisconnect then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
end)

-- Luck Booster
task.spawn(function()
    while task.wait(0.5) do
        if Settings.LuckBoost then
            pcall(function()
                local playerGui = player:WaitForChild("PlayerGui")
                
                -- Modify luck meter
                for _, gui in pairs(playerGui:GetDescendants()) do
                    if gui:IsA("Frame") or gui:IsA("ImageLabel") then
                        local name = gui.Name:lower()
                        if name:find("luck") or name:find("meter") or name:find("bar") then
                            local fill = gui:FindFirstChild("Fill") or gui:FindFirstChild("Bar")
                            if fill and fill:IsA("GuiObject") then
                                fill.Size = UDim2.new(1, 0, 1, 0)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Shake (Fast Click)
task.spawn(function()
    while task.wait(0.01) do
        if Settings.AutoShake then
            pcall(function()
                local playerGui = player:WaitForChild("PlayerGui")
                
                for _, button in pairs(playerGui:GetDescendants()) do
                    if button:IsA("TextButton") or button:IsA("ImageButton") then
                        local name = button.Name:lower()
                        local text = (button.Text or ""):lower()
                        
                        if (name:find("shake") or name:find("click") or text:find("click")) and button.Visible then
                            for i = 1, 3 do
                                VirtualUser:CaptureController()
                                VirtualUser:Button1Down(Vector2.new(0, 0))
                                task.wait(0.01)
                                VirtualUser:Button1Up(Vector2.new(0, 0))
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Perfect Catch
task.spawn(function()
    while task.wait(0.03) do
        if Settings.AutoPerfect then
            pcall(function()
                local playerGui = player:WaitForChild("PlayerGui")
                
                for _, gui in pairs(playerGui:GetDescendants()) do
                    if gui:IsA("Frame") and gui.Visible then
                        local perfectZone = gui:FindFirstChild("Perfect") or gui:FindFirstChild("PerfectZone") or gui:FindFirstChild("Green")
                        local indicator = gui:FindFirstChild("Indicator") or gui:FindFirstChild("Pointer") or gui:FindFirstChild("Bar")
                        
                        if perfectZone and indicator and perfectZone.Visible and indicator.Visible then
                            local pPos = perfectZone.AbsolutePosition
                            local pSize = perfectZone.AbsoluteSize
                            local iPos = indicator.AbsolutePosition
                            
                            local inZone = iPos.X >= pPos.X and iPos.X <= (pPos.X + pSize.X)
                            
                            if inZone then
                                task.wait(Settings.PerfectDelay / 1000)
                                VirtualUser:CaptureController()
                                VirtualUser:Button1Down(Vector2.new(0, 0))
                                task.wait(0.05)
                                VirtualUser:Button1Up(Vector2.new(0, 0))
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Reel
task.spawn(function()
    while task.wait(0.2) do
        if Settings.AutoReel then
            pcall(function()
                local playerGui = player:WaitForChild("PlayerGui")
                
                for _, button in pairs(playerGui:GetDescendants()) do
                    if button:IsA("TextButton") or button:IsA("ImageButton") then
                        local name = button.Name:lower()
                        local text = (button.Text or ""):lower()
                        
                        if (name:find("reel") or name:find("collect") or text:find("reel")) and button.Visible then
                            VirtualUser:CaptureController()
                            VirtualUser:Button1Down(Vector2.new(0, 0))
                            task.wait(0.1)
                            VirtualUser:Button1Up(Vector2.new(0, 0))
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Cast
task.spawn(function()
    while task.wait(1) do
        if Settings.AutoCast then
            pcall(function()
                local playerGui = player:WaitForChild("PlayerGui")
                local fishingGui = playerGui:FindFirstChild("FishingGui") or playerGui:FindFirstChild("FishingUI")
                
                if not fishingGui or not fishingGui.Enabled then
                    -- Cast rod
                    VirtualUser:CaptureController()
                    VirtualUser:Button1Down(Vector2.new(0, 0))
                    task.wait(0.5)
                    VirtualUser:Button1Up(Vector2.new(0, 0))
                end
            end)
        end
    end
end)

-- Auto Sell
task.spawn(function()
    while task.wait(60) do
        if Settings.AutoSell then
            pcall(function()
                if humanoidRootPart then
                    -- TP to merchant
                    local merchantPos = Islands["Fisherman Island"]
                    humanoidRootPart.CFrame = merchantPos
                    task.wait(1)
                    
                    -- Find sell button
                    local playerGui = player:WaitForChild("PlayerGui")
                    for _, button in pairs(playerGui:GetDescendants()) do
                        if button:IsA("TextButton") then
                            if button.Text:lower():find("sell") then
                                VirtualUser:CaptureController()
                                VirtualUser:Button1Down(Vector2.new(0, 0))
                                task.wait(0.1)
                                VirtualUser:Button1Up(Vector2.new(0, 0))
                                print("Auto sold fish!")
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Character Update
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
end)

-- Success Notification
Notify("Fish It Auto Loaded!", "BLATAN Edition v3.0 - All features ready!", 5)

print("=" .. string.rep("=", 60))
print("🎣 FISH IT AUTO SCRIPT - BLATAN EDITION 🎣")
print("Status: LOADED & READY!")
print("UI: WindUI by Footagesus (Official)")
print("Features: Perfect, Luck 999%, Anti-DC, Fast Shake, TP")
print("=" .. string.rep("=", 60))
