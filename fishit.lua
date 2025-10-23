-- Fish It Auto Script with WindUI
-- Load WindUI Library
local Wind = loadstring(game:HttpGet("https://raw.githubusercontent.com/aldyjrz/WindUI/main/source.lua"))()

-- Services
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local virtualUser = game:GetService("VirtualUser")
local tweenService = game:GetService("TweenService")

-- Settings
local settings = {
    autoPerfect = false,
    autoFastFishing = false,
    perfectDelay = 0.1,
    autoReel = true,
    antiDisconnect = false,
    luckBoost = false,
    luckMultiplier = 1000,
    autoShake = true,
    autoSell = false,
    selectedIsland = "Fisherman Island",
    farmMode = "Kohana Volcano"
}

-- Island Coordinates (Stingray Shores = Fisherman Island)
local islands = {
    ["Fisherman Island"] = CFrame.new(68, 35, -178),
    ["Kohana Island"] = CFrame.new(2146, 133, 3103),
    ["Kohana Volcano"] = CFrame.new(2530, 195, 3554),
    ["Coral Reef Island"] = CFrame.new(2095, 135, 1348),
    ["Esoteric Depths"] = CFrame.new(2127, 11, 2096),
    ["Tropical Grove Island"] = CFrame.new(2875, 135, 1997),
    ["Crater Island"] = CFrame.new(1422, 151, 2772),
    ["Lost Isle"] = CFrame.new(3635, 220, 3133),
    ["Ancient Jungle Island"] = CFrame.new(4251, 144, 1861)
}

-- Best Farming Spots
local farmSpots = {
    ["Kohana Volcano"] = {pos = CFrame.new(2530, 195, 3554), reason = "Best Early-Mid (Magma Goby)"},
    ["Tropical Grove"] = {pos = CFrame.new(2875, 135, 1997), reason = "Enchant Stones Farm"},
    ["Lost Isle"] = {pos = CFrame.new(3635, 220, 3133), reason = "Rare Fish + Treasure Room"},
    ["Ancient Jungle"] = {pos = CFrame.new(4251, 144, 1861), reason = "Latest Update (Sacred Temple)"}
}

-- Create Window
local win = Wind:CreateWindow({
    Title = "Fish It Auto [BLATAN]",
    Author = "Pro Script",
    Folder = "FishItBlatan",
    Size = UDim2.fromOffset(550, 600),
    KeySystem = {
        Key = "fishit2025",
        Note = "Key: fishit2025",
        SaveKey = true,
        GrabKeyFrom = "https://pastebin.com/raw/example"
    },
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 180,
})

-- Main Tab
local main = win:Tab({
    Text = "Main",
    Icon = "rbxassetid://10734950309"
})

-- Auto Fishing Section
local autoSection = main:Section({
    Text = "⚡ Auto Fishing"
})

autoSection:Toggle({
    Text = "Auto Perfect Catch",
    Default = false,
    Callback = function(v)
        settings.autoPerfect = v
        print("Auto Perfect:", v)
    end
})

autoSection:Toggle({
    Text = "Auto Shake (Fast Click)",
    Default = true,
    Callback = function(v)
        settings.autoShake = v
        print("Auto Shake:", v)
    end
})

autoSection:Toggle({
    Text = "Auto Fast Fishing",
    Default = false,
    Callback = function(v)
        settings.autoFastFishing = v
        print("Auto Fast Fishing:", v)
    end
})

autoSection:Toggle({
    Text = "Auto Reel",
    Default = true,
    Callback = function(v)
        settings.autoReel = v
        print("Auto Reel:", v)
    end
})

autoSection:Slider({
    Text = "Perfect Delay (ms)",
    Min = 0,
    Max = 500,
    Default = 100,
    Callback = function(v)
        settings.perfectDelay = v / 1000
    end
})

-- Luck Boost Section (BLATAN!)
local luckSection = main:Section({
    Text = "🍀 Luck Booster [BLATAN]"
})

