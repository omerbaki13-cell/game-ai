-- GLOBAL DEĞİŞKENLER (Hafıza)
if getgenv().AutoReexecute == nil then
    getgenv().AutoReexecute = false
end

local scriptUrl = "https://raw.githubusercontent.com/omerbaki13-cell/game-ai/refs/heads/main/speedrun.lua"

-- TELEPORT (DÜNYA DEĞİŞTİRME) SİSTEMİ
local queueFunction = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or (Identifyexecutor and identifyexecutor() and queue_on_teleport)

local function applyTeleportQueue()
    if queueFunction and getgenv().AutoReexecute then
        pcall(function()
            queueFunction(string.format([[
                repeat task.wait() until game:IsLoaded()
                getgenv().AutoReexecute = true
                loadstring(game:HttpGet("%s"))()
            ]], scriptUrl))
        end)
    end
end

-- Teleport anında otomatik tetikleme
local TeleportService = game:GetService("TeleportService")
TeleportService.TeleportInitFailed:Connect(function() end)
game:GetService("Players").LocalPlayer.OnTeleport:Connect(function()
    applyTeleportQueue()
end)

-- Eski GUI temizliği
if game.CoreGui:FindFirstChild("SpeedrunTimerGui") then
    game.CoreGui.SpeedrunTimerGui:Destroy()
end

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local connections = {}

-- 1. PB KAYDETME / YÜKLEME SİSTEMİ (FILE SAVING)
local fileName = "speedrun_pb_data.json"
local HttpService = game:GetService("HttpService")

local function savePB(pbValue)
    if writefile then
        pcall(function()
            local data = {PB = pbValue}
            writefile(fileName, HttpService:JSONEncode(data))
        end)
    end
end

local function loadPB()
    if readfile and isfile and isfile(fileName) then
        local success, result = pcall(function()
            local data = HttpService:JSONDecode(readfile(fileName))
            return data.PB
        end)
        if success then return result end
    end
    return nil
end

local bestTime = loadPB()

-- SES SİSTEMİ
local soundEnabled = true
local function playSound(assetPath, volume, pitch)
    if not soundEnabled then return end
    task.spawn(function()
        local sound = Instance.new("Sound")
        sound.SoundId = assetPath
        sound.Volume = volume or 0.5
        sound.PlaybackSpeed = pitch or 1
        sound.Parent = game:GetService("SoundService")
        sound:Play()
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end)
end

local SOUND_START = "rbxasset://sounds/uipositionreset.wav"
local SOUND_STOP  = "rbxasset://sounds/button.wav"
local SOUND_RESET = "rbxasset://sounds/uipositionreset.wav"

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpeedrunTimerGui"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local autoStartEnabled = false
local currentThemeIndex = 1
local rgbConnection = nil
local rgbOffset = 0
local mobileButtonsEnabled = false
local opacityIndex = 1
local opacityValues = {0.35, 0.70, 0.00} -- Şeffaflık seviyeleri

-- "S" BUTONU
local ToggleIconButton = Instance.new("TextButton")
local IconCorner = Instance.new("UICorner")
local IconStroke = Instance.new("UIStroke")

ToggleIconButton.Name = "ToggleIconButton"
ToggleIconButton.Parent = ScreenGui
ToggleIconButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ToggleIconButton.BackgroundTransparency = 0.2
ToggleIconButton.Position = UDim2.new(0, 15, 0.3, 0)
ToggleIconButton.Size = UDim2.new(0, 45, 0, 45)
ToggleIconButton.Font = Enum.Font.SourceSansBold
ToggleIconButton.Text = "S"
ToggleIconButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleIconButton.TextSize = 26
ToggleIconButton.Active = true
ToggleIconButton.Draggable = true

IconCorner.CornerRadius = UDim.new(1, 0)
IconCorner.Parent = ToggleIconButton

IconStroke.Color = Color3.fromRGB(46, 204, 113)
IconStroke.Thickness = 2
IconStroke.Parent = ToggleIconButton

