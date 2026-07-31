-- =============================================
-- BLOX FRUIT AUTO FARM + FAST ATTACK (Mobile)
-- Dùng RemoteEvent để tấn công, không cần click chuột
-- Bấm F9 để bật/tắt
-- =============================================

local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")

-- ===== CẤU HÌNH =====
local ATTACK_INTERVAL = 0.12    -- tốc độ đánh (giây)
local SEARCH_RADIUS = 40        -- bán kính tìm quái
local AUTO_FARM = false         -- trạng thái

-- ===== TÌM REMOTE TẤN CÔNG =====
-- Tìm remote event dùng để tấn công trong game
local remoteAttack = nil
local attackEvent = nil

-- Danh sách remote thường gặp
local remotes = {
    game:GetService("ReplicatedStorage"):FindFirstChild("Attack"),
    game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvent"),
    game:GetService("ReplicatedStorage"):FindFirstChild("Combat"),
    -- Tìm trong ReplicatedStorage, Workspace, PlayerScripts
}

for _, r in pairs(remotes) do
    if r and r:IsA("RemoteEvent") then
        attackEvent = r
        break
    end
end

-- Nếu không tìm thấy, thử dùng cách gửi Click thông qua mạng (dành cho Delta)
if not attackEvent then
    -- Tìm trong các Folder
    for _, folder in pairs(game:GetService("ReplicatedStorage"):GetChildren()) do
        if folder:IsA("Folder") then
            for _, child in pairs(folder:GetChildren()) do
                if child:IsA("RemoteEvent") and (child.Name:lower():find("attack") or child.Name:lower():find("click")) then
                    attackEvent = child
                    break
                end
            end
        end
    end
end

-- ===== HÀM TẤN CÔNG =====
local function doAttack()
    if attackEvent then
        -- Gửi RemoteEvent để tấn công
        attackEvent:FireServer()
    else
        -- Fallback: gửi sự kiện Click (dùng Input) – có thể không hiệu quả
        if game:GetService("VirtualInputManager") then
            local vim = game:GetService("VirtualInputManager")
            vim:SendMouseButtonEvent(1, 0, 0, true, game, 1)
            task.wait(0.05)
            vim:SendMouseButtonEvent(1, 0, 0, false, game, 1)
        end
    end
end

-- ===== TÌM QUÁI GẦN NHẤT =====
local function getNearestEnemy()
    local char = player.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local best = nil
    local bestDist = SEARCH_RADIUS

    -- Danh sách tên quái thường gặp (mở rộng nếu cần)
    local enemyKeywords = {"NPC", "Mob", "Bandit", "Pirate", "Soldier", "Shark", "Dragon", "Monkey", "Zombie", "Skeleton", "Ghost"}

    for _, obj in pairs(game.Workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
            local hum = obj:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                -- Bỏ qua player và người chơi khác
                if obj.Name ~= player.Name and not game.Players:FindFirstChild(obj.Name) then
                    -- Kiểm tra tên có chứa từ khóa quái không
                    local name = obj.Name:lower()
                    local isEnemy = false
                    for _, kw in pairs(enemyKeywords) do
                        if name:find(kw:lower()) then
                            isEnemy = true
                            break
                        end
                    end
                    if isEnemy then
                        local rootPart = obj:FindFirstChild("HumanoidRootPart")
                        if rootPart then
                            local dist = (rootPart.Position - root.Position).Magnitude
                            if dist < bestDist then
                                bestDist = dist
                                best = obj
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

-- ===== VÒNG LẶP FARM =====
local farmTask = nil
local function toggleFarm()
    AUTO_FARM = not AUTO_FARM
    print("Auto Farm:", AUTO_FARM and "BẬT" or "TẮT")

    if AUTO_FARM then
        if farmTask then farmTask:Disconnect() end
        farmTask = runService.Heartbeat:Connect(function()
            if not AUTO_FARM then return end
            local target = getNearestEnemy()
            if target then
                local char = player.Character
                if char then
                    local humanoid = char:FindFirstChild("Humanoid")
                    if humanoid then
                        -- Di chuyển đến quái
                        local rootPart = target:FindFirstChild("HumanoidRootPart")
                        if rootPart then
                            humanoid:MoveTo(rootPart.Position + Vector3.new(0, 0, 0))
                        end
                        -- Quay mặt về hướng quái
                        local root = char:FindFirstChild("HumanoidRootPart")
                        if root and rootPart then
                            root.CFrame = CFrame.lookAt(root.Position, rootPart.Position)
                        end
                        -- Đánh
                        doAttack()
                        task.wait(ATTACK_INTERVAL)
                    end
                end
            end
        end)
    else
        if farmTask then
            farmTask:Disconnect()
            farmTask = nil
        end
    end
end

-- ===== BIND PHÍM F9 =====
uis.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F9 then
        toggleFarm()
    end
end)

-- ===== HIỂN THỊ MENU (cho mobile) =====
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 120, 0, 40)
btn.Position = UDim2.new(0.8, -60, 0.05, 0)
btn.Text = "🔧 Auto Farm"
btn.TextColor3 = Color3.fromRGB(255,255,255)
btn.BackgroundColor3 = Color3.fromRGB(30,30,50)
btn.BorderSizePixel = 1
btn.BorderColor3 = Color3.fromRGB(0,200,255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 16
btn.Parent = screenGui

btn.MouseButton1Click:Connect(function()
    toggleFarm()
    btn.Text = AUTO_FARM and "✅ Farm ON" or "🔧 Auto Farm"
    btn.BackgroundColor3 = AUTO_FARM and Color3.fromRGB(0,180,0) or Color3.fromRGB(30,30,50)
end)

print("✅ Script loaded. Press F9 or click button to toggle auto farm.")
