local KavoLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()

getgenv().Config = {
    SilentAim = false,
    AimBots = false,
    Fov = 150,
    MaxDistance = 500,
    WallCheck = false,
    EspPlayers = false,
    EspBots = false
}

local Window = KavoLib.CreateLib("Project Delta | Fixed", "BloodTheme")

-- ВКЛАДКА АИМА
local AimTab = Window:NewTab("Silent Aim")
local AimSection = AimTab:NewSection("Настройки Аима")

AimSection:NewToggle("Аим на Игроков", "", function(v) getgenv().Config.SilentAim = v end)
AimSection:NewToggle("Аим на Ботов", "", function(v) getgenv().Config.AimBots = v end)

-- Слайдеры с фиксом (теперь должны двигаться)
AimSection:NewSlider("FOV Radius", "Радиус", 800, 10, function(v)
    getgenv().Config.Fov = v
end)

AimSection:NewSlider("Max Distance", "Дальность", 2000, 50, function(v)
    getgenv().Config.MaxDistance = v
end)

AimSection:NewToggle("Wall Check", "", function(v) getgenv().Config.WallCheck = v end)

-- ВКЛАДКА ВИЗУАЛОВ
local VisualsTab = Window:NewTab("Visuals")
local VisualsSection = VisualsTab:NewSection("ESP (Рамки через стены)")

VisualsSection:NewToggle("ESP Игроки", "", function(v) getgenv().Config.EspPlayers = v end)
VisualsSection:NewToggle("ESP Боты", "", function(v) getgenv().Config.EspBots = v end)

---------------------------------------------------------
-- ЛОГИКА
---------------------------------------------------------
local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = Player:GetMouse()

local function GetTarget()
    local closest = nil
    local shortestMouseDist = getgenv().Config.Fov
    
    -- Ищем во всем мире
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") then
            if v.Humanoid.Health > 0 then
                local isBot = not game.Players:GetPlayerFromCharacter(v)
                local isPlr = game.Players:GetPlayerFromCharacter(v) and v ~= Player.Character
                
                if (isPlr and getgenv().Config.SilentAim) or (isBot and getgenv().Config.AimBots) then
                    local hrp = v.HumanoidRootPart
                    local dist = (Player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                    
                    if dist <= getgenv().Config.MaxDistance then
                        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            local mouseDist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                            if mouseDist < shortestMouseDist then
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

-- Silent Aim Hook
local old; old = hookmetamethod(game, "__index", function(self, key)
    if self == Mouse and key == "Hit" and (getgenv().Config.SilentAim or getgenv().Config.AimBots) then
        local t = GetTarget()
        if t then return t.CFrame end
    end
    return old(self, key)
end)

-- ESP ЛОГИКА (2D BOXES)
task.spawn(function()
    while task.wait(0.5) do
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") then
                local isBot = not game.Players:GetPlayerFromCharacter(v)
                local isPlr = game.Players:GetPlayerFromCharacter(v) and v ~= Player.Character
                
                local shouldShow = (isPlr and getgenv().Config.EspPlayers) or (isBot and getgenv().Config.EspBots)
                
                if shouldShow and v.Humanoid.Health > 0 then
                    local hrp = v.HumanoidRootPart
                    local folder = hrp:FindFirstChild("EspFolder") or Instance.new("Folder", hrp)
                    folder.Name = "EspFolder"
                    
                    local gui = folder:FindFirstChild("BoxGui") or Instance.new("BillboardGui", folder)
                    gui.Name = "BoxGui"
                    gui.AlwaysOnTop = true
                    gui.Size = UDim2.new(4, 0, 5.5, 0)
                    gui.Adornee = v
                    
                    local box = gui:FindFirstChild("Frame") or Instance.new("Frame", gui)
                    box.Name = "Frame"
                    box.Size = UDim2.new(1, 0, 1, 0)
                    box.BackgroundTransparency = 1
                    box.BorderSizePixel = 2
                    box.BorderColor3 = isPlr and Color3.new(1,0,0) or Color3.new(0,1,0)
                else
                    if v.HumanoidRootPart:FindFirstChild("EspFolder") then
                        v.HumanoidRootPart.EspFolder:Destroy()
                    end
                end
            end
        end
    end
end)