-- ANA PANEL
local MainFrame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local TimeText = Instance.new("TextLabel")
local PBText = Instance.new("TextLabel")
local FpsPingText = Instance.new("TextLabel")
local ToggleBtn = Instance.new("TextButton")
local ResetBtn = Instance.new("TextButton")
local SettingsToggleBtn = Instance.new("TextButton")

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = opacityValues[opacityIndex]
MainFrame.Position = UDim2.new(0, 15, 0.4, 0)
MainFrame.Size = UDim2.new(0, 210, 0, 120)
MainFrame.Active = true
MainFrame.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Süre Göstergesi
TimeText.Name = "TimeText"
TimeText.Parent = MainFrame
TimeText.BackgroundTransparency = 1
TimeText.Position = UDim2.new(0, 0, 0, 4)
TimeText.Size = UDim2.new(1, 0, 0, 26)
TimeText.Font = Enum.Font.SourceSansBold
TimeText.Text = "00:00:00.00"
TimeText.TextColor3 = Color3.fromRGB(255, 255, 255)
TimeText.TextSize = 20
TimeText.TextScaled = true

-- PB Göstergesi
local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    local milliseconds = math.floor((seconds % 1) * 100)
    return string.format("%02d:%02d:%02d.%02d", hours, minutes, secs, milliseconds)
end

PBText.Name = "PBText"
PBText.Parent = MainFrame
PBText.BackgroundTransparency = 1
PBText.Position = UDim2.new(0, 0, 0, 30)
PBText.Size = UDim2.new(1, 0, 0, 16)
PBText.Font = Enum.Font.SourceSansBold
PBText.Text = bestTime and ("PB: " .. formatTime(bestTime)) or "PB: --:--:--.--"
PBText.TextColor3 = Color3.fromRGB(241, 196, 15)
PBText.TextSize = 12

-- FPS & PING GÖSTERGESİ (İstek 6)
FpsPingText.Name = "FpsPingText"
FpsPingText.Parent = MainFrame
FpsPingText.BackgroundTransparency = 1
FpsPingText.Position = UDim2.new(0, 0, 0, 46)
FpsPingText.Size = UDim2.new(1, 0, 0, 14)
FpsPingText.Font = Enum.Font.SourceSans
FpsPingText.Text = "FPS: -- | Ping: -- ms"
FpsPingText.TextColor3 = Color3.fromRGB(180, 180, 180)
FpsPingText.TextSize = 10

-- BAŞLAT / DURDUR
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Parent = MainFrame
ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.62, 0)
ToggleBtn.Size = UDim2.new(0.50, 0, 0.28, 0)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.Text = "BAŞLAT / DURDUR"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 9

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 4)
ToggleCorner.Parent = ToggleBtn

-- SIFIRLA
ResetBtn.Name = "ResetBtn"
ResetBtn.Parent = MainFrame
ResetBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
ResetBtn.Position = UDim2.new(0.58, 0, 0.62, 0)
ResetBtn.Size = UDim2.new(0.24, 0, 0.28, 0)
ResetBtn.Font = Enum.Font.SourceSansBold
ResetBtn.Text = "SIFIRLA"
ResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetBtn.TextSize = 9

local ResetCorner = Instance.new("UICorner")
ResetCorner.CornerRadius = UDim.new(0, 4)
ResetCorner.Parent = ResetBtn

-- AYARLAR BUTONU
SettingsToggleBtn.Name = "SettingsToggleBtn"
SettingsToggleBtn.Parent = MainFrame
SettingsToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
SettingsToggleBtn.Position = UDim2.new(0.85, 0, 0.62, 0)
SettingsToggleBtn.Size = UDim2.new(0.10, 0, 0.28, 0)
SettingsToggleBtn.Font = Enum.Font.SourceSansBold
SettingsToggleBtn.Text = "⚙️"
SettingsToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsToggleBtn.TextSize = 10

local SettingsCorner = Instance.new("UICorner")
SettingsCorner.CornerRadius = UDim.new(0, 4)
SettingsCorner.Parent = SettingsToggleBtn

-- AYARLAR PENCERESİ (GENİŞLETİLDİ)
local SettingsFrame = Instance.new("Frame")
local SettingsUICorner = Instance.new("UICorner")
local SettingsLayout = Instance.new("UIListLayout")

