-- Abdee v1.0 | Universal FPS Hub
-- Feature: Raycast Wall Check, Smooth Camera Transition, Dynamic FOV Check

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Abdee v1.0 | Universal FPS Hub",
    LoadingTitle = "Initializing Systems...",
    LoadingSubtitle = "by Abdee v1.0",
    ConfigurationSaving = { Enabled = false }
})

-- TABS
local TabCombat = Window:CreateTab("Combat (Aimbot)", nil)
local TabVisual = Window:CreateTab("Visuals (ESP)", nil)

-- SERVICES
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- CONFIG STATES
_G.AimbotEnabled = false
_G.WallCheck = true
_G.AimPart = "Head"
_G.TeamCheck = true
_G.Smoothness = 0.25 -- Nilai transisi kamera (semakin kecil semakin smooth, 1 = instan nempel)
_G.FOVRadius = 150 -- Jarak maksimal radius deteksi target dari tengah layar

_G.ChamsEnabled = false

local AimConnection
local FOVCircle = Drawing.new("Circle")

-- Setup Visual FOV Radius
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Color = Color3.fromRGB(255, 0, 0)
FOVCircle.Thickness = 1
FOVCircle.Filled = false
FOVCircle.Visible = false

-- Update FOV Center Position when Screen Resizes
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end)

-- ==========================================
-- UTILITY FUNCTIONS
-- ==========================================

-- Check Wall Obstruction (Raycasting)
local function isVisible(targetPart)
    if not _G.WallCheck then return true end
    if not targetPart then return false end
    
    local origin = Camera.CFrame.Position
    local destination = targetPart.Position
    local direction = destination - origin
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    raycastParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    
    if result then
        if result.Instance:IsDescendantOf(targetPart.Parent) then
            return true
        end
        return false
    end
    return true
end

-- Get Closest Target within FOV Constraint
local function getClosestTarget()
    local closest = nil
    local shortestDistance = _G.FOVRadius -- Target harus di dalam batas radius ini
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            
            if _G.TeamCheck and p.Team == LocalPlayer.Team then
                continue
            end
            
            local targetPart = p.Character:FindFirstChild(_G.AimPart)
            if targetPart and isVisible(targetPart) then
                local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    local distance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    
                    if distance < shortestDistance then
                        closest = targetPart
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    return closest
end

-- ==========================================
-- TAB 1: COMBAT (AIMBOT SYSTEM)
-- ==========================================

TabCombat:CreateToggle({
    Name = "Enable Aimbot System",
    CurrentValue = false,
    Callback = function(Value)
        _G.AimbotEnabled = Value
        if _G.AimbotEnabled then
            AimConnection = RunService.RenderStepped:Connect(function()
                if not _G.AimbotEnabled then 
                    if AimConnection then AimConnection:Disconnect() end 
                    return 
                end
                
                local target = getClosestTarget()
                if target then
                    -- Menggunakan CFrame:Lerp untuk transisi perpindahan kamera yang mulus ke target (Easy Camera)
                    local targetLook = CFrame.new(Camera.CFrame.Position, target.Position)
                    Camera.CFrame = Camera.CFrame:Lerp(targetLook, _G.Smoothness)
                end
            end)
        else
            if AimConnection then
                AimConnection:Disconnect()
                AimConnection = nil
            end
        end
    end
})

TabCombat:CreateSlider({
    Name = "Camera Smoothness (Easy Camera)",
    Range = {5, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 25,
    Callback = function(Value)
        -- Mengubah persentase slider menjadi pecahan decimal untuk Lerp factor
        _G.Smoothness = Value / 100
    end
})

TabCombat:CreateToggle({
    Name = "Show FOV Radius Circle",
    CurrentValue = false,
    Callback = function(Value)
        FOVCircle.Visible = Value
    end
})

TabCombat:CreateSlider({
    Name = "FOV Radius Size",
    Range = {50, 500},
    Increment = 10,
    Suffix = "px",
    CurrentValue = 150,
    Callback = function(Value)
        _G.FOVRadius = Value
        FOVCircle.Radius = Value
    end
})

TabCombat:CreateToggle({
    Name = "Wall Check (Raycast)",
    CurrentValue = true,
    Callback = function(Value)
        _G.WallCheck = Value
    end
})

TabCombat:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Callback = function(Value)
        _G.TeamCheck = Value
    end
})

TabCombat:CreateDropdown({
    Name = "Target Hitbox Location",
    Options = {"Head", "HumanoidRootPart"},
    CurrentOption = "Head",
    MultipleOptions = false,
    Callback = function(Option)
        _G.AimPart = Option
    end
})

-- ==========================================
-- TAB 2: VISUALS (ESP SYSTEM)
-- ==========================================

TabVisual:CreateToggle({
    Name = "Player Chams (Wallhack)",
    CurrentValue = false,
    Callback = function(Value)
        _G.ChamsEnabled = Value
        task.spawn(function()
            while _G.ChamsEnabled do
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local h = p.Character:FindFirstChild("UniversalHighlight") or Instance.new("Highlight")
                        h.Name = "UniversalHighlight"
                        h.Parent = p.Character
                        h.Enabled = true
                        
                        if p.Team == LocalPlayer.Team then
                            h.FillColor = Color3.fromRGB(0, 255, 100)
                        else
                            h.FillColor = Color3.fromRGB(255, 50, 50)
                        end
                        h.OutlineColor = Color3.fromRGB(255, 255, 255)
                    end
                end
                task.wait(1)
            end
            if not _G.ChamsEnabled then
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Character and p.Character:FindFirstChild("UniversalHighlight") then
                        p.Character.UniversalHighlight.Enabled = false
                    end
                end
            end
        end)
    end
})

Rayfield:Load()