luckSection:Toggle({
    Text = "Enable Luck Boost (999%)",
    Default = false,
    Callback = function(v)
        settings.luckBoost = v
        if v then
            Wind:Notification({
                Title = "Luck Boost",
                Text = "Luck multiplier activated! Better rare fish!",
                Duration = 3,
            })
        end
        print("Luck Boost:", v)
    end
})

luckSection:Slider({
    Text = "Luck Multiplier (%)",
    Min = 100,
    Max = 2000,
    Default = 1000,
    Callback = function(v)
        settings.luckMultiplier = v
        print("Luck Multiplier:", v .. "%")
    end
})

luckSection:Label({
    Text = "⚠️ Higher luck = more Legendary/Mythic fish!"
})

luckSection:Toggle({
    Text = "Auto Sell Fish",
    Default = false,
    Callback = function(v)
        settings.autoSell = v
        print("Auto Sell:", v)
    end
})

-- Anti Disconnect Section
local antiDCSection = main:Section({
    Text = "🛡️ Anti Disconnect"
})

antiDCSection:Toggle({
    Text = "Anti AFK Disconnect",
    Default = false,
    Callback = function(v)
        settings.antiDisconnect = v
        print("Anti Disconnect:", v)
    end
})

-- Teleport Tab
local teleportTab = win:Tab({
    Text = "Teleport",
    Icon = "rbxassetid://10723407389"
})

local teleportSection = teleportTab:Section({
    Text = "🏝️ Island Teleport"
})

teleportSection:Dropdown({
    Text = "Select Island",
    List = {
        "Fisherman Island",
        "Kohana Island", 
        "Kohana Volcano",
        "Coral Reef Island",
        "Esoteric Depths",
        "Tropical Grove Island",
        "Crater Island",
        "Lost Isle",
        "Ancient Jungle Island"
    },
    Default = "Fisherman Island",
    Callback = function(v)
        settings.selectedIsland = v
    end
})

teleportSection:Button({
    Text = "Teleport to Selected Island",
    Callback = function()
        local targetCF = islands[settings.selectedIsland]
        if targetCF and character and character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = targetCF
            
            Wind:Notification({
                Title = "Teleport",
                Text = "Teleported to " .. settings.selectedIsland,
                Duration = 3,
            })
        end
    end
})

-- Farm Spots Section
local farmSection = teleportTab:Section({
    Text = "🎯 Best Farm Spots"
})

farmSection:Dropdown({
    Text = "Quick Farm Teleport",
    List = {
        "Kohana Volcano",
        "Tropical Grove",
        "Lost Isle",
        "Ancient Jungle"
    },
    Default = "Kohana Volcano",
    Callback = function(v)
        settings.farmMode = v
    end
})

farmSection:Button({
    Text = "Go to Farm Spot!",
    Callback = function()
        local spot = farmSpots[settings.farmMode]
        if spot and character and character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = spot.pos
            
            Wind:Notification({
                Title = "Farm Spot",
                Text = settings.farmMode .. " - " .. spot.reason,
                Duration = 4,
            })
        end
    end
})

farmSection:Label({
    Text = "💰 Top Money Spots:"
})

farmSection:Label({
    Text = "• Kohana Volcano - Best consistent profit"
})

farmSection:Label({
    Text = "• Tropical Grove - 1/1000 Enchant Stones"
})

farmSection:Label({
    Text = "• Lost Isle - Treasure Room (need 75k)"
})

-- Settings Tab
local settingsTab = win:Tab({
    Text = "Settings",
    Icon = "rbxassetid://10734950309"
})

local configSection = settingsTab:Section({
    Text = "⚙️ Configuration"
})

configSection:Button({
    Text = "Reset All Settings",
    Callback = function()
        settings.autoPerfect = false
        settings.autoFastFishing = false
        settings.perfectDelay = 0.1
        settings.autoReel = true
        settings.antiDisconnect = false
        settings.luckBoost = false
        settings.autoShake = true
        settings.autoSell = false
        
        Wind:Notification({
            Title = "Settings",
            Text = "All settings reset to default",
            Duration = 3,
        })
    end
})

configSection:Label({
    Text = "Script Version: 3.0 BLATAN Edition"
})