SettingsFrame.Name = "SettingsFrame"
SettingsFrame.Parent = ScreenGui
SettingsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SettingsFrame.BackgroundTransparency = 0.1
SettingsFrame.Position = UDim2.new(0, 235, 0.35, 0)
SettingsFrame.Size = UDim2.new(0, 160, 0, 220)
SettingsFrame.Visible = false

SettingsUICorner.CornerRadius = UDim.new(0, 8)
SettingsUICorner.Parent = SettingsFrame

SettingsLayout.Parent = SettingsFrame
SettingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SettingsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
SettingsLayout.Padding = UDim.new(0, 5)

local function createSettingBtn(name, text, color)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Parent = SettingsFrame
    btn.BackgroundColor3 = color
    btn.Size = UDim2.new(0.9, 0, 0, 25)
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 10
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn
    return btn
end

local AutoStartBtn   = createSettingBtn("AutoStartBtn", "Oto Başla: KAPALI", Color3.fromRGB(192, 57, 43))
local AutoExecBtn    = createSettingBtn("AutoExecBtn", getgenv().AutoReexecute and "Oto Yükleme: AÇIK" or "Oto Yükleme: KAPALI", getgenv().AutoReexecute and Color3.fromRGB(39, 174, 96) or Color3.fromRGB(192, 57, 43))
local MobileTouchBtn = createSettingBtn("MobileTouchBtn", "Mobil Tuşlar: KAPALI", Color3.fromRGB(192, 57, 43)) -- İstek 3
local OpacityBtn     = createSettingBtn("OpacityBtn", "Şeffaflık: Normal", Color3.fromRGB(142, 68, 173)) -- İstek 4
local SoundToggleBtn = createSettingBtn("SoundToggleBtn", "Sesler: AÇIK", Color3.fromRGB(39, 174, 96)) -- İstek 5
local ThemeBtn       = createSettingBtn("ThemeBtn", "Tema: Varsayılan", Color3.fromRGB(52, 152, 219))
local CloseScriptBtn = createSettingBtn("CloseScriptBtn", "❌ Scripti Kapat", Color3.fromRGB(180, 40, 40))

-- 3. MOBİL DOKUNMATİK TUŞLAR (İstek 3)
local MobileFrame = Instance.new("Frame")
MobileFrame.Name = "MobileFrame"
MobileFrame.Parent = ScreenGui
MobileFrame.BackgroundTransparency = 1
MobileFrame.Position = UDim2.new(0.75, 0, 0.6, 0)
MobileFrame.Size = UDim2.new(0, 130, 0, 60)
MobileFrame.Visible = false

local TouchStartBtn = Instance.new("TextButton")
TouchStartBtn.Parent = MobileFrame
TouchStartBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
TouchStartBtn.Position = UDim2.new(0, 0, 0, 0)
TouchStartBtn.Size = UDim2.new(0, 55, 0, 55)
TouchStartBtn.Font = Enum.Font.SourceSansBold
TouchStartBtn.Text = "Q\n(BAŞLA)"
TouchStartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TouchStartBtn.TextSize = 12
TouchStartBtn.Active = true
TouchStartBtn.Draggable = true

local TouchStartCorner = Instance.new("UICorner")
TouchStartCorner.CornerRadius = UDim.new(1, 0)
TouchStartCorner.Parent = TouchStartBtn

local TouchResetBtn = Instance.new("TextButton")
TouchResetBtn.Parent = MobileFrame
TouchResetBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
TouchResetBtn.Position = UDim2.new(0, 65, 0, 0)
TouchResetBtn.Size = UDim2.new(0, 55, 0, 55)
TouchResetBtn.Font = Enum.Font.SourceSansBold
TouchResetBtn.Text = "R\n(SIFIRLA)"
TouchResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TouchResetBtn.TextSize = 11
TouchResetBtn.Active = true
TouchResetBtn.Draggable = true

local TouchResetCorner = Instance.new("UICorner")
TouchResetCorner.CornerRadius = UDim.new(1, 0)
TouchResetCorner.Parent = TouchResetBtn

-- KRONOMETRE MANTIĞI
local running = false
local startTime = 0
local elapsedTime = 0

