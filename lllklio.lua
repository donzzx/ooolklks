local KavoLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()

-- Настройки
getgenv().Config = {
    SilentAim = false,
    AimBots = false,
    Fov = 150,
    MaxDistance = 500,
    WallCheck = false,
    EspPlayers = false,
    EspBots = false
}

-- Создание окна (Тема: Bloods - красно-черная)
local Window = KavoLib.CreateLib("Project Delta | Kavo Edition", "BloodTheme")

-- ВКЛАДКА АИМА
local AimTab = Window:NewTab("Silent Aim")
local AimSection = AimTab:NewSection("Настройки Аима")

AimSection:NewToggle("Аим на Игроков", "Включает сайлент аим на людей", function(v)
    getgenv().Config.SilentAim = v
end)

AimSection:NewToggle("Аим на Ботов (NPC)", "Включает аим на зомби/ботов", function(v)
    getgenv().Config.AimBots = v
end)

AimSection:NewSlider("FOV Radius", "Радиус круга на экране", 800, 10, function(v)
    getgenv().Config.Fov = v
end)

AimSection:NewSlider("Max Distance", "Дальность работы (в студах)", 2000, 50, function(v)
    getgenv().Config.MaxDistance = v
end)

AimSection:NewToggle("Wall Check", "Не стрелять через стены", function(v)
    getgenv().Config.WallCheck = v
end)

-- ВКЛАДКА ВИЗУАЛОВ
local VisualsTab = Window:NewTab("Visuals")
local VisualsSection = VisualsTab:NewSection("ESP Настройки")

VisualsSection:NewToggle("ESP Игроки", "Подсветка игроков", function(v)
    getgenv().Config.EspPlayers = v
end)

VisualsSection:NewToggle("ESP Боты", "Подсветка ботов", function(v)
    getgenv().Config.EspBots = v
end)

---------------------------------------------------------
-- ЛОГИКА (АИМ + ЕСП)
---------------------------------------------------------

local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = Player:GetMouse()

-- Функция поиска цели
local function GetAimTarget()
    local closest = nil
    local shortestMouseDist = getgenv().Config.Fov
    
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") then
            local isBot = not game.Players:GetPlayerFromCharacter(v)
            local isPlayer = game.Players:GetPlayerFromCharacter(v) and v ~= Player.Character
            
            local canAim = (isPlayer and getgenv().Config.SilentAim) or (isBot and getgenv().Config.AimBots)
            
            if canAim then
                local hrp = v.HumanoidRootPart
                local dist = (Player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                
                if dist <= getgenv().Config.MaxDistance then
                    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local mouseDist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                        if mouseDist < shortestMouseDist then
                            -- Проверка видимости
                            local isVisible = true
                            if getgenv().Config.WallCheck then
                                local parts = Camera:GetPartsObscuringTarget({hrp.Position}, {Player.Character, v})
                                isVisible = (#parts == 0)
                            end
                            
                            if isVisible then
                                closest = hrp
                                shortestMouseDist = mouseDist
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

-- Хук выстрела
local old; old = hookmetamethod(game, "__index", function(self, key)
    if self == Mouse and key == "Hit" and (getgenv().Config.SilentAim or getgenv().Config.AimBots) then
        local t = GetAimTarget()
        if t then return t.CFrame end
    end
    return old(self, key)
end)

-- ESP через Highlight (Самый стабильный метод)
task.spawn(function()
    while task.wait(0.5) do
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") then
                local isBot = not game.Players:GetPlayerFromCharacter(v)
                local isPlayer = game.Players:GetPlayerFromCharacter(v) and v ~= Player.Character
                
                local shouldShow = (isPlayer and getgenv().Config.EspPlayers) or (isBot and getgenv().Config.EspBots)
                
                if shouldShow then
                    if not v:FindFirstChild("EspHighlight") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "EspHighlight"
                        hl.Parent = v
                        hl.FillTransparency = 0.5
                        hl.OutlineTransparency = 0
                        hl.FillColor = isPlayer and Color3.new(1,0,0) or Color3.new(0,1,0)
                    end
                else
                    if v:FindFirstChild("EspHighlight") then
                        v.EspHighlight:Destroy()
                    end
                end
            end
        end
    end
end)