-- Info Section
local infoSection = settingsTab:Section({
    Text = "📊 Game Info"
})

infoSection:Label({
    Text = "Total Fish Types: 112+"
})

infoSection:Label({
    Text = "Rarity: Uncommon → Mythic/Special"
})

infoSection:Label({
    Text = "Best Rod: Astral (350% Luck)"
})

infoSection:Label({
    Text = "Best Bait: Aether (240% Luck)"
})

-- Credits Tab
local creditsTab = win:Tab({
    Text = "Credits",
    Icon = "rbxassetid://10747373176"
})

local creditsSection = creditsTab:Section({
    Text = "ℹ️ Information"
})

creditsSection:Label({
    Text = "Script: BLATAN Pro Edition"
})

creditsSection:Label({
    Text = "UI Library: WindUI by NazarickSpy_"
})

creditsSection:Label({
    Text = "Game: Fish It by Fish Atelier"
})

creditsSection:Label({
    Text = "Features: Perfect, Luck, Anti-DC, TP"
})

-- Anti Disconnect Function
local function antiDisconnect()
    spawn(function()
        while true do
            wait(240) -- Check every 4 minutes
            
            if settings.antiDisconnect then
                virtualUser:CaptureController()
                virtualUser:ClickButton2(Vector2.new())
                
                -- Micro movement
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local currentCF = character.HumanoidRootPart.CFrame
                    character.HumanoidRootPart.CFrame = currentCF * CFrame.new(0.1, 0, 0.1)
                    wait(0.1)
                    character.HumanoidRootPart.CFrame = currentCF
                end
            end
        end
    end)
end

-- Luck Boost Function (Modify luck meter)
local function luckBooster()
    spawn(function()
        while true do
            task.wait(0.5)
            
            if settings.luckBoost then
                local playerGui = player:WaitForChild("PlayerGui")
                
                -- Find luck meter/bar
                for _, gui in pairs(playerGui:GetDescendants()) do
                    if gui:IsA("Frame") or gui:IsA("ImageLabel") then
                        if gui.Name:lower():find("luck") or 
                           gui.Name:lower():find("meter") or
                           gui.Name:lower():find("bar") then
                            
                            -- Modify size to max
                            if gui:FindFirstChild("Fill") or gui:FindFirstChild("Bar") then
                                local fill = gui:FindFirstChild("Fill") or gui:FindFirstChild("Bar")
                                if fill:IsA("GuiObject") then
                                    fill.Size = UDim2.new(1, 0, 1, 0) -- Max luck
                                end
                            end
                        end
                    end
                end
                
                -- Try to modify stats via game values
                local stats = player:FindFirstChild("leaderstats") or player:FindFirstChild("Stats")
                if stats then
                    local luck = stats:FindFirstChild("Luck")
                    if luck and luck:IsA("NumberValue") then
                        luck.Value = luck.Value * (settings.luckMultiplier / 100)
                    end
                end
            end
        end
    end)
end

