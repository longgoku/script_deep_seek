-- ==============================================================
-- [ BloxFruit-Delta.lua ]
-- Hack cho game Blox Fruit (Roblox), chạy trên Delta
-- Tính năng: Auto Farm, Auto Collect, Fly, Teleport, Speed, Jump
-- Tích hợp cơ chế hook để bypass key check (giống script BF-BananaCat)
-- ==============================================================

-- Kiểm tra môi trường Delta
if not (getrenv and getgenv) then
    warn("Script này chỉ chạy trên Delta hoặc executor hỗ trợ getrenv()")
end

-- 1. HOOK HỆ THỐNG (để bypass key check nếu script con yêu cầu)
local env = getrenv() or _G

-- Lưu hàm loadstring gốc
local old_loadstring = env.loadstring

-- Ghi đè loadstring để log và bypass key
env.loadstring = function(code, chunkname)
    if type(code) == "string" then
        -- Nếu phát hiện code yêu cầu key/license, ta thay thế
        if string.find(code:lower(), "key") or string.find(code:lower(), "license") then
            print("[Bypass] Phát hiện key check trong chunk:", chunkname or "?")
            -- Chèn một hàm giả trả về true
            code = "local function CheckLicense() return true end\n" .. code
            -- Hoặc thay thế trực tiếp điều kiện
            code = code:gsub("([%w_]+)%.%s*Key%s*==?%s*(.-)(%s*)then", function(a,b,c,d)
                return a .. "." .. b .. " = true " .. d .. " then"
            end)
        end
    end
    return old_loadstring(code, chunkname)
end

print("[BloxFruit] Đã hook loadstring thành công!")

-- 2. CÁC BIẾN TOÀN CỤC
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInput = game:GetService("VirtualInputManager")

-- Các trạng thái
local farmEnabled = false
local collectEnabled = false
local flyEnabled = false
local speedEnabled = false
local jumpEnabled = false
local currentIsland = nil

-- 3. HÀM LẤY NHÂN VẬT VÀ HUMANOLD
local function getCharacter()
    local char = LocalPlayer.Character
    if not char or not char.Parent then
        return nil, nil
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return char, hum
end

-- 4. AUTO FARM (đánh quái gần nhất)
local function autoFarm()
    if not farmEnabled then return end
    local char, hum = getCharacter()
    if not char or not hum then return end

    -- Tìm quái gần nhất (dùng Name chứa "NPC" hoặc "Mob")
    local nearest = nil
    local minDist = math.huge
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") then
            local name = v.Name:lower()
            if name:find("npc") or name:find("mob") or name:find("bandit") or name:find("pirate") then
                local dist = (v.PrimaryPart.Position - char.PrimaryPart.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = v
                end
            end
        end
    end

    if nearest then
        -- Di chuyển đến quái
        local targetPos = nearest.PrimaryPart.Position
        hum:MoveTo(targetPos)

        -- Tấn công (giả lập click chuột)
        VirtualInput:SendMouseButtonEvent(1, 0, 0, true, game, 1)
        wait(0.1)
        VirtualInput:SendMouseButtonEvent(1, 0, 0, false, game, 1)
    end
end

-- 5. AUTO COLLECT FRUIT (tìm fruit trên ground)
local function autoCollect()
    if not collectEnabled then return end
    local char, hum = getCharacter()
    if not char or not hum then return end

    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Tool") and v:FindFirstChild("Handle") then
            -- Nếu tên chứa "Fruit" hoặc "Devil"
            local name = v.Name:lower()
            if name:find("fruit") or name:find("devil") then
                local dist = (v.Handle.Position - char.PrimaryPart.Position).Magnitude
                if dist < 20 then -- trong tầm
                    hum:MoveTo(v.Handle.Position)
                    wait(0.5)
                    -- Click để nhặt
                    VirtualInput:SendMouseButtonEvent(1, 0, 0, true, game, 1)
                    wait(0.1)
                    VirtualInput:SendMouseButtonEvent(1, 0, 0, false, game, 1)
                end
            end
        end
    end
end

-- 6. FLY (sử dụng BodyVelocity)
local flyBody = nil
local flyEnabled = false

local function toggleFly()
    local char, hum = getCharacter()
    if not char then return end
    flyEnabled = not flyEnabled

    if flyEnabled then
        flyBody = Instance.new("BodyVelocity")
        flyBody.Velocity = Vector3.new(0, 0, 0)
        flyBody.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        flyBody.Parent = char.PrimaryPart
        -- Cập nhật hướng bay theo hướng nhân vật
        RunService.Heartbeat:Connect(function()
            if flyEnabled and char and char.PrimaryPart then
                local dir = char.PrimaryPart.CFrame.LookVector
                flyBody.Velocity = dir * 50
                -- Giữ độ cao (nếu không nhấn shift)
                if not (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)) then
                    flyBody.Velocity = flyBody.Velocity + Vector3.new(0, 10, 0)
                end
            end
        end)
    else
        if flyBody then flyBody:Destroy() end
    end