local themes = {
    {name = "Varsayılan", color = Color3.fromRGB(46, 204, 113)},
    {name = "RGB Gökkuşağı", color = Color3.fromRGB(255, 255, 255)},
    {name = "Neon Mavi", color = Color3.fromRGB(0, 210, 255)},
    {name = "Karanlık Kırmızı", color = Color3.fromRGB(231, 76, 60)}
}

local function toggleTimer()
    if not running then
        running = true
        startTime = os.clock() - elapsedTime
        playSound(SOUND_START, 0.7, 1.2)
        
        task.spawn(function()
            while running do
                elapsedTime = os.clock() - startTime
                TimeText.Text = formatTime(elapsedTime)
                task.wait(0.03)
            end
        end)
    else
        running = false
        playSound(SOUND_STOP, 0.7, 0.8)
        if bestTime == nil or elapsedTime < bestTime then
            bestTime = elapsedTime
            PBText.Text = "PB: " .. formatTime(bestTime)
            savePB(bestTime) -- PB Kaydedildi (İstek 1)
        end
    end
end

local function resetTimer()
    running = false
    elapsedTime = 0
    TimeText.Text = "00:00:00.00"
    playSound(SOUND_RESET, 0.6, 0.9)
    if themes[currentThemeIndex].name == "RGB Gökkuşağı" then
        rgbOffset = (rgbOffset + 0.33) % 1
    end
end

-- Buton Dinleyicileri
ToggleBtn.MouseButton1Click:Connect(toggleTimer)
ResetBtn.MouseButton1Click:Connect(resetTimer)
TouchStartBtn.MouseButton1Click:Connect(toggleTimer)
TouchResetBtn.MouseButton1Click:Connect(resetTimer)

ToggleIconButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    SettingsFrame.Visible = false
    playSound(SOUND_STOP, 0.3, 1)
end)

SettingsToggleBtn.MouseButton1Click:Connect(function()
    SettingsFrame.Visible = not SettingsFrame.Visible
    playSound(SOUND_STOP, 0.3, 1)
end)

-- Oto Başla
AutoStartBtn.MouseButton1Click:Connect(function()
    autoStartEnabled = not autoStartEnabled
    playSound(SOUND_STOP, 0.5, 1)
    AutoStartBtn.Text = autoStartEnabled and "Oto Başla: AÇIK" or "Oto Başla: KAPALI"
    AutoStartBtn.BackgroundColor3 = autoStartEnabled and Color3.fromRGB(39, 174, 96) or Color3.fromRGB(192, 57, 43)
end)

-- Auto Execute (Oto Yükleme)
AutoExecBtn.MouseButton1Click:Connect(function()
    getgenv().AutoReexecute = not getgenv().AutoReexecute
    applyTeleportQueue()
    playSound(SOUND_STOP, 0.5, 1)
    AutoExecBtn.Text = getgenv().AutoReexecute and "Oto Yükleme: AÇIK" or "Oto Yükleme: KAPALI"
    AutoExecBtn.BackgroundColor3 = getgenv().AutoReexecute and Color3.fromRGB(39, 174, 96) or Color3.fromRGB(192, 57, 43)
end)

-- Mobil Tuşlar Aç/Kapat (İstek 3)
MobileTouchBtn.MouseButton1Click:Connect(function()
    mobileButtonsEnabled = not mobileButtonsEnabled
    MobileFrame.Visible = mobileButtonsEnabled
    playSound(SOUND_STOP, 0.5, 1)
    MobileTouchBtn.Text = mobileButtonsEnabled and "Mobil Tuşlar: AÇIK" or "Mobil Tuşlar: KAPALI"
    MobileTouchBtn.BackgroundColor3 = mobileButtonsEnabled and Color3.fromRGB(39, 174, 96) or Color3.fromRGB(192, 57, 43)
end)

-- Şeffaflık Değiştirme (İstek 4)
OpacityBtn.MouseButton1Click:Connect(function()
    opacityIndex = opacityIndex + 1
    if opacityIndex > #opacityValues then opacityIndex = 1 end
    MainFrame.BackgroundTransparency = opacityValues[opacityIndex]
    playSound(SOUND_STOP, 0.5, 1)
    
    local opNames = {"Normal", "Şeffaf", "Tam Cam"}
    OpacityBtn.Text = "Şeffaflık: " .. opNames[opacityIndex]
end)