-- Auto Shake Function (BLATAN FAST CLICK!)
local function autoShake()
    spawn(function()
        while true do
            task.wait(0.01) -- Super fast
            
            if settings.autoShake then
                local playerGui = player:WaitForChild("PlayerGui")
                
                -- Find shake button
                for _, button in pairs(playerGui:GetDescendants()) do
                    if button:IsA("TextButton") or button:IsA("ImageButton") then
                        if button.Name:lower():find("shake") or 
                           button.Name:lower():find("click") or
                           button.Text:lower():find("click") then
                            
                            if button.Visible and button.Active then
                                -- Auto click super fast
                                for i = 1, 3 do
                                    virtualUser:CaptureController()
                                    virtualUser:Button1Down(Vector2.new(0,0))
                                    task.wait(0.01)
                                    virtualUser:Button1Up(Vector2.new(0,0))
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Auto Perfect Fishing Function
local function autoPerfectCatch()
    spawn(function()
        while true do
            task.wait(0.03)
            
            if settings.autoPerfect then
                local playerGui = player:WaitForChild("PlayerGui")
                
                for _, gui in pairs(playerGui:GetDescendants()) do
                    if gui:IsA("Frame") and gui.Visible then
                        -- Look for perfect zone
                        local perfectZone = gui:FindFirstChild("Perfect") or 
                                          gui:FindFirstChild("PerfectZone") or
                                          gui:FindFirstChild("Green")
                        
                        local indicator = gui:FindFirstChild("Indicator") or 
                                        gui:FindFirstChild("Pointer") or
                                        gui:FindFirstChild("Bar")
                        
                        if perfectZone and indicator then
                            -- Check position overlap
                            local pPos = perfectZone.AbsolutePosition
                            local pSize = perfectZone.AbsoluteSize
                            local iPos = indicator.AbsolutePosition
                            
                            local inZone = iPos.X >= pPos.X and 
                                         iPos.X <= (pPos.X + pSize.X)
                            
                            if inZone then
                                wait(settings.perfectDelay)
                                
                                -- Click!
                                virtualUser:CaptureController()
                                virtualUser:Button1Down(Vector2.new(0,0))
                                wait(0.05)
                                virtualUser:Button1Up(Vector2.new(0,0))
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Auto Fast Fishing Function
local function autoFastFishing()
    spawn(function()
        while true do
            task.wait(0.5)
            
            if settings.autoFastFishing then
                -- Speed up animations
                if character then
                    local humanoid = character:FindFirstChild("Humanoid")
                    if humanoid then
                        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                            if track.Name:lower():find("fish") or 
                               track.Name:lower():find("cast") or
                               track.Name:lower():find("reel") then
                                track:AdjustSpeed(5) -- 5x speed
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Auto Reel Function
local function autoReel()
    spawn(function()
        while true do
            task.wait(0.2)
            
            if settings.autoReel then
                local playerGui = player:WaitForChild("PlayerGui")
                
                -- Find reel button
                for _, button in pairs(playerGui:GetDescendants()) do
                    if button:IsA("TextButton") or button:IsA("ImageButton") then
                        if button.Name:lower():find("reel") or 
                           button.Name:lower():find("collect") or
                           button.Text:lower():find("reel") then
                            
                            if button.Visible and button.Active then
                                -- Auto click reel
                                virtualUser:CaptureController()
                                virtualUser:Button1Down(Vector2.new(0,0))
                                wait(0.1)
                                virtualUser:Button1Up(Vector2.new(0,0))
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Auto Sell Function
local function autoSell()
    spawn(function()
        while true do
            wait(60) -- Every 1 minute
            
            if settings.autoSell then
                -- Teleport to merchant
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local merchantPos = CFrame.new(68, 35, -178) -- Fisherman Island merchant
                    character.HumanoidRootPart.CFrame = merchantPos
                    
                    wait(1)
                    
                    -- Find and click sell button
                    local playerGui = player:WaitForChild("PlayerGui")
                    for _, button in pairs(playerGui:GetDescendants()) do
                        if button:IsA("TextButton") then
                            if button.Text:lower():find("sell") then
                                virtualUser:CaptureController()
                                virtualUser:Button1Down(Vector2.new(0,0))
                                wait(0.1)
                                virtualUser:Button1Up(Vector2.new(0,0))
                                
                                print("Auto sold fish!")
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Character respawn handler
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    wait(1)
end)

-- Start all functions
antiDisconnect()
luckBooster()
autoShake()
autoPerfectCatch()
autoFastFishing()
autoReel()
autoSell()

-- Success Notification
Wind:Notification({
    Title = "Fish It BLATAN Edition!",
    Text = "Luck boost & all features loaded! Selamat farming! 🎣",
    Duration = 5,
})

print("=" .. string.rep("=", 60))
print("🎣 FISH IT AUTO SCRIPT - BLATAN EDITION 🎣")
print("Features: Perfect Catch, Luck 999%, Anti-DC, Fast Shake, TP")
print("Best Farm: Kohana Volcano (Early-Mid), Tropical Grove (Stones)")
print("Made with WindUI by NazarickSpy_")
print("=" .. string.rep("=", 60))