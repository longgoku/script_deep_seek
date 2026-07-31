-- =============================================
-- BLOX FRUIT AUTO FARM - FIX (dùng click chuột + tìm NPC đúng)
-- Không dùng RemoteEvent, không dùng Humanoid
-- =============================================

local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local vim = game:GetService("VirtualInputManager") -- Bắt buộc cho Delta

-- ===== CẤU HÌNH =====
local ATTACK_INTERVAL = 0.12
local SEARCH_RADIUS = 50
local AUTO_FARM = false

-- ===== HÀM CLICK CHUỘT (mô phỏng tấn công) =====
local function doAttack()
    -- Click trái
    vim:SendMouseButtonEvent(1, 0, 0, true, game, 1)
    task.wait(0.05)
    vim:SendMouseButtonEvent(1, 0, 0, false, game, 1)
end

-- ===== TÌM NPC GẦN NHẤT (bằng tên chính xác từ log) =====
local function getNearestNPC()
    local char = player.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local best = nil
    local bestDist = SEARCH_RADIUS

    -- QUAN TRỌNG: Lấy tất cả model trong Workspace
    for _, obj in pairs(workspace:GetChildren()) do
        -- Kiểm tra nếu obj là NPC (có tên như "Prisoner", "Bandit", v.v.)
        if obj:IsA("Model") and obj.Name ~= player.Name then
            -- Lọc tên NPC dựa trên từ khóa thường gặp (mở rộng theo game)
            local name = obj.Name:lower()
            if name:find("prisoner") or name:find("bandit") or name:find("pirate") or 
               name:find("soldier") or name:find("marine") or name:find("monkey") or
               name:find("shark") or name:find("dragon") or name:find("zombie") or
               name:find("skeleton") or name:find("ghost") or name:find("npc") or
               name:find("mob") then
                
                -- Tìm HumanoidRootPart (thay vì Humanoid)
                local npcRoot = obj:FindFirstChild("HumanoidRootPart")
                if npcRoot then
                    -- Bỏ qua NPC quá cao (lỗi >50k y)
                    if math.abs(npcRoot.Position.Y) < 50000 then
                        local dist = (npcRoot.Position - root.Position).Magnitude
                        if dist < bestDist and dist > 0 then
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

-- ===== VÒNG LẶP FARM =====
local farmTask = nil
local function toggleFarm()
    AUTO_FARM = not AUTO_FARM
    print("Auto Farm:", AUTO_FARM and "BẬT" or "TẮT")

    if AUTO_FARM then
        if farmTask then farmTask:Disconnect() end
        farmTask = runService.Heartbeat:Connect(function()
            if not AUTO_FARM then return end
            local target = getNearestNPC()
            if target then
                local char = player.Character
                if char then
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        -- Di chuyển đến target
                        local targetRoot = target:FindFirstChild("HumanoidRootPart")
                        if targetRoot then
                            humanoid:MoveTo(targetRoot.Position)
                            -- Quay mặt
                            local root = char:FindFirstChild("HumanoidRootPart")
                            if root then
                                root.CFrame = CFrame.lookAt(root.Position, targetRoot.Position)
                            end
                            -- Đánh (click)
                            doAttack()
                            task.wait(ATTACK_INTERVAL)
                        end
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

-- ===== MENU TRÊN MÀN HÌNH =====
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui") or game:GetService("CoreGui")

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 140, 0, 45)
btn.Position = UDim2.new(0.8, -70, 0.03, 0)
btn.Text = "🔧 Auto Farm"
btn.TextColor3 = Color3.fromRGB(255,255,255)
btn.BackgroundColor3 = Color3.fromRGB(40,40,60)
btn.BorderSizePixel = 2
btn.BorderColor3 = Color3.fromRGB(0,200,255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 16
btn.Parent = screenGui

btn.MouseButton1Click:Connect(function()
    toggleFarm()
    btn.Text = AUTO_FARM and "✅ Farm ON" or "🔧 Auto Farm"
    btn.BackgroundColor3 = AUTO_FARM and Color3.fromRGB(0,180,0) or Color3.fromRGB(40,40,60)
end)

print("✅ Script fix loaded. Press F9 or click button.")
