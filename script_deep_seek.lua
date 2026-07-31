-- ============================================================
-- BLOX FRUIT AUTO FARM + FAST ATTACK (Delta/Mobile Fix)
-- Tác giả: palofsc
-- Dùng RemoteEvent "Attack" của game, không dùng VirtualInput
-- Tự động tìm RemoteEvent theo nhiều cách
-- ============================================================

local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- ===== CẤU HÌNH =====
local ATTACK_INTERVAL = 0.1       -- tốc độ đánh (giây)
local SEARCH_RADIUS = 35          -- bán kính tìm quái
local AUTO_FARM = false
local attackRemote = nil          -- RemoteEvent tấn công

-- ===== TÌM REMOTE TẤN CÔNG (thông minh) =====
local function findAttackRemote()
    -- Cách 1: Tìm trực tiếp trong ReplicatedStorage
    local remotes = {
        replicatedStorage:FindFirstChild("Attack"),
        replicatedStorage:FindFirstChild("RemoteEvent"),
        replicatedStorage:FindFirstChild("Combat"),
        replicatedStorage:FindFirstChild("Click"),
        replicatedStorage:FindFirstChild("SwordAttack"),
    }
    for _, r in pairs(remotes) do
        if r and r:IsA("RemoteEvent") then
            return r
        end
    end

    -- Cách 2: Duyệt tất cả các Folder trong ReplicatedStorage
    for _, folder in pairs(replicatedStorage:GetChildren()) do
        if folder:IsA("Folder") then
            for _, child in pairs(folder:GetChildren()) do
                if child:IsA("RemoteEvent") and (
                    child.Name:lower():find("attack") or 
                    child.Name:lower():find("click") or 
                    child.Name:lower():find("sword") or
                    child.Name:lower():find("combat")
                ) then
                    return child
                end
            end
        end
    end

    -- Cách 3: Tìm trong LocalPlayer.PlayerScripts (nếu có)
    local scripts = player:FindFirstChild("PlayerScripts")
    if scripts then
        for _, child in pairs(scripts:GetDescendants()) do
            if child:IsA("RemoteEvent") and child.Name:lower():find("attack") then
                return child
            end
        end
    end

    return nil
end

-- ===== KHỞI TẠO REMOTE =====
attackRemote = findAttackRemote()
if attackRemote then
    print("[Bypass] Tìm thấy RemoteEvent:", attackRemote.Name)
else
    warn("[Bypass] Không tìm thấy RemoteEvent. Thử phương án click thủ công.")
end

-- ===== HÀM TẤN CÔNG =====
local function doAttack()
    if attackRemote then
        -- Gửi RemoteEvent (thường không cần tham số)
        pcall(function()
            attackRemote:FireServer()
        end)
        -- Thử FireServer với tham số (nếu cần)
        pcall(function()
            attackRemote:FireServer(player.Character)
        end)
    else
        -- Phương án dự phòng: gửi sự kiện click chuột qua UserInputService
        -- (cách này ít hiệu quả nhưng vẫn thử)
        uis:SendMouseButtonEvent(1, 0, 0, true)
        task.wait(0.05)
        uis:SendMouseButtonEvent(1, 0, 0, false)
    end
end

-- ===== KIỂM TRA NPC CÓ TỒN TẠI KHÔNG =====
local function isValidNPC(model)
    if not model or not model:IsA("Model") then return false end
    local hum = model:FindFirstChild("Humanoid")
    if not hum then return false end
    if hum.Health <= 0 then return false end
    -- Bỏ qua player
    if game.Players:FindFirstChild(model.Name) then return false end
    -- Bỏ qua các model không có HumanoidRootPart
    if not model:FindFirstChild("HumanoidRootPart") then return false end
    -- Kiểm tra tên (chỉ lấy NPC, không lấy vật phẩm)
    local name = model.Name:lower()
    -- Danh sách từ khóa quái
    local keywords = {"npc", "mob", "bandit", "pirate", "soldier", "marine", "shark", "dragon", "monkey", "zombie", "skeleton", "ghost", "boss", "demon", "warrior", "guard", "knight"}
    for _, kw in pairs(keywords) do
        if name:find(kw) then
            return true
        end
    end
    -- Nếu không trùng từ khóa, nhưng vẫn có Humanoid và không phải player -> coi là NPC
    return true
