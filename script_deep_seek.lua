-- ==============================================================
-- [ BloxFruit-Delta-Mobile.lua ]
-- Hack Blox Fruit tối ưu cho Delta trên điện thoại
-- Tính năng: Auto Farm, Auto Collect, Fly, Teleport, Speed, Jump
-- Menu dạng nút to, dễ bấm
-- ==============================================================

-- Khởi tạo môi trường
local env = getrenv() or _G
local old_loadstring = env.loadstring
env.loadstring = function(code, chunkname)
    if type(code) == "string" and (string.find(code:lower(), "key") or string.find(code:lower(), "license")) then
        code = "local function CheckLicense() return true end\n" .. code
        code = code:gsub("([%w_]+)%.%s*Key%s*==?%s*(.-)(%s*)then", function(a,b,c,d)
            return a .. "." .. b .. " = true " .. d .. " then"
        end)
    end
    return old_loadstring(code, chunkname)
end

-- Các service
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualInput = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- Trạng thái
local farmEnabled = false
local collectEnabled = false
local flyEnabled = false
local speedEnabled = false
local jumpEnabled = false

-- Hàm lấy nhân vật và humanoid
local function getCharHum()
    local char = LocalPlayer.Character
    if not char or not char.Parent then return nil, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return char, hum
end

