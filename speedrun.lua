-- Eski GUI varsa temizleyelim
if game.CoreGui:FindFirstChild("SpeedrunTimerGui") then
    game.CoreGui.SpeedrunTimerGui:Destroy()
end

local UserInputService = game:GetService("UserInputService")

-- ScreenGui Oluşturma
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpeedrunTimerGui"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- 1. SIMGESEL AÇMA/KAPAMA BUTONU ("S")
local ToggleIconButton = Instance.new("TextButton")
local IconCorner = Instance.new("UICorner")
local IconStroke = Instance.new("UIStroke")

ToggleIconButton.Name = "ToggleIconButton"
ToggleIconButton.Parent = ScreenGui
ToggleIconButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ToggleIconButton.BackgroundTransparency = 0.2
ToggleIconButton.Position = UDim2.new(0, 15, 0.3, 0) -- Başlangıç konumu
ToggleIconButton.Size = UDim2.new(0, 45, 0, 45)
ToggleIconButton.Font = Enum.Font.SourceSansBold
ToggleIconButton.Text = "S"
ToggleIconButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleIconButton.TextSize = 26
ToggleIconButton.Active = true
ToggleIconButton.Draggable = true -- Simgemizi istediğin yere sürükleyebilirsin

IconCorner.CornerRadius = UDim.new(1, 0) -- Tam yuvarlak yapar
IconCorner.Parent = ToggleIconButton

IconStroke.Color = Color3.fromRGB(46, 204, 113) -- Yeşil kenarlık
IconStroke.Thickness = 2
IconStroke.Parent = ToggleIconButton

-- 2. KRONOMETRE PANELLİ ANA ÇERÇEVE
local MainFrame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local TimeText = Instance.new("TextLabel")
local ToggleBtn = Instance.new("TextButton")
local ResetBtn = Instance.new("TextButton")
local ToggleCorner = Instance.new("UICorner")
local ResetCorner = Instance.new("UICorner")

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.35
MainFrame.Position = UDim2.new(0, 15, 0.4, 0)
MainFrame.Size = UDim2.new(0, 180, 0, 80)
MainFrame.Active = true
MainFrame.Draggable = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Süre Göstergesi (00:00:00.00)
TimeText.Name = "TimeText"
TimeText.Parent = MainFrame
TimeText.BackgroundTransparency = 1
TimeText.Position = UDim2.new(0, 0, 0, 6)
TimeText.Size = UDim2.new(1, 0, 0, 32)
TimeText.Font = Enum.Font.SourceSansBold
TimeText.Text = "00:00:00.00"
TimeText.TextColor3 = Color3.fromRGB(255, 255, 255)
TimeText.TextSize = 22
TimeText.TextScaled = true

-- BAŞLAT / DURDUR Butonu
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Parent = MainFrame
ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.58, 0)
ToggleBtn.Size = UDim2.new(0.58, 0, 0.32, 0)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.Text = "BAŞLAT / DURDUR"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 10

ToggleCorner.CornerRadius = UDim.new(0, 4)
ToggleCorner.Parent = ToggleBtn

-- SIFIRLA Butonu
ResetBtn.Name = "ResetBtn"
ResetBtn.Parent = MainFrame
ResetBtn.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
ResetBtn.Position = UDim2.new(0.67, 0, 0.58, 0)
ResetBtn.Size = UDim2.new(0.28, 0, 0.32, 0)
ResetBtn.Font = Enum.Font.SourceSansBold
ResetBtn.Text = "SIFIRLA"
ResetBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
ResetBtn.TextSize = 10

ResetCorner.CornerRadius = UDim.new(0, 4)
ResetCorner.Parent = ResetBtn

-- 3. MANTIK VE SÜRE HESAPLAMA
local running = false
local startTime = 0
local elapsedTime = 0

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
        
        task.spawn(function()
            while running do
                elapsedTime = os.clock() - startTime
                TimeText.Text = formatTime(elapsedTime)
                task.wait(0.03)
            end
        end)
    else
        running = false
    end
end

local function resetTimer()
    running = false
    elapsedTime = 0
    TimeText.Text = "00:00:00.00"
end

-- Buton Bağlantıları
ToggleBtn.MouseButton1Click:Connect(toggleTimer)
ResetBtn.MouseButton1Click:Connect(resetTimer)

-- "S" Simgesine Tıklayınca Açma / Kapama İşlevi
ToggleIconButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Klavye (PC) Tuş Kontrolleri (Space ve R)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Space then
        toggleTimer()
    elseif input.KeyCode == Enum.KeyCode.R then
        resetTimer()
    end
end)