-- Ses Aç/Kapat (İstek 5)
SoundToggleBtn.MouseButton1Click:Connect(function()
    soundEnabled = not soundEnabled
    playSound(SOUND_STOP, 0.5, 1)
    SoundToggleBtn.Text = soundEnabled and "Sesler: AÇIK" or "Sesler: KAPALI"
    SoundToggleBtn.BackgroundColor3 = soundEnabled and Color3.fromRGB(39, 174, 96) or Color3.fromRGB(192, 57, 43)
end)

-- Tema Değiştirme
ThemeBtn.MouseButton1Click:Connect(function()
    currentThemeIndex = currentThemeIndex + 1
    if currentThemeIndex > #themes then currentThemeIndex = 1 end
    local theme = themes[currentThemeIndex]
    ThemeBtn.Text = "Tema: " .. theme.name
    playSound(SOUND_STOP, 0.5, 1.1)
    
    if rgbConnection then
        rgbConnection:Disconnect()
        rgbConnection = nil
    end

    if theme.name == "RGB Gökkuşağı" then
        rgbConnection = RunService.RenderStepped:Connect(function()
            local hue1 = ((tick() * 0.5) + rgbOffset) % 1
            local hue2 = ((tick() * 0.5) + rgbOffset + 0.5) % 1
            local color1 = Color3.fromHSV(hue1, 1, 1)
            local color2 = Color3.fromHSV(hue2, 1, 1)
            IconStroke.Color = color1
            ToggleBtn.BackgroundColor3 = color1
            ResetBtn.BackgroundColor3 = color2
        end)
    else
        IconStroke.Color = theme.color
        ToggleBtn.BackgroundColor3 = theme.color
        ResetBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    end
end)

-- Scripti Kapat
CloseScriptBtn.MouseButton1Click:Connect(function()
    playSound(SOUND_RESET, 0.5, 0.7)
    running = false
    for _, conn in ipairs(connections) do
        if conn then conn:Disconnect() end
    end
    if rgbConnection then rgbConnection:Disconnect() end
    ScreenGui:Destroy()
end)

-- FPS ve Ping Güncelleme Döngüsü (İstek 6)
task.spawn(function()
    local lastTime = os.clock()
    local frameCount = 0
    while ScreenGui and ScreenGui.Parent do
        frameCount = frameCount + 1
        local currentTime = os.clock()
        if currentTime - lastTime >= 1 then
            local fps = math.floor(frameCount / (currentTime - lastTime))
            local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            FpsPingText.Text = string.format("FPS: %d | Ping: %d ms", fps, ping)
            frameCount = 0
            lastTime = currentTime
        end
        task.wait(0.5)
    end
end)

-- Klavye Kontrolleri (PC - Q Tuşu)
local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        toggleTimer()
    elseif input.KeyCode == Enum.KeyCode.R then
        resetTimer()
    end
    if autoStartEnabled and not running then
        local k = input.KeyCode
        if k == Enum.KeyCode.W or k == Enum.KeyCode.A or k == Enum.KeyCode.S or k == Enum.KeyCode.D or
           k == Enum.KeyCode.Up or k == Enum.KeyCode.Down or k == Enum.KeyCode.Left or k == Enum.KeyCode.Right then
            toggleTimer()
        end
    end
end)
table.insert(connections, inputConn)

-- Karakter Hareketiyle Oto Başlat
local renderConn = RunService.RenderStepped:Connect(function()
    if autoStartEnabled and not running then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.MoveDirection.Magnitude > 0 then
                toggleTimer()
            end
        end
    end
end)
table.insert(connections, renderConn)

-- Ölünce Otomatik Sıfırlama
local function setupDeathReset(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        local deathConn = humanoid.Died:Connect(function()
            resetTimer()
        end)
        table.insert(connections, deathConn)
    end
end

if LocalPlayer.Character then setupDeathReset(LocalPlayer.Character) end
local charAddedConn = LocalPlayer.CharacterAdded:Connect(setupDeathReset)
table.insert(connections, charAddedConn)