end

-- ===== TÌM QUÁI GẦN NHẤT =====
local function getNearestEnemy()
    local char = player.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local best = nil
    local bestDist = SEARCH_RADIUS

    for _, obj in pairs(game.Workspace:GetChildren()) do
        if isValidNPC(obj) then
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
    return best
end

-- ===== VÒNG LẶP FARM =====
local farmLoop = nil
function toggleFarm()
    AUTO_FARM = not AUTO_FARM
    print("[AutoFarm] Trạng thái:", AUTO_FARM and "BẬT" or "TẮT")

    if AUTO_FARM then
        if farmLoop then farmLoop:Disconnect() end
        farmLoop = runService.Heartbeat:Connect(function()
            if not AUTO_FARM then return end
            local target = getNearestEnemy()
            if target then
                local char = player.Character
                if char then
                    local hum = char:FindFirstChild("Humanoid")
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local targetRoot = target:FindFirstChild("HumanoidRootPart")
                    if hum and root and targetRoot then
                        -- Di chuyển đến quái
                        hum:MoveTo(targetRoot.Position + Vector3.new(0, 0, 0))
                        -- Quay mặt về quái
                        root.CFrame = CFrame.lookAt(root.Position, targetRoot.Position)
                        -- Tấn công
                        doAttack()
                        task.wait(ATTACK_INTERVAL)
                    end
                end
            else
                -- Nếu không có quái trong tầm, in ra console (debug)
                -- print("[AutoFarm] Không tìm thấy quái trong bán kính.")
            end
        end)
    else
        if farmLoop then
            farmLoop:Disconnect()
            farmLoop = nil
        end
    end
end

-- ===== BIND PHÍM F9 =====
uis.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F9 then
        toggleFarm()
    end
end)

-- ===== MENU CHO MOBILE =====
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 150, 0, 50)
btn.Position = UDim2.new(0.5, -75, 0.92, 0)
btn.Text = "🔧 AUTO FARM"
btn.TextColor3 = Color3.fromRGB(255,255,255)
btn.BackgroundColor3 = Color3.fromRGB(30,30,50)
btn.BorderSizePixel = 2
btn.BorderColor3 = Color3.fromRGB(0,200,255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 18
btn.Parent = screenGui

btn.MouseButton1Click:Connect(function()
    toggleFarm()
    btn.Text = AUTO_FARM and "✅ FARM ON" or "🔧 AUTO FARM"
    btn.BackgroundColor3 = AUTO_FARM and Color3.fromRGB(0,180,0) or Color3.fromRGB(30,30,50)
end)

-- ===== THÔNG BÁO KHỞI TẠO =====
print("[Bypass] Script loaded! Press F9 or click button to toggle.")
print("[Bypass] RemoteEvent:", attackRemote and attackRemote.Name or "Không tìm thấy (dùng click dự phòng)")

-- ===== XỬ LÝ LỖI INFINITE YIELD =====
-- Vô hiệu hóa lỗi chờ JumpButton (nếu có)
pcall(function()
    local touchGui = player.PlayerGui:FindFirstChild("TouchGui")
    if touchGui then
        local touchControl = touchGui:FindFirstChild("TouchControlFrame")
        if touchControl then
            -- Gán giả JumpButton để tránh lỗi
            if not touchControl:FindFirstChild("JumpButton") then
                local fakeBtn = Instance.new("TextButton")
                fakeBtn.Name = "JumpButton"
                fakeBtn.Parent = touchControl
            end
        end
    end
end)

-- ===== CHỐNG CRASH TỪ LỖI NPC Y AXIS =====
-- Bỏ qua các model ở vị trí y > 50000 (lỗi game)
local oldGetChildren = game.Workspace.GetChildren
game.Workspace.GetChildren = function(self)
    local children = oldGetChildren(self)
    local filtered = {}
    for _, child in pairs(children) do
        local root = child:FindFirstChild("HumanoidRootPart")
        if root and root.Position.Y > 50000 then
            -- Bỏ qua
        else
            table.insert(filtered, child)
        end
    end
    return filtered
end

print("[Bypass] Script đã sẵn sàng. Chờ bạn bật Farm.")
