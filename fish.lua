-- Load Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- Window
local Window = Rayfield:CreateWindow({
   Name = "CatalystHub",
   LoadingTitle = "CatalystHub",
   LoadingSubtitle = "Auto Fish System",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "CatalystHubConfig",
      FileName = "AutoConfig"
   }
})

-- Tabs
local MainTab = Window:CreateTab("Main", 4483362458)
local TeleportTab = Window:CreateTab("Teleport", 4483362458)
local FishNotif = Window:CreateTab("Webhook", 4483362458)
local AutoFavTab = Window:CreateTab("Auto Favorite", 4483362458)

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- State
local state = { AutoFish = false, AutoSell = false }
local autoFishLoop

-- Helpers
local function safeRequire(pathTbl)
    local ptr = ReplicatedStorage
    for _, seg in ipairs(pathTbl) do
        ptr = ptr:FindFirstChild(seg)
        if not ptr then return nil end
    end
    local ok, mod = pcall(require, ptr)
    return ok and mod or nil
end

local function getNetFolder()
   local packages = ReplicatedStorage:WaitForChild("Packages", 10)
   if not packages then return nil end
   local index = packages:FindFirstChild("_Index")
   if index then
      for _, child in ipairs(index:GetChildren()) do
         if child.Name:match("^sleitnick_net@") then
            return child:FindFirstChild("net")
         end
      end
   end
   return ReplicatedStorage:FindFirstChild("net") or ReplicatedStorage:FindFirstChild("Net")
end

local FishingController = safeRequire({"Controllers","FishingController"})
local Replion = safeRequire({"Packages","Replion"}) or safeRequire({"Packages","replion"})
------------------------------------------------------------------------------------
-- WEBHOOK SYSTEM
------------------------------------------------------------------------------------
local savedData = { webhookUrl = "" }
local file_name = "catalysthub_webhook.json"

local function saveConfig()
    if writefile then
        writefile(file_name, HttpService:JSONEncode(savedData))
    end
end

local function loadConfig()
    if isfile and isfile(file_name) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(file_name))
        end)
        if success and type(data) == "table" then
            savedData = data
        end
    end
end

loadConfig()
local webhookUrl = savedData.webhookUrl

FishNotif:CreateParagraph({
    Title = "Fish Notification System",
    Content = "Masukkan URL webhook Discord untuk menerima notifikasi otomatis saat mendapatkan ikan langka."
})

FishNotif:CreateInput({
    Name = "Webhook URL",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    RemoveTextAfterFocusLost = false,
    CurrentValue = savedData.webhookUrl,
    Callback = function(text)
        if text == "" then
            webhookUrl = nil
            savedData.webhookUrl = ""
            saveConfig()
            Rayfield:Notify({ Title = "Webhook", Content = "Webhook berhasil dihapus!", Duration = 4 })
            return
        end
        webhookUrl = text
        savedData.webhookUrl = text
        saveConfig()
        Rayfield:Notify({ Title = "Webhook", Content = "Webhook berhasil disimpan!", Duration = 4 })
    end
})

-- Fish Data
local FishDataById, VariantsByName, SelectedCategories = {}, {}, {}
local rarityMap = {
    [1] = "Common", [2] = "Uncommon", [3] = "Rare",
    [4] = "Epic", [5] = "Legendary", [6] = "Mythic", [7] = "Secret"
}

pcall(function()
    for _, item in ipairs(ReplicatedStorage.Items:GetChildren()) do
        local ok, data = pcall(require, item)
        if ok and data.Data and data.Data.Type == "Fishes" then
            FishDataById[data.Data.Id] = {
                Name = data.Data.Name,
                SellPrice = data.SellPrice or 0,
                Tier = data.Data.Tier,
                Icon = data.IconId or data.Data.Icon or ""
            }
        end
    end
    for _, v in ipairs(ReplicatedStorage.Variants:GetChildren()) do
        local ok, data = pcall(require, v)
        if ok and data.Data and data.Data.Type == "Variant" then
            VariantsByName[data.Data.Name] = data.SellMultiplier or 1
        end
    end
end)

FishNotif:CreateDropdown({
    Name = "Pilih Kelangkaan",
    Options = {"Secret", "Legendary", "Mythic", "Epic"},
    CurrentOption = {"Secret"},
    MultipleOptions = true,
    Callback = function(selected)
        SelectedCategories = selected
    end
})

