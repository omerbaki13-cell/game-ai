-- AYAR DEĞİŞKENLERİ (Varsayılan olarak Otomatik Yükleme KAPALI)
if getgenv().AutoReexecute == nil then
    getgenv().AutoReexecute = false
end

-- TELEPORT (BAŞKA OYUNA/DÜNYAYA GEÇİNCE) OTOMATİK ÇALIŞMA MANTIĞI
local scriptUrl = "https://raw.githubusercontent.com/omerbaki13-cell/game-ai/refs/heads/main/speedrun.lua"
local queueFunction = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)

if queueFunction and getgenv().AutoReexecute then
    queueFunction(string.format([[
        repeat task.wait() until game:IsLoaded()
        loadstring(game:HttpGet("%s"))()
    ]], scriptUrl))
end

-- Eski GUI varsa temizleyelim
if game.CoreGui:FindFirstChild("SpeedrunTimerGui") then
    game.CoreGui.SpeedrunTimerGui:Destroy()
end

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- Bağlantıları (Connections) Takip Eden Tablo
local connections = {}

-- SES EFEKTLERİ (Roblox Sistem Sesleri)
local function playSound(assetPath, volume, pitch)
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

-- Ayar Değişkenleri
local autoStartEnabled = false
local bestTime = nil
local currentThemeIndex = 1
local rgbConnection = nil
local rgbOffset = 0

-- 1. "S" SİMGESİ (AÇ / KAPAT)
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

-- 2. ANA PANEL
local MainFrame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local TimeText = Instance.new("TextLabel")
local PBText = Instance.new("TextLabel")
local ToggleBtn = Instance.new("TextButton")
local ResetBtn = Instance.new("TextButton")
local SettingsToggleBtn = Instance.new("TextButton")
local ToggleCorner = Instance.new("UICorner")
local ResetCorner = Instance.new("UICorner")

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.35
MainFrame.Position = UDim2.new(0, 15, 0.4, 0)
MainFrame.Size = UDim2.new(0, 200, 0, 100)
MainFrame.Active = true
MainFrame.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Süre Göstergesi
TimeText.Name = "TimeText"
TimeText.Parent = MainFrame
TimeText.BackgroundTransparency = 1
TimeText.Position = UDim2.new(0, 0, 0, 4)
TimeText.Size = UDim2.new(1, 0, 0, 28)
TimeText.Font = Enum.Font.SourceSansBold
TimeText.Text = "00:00:00.00"
TimeText.TextColor3 = Color3.fromRGB(255, 255, 255)
TimeText.TextSize = 20
TimeText.TextScaled = true

-- Kişisel Rekor (PB) Göstergesi
PBText.Name = "PBText"
PBText.Parent = MainFrame
PBText.BackgroundTransparency = 1
PBText.Position = UDim2.new(0, 0, 0, 32)
PBText.Size = UDim2.new(1, 0, 0, 16)
PBText.Font = Enum.Font.SourceSansBold
PBText.Text = "PB: --:--:--.--"
PBText.TextColor3 = Color3.fromRGB(241, 196, 15)
PBText.TextSize = 12

-- BAŞLAT / DURDUR Butonu
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Parent = MainFrame
ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.58, 0)
ToggleBtn.Size = UDim2.new(0.50, 0, 0.32, 0)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.Text = "BAŞLAT / DURDUR"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 9

ToggleCorner.CornerRadius = UDim.new(0, 4)
ToggleCorner.Parent = ToggleBtn

-- SIFIRLA Butonu
ResetBtn.Name = "ResetBtn"
ResetBtn.Parent = MainFrame
ResetBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
ResetBtn.Position = UDim2.new(0.58, 0, 0.58, 0)
ResetBtn.Size = UDim2.new(0.24, 0, 0.32, 0)
ResetBtn.Font = Enum.Font.SourceSansBold
ResetBtn.Text = "SIFIRLA"
ResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetBtn.TextSize = 9

ResetCorner.CornerRadius = UDim.new(0, 4)
ResetCorner.Parent = ResetBtn