end

-- 7. TĂNG TỐC ĐỘ
local function setSpeed(val)
    local _, hum = getCharacter()
    if hum then
        hum.WalkSpeed = val
    end
end

-- 8. NHẢY CAO
local function setJump(val)
    local _, hum = getCharacter()
    if hum then
        hum.JumpPower = val
    end
end

-- 9. TELEPORT ĐẾN ĐẢO (dựa vào tên)
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
    local target = nil
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Model") and v.Name:find(islandName) then
            target = v
            break
        end
    end
    if target and target.PrimaryPart then
        local char, hum = getCharacter()
        if char then
            char.PrimaryPart.CFrame = target.PrimaryPart.CFrame + Vector3.new(0, 10, 0)
        end
    end
end

-- 10. TẠO GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BloxFruitHack"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 380, 0, 500)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BackgroundTransparency = 0
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(0, 200, 255)
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Tiêu đề
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.Text = "Blox Fruit Hack [Delta]"
title.TextColor3 = Color3.fromRGB(0, 200, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = mainFrame

-- Hàm tạo nút với label
local function createButton(text, position, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.8, 0, 0, 35)
    btn.Position = UDim2.new(0.1, 0, position, 0)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    btn.BorderSizePixel = 1
    btn.BorderColor3 = Color3.fromRGB(0, 200, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 16
    btn.Parent = mainFrame
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Nút Auto Farm
local farmBtn = createButton("Auto Farm (ON/OFF)", 0.12, function()
    farmEnabled = not farmEnabled
    farmBtn.Text = farmEnabled and "Auto Farm (ON)" or "Auto Farm (OFF)"
    farmBtn.BackgroundColor3 = farmEnabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
end)

-- Nút Auto Collect
local collectBtn = createButton("Auto Collect Fruit", 0.25, function()
    collectEnabled = not collectEnabled
    collectBtn.Text = collectEnabled and "Auto Collect (ON)" or "Auto Collect (OFF)"
    collectBtn.BackgroundColor3 = collectEnabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
end)

-- Nút Fly
local flyBtn = createButton("Fly (Shift để lên)", 0.38, function()
    toggleFly()
    flyBtn.Text = flyEnabled and "Fly (ON)" or "Fly (OFF)"
    flyBtn.BackgroundColor3 = flyEnabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
end)

-- Nút Speed (tăng tốc)
local speedBtn = createButton("Speed Boost (x2)", 0.51, function()
    speedEnabled = not speedEnabled
    if speedEnabled then
        setSpeed(50)
        speedBtn.Text = "Speed Boost (ON)"
        speedBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    else
        setSpeed(16)
        speedBtn.Text = "Speed Boost (OFF)"
        speedBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    end
end)

-- Nút Jump (nhảy cao)
local jumpBtn = createButton("Super Jump", 0.64, function()
    jumpEnabled = not jumpEnabled
    if jumpEnabled then
        setJump(500)
        jumpBtn.Text = "Super Jump (ON)"
        jumpBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    else
        setJump(50)
        jumpBtn.Text = "Super Jump (OFF)"
        jumpBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    end
end)

-- Nút Teleport đến các đảo (drop-down)
local teleportBtn = createButton("Teleport to Island", 0.77, function()
    -- Tạo một menu phụ (đơn giản: chọn từ danh sách)
    local subFrame = Instance.new("Frame")
    subFrame.Size = UDim2.new(0.6, 0, 0, 100)
    subFrame.Position = UDim2.new(0.2, 0, 0.85, 0)
    subFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    subFrame.BorderSizePixel = 1
    subFrame.BorderColor3 = Color3.fromRGB(0, 200, 255)
    subFrame.Parent = mainFrame

    for i, name in ipairs(islands) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 25)
        btn.Position = UDim2.new(0, 0, (i-1)*0.25, 0)
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.Parent = subFrame
        btn.MouseButton1Click:Connect(function()
            teleportTo(name)
            subFrame:Destroy()
        end)
    end
    -- Xóa subFrame khi click ra ngoài
    local function closeSub()
        if subFrame then subFrame:Destroy() end
    end
    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            closeSub()
        end
    end)
end)

-- 11. CÁC VÒNG LẶP TỰ ĐỘNG CHẠY TRONG NỀN
RunService.Heartbeat:Connect(function()
    if farmEnabled then autoFarm() end
    if collectEnabled then autoCollect() end
end)

-- 12. KEY BIND (F9 để bật/tắt farm, F10 để fly)
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F9 then
        farmBtn:Fire("MouseButton1Click")
    elseif input.KeyCode == Enum.KeyCode.F10 then
        flyBtn:Fire("MouseButton1Click")
    end
end)

-- 13. KHỞI TẠO BAN ĐẦU
print("[BloxFruit] Script đã load thành công! Mở GUI để sử dụng.")
print("[BloxFruit] Phím tắt: F9 (Farm), F10 (Fly)")