local function GetRobloxImage(assetId)
    local url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. assetId .. "&size=420x420&format=Png&isCircular=false"
    local success, response = pcall(game.HttpGet, game, url)
    if success then
        local data = HttpService:JSONDecode(response)
        if data and data.data and data.data[1] and data.data[1].imageUrl then
            return data.data[1].imageUrl
        end
    end
    return nil
end

local function sendFishWebhook(fishName, rarityText, assetId, itemId, variantId)
    if not webhookUrl or webhookUrl == "" then return end
    local username = player.DisplayName
    local imageUrl = GetRobloxImage(assetId)
    if not imageUrl then return end

    local caught = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Caught")
    local rarest = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Rarest Fish")
    local basePrice = (FishDataById[itemId] and FishDataById[itemId].SellPrice or 0) * (VariantsByName[variantId] or 1)
    
    -- Format harga dengan separator ribuan
    local formattedPrice = tostring(basePrice):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
    
    -- Tentukan warna embed berdasarkan rarity
    local colorMap = {
        ["Epic"] = 0x9B59B6,
        ["Legendary"] = 0xF1C40F,
        ["Mythic"] = 0xE74C3C,
        ["Secret"] = 0x1ABC9C
    }
    local embedColor = colorMap[rarityText] or 0x3498DB
    
    -- Emoji rarity
    local rarityEmoji = {
        ["Epic"] = "💜",
        ["Legendary"] = "💛",
        ["Mythic"] = "❤️",
        ["Secret"] = "🤍"
    }
    local emoji = rarityEmoji[rarityText] or "🎣"

    local data = {
        ["username"] = "CatalystHub Notifier",
        ["avatar_url"] = "https://cdn.discordapp.com/attachments/124567890123456789/123456789012345678/catalyst_logo.png", -- Ganti dengan URL logo jika ada
        ["embeds"] = {{
            ["title"] = emoji .. " Rare Fish Caught!",
            ["description"] = string.format("**Player:** `%s`\n**Fish:** `%s`\n**Rarity:** `%s`", username, fishName, rarityText),
            ["color"] = embedColor,
            ["thumbnail"] = { ["url"] = imageUrl },
            ["fields"] = {
                { 
                    name = "💰 Sell Price", 
                    value = string.format("**%s** 💎", formattedPrice), 
                    inline = true
                },
                { 
                    name = "📊 Total Caught", 
                    value = string.format("**%s**", tostring(caught and caught.Value or "N/A")), 
                    inline = true
                },
                { 
                    name = "🏆 Rarest Fish", 
                    value = string.format("**%s**", tostring(rarest and rarest.Value or "N/A")), 
                    inline = true
                },
            },
            ["footer"] = { 
                ["text"] = "CatalystHub • " .. os.date("%d/%m/%Y %I:%M:%S %p", os.time()),
                ["icon_url"] = "https://cdn.discordapp.com/emojis/123456789012345678.png"
            },
            ["timestamp"] = DateTime.now():ToIsoDate()
        }}
    }

    local requestFunc = syn and syn.request or http and http.request or http_request or request or fluxus and fluxus.request
    if requestFunc then
        pcall(function()
            requestFunc({
                Url = webhookUrl, 
                Method = "POST", 
                Headers = { ["Content-Type"] = "application/json" }, 
                Body = HttpService:JSONEncode(data)
            })
        end)
    end
end

local REObtainedNewFishNotification = getNetFolder() and getNetFolder():FindFirstChild("RE/ObtainedNewFishNotification")
if REObtainedNewFishNotification then
    REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, _, eventData)
        if not webhookUrl or webhookUrl == "" then return end
        pcall(function()
            local fishInfo = FishDataById[itemId]
            if not fishInfo then return end

            local rarityName = rarityMap[fishInfo.Tier] or "Unknown"
            local isTarget = false
            for _, category in pairs(SelectedCategories) do
                if string.lower(category) == string.lower(rarityName) then
                    isTarget = true
                    break
                end
            end

            if isTarget then
                local assetId = string.match(fishInfo.Icon or "", "%d+")
                if not assetId then return end
                local fishName = fishInfo.Name
                local variantId = eventData and eventData.InventoryItem and eventData.InventoryItem.Metadata and eventData.InventoryItem.Metadata.VariantId
                sendFishWebhook(fishName, rarityName, assetId, itemId, variantId)
            end
        end)
    end)
end