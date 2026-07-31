-- =====================================
-- BLOX FRUIT AUTO FARM (Delta/Mobile)
-- Bấm F9 để bật/tắt
-- =====================================

local player = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")

local isFarming = false
local farmConnection = nil

-- Cấu hình
local ATTACK_DELAY = 0.1
local SEARCH_RADIUS = 30

-- Hàm tìm quái gần nhất (dựa vào tên)
local function getNearestEnemy()
    local char = player.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local best = nil
    local bestDist = SEARCH_RADIUS

    for _, obj in pairs(game.Workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
            local hum = obj:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                -- Bỏ qua người chơi
                if not game.Players:FindFirstChild(obj.Name) then
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
    return best
end

-- Hàm tấn công (mô phỏng click chuột)
local function attack()
    -- Thử dùng VirtualInputManager (thường có trong Delta)
    local vim = game:GetService("VirtualInputManager")
    if vim then
        vim:SendMouseButtonEvent(1, 0, 0, true, game, 1)
        task.wait(0.05)
        vim:SendMouseButtonEvent(1, 0, 0, false, game, 1)
        return true
    end

    -- Fallback: dùng mouse click (nếu có)
    local mouse = player:GetMouse()
    if mouse then
        mouse.Button1Down:Fire()
        task.wait(0.05)
        mouse.Button1Up:Fire()
        return true
    end

    print("⚠️ Không tìm thấy cách tấn công!")
    return false
end

-- Hàm bật/tắt farm
local function toggleFarm()
    isFarming = not isFarming

    if isFarming then
        print("✅ Auto Farm BẬT")
        farmConnection = rs.Heartbeat:Connect(function()
            if not isFarming then return end

            local target = getNearestEnemy()
            if target then
                local char = player.Character
                if char then
                    local hum = char:FindFirstChild("Humanoid")
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local targetRoot = target:FindFirstChild("HumanoidRootPart")
                    if hum and root and targetRoot then
                        -- Di chuyển đến quái
                        hum:MoveTo(targetRoot.Position)
                        -- Quay mặt về phía quái
                        root.CFrame = CFrame.lookAt(root.Position, targetRoot.Position)
                        -- Tấn công
                        attack()
                        task.wait(ATTACK_DELAY)
                    end
                end
            else
                -- Nếu không có quái, in ra log (để debug)
                print("🔍 Không tìm thấy quái trong phạm vi")
            end
        end)
    else
        print("❌ Auto Farm TẮT")
        if farmConnection then
            farmConnection:Disconnect()
            farmConnection = nil
        end
    end
end

-- Tạo nút bấm trên màn hình (cho mobile)
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 100, 0, 40)
btn.Position = UDim2.new(0.85, -50, 0.05, 0)
btn.Text = "Farm OFF"
btn.TextColor3 = Color3.fromRGB(255,255,255)
btn.BackgroundColor3 = Color3.fromRGB(200,50,50)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 16
btn.BorderSizePixel = 0
btn.Parent = gui

btn.MouseButton1Click:Connect(function()
    toggleFarm()
    btn.Text = isFarming and "Farm ON" or "Farm OFF"
    btn.BackgroundColor3 = isFarming and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
end)

-- Phím tắt F9
uis.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F9 then
        toggleFarm()
        btn.Text = isFarming and "Farm ON" or "Farm OFF"
        btn.BackgroundColor3 = isFarming and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
    end
end)

print("✅ Script đã sẵn sàng! Bấm F9 hoặc nút trên màn hình để bắt đầu.")
print("💡 Kiểm tra Console (F9) để xem log tìm quái.")