-- AYARLAR BUTONU (⚙️)
SettingsToggleBtn.Name = "SettingsToggleBtn"
SettingsToggleBtn.Parent = MainFrame
SettingsToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
SettingsToggleBtn.Position = UDim2.new(0.85, 0, 0.58, 0)
SettingsToggleBtn.Size = UDim2.new(0.10, 0, 0.32, 0)
SettingsToggleBtn.Font = Enum.Font.SourceSansBold
SettingsToggleBtn.Text = "⚙️"
SettingsToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsToggleBtn.TextSize = 10

local SettingsCorner = Instance.new("UICorner")
SettingsCorner.CornerRadius = UDim.new(0, 4)
SettingsCorner.Parent = SettingsToggleBtn

-- 3. AYARLAR PENCERESİ
local SettingsFrame = Instance.new("Frame")
local SettingsUICorner = Instance.new("UICorner")
local AutoStartBtn = Instance.new("TextButton")
local AutoExecBtn = Instance.new("TextButton")
local ThemeBtn = Instance.new("TextButton")
local CloseScriptBtn = Instance.new("TextButton")

SettingsFrame.Name = "SettingsFrame"
SettingsFrame.Parent = ScreenGui
SettingsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SettingsFrame.BackgroundTransparency = 0.1
SettingsFrame.Position = UDim2.new(0, 225, 0.4, 0)
SettingsFrame.Size = UDim2.new(0, 160, 0, 160)
SettingsFrame.Visible = false

SettingsUICorner.CornerRadius = UDim.new(0, 8)
SettingsUICorner.Parent = SettingsFrame

-- Otomatik Başlatma Butonu
AutoStartBtn.Name = "AutoStartBtn"
AutoStartBtn.Parent = SettingsFrame
AutoStartBtn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
AutoStartBtn.Position = UDim2.new(0.05, 0, 0.08, 0)
AutoStartBtn.Size = UDim2.new(0.9, 0, 0.20, 0)
AutoStartBtn.Font = Enum.Font.SourceSansBold
AutoStartBtn.Text = "Oto Başla: KAPALI"
AutoStartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoStartBtn.TextSize = 10

local AutoStartCorner = Instance.new("UICorner")
AutoStartCorner.CornerRadius = UDim.new(0, 4)
AutoStartCorner.Parent = AutoStartBtn

-- Otomatik Yükleme (Auto Execute) Butonu
AutoExecBtn.Name = "AutoExecBtn"
AutoExecBtn.Parent = SettingsFrame
AutoExecBtn.BackgroundColor3 = getgenv().AutoReexecute and Color3.fromRGB(39, 174, 96) or Color3.fromRGB(192, 57, 43)
AutoExecBtn.Position = UDim2.new(0.05, 0, 0.31, 0)
AutoExecBtn.Size = UDim2.new(0.9, 0, 0.20, 0)
AutoExecBtn.Font = Enum.Font.SourceSansBold
AutoExecBtn.Text = getgenv().AutoReexecute and "Oto Yükleme: AÇIK" or "Oto Yükleme: KAPALI"
AutoExecBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoExecBtn.TextSize = 10

local AutoExecCorner = Instance.new("UICorner")
AutoExecCorner.CornerRadius = UDim.new(0, 4)
AutoExecCorner.Parent = AutoExecBtn

-- Tema Değiştirme Butonu
ThemeBtn.Name = "ThemeBtn"
ThemeBtn.Parent = SettingsFrame
ThemeBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
ThemeBtn.Position = UDim2.new(0.05, 0, 0.54, 0)
ThemeBtn.Size = UDim2.new(0.9, 0, 0.20, 0)
ThemeBtn.Font = Enum.Font.SourceSansBold
ThemeBtn.Text = "Tema: Varsayılan"
ThemeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ThemeBtn.TextSize = 10

local ThemeCorner = Instance.new("UICorner")
ThemeCorner.CornerRadius = UDim.new(0, 4)
ThemeCorner.Parent = ThemeBtn

-- SCRIPT'İ KAPAT BUTONU
CloseScriptBtn.Name = "CloseScriptBtn"
CloseScriptBtn.Parent = SettingsFrame
CloseScriptBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseScriptBtn.Position = UDim2.new(0.05, 0, 0.77, 0)
CloseScriptBtn.Size = UDim2.new(0.9, 0, 0.20, 0)
CloseScriptBtn.Font = Enum.Font.SourceSansBold
CloseScriptBtn.Text = "❌ Scripti Kapat"
CloseScriptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseScriptBtn.TextSize = 10