-- Hàm tìm quái gần nhất (chỉ tìm những model có chứa Humanoid và không phải người chơi)
local function getNearestMob()
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return nil end
    local pos = char.PrimaryPart.Position
    local nearest = nil
    local minDist = math.huge
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Model") and v ~= char and v:FindFirstChildOfClass("Humanoid") then
            -- Loại bỏ người chơi (dùng tên hoặc attribute)
            if not Players:GetPlayerFromCharacter(v) then
                local part = v.PrimaryPart or v:FindFirstChild("Head") or v:FindFirstChild("Torso")
                if part then
                    local dist = (part.Position - pos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        nearest = v
                    end
                end
            end
        end
    end
    return nearest, minDist
end

-- Auto Farm
local function autoFarm()
    if not farmEnabled then return end
    local char, hum = getCharHum()
    if not char or not hum then return end
    local mob, dist = getNearestMob()
    if mob and dist < 200 then
        local targetPart = mob.PrimaryPart or mob:FindFirstChild("Head") or mob:FindFirstChild("Torso")
        if targetPart then
            hum:MoveTo(targetPart.Position)
            -- Tấn công (simulate click)
            VirtualInput:SendMouseButtonEvent(1, 0, 0, true, game, 1)
            wait(0.1)
            VirtualInput:SendMouseButtonEvent(1, 0, 0, false, game, 1)
        end
    else
        -- Nếu không có quái gần, di chuyển ngẫu nhiên hoặc dừng
        hum:MoveTo(Vector3.new(0, 0, 0)) -- tạm thời
    end
end

-- Auto Collect (tìm fruit tool)
local function autoCollect()
    if not collectEnabled then return end
    local char, hum = getCharHum()
    if not char or not hum then return end
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Tool") and v:FindFirstChild("Handle") then
            if string.find(v.Name:lower(), "fruit") or string.find(v.Name:lower(), "devil") then
                local dist = (v.Handle.Position - char.PrimaryPart.Position).Magnitude
                if dist < 25 then
                    hum:MoveTo(v.Handle.Position)
                    wait(0.3)
                    VirtualInput:SendMouseButtonEvent(1, 0, 0, true, game, 1)
                    wait(0.1)
                    VirtualInput:SendMouseButtonEvent(1, 0, 0, false, game, 1)
                end
            end
        end
    end
end

-- Fly
local flyBody = nil
local function toggleFly()
    local char, hum = getCharHum()
    if not char then return end
    flyEnabled = not flyEnabled
    if flyEnabled then
        flyBody = Instance.new("BodyVelocity")
        flyBody.Velocity = Vector3.new(0, 0, 0)
        flyBody.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        flyBody.Parent = char.PrimaryPart
        RunService.Heartbeat:Connect(function()
            if flyEnabled and char and char.PrimaryPart and flyBody then
                local dir = char.PrimaryPart.CFrame.LookVector
                local speed = 50
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    flyBody.Velocity = dir * speed + Vector3.new(0, 20, 0)
                else
                    flyBody.Velocity = dir * speed
                end
            end
        end)
    else
        if flyBody then flyBody:Destroy() end
    end
end

-- Speed & Jump
local function setSpeed(val)
    local _, hum = getCharHum()
    if hum then hum.WalkSpeed = val end
end
local function setJump(val)
    local _, hum = getCharHum()
    if hum then hum.JumpPower = val end
end

-- Teleport đảo (tìm model theo tên)
local islands = {
    "Jungle",
    "Pirate Village",
    "Marine Fortress",
    "Sky Island",
    "Ice Island",
    "Volcano Island",
    "Dressrosa"
}
local function teleportTo(islandName)
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Model") and string.find(v.Name:lower(), islandName:lower()) then
            local part = v.PrimaryPart or v:FindFirstChild("Head") or v:FindFirstChild("Torso")
            if part then
                local char, hum = getCharHum()
                if char and char.PrimaryPart then
                    char.PrimaryPart.CFrame = part.CFrame + Vector3.new(0, 5, 0)
                    break
                end
            end
        end
    end
end

-- TẠO GUI CHO ĐIỆN THOẠI (nút to, cách xa)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BloxFruitMobile"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 420)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 200, 0)
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "⚡BLOX FRUIT MOBILE⚡"
title.TextColor3 = Color3.fromRGB(255, 200, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = mainFrame

-- Hàm tạo nút (to, dễ bấm)
local function createBigButton(text, yPos, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85, 0, 0, 45)
    btn.Position = UDim2.new(0.075, 0, yPos, 0)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 70)
    btn.BorderSizePixel = 1
    btn.BorderColor3 = Color3.fromRGB(255, 200, 0)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18
    btn.Parent = mainFrame
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Nút Auto Farm
local farmBtn = createBigButton("🤖 Auto Farm (OFF)", 0.12, Color3.fromRGB(200, 50, 50), function()
    farmEnabled = not farmEnabled
    farmBtn.Text = farmEnabled and "🤖 Auto Farm (ON)" or "🤖 Auto Farm (OFF)"
    farmBtn.BackgroundColor3 = farmEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

-- Auto Collect
local collectBtn = createBigButton("🍎 Auto Collect (OFF)", 0.26, Color3.fromRGB(200, 50, 50), function()
    collectEnabled = not collectEnabled
    collectBtn.Text = collectEnabled and "🍎 Auto Collect (ON)" or "🍎 Auto Collect (OFF)"
    collectBtn.BackgroundColor3 = collectEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

-- Fly
local flyBtn = createBigButton("✈️ Fly (OFF)", 0.40, Color3.fromRGB(200, 50, 50), function()
    toggleFly()
    flyBtn.Text = flyEnabled and "✈️ Fly (ON)" or "✈️ Fly (OFF)"
    flyBtn.BackgroundColor3 = flyEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

-- Speed
local speedBtn = createBigButton("💨 Speed x2 (OFF)", 0.54, Color3.fromRGB(200, 50, 50), function()
    speedEnabled = not speedEnabled
    if speedEnabled then setSpeed(50) else setSpeed(16) end
    speedBtn.Text = speedEnabled and "💨 Speed x2 (ON)" or "💨 Speed x2 (OFF)"
    speedBtn.BackgroundColor3 = speedEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

-- Super Jump
local jumpBtn = createBigButton("🦘 Super Jump (OFF)", 0.68, Color3.fromRGB(200, 50, 50), function()
    jumpEnabled = not jumpEnabled
    if jumpEnabled then setJump(500) else setJump(50) end
    jumpBtn.Text = jumpEnabled and "🦘 Super Jump (ON)" or "🦘 Super Jump (OFF)"
    jumpBtn.BackgroundColor3 = jumpEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

-- Teleport (chọn đảo)
local teleBtn = createBigButton("🗺️ Teleport (chọn đảo)", 0.82, Color3.fromRGB(30, 30, 50), function()
    -- Tạo sub-menu chọn đảo
    local subFrame = Instance.new("Frame")
    subFrame.Size = UDim2.new(0.8, 0, 0, 200)
    subFrame.Position = UDim2.new(0.1, 0, 0.9, 0)
    subFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    subFrame.BorderSizePixel = 1
    subFrame.BorderColor3 = Color3.fromRGB(255, 200, 0)
    subFrame.Parent = mainFrame

    for i, name in ipairs(islands) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.Position = UDim2.new(0, 0, (i-1)*0.2, 0)
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16
        btn.Parent = subFrame
        btn.MouseButton1Click:Connect(function()
            teleportTo(name)
            subFrame:Destroy()
        end)
    end
    -- Tự xóa khi bấm ra ngoài
    local function onTouchEnded()
        if subFrame then subFrame:Destroy() end
    end
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            onTouchEnded()
        end
    end)
end)

-- Chạy vòng lặp auto
RunService.Heartbeat:Connect(function()
    if farmEnabled then autoFarm() end
    if collectEnabled then autoCollect() end
end)

-- Key bind (cho máy tính nếu có)
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F9 then
        farmBtn:Fire("MouseButton1Click")
    elseif input.KeyCode == Enum.KeyCode.F10 then
        flyBtn:Fire("MouseButton1Click")
    end
end)

print("[BloxFruit] Script đã load! GUI dành cho điện thoại.")