local CloseScriptCorner = Instance.new("UICorner")
CloseScriptCorner.CornerRadius = UDim.new(0, 4)
CloseScriptCorner.Parent = CloseScriptBtn

-- 4. KRONOMETRE MANTIĞI
local running = false
local startTime = 0
local elapsedTime = 0

local themes = {
    {name = "Varsayılan", color = Color3.fromRGB(46, 204, 113)},
    {name = "RGB Gökkuşağı", color = Color3.fromRGB(255, 255, 255)},
    {name = "Neon Mavi", color = Color3.fromRGB(0, 210, 255)},
    {name = "Karanlık Kırmızı", color = Color3.fromRGB(231, 76, 60)}
}

local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    local milliseconds = math.floor((seconds % 1) * 100)

    return string.format("%02d:%02d:%02d.%02d", hours, minutes, secs, milliseconds)
end

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
        end
    end
end

local function resetTimer()
    running = false
    elapsedTime = 0
    TimeText.Text = "00:00:00.00"
    playSound(SOUND_RESET, 0.6, 0.9)
    
    -- RGB Temasında Sıfırlanınca Renk Geçiş Kaydırması
    if themes[currentThemeIndex].name == "RGB Gökkuşağı" then
        rgbOffset = (rgbOffset + 0.33) % 1
    end
end

-- Tıklama Bağlantıları
ToggleBtn.MouseButton1Click:Connect(toggleTimer)
ResetBtn.MouseButton1Click:Connect(resetTimer)

ToggleIconButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    SettingsFrame.Visible = false
    playSound(SOUND_STOP, 0.3, 1)
end)

SettingsToggleBtn.MouseButton1Click:Connect(function()
    SettingsFrame.Visible = not SettingsFrame.Visible
    playSound(SOUND_STOP, 0.3, 1)
end)

-- Oto Başla Ayar Aç/Kapat
AutoStartBtn.MouseButton1Click:Connect(function()
    autoStartEnabled = not autoStartEnabled
    playSound(SOUND_STOP, 0.5, 1)
    if autoStartEnabled then
        AutoStartBtn.Text = "Oto Başla: AÇIK"
        AutoStartBtn.BackgroundColor3 = Color3.fromRGB(39, 174, 96)
    else
        AutoStartBtn.Text = "Oto Başla: KAPALI"
        AutoStartBtn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
    end
end)

-- Auto Execute (Oto Yükleme) Aç/Kapat
AutoExecBtn.MouseButton1Click:Connect(function()
    getgenv().AutoReexecute = not getgenv().AutoReexecute
    playSound(SOUND_STOP, 0.5, 1)
    if getgenv().AutoReexecute then
        AutoExecBtn.Text = "Oto Yükleme: AÇIK"
        AutoExecBtn.BackgroundColor3 = Color3.fromRGB(39, 174, 96)
    else
        AutoExecBtn.Text = "Oto Yükleme: KAPALI"
        AutoExecBtn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
    end
end)

-- Tema Ayar Değiştir
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
        ResetBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Varsayılan kırmızı
    end
end)

-- SCRIPT'I TAMAMEN KAPATMA VE TEMİZLEME
CloseScriptBtn.MouseButton1Click:Connect(function()
    playSound(SOUND_RESET, 0.5, 0.7)
    running = false
    
    -- Tüm event dinleyicilerini durdur
    for _, conn in ipairs(connections) do
        if conn then conn:Disconnect() end
    end
    if rgbConnection then rgbConnection:Disconnect() end
    
    ScreenGui:Destroy()
end)

-- Klavye Kontrolleri (PC - Başlat/Durdur Q Tuşu)
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

-- Karakter Hareketiyle Otomatik Başlatma (Mobil & PC)
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

-- ÖLÜNCE OTOMATİK SIFIRLAMA
local function setupDeathReset(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        local deathConn = humanoid.Died:Connect(function()
            resetTimer()
        end)
        table.insert(connections, deathConn)
    end
end

if LocalPlayer.Character then
    setupDeathReset(LocalPlayer.Character)
end

local charAddedConn = LocalPlayer.CharacterAdded:Connect(setupDeathReset)
table.insert(connections, charAddedConn)